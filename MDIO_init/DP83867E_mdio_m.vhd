library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.DP83867E_bringup_pkg.all;
    
entity DP83867E_mdio_m is
	generic(
		command_mode		: cmd_opmode:= INTERNAL;
		prescale_count		: integer	:= 3
	);
    port(
        clk					: in  std_logic;
        rst_n				: in  std_logic;
		
		--Input command data
		cmd_phyaddr			: in std_logic_vector(4 downto 0);
		cmd_regaddr			: in std_logic_vector(4 downto 0);
		cmd_data			: in std_logic_vector(15 downto 0);
		cmd_opcode			: in std_logic_vector(1 downto 0);
		
		--Handshaking signals with the external controller
		cmd_valid			: in std_logic;
		cmd_ready			: out std_logic;
		
		--Data received from PHY interface
		data_out			: out std_logic_vector(15 downto 0);
		data_out_valid		: out std_logic;
		data_out_ready		: in std_logic;
		
		--MDIO interface signals
		mdc					: out std_logic;
		mdio_i				: in std_logic  ;
        mdio_o				: out std_logic ;
		mdio_t				: out std_logic 
		
         );
end DP83867E_mdio_m ;

architecture rtl  of DP83867E_mdio_m is
	
	constant mdc_cnt_w 						: integer := 16;							--MDC scaler counter width
	constant dataread_slot_order			: unsigned(5 downto 0) := "010011";			--The start bit order of the data to be read from PHY registers
	
	signal data_wrd_count					: unsigned(3 downto 0);
	signal op_rec1, op_rec2, op_rec3		: state_t;									--Declaring 3 registers to increment the word count based on last 3 states
	
	signal state_reg, state_next			: state_t;									--FSM register signals
	signal mdcnt_reg, mdcnt_next			: std_logic_vector(mdc_cnt_w-1 downto 0);	--MDC clock scaling counter register signals
    signal bit_count_reg, bit_count_next	: std_logic_vector(5 downto 0);				--MDIO bit counter register signals
	signal mdcycle_reg, mdcycle_next		: std_logic;								--Flag register signals for resetting the scaling counter
	signal cmdrdy_reg, cmdrdy_next			: std_logic;								--Command Ready Handshaking register signals
	--MDIO Interface registers signals
	signal mdc_reg, mdc_next				: std_logic;								--MDC register signals
	signal mdio_o_reg, mdio_o_next			: std_logic;								--MDIO output register signals
	signal mdio_t_reg, mdio_t_next			: std_logic;								--MDIO Tristate buffer control register signals
	signal mdio_i_reg						: std_logic;								--MDIO input signal
	
	--MDIO data register signals
	signal op_reg, op_next					: std_logic_vector(1 downto 0);				--OPCODE 2-bit register signals
	signal data_reg, data_next				: std_logic_vector(31 downto 0);			--PHY Entire Command Register

	--Data received from PHY interface signals
	signal data_out_valid_reg, data_out_valid_next: std_logic; 							--Handshaking signal registers
	signal data_out_reg, data_out_next		: std_logic_vector(15 downto 0);			--Output data register signals
	
begin
	--Wiring I/O signals to registers outputs
	mdc			<= mdc_reg;
	mdio_o		<= mdio_o_reg;
	mdio_t		<= mdio_t_reg;
	cmd_ready	<= cmdrdy_reg;
	data_out	<= data_out_reg;
	data_out_valid	<= data_out_valid_reg;
	
	
	--Next state combinational logic process
	process (all)
	begin
		--Setting default values for next state signals
		state_next		<= IDLE;
		mdcnt_next		<= mdcnt_reg;
		bit_count_next	<= bit_count_reg;
		mdcycle_next	<= mdcycle_reg;
		cmdrdy_next		<= '0';
		op_next			<= op_reg;
		mdc_next		<= mdc_reg;
		mdio_o_next		<= mdio_o_reg;
		mdio_t_next		<= mdio_t_reg;
		mdio_i_reg		<= '1';
		data_out_next	<= data_out_reg;
		data_out_valid_next <= data_out_valid_reg and (not data_out_ready);
		if unsigned(mdcnt_reg) > 0 then
			--Wait for MDC cycle
			mdcnt_next	<= std_logic_vector(unsigned(mdcnt_reg) - 1);
			state_next	<= state_reg;
		elsif (mdcycle_reg = '1') then
			mdcycle_next <= '0';
			mdc_next <= '1';
			mdcnt_next <= std_logic_vector(to_unsigned(prescale_count,mdc_cnt_w));
			state_next <= state_reg;
		else
			mdc_next <= '0';
			case state_reg is
			
                when IDLE => 
					cmdrdy_next <= '1';
					--Handshaking success check
					if cmd_ready = '1' and cmd_valid = '1' then
						cmdrdy_next <= '0';
						case command_mode is
							when INTERNAL =>
								data_next <= config_vector(to_integer(data_wrd_count));
							when others =>
								data_next <= START & cmd_opcode & cmd_phyaddr & cmd_regaddr & TA & cmd_data;
						end case;
						op_next <= cmd_opcode;
						mdio_t_next <= '0';
						mdio_o_next <= '1';
						bit_count_next <= "100000";		--Initializing bit count to the max number of bits
						mdcycle_next <= '1';
						mdcnt_next <= std_logic_vector(to_unsigned(prescale_count,mdc_cnt_w));	--Resetting the MDC scaler counter
						state_next <= PREAMBLE;
					else
						state_next <= IDLE;
					end if;
					
                when PREAMBLE =>
                    mdcycle_next <= '1';
					mdcnt_next <= std_logic_vector(to_unsigned(prescale_count,mdc_cnt_w));
					if unsigned(bit_count_reg) > 1 then
						bit_count_next <= std_logic_vector(unsigned(bit_count_reg)-1);
						state_next <= PREAMBLE;
					else
						bit_count_next <= "100000";	--Resetting the bit count to the number of preamble bits to be sent (32)
						mdio_o_next <= data_reg(data_reg'length-1);
						data_next <= data_reg(data_reg'length-2 downto 0) & mdio_i_reg;
						state_next <= CONFIG;
					end if;
                when CONFIG => 
                    mdcycle_next <= '1';
					mdcnt_next <= std_logic_vector(to_unsigned(prescale_count,mdc_cnt_w));
					if (op_reg = "10" or op_reg = "11") and bit_count_reg = std_logic_vector(dataread_slot_order) then
						mdio_t_next <= '1';	--Driving the Tristate buffer to read mode
					end if;
					if unsigned(bit_count_reg) > 1 then
						bit_count_next <= std_logic_vector(unsigned(bit_count_reg)-1);
						mdio_o_next <= data_reg(data_reg'length-1);
                        data_next <= data_reg(data_reg'length-2 downto 0) & mdio_i_reg;
						state_next <= CONFIG;
					else
						if (op_reg = OP_RD1 or op_reg = OP_RD2) then
							data_out_next <= data_reg(15 downto 0);
							data_out_valid_next <= '1';
						end if;
						mdio_t_next <= '1';
						state_next <= IDLE;
					end if;
                when others => 
                        state_reg <= IDLE;
            end case;
		
		
		end if;
	end process;
	

    process (clk)
    begin
		if (rising_edge(clk)) then
			
			if(rst_n = '0') then
				state_reg <= IDLE;
				mdcnt_reg <= (others => '0');
				bit_count_reg <= (others => '0');
				mdcycle_reg <= '0';
				cmdrdy_reg <= '0';
				mdc_reg <= '0';
				mdio_o_reg <= '0';
				mdio_t_reg <= '1';
				data_wrd_count <= (others => '0');
				op_rec1 <= IDLE;
				op_rec2 <= IDLE;
				op_rec3 <= IDLE;
			else
				op_rec1 <= state_reg;
				op_rec2 <= op_rec1;
				op_rec3 <= op_rec2;
				state_reg <= state_next;
				mdcnt_reg <= mdcnt_next;
				bit_count_reg <= bit_count_next;
				mdcycle_reg <= mdcycle_next;
				cmdrdy_reg <= cmdrdy_next;
				mdc_reg <= mdc_next;
				mdio_o_reg <= mdio_o_next;
				mdio_t_reg <= mdio_t_next;
				data_out_valid_reg <= data_out_valid_next;
				if (op_rec1 = IDLE and op_rec2 = PREAMBLE and op_rec3 = CONFIG) then
					--If a configuration operation was done increment the word counter
					if (data_wrd_count = 11) then
						data_wrd_count <= (others => '0');
					else
						data_wrd_count <= data_wrd_count + 1;
					end if;
				else
					data_wrd_count <= data_wrd_count;
				end if;
				
			end if;
			--I/O registers
			data_reg <= data_next;
			op_reg <= op_next;
			mdio_i_reg <= mdio_i;
			data_out_reg <= data_out_next;
		end if;
    end process;
 
    
end rtl;