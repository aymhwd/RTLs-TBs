library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.DP83867E_bringup_pkg.all;
    
entity DP83867E_bringup is
    port(
        clk   : in  std_logic ;
        rst_n : in  std_logic ;
        MDIO_O: out std_logic ;
		MDIO_T: out std_logic 
         );
end DP83867E_bringup ;
    
architecture rtl  of DP83867E_bringup is
    
    signal state_reg : state_t;
    signal cnt_word: unsigned(3 downto 0);
    signal cnt_bit: unsigned(4 downto 0);
    signal shift_reg: std_logic_vector(31 downto 0);
    signal mdio_tmp : std_logic;
    signal mdio_ctrl : std_logic;


begin
    mdio_tmp <= shift_reg(31) when (mdio_ctrl = '1') else 'Z';
    mdio_ctrl <= '1' when (state_reg = CONFIG) else '0';
    MDIO_O <= mdio_tmp;
	MDIO_T <= mdio_ctrl;
    -- configuration state machine
    process (clk, rst_n)
    begin
        if (rst_n = '0') then 
            state_reg <= RESET;
            cnt_word <= (others => '0');
            cnt_bit  <= (others => '0');
            shift_reg <= (others => '0');
        elsif (rising_edge(clk)) then

            case state_reg is
                when RESET => 
                    if (rst_n = '1') then
                        state_reg <= SAFE;
                    else
                        state_reg <= RESET;
                    end if;

                when SAFE =>
                    state_reg <= IDLE;
                
                when IDLE => 
                    if (cnt_word = 12) then 
                        state_reg <= IDLE;
                    else
                        cnt_bit  <= (others => '0');
                        shift_reg <= config_vector(to_integer(cnt_word));
                        state_reg <= CONFIG;
                    end if;

                when CONFIG =>
                        shift_reg <= shift_reg(30 downto 0) & '0';
                        if (cnt_bit = 31) then 
                            state_reg <= IDLE;
                            cnt_word <= cnt_word + 1;
                            else
                            cnt_bit <= cnt_bit + 1;
                            state_reg <= CONFIG;
                        end if;

                when others => 
                        state_reg <= RESET;
            end case;
        end if;
    end process;
 
    
end rtl;