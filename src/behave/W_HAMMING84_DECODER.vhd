library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_HAMMING84_DECODER is
    generic (runner_cfg : string);
end entity W_HAMMING84_DECODER;

architecture tb of W_HAMMING84_DECODER is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;

signal CLK_27_750 : std_logic := '0';
signal ENCODED_DATA : std_logic_vector(7 downto 0);
signal DECODED_DATA : std_logic_vector(3 downto 0);
signal DATA_VALID : std_logic;
signal EXPECTED_DECODED_DATA : std_logic_vector(3 downto 0);
signal EXPECTED_DATA_VALID : std_logic;

begin
    
    CLK_27_750 <= not CLK_27_750 after CLK_PERIOD / 2;

UUT: entity work.HAMMING84_DECODER
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
            -- All test data MSB first, so bit order is D4,P4,D3,P3,D2,P2,D1,P1 for encoded data and D4,D3,D2,D1 for decoded data
            if run("T001_VALID") then
                ENCODED_DATA <= "11101010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T002_D1_ERROR") then
                ENCODED_DATA <= "11101000";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T003_D2_ERROR") then
                ENCODED_DATA <= "11100010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T004_D3_ERROR") then
                ENCODED_DATA <= "11001010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T005_D4_ERROR") then
                ENCODED_DATA <= "01101010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T006_P1_ERROR") then
                ENCODED_DATA <= "11101011";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T007_P2_ERROR") then
                ENCODED_DATA <= "11101110";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T008_P3_ERROR") then
                ENCODED_DATA <= "11111010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T009_P4_ERROR") then
                ENCODED_DATA <= "10101010";
                EXPECTED_DECODED_DATA <= "1111";
                EXPECTED_DATA_VALID <= '1';
            elsif run("T010_DOUBLE_ERROR") then
                ENCODED_DATA <= "11100000";
                EXPECTED_DECODED_DATA <= "0000";
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
