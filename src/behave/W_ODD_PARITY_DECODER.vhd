library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_ODD_PARITY_DECODER is
    generic (runner_cfg : string);
end entity W_ODD_PARITY_DECODER;

architecture tb of W_ODD_PARITY_DECODER is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;

signal CLK_27_750 : std_logic := '0';
signal ENCODED_DATA : std_logic_vector(7 downto 0);
signal DECODED_DATA : std_logic_vector(6 downto 0);
signal DATA_VALID : std_logic;
signal EXPECTED_DECODED_DATA : std_logic_vector(6 downto 0);
signal EXPECTED_DATA_VALID : std_logic;

begin
    
    CLK_27_750 <= not CLK_27_750 after CLK_PERIOD / 2;

UUT: entity work.ODD_PARITY_DECODER
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
            -- All test data MSB first, so MSB is the parity bit
            if run("T001_INVALID") then
                ENCODED_DATA <= "01010101";
                EXPECTED_DECODED_DATA <= "1010101";
                EXPECTED_DATA_VALID <= '0';
            elsif run("T002_VALID") then
                ENCODED_DATA <= "11001110";
                EXPECTED_DECODED_DATA <= "1001110";
                EXPECTED_DATA_VALID <= '1';
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
