library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.DP83867E_bringup_pkg.all;


entity DP83867E_bringup_tb is 
end DP83867E_bringup_tb;

architecture behav  of DP83867E_bringup_tb is

component DP83867E_bringup is
    port(
        clk   : in  std_logic ;
        rst_n : in  std_logic ;
        MDIO  : out std_logic
         );
end component ;

signal clk   : std_logic := '0';
signal rst_n : std_logic := '0';
signal MDIO  : std_logic;

signal start: std_logic_vector (1 downto 0);
signal opcode: std_logic_vector (1 downto 0);
signal TA: std_logic_vector (1 downto 0);
signal phy: std_logic_vector(4 downto 0);
signal reg: std_logic_vector(4 downto 0);
signal data: std_logic_vector(15 downto 0);

type vector_phy is array (0 to 11) of std_logic_vector (4 downto 0);
type vector_reg is array (0 to 11) of std_logic_vector (4 downto 0);
type vector_data is array (0 to 11) of std_logic_vector (15 downto 0);

constant start_ref: std_logic_vector (1 downto 0) := "01";
constant opcode_ref: std_logic_vector (1 downto 0) := "01";
constant TA_ref: std_logic_vector (1 downto 0) := "10";
constant phy_ref: vector_phy := ("00011", "00011", "00011", "00011", "00011", "00011", "00011", "00011", "00011", "00011", "00011", "00011");
constant reg_ref: vector_reg := ("01101", "01110", "01101", "01110", "01101", "01110", "01101", "01110", "01101", "01110", "01101", "01110");
constant data_ref: vector_data := (x"001F", x"0031", x"401F", x"0070", x"001F", x"00D3", x"401F", x"4000", x"001F", x"016F", x"401F", x"0015");

begin 
dut : DP83867E_bringup
    port map(
        clk   => clk,  
        rst_n => rst_n,
        MDIO  => MDIO 
    );

clk <= not clk after 50 ns;

process begin
    wait for 250 ns;
    rst_n <= '1';

	for idx in 0 to 11 loop	
		--wait for the start of the operation
		wait until (MDIO /= 'Z');
		--register the start sequence
		for i in 1 downto 0 loop
			wait for 10 ns;
			start(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--register the opcode sequence
		for i in 1 downto 0 loop
			wait for 10 ns;
			opcode(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--register the phy address
		for i in 4 downto 0 loop
			wait for 10 ns;
			phy(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--register the reg address
		for i in 4 downto 0 loop
			wait for 10 ns;
			reg(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--register the TA sequence
		for i in 1 downto 0 loop
			wait for 10 ns;
			TA(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--register the data
		for i in 15 downto 0 loop
			wait for 10 ns;
			data(i) <= MDIO;
			wait until(rising_edge(clk));
		end loop;
		--checking and reporting
		wait for 10 ns;
		if((phy = phy_ref(idx)) and (reg = reg_ref(idx)) and (data = data_ref(idx)) and (start = start_ref) and (opcode = opcode_ref) and (TA = TA_ref)) then
			report "success in state " & integer'image(idx+1);
		else
			report "error in state " & integer'image(idx+1);
		end if;
		--restart
		phy <= "XXXXX";
		reg <= "XXXXX";
		data <= "XXXXXXXXXXXXXXXX";
	end loop;
	
end process;


end behav;