library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_KEYPAD is
    generic (runner_cfg : string);
end entity W_KEYPAD;

architecture tb of W_KEYPAD is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;
constant MOMENTARY_MASK : std_logic_vector(35 downto 0) := "001111001111001111001111001111000000";

signal RESET : std_logic;
signal CLK : std_logic := '0';

signal COLS : std_logic_vector(5 downto 0);
signal ROWS : std_logic_vector(5 downto 0);
signal BUTTONS : std_logic_vector(35 downto 0);
signal FIRST_PASS : std_logic;

begin
    
    CLK <= not CLK after CLK_PERIOD / 2;
    ROWS <= (others => 'H');
    COLS <= (others => 'H');

UUT: entity work.KEYPAD
    generic map(
    COLS => 6,
    ROWS => 6,
    DELAY => 10,
    MOMENTARY_MASK => MOMENTARY_MASK
    )
    port map(
    RESET => RESET,
    CLK => CLK,
    COLS_IN => COLS,
    ROWS_OUT => ROWS,
    BUTTONS_OUT => BUTTONS,
    FIRST_PASS_OUT => FIRST_PASS);
    
    
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            RESET <= '1';
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
            RESET <= '0';
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
            if run("T001_PRESS_COL_1_ROW_6") then
                COLS <= (others => '1');
                wait until ROWS = "0HHHHH";
                COLS <= "111110";
                wait until ROWS /= "0HHHHH";
                COLS <= "111111";
                wait until rising_edge(CLK);
                assert BUTTONS = "000001000000000000000000000000000000" report "Button press not detected" severity error;
                COLS <= (others => '1');
                wait until ROWS = "0HHHHH";
                COLS <= "111110";
                wait until ROWS /= "0HHHHH";
                COLS <= "111111";
                wait until rising_edge(CLK);
                assert BUTTONS = "000000000000000000000000000000000000" report "Button output not momentary" severity error;
                COLS <= (others => '1');
                wait until ROWS = "0HHHHH";
                COLS <= "111111";
                wait until ROWS /= "0HHHHH";
                COLS <= "111111";
                wait until rising_edge(CLK);
                assert BUTTONS = "000000000000000000000000000000000000" report "Button output not cleared after release" severity error;
            elsif run("T002_DIPSW_COL_6_ROW_1") then
                COLS <= (others => '1');
                wait until ROWS = "HHHHH0";
                COLS <= "011111";
                wait until ROWS /= "HHHHH0";
                COLS <= "111111";
                wait until rising_edge(CLK);
                assert BUTTONS = "000000000000000000000000000000100000" report "DIP switch not detected" severity error;
                COLS <= (others => '1');
                wait until ROWS = "HHHHH0";
                COLS <= "011111";
                wait until ROWS /= "HHHHH0";
                COLS <= "111111";
                wait until rising_edge(CLK);
                assert BUTTONS = "000000000000000000000000000000100000" report "DIP switch output incorrectly momentary" severity error;
            end if;
            
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
            wait until rising_edge(CLK);
            
        end loop;
        test_runner_cleanup(runner); -- Simulation ends here
    end process;
    
end architecture;
