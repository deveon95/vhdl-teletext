library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_TXT_DATA_RECOVERY is
    generic (runner_cfg : string);
end entity;

architecture tb of W_TXT_DATA_RECOVERY is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;

signal RESET : std_logic;
signal CLK_27_750 : std_logic := '0';
signal RX : std_logic;
signal SERIAL_DATA : std_logic;
signal SERIAL_CLOCK : std_logic;
signal FRAME_VALID : std_logic;

constant BIT_SAMPLE_COUNTER_MAX : integer := 3;
constant BIT_NUMBER_COUNTER_MAX : integer := 359;
signal TEST_ARRAY : std_logic_vector(BIT_NUMBER_COUNTER_MAX downto 0);
signal IMBALANCE_ENABLE : std_logic;

signal NO_DATA_RECEIVED : std_logic := '1';
constant RX_BIT_NUMBER_COUNTER_MAX : integer := 336;
signal RX_COUNTER : integer range 0 to RX_BIT_NUMBER_COUNTER_MAX;
signal RX_SHIFT_REGISTER : std_logic_vector(RX_BIT_NUMBER_COUNTER_MAX - 1 downto 0);

begin
    
    CLK_27_750 <= not CLK_27_750 after CLK_PERIOD / 2;

UUT: entity work.TXT_DATA_RECOVERY
    port map(
    RESET => RESET,
    CLK_27_750 => CLK_27_750,
    RX_IN => RX,
    SERIAL_DATA_OUT => SERIAL_DATA,
    SERIAL_CLOCK_OUT => SERIAL_CLOCK,
    FRAME_VALID_OUT => FRAME_VALID);
    
    
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            RESET <= '1';
            RX <= '0';
            IMBALANCE_ENABLE <= '0';
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            RESET <= '0';
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            if run("T001_PERFECT_SIGNAL") then
                TEST_ARRAY <= B"10101010_10101010_11100100_01101101_00011100" &
                B"01100001_00110010_11110111_01110110_00100110_11110111_01110110_00000100" &
                B"00101111_11110111_00000100_00110010_11110111_11001110_00000100_10000011" &
                B"01110110_11100110_10100111_00110111_10100111_11001110_00000100_10010111" &
                B"01110110_00000100_00101111_10010111_10110110_10100111_00000100_01100111" &
                B"11110111_01001111_00000100_00101111_00010110_10100111_00000100_00000100";
                IMBALANCE_ENABLE <= '0';
            elsif run("T002_IMBALANCED_SIGNAL") then
                TEST_ARRAY <= B"10101010_10101010_11100100_01101101_00011100" &
                B"01100001_00110010_11110111_01110110_00100110_11110111_01110110_00000100" &
                B"00101111_11110111_00000100_00110010_11110111_11001110_00000100_10000011" &
                B"01110110_11100110_10100111_00110111_10100111_11001110_00000100_10010111" &
                B"01110110_00000100_00101111_10010111_10110110_10100111_00000100_01100111" &
                B"11110111_01001111_00000100_00101111_00010110_10100111_00000100_00000100";
                IMBALANCE_ENABLE <= '1';
            end if;
            
            wait until rising_edge(CLK_27_750);
            
            for BIT_NUMBER_COUNTER in 0 to BIT_NUMBER_COUNTER_MAX loop
                RX <= TEST_ARRAY(BIT_NUMBER_COUNTER_MAX - BIT_NUMBER_COUNTER);
                for BIT_SAMPLE_COUNTER in 0 to BIT_SAMPLE_COUNTER_MAX loop
                    if BIT_SAMPLE_COUNTER = BIT_SAMPLE_COUNTER_MAX and IMBALANCE_ENABLE = '1' and BIT_NUMBER_COUNTER < BIT_NUMBER_COUNTER_MAX then
                        RX <= TEST_ARRAY(BIT_NUMBER_COUNTER_MAX - BIT_NUMBER_COUNTER) and TEST_ARRAY(BIT_NUMBER_COUNTER_MAX - BIT_NUMBER_COUNTER - 1);
                    end if;
                    wait until rising_edge(CLK_27_750);
                end loop;
            end loop;
            
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            assert NO_DATA_RECEIVED = '0' report "No data received" severity error;
            assert RX_SHIFT_REGISTER = TEST_ARRAY(RX_BIT_NUMBER_COUNTER_MAX - 1 downto 0) report "Received data does not match transmitted data" severity error;
            
        end loop;
        test_runner_cleanup(runner); -- Simulation ends here
    end process;
    
    RX_CHECK: process
    begin
        wait until FRAME_VALID = '1';
        NO_DATA_RECEIVED <= '0';
        loop
            wait until SERIAL_CLOCK = '1';
            RX_SHIFT_REGISTER <= RX_SHIFT_REGISTER(RX_BIT_NUMBER_COUNTER_MAX - 2 downto 0) & SERIAL_DATA;
            RX_COUNTER <= RX_COUNTER + 1;
        end loop;
    end process;
end architecture;
