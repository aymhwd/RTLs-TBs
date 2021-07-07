library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
    
package  DP83867E_bringup_pkg is
    constant START : std_logic_vector(1 downto 0) := "01";
    constant OP_WR : std_logic_vector(1 downto 0) := "01";
	constant OP_RD1: std_logic_vector(1 downto 0) := "10";
	constant OP_RD2: std_logic_vector(1 downto 0) := "11";
    constant TA    : std_logic_vector(1 downto 0) := "10";
    constant PHY_ADDR : std_logic_vector(4 downto 0) := 5X"03";
    constant REG1  : std_logic_vector(4 downto 0) := 5X"0D";
    constant REG2  : std_logic_vector(4 downto 0) := 5X"0E";
    constant DATA0 : std_logic_vector(15 downto 0):= x"001F";
    constant DATA1 : std_logic_vector(15 downto 0):= x"0031";
    constant DATA2 : std_logic_vector(15 downto 0):= x"401F";
    constant DATA3 : std_logic_vector(15 downto 0):= x"0070";
    constant DATA4 : std_logic_vector(15 downto 0):= x"001F";
    constant DATA5 : std_logic_vector(15 downto 0):= x"00D3";
    constant DATA6 : std_logic_vector(15 downto 0):= x"401F";
    constant DATA7 : std_logic_vector(15 downto 0):= x"4000";
    constant DATA8 : std_logic_vector(15 downto 0):= x"001F";
    constant DATA9 : std_logic_vector(15 downto 0):= x"016F";
    constant DATA10: std_logic_vector(15 downto 0):= x"401F";
    constant DATA11: std_logic_vector(15 downto 0):= x"0015";

    
    type vector_t is array (0 to 11) of std_logic_vector (31 downto 0);
    constant config_vector: vector_t := (
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA0,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA1,
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA2,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA3,
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA4,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA5,
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA6,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA7,
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA8,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA9,
        START & OP_WR & PHY_ADDR & REG1 & TA & DATA10,
        START & OP_WR & PHY_ADDR & REG2 & TA & DATA11
    );

    type state_t is (IDLE, PREAMBLE, CONFIG);
	type cmd_opmode is (INTERNAL, EXTERNAL);
end package DP83867E_bringup_pkg ;
    
