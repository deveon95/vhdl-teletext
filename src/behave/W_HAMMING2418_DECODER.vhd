library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_HAMMING2418_DECODER is
    generic (runner_cfg : string);
end entity W_HAMMING2418_DECODER;

architecture tb of W_HAMMING2418_DECODER is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;

signal CLK_27_750 : std_logic := '0';
signal ENCODED_DATA : std_logic_vector(23 downto 0);
signal DECODED_DATA : std_logic_vector(17 downto 0);
signal DATA_VALID : std_logic;
signal EXPECTED_DECODED_DATA : std_logic_vector(17 downto 0);
signal EXPECTED_DATA_VALID : std_logic;

begin
    
    CLK_27_750 <= not CLK_27_750 after CLK_PERIOD / 2;

UUT: entity work.HAMMING2418_DECODER
    port map(
    DATA_IN => ENCODED_DATA,
    DATA_OUT => DECODED_DATA,
    DATA_VALID_OUT => DATA_VALID);
    
    
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            ENCODED_DATA <= (others => '0');
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            -- All test data MSB first
            if run("T001_VALID") then
                ENCODED_DATA <= "111111110111111101110100";
                EXPECTED_DECODED_DATA <= "111111111111111111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T002_VALID") then
                ENCODED_DATA <= "000000001000000010001011";
                EXPECTED_DECODED_DATA <= "000000000000000000";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T003_P6_ERROR") then
                ENCODED_DATA <= "100000001000000010001011";
                EXPECTED_DECODED_DATA <= "000000000000000000";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T002_D5_ERROR") then
                ENCODED_DATA <= "000000001000000110001011";
                EXPECTED_DECODED_DATA <= "000000000000000000";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T002_D5_AND_D6_ERROR") then
                ENCODED_DATA <= "000000001000001110001011";
                EXPECTED_DECODED_DATA <= "000000000000000000";
                EXPECTED_DATA_VALID <= '0';
            end if;
            
            wait until rising_edge(CLK_27_750);
            assert DECODED_DATA = EXPECTED_DECODED_DATA report "Decoded data does not match expectation" severity error;
            assert DATA_VALID = EXPECTED_DATA_VALID report "Data Valid does not match expectation" severity error;
            
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
        end loop;
        test_runner_cleanup(runner); -- Simulation ends here
    end process;
    
end architecture;
