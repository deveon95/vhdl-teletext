library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity W_TXT_DATA_PROCESSOR is
    generic (runner_cfg : string);
end entity W_TXT_DATA_PROCESSOR;

architecture tb of W_TXT_DATA_PROCESSOR is

constant CLK_FREQUENCY : integer := 27750000;
constant CLK_PERIOD : time := 1 sec / CLK_FREQUENCY;

signal RESET : std_logic;
signal CLK_27_750 : std_logic := '0';
signal PARALLEL_DATA : std_logic_vector(7 downto 0);
signal PARALLEL_CLOCK : std_logic;
signal PARALLEL_FRAME_VALID : std_logic;
signal PROCESSED_DATA : std_logic_vector(6 downto 0);
signal PROCESSED_DATA_18B : std_logic_vector(17 downto 0);
signal PROCESSED_CLOCK : std_logic;
signal PROCESSED_FRAME_VALID : std_logic;


signal MAGAZINE    : std_logic_vector(2 downto 0);
signal ROW         : std_logic_vector(4 downto 0);
signal PAGE        : std_logic_vector(7 downto 0);
signal SUBCODE     : std_logic_vector(12 downto 0);
signal CONTROL_BITS: std_logic_vector(10 downto 0);

constant NUMBER_OF_BYTES_MAX : integer := 41;
type TEST_ARRAY_TYPE is array (integer range <>) of std_logic_vector(7 downto 0);
signal TEST_ARRAY : TEST_ARRAY_TYPE(0 to NUMBER_OF_BYTES_MAX);
signal RX_DATA : TEST_ARRAY_TYPE(0 to NUMBER_OF_BYTES_MAX - 2);
signal TEST_ARRAY_COUNTER : integer range 0 to NUMBER_OF_BYTES_MAX;
signal RX_COUNTER : integer range 0 to NUMBER_OF_BYTES_MAX;

signal DATA_RECEIVED : std_logic := '0';
signal EXPECT_DATA_RECEIVED : std_logic := '0';
signal HEADER_PACKET : std_logic := '0';

begin
    
    CLK_27_750 <= not CLK_27_750 after CLK_PERIOD / 2;
    PROCESSED_DATA <= PROCESSED_DATA_18B(6 downto 0);

UUT: entity work.TXT_DATA_PROCESSOR
    port map(
    RESET => RESET,
    CLK_27_750 => CLK_27_750,
    BYTE_IN => PARALLEL_DATA,
    BYTE_CLOCK_IN => PARALLEL_CLOCK,
    FRAME_VALID_IN => PARALLEL_FRAME_VALID,
    WORD_OUT => PROCESSED_DATA_18B,
    WORD_CLOCK_OUT => PROCESSED_CLOCK,
    FRAME_VALID_OUT => PROCESSED_FRAME_VALID,
    MAGAZINE_OUT => MAGAZINE,
    ROW_OUT => ROW,
    PAGE_OUT => PAGE,
    SUBCODE_OUT => SUBCODE,
    CONTROL_BITS_OUT => CONTROL_BITS);
    
    
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            RESET <= '1';
            PARALLEL_DATA <= (others => '0');
            PARALLEL_CLOCK <= '0';
            PARALLEL_FRAME_VALID <= '0';
            HEADER_PACKET <= '0';
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
            if run("T001_HEADER_PACKET") then
                TEST_ARRAY <= ("01110011","00010101",
                "00010101","00010101","00010101","11010000","00010101","00010101","01001001","00010101",
                "11110100","11101111","00100000","01001100","11101111","01110011","00100000","11000001",
                "01101110","01100111","11100101","11101100","11100101","01110011","00100000","11101001",
                "01101110","00100000","11110100","11101001","01101101","11100101","00100000","11100110",
                "11101111","11110010","00100000","11110100","01101000","11100101","00100000","00100000");
                EXPECT_DATA_RECEIVED <= '1';
                HEADER_PACKET <= '1';
            elsif run("T002_NORMAL_PACKET_WITH_HEADER") then
                -- Header packet required first to enable reception of data packet
                TEST_ARRAY <= ("01110011","00010101",
                "00010101","00010101","00010101","11010000","00010101","00010101","01001001","00010101",
                "11110100","11101111","00100000","01001100","11101111","01110011","00100000","11000001",
                "01101110","01100111","11100101","11101100","11100101","01110011","00100000","11101001",
                "01101110","00100000","11110100","11101001","01101101","11100101","00100000","11100110",
                "11101111","11110010","00100000","11110100","01101000","11100101","00100000","00100000");
                HEADER_PACKET <= '1';
                wait until rising_edge(CLK_27_750);
                PARALLEL_FRAME_VALID <= '1';
                wait until rising_edge(CLK_27_750);
                for TEST_ARRAY_COUNTER in 0 to NUMBER_OF_BYTES_MAX loop
                    PARALLEL_DATA <= TEST_ARRAY(TEST_ARRAY_COUNTER);
                    PARALLEL_CLOCK <= '1';
                    wait until rising_edge(CLK_27_750);
                    PARALLEL_CLOCK <= '0';
                    for CLOCK_COUNTER in 1 to 8 * 4 - 1 loop
                        wait until rising_edge(CLK_27_750);
                    end loop;
                end loop;
                PARALLEL_FRAME_VALID <= '0';
                wait until rising_edge(CLK_27_750);
                -- Valid packet transmitted after corresponding header
                TEST_ARRAY <= ("10110110","00111000",
                "10000110","01001100","11101111","01101110","01100100","11101111","01101110","00100000",
                "11110100","11101111","00100000","01001100","11101111","01110011","00100000","11000001",
                "01101110","01100111","11100101","11101100","11100101","01110011","00100000","11101001",
                "01101110","00100000","11110100","11101001","01101101","11100101","00100000","11100110",
                "11101111","11110010","00100000","11110100","01101000","11100101","00100000","00100000");
                HEADER_PACKET <= '0';
                EXPECT_DATA_RECEIVED <= '1';
            elsif run("T003_NORMAL_PACKET_NO_HEADER") then
                -- Valid packet but corresponding header has not been received, so packet should be ignored
                TEST_ARRAY <= ("10110110","00111000",
                "10000110","01001100","11101111","01101110","01100100","11101111","01101110","00100000",
                "11110100","11101111","00100000","01001100","11101111","01110011","00100000","11000001",
                "01101110","01100111","11100101","11101100","11100101","01110011","00100000","11101001",
                "01101110","00100000","11110100","11101001","01101101","11100101","00100000","11100110",
                "11101111","11110010","00100000","11110100","01101000","11100101","00100000","00100000");
                HEADER_PACKET <= '0';
                EXPECT_DATA_RECEIVED <= '0';
            elsif run("T004_BAD_PACKET") then
                -- Just a reversal of T003
                TEST_ARRAY <= ("01101101","00011100",
                "01100001","00110010","11110111","01110110","00100110","11110111","01110110","00000100",
                "00101111","11110111","00000100","00110010","11110111","11001110","00000100","10000011",
                "01110110","11100110","10100111","00110111","10100111","11001110","00000100","10010111",
                "01110110","00000100","00101111","10010111","10110110","10100111","00000100","01100111",
                "11110111","01001111","00000100","00101111","00010110","10100111","00000100","00000100");
                HEADER_PACKET <= '0';
                EXPECT_DATA_RECEIVED <= '0';
            elsif run("T005_HEADER_PACKET_BAD_PAGE_ADDRESS") then
                TEST_ARRAY <= ("01110011","00010101",
                "10000110","01001100","11101111","01101110","01100100","11101111","01101110","00100000",
                "11110100","11101111","00100000","01001100","11101111","01110011","00100000","11000001",
                "01101110","01100111","11100101","11101100","11100101","01110011","00100000","11101001",
                "01101110","00100000","11110100","11101001","01101101","11100101","00100000","11100110",
                "11101111","11110010","00100000","11110100","01101000","11100101","00100000","00100000");
                HEADER_PACKET <= '1';
                EXPECT_DATA_RECEIVED <= '0';
            end if;
            
            wait until rising_edge(CLK_27_750);
            PARALLEL_FRAME_VALID <= '1';     -- This should go high one clock cycle before first SERIAL_CLOCK
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            
            for TEST_ARRAY_COUNTER in 0 to NUMBER_OF_BYTES_MAX loop
                PARALLEL_DATA <= TEST_ARRAY(TEST_ARRAY_COUNTER);
                PARALLEL_CLOCK <= '1';
                wait until rising_edge(CLK_27_750);
                PARALLEL_CLOCK <= '0';
                for CLOCK_COUNTER in 1 to 8 * 4 - 1 loop
                    wait until rising_edge(CLK_27_750);
                end loop;
            end loop;
            
            
            PARALLEL_DATA <= (others => '0');
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            wait until rising_edge(CLK_27_750);
            
            assert DATA_RECEIVED = EXPECT_DATA_RECEIVED report "No data received, or data received when it shouldn't" severity error;
            
            -- Check data if data was received
            if DATA_RECEIVED = '1' then
                if HEADER_PACKET = '1' then
                    -- Different checking loop for header packet because first few bytes are not written to the dual port RAM
                    for RX_CHECK_COUNTER in 0 to NUMBER_OF_BYTES_MAX - 10 loop
                        assert RX_DATA(RX_CHECK_COUNTER)(6 downto 0) = TEST_ARRAY(RX_CHECK_COUNTER + 10)(6 downto 0) report "RX data does not match TX data, No: " & to_string(RX_CHECK_COUNTER) & " Expected: " & to_string(TEST_ARRAY(RX_CHECK_COUNTER + 2)(6 downto 0)) & " Received: " & to_string(RX_DATA(RX_CHECK_COUNTER)(6 downto 0)) severity error;
                    end loop;
                else
                    -- Checking loop for non-header packet
                    for RX_CHECK_COUNTER in 0 to NUMBER_OF_BYTES_MAX - 2 loop
                        assert RX_DATA(RX_CHECK_COUNTER)(6 downto 0) = TEST_ARRAY(RX_CHECK_COUNTER + 2)(6 downto 0) report "RX data does not match TX data, No: " & to_string(RX_CHECK_COUNTER) & " Expected: " & to_string(TEST_ARRAY(RX_CHECK_COUNTER + 2)(6 downto 0)) & " Received: " & to_string(RX_DATA(RX_CHECK_COUNTER)(6 downto 0)) severity error;
                    end loop;
                end if;
            end if;
            report "Page number, subcode and control bit output checking not implemented" severity warning;
            
        end loop;
        test_runner_cleanup(runner); -- Simulation ends here
    end process;
    
    RX_CHECK: process
    begin
        wait until PROCESSED_FRAME_VALID = '1';
        DATA_RECEIVED <= '1';
        loop
            wait until PROCESSED_CLOCK = '1' or PARALLEL_FRAME_VALID = '0';
            if PROCESSED_FRAME_VALID = '1' then
                RX_DATA(RX_COUNTER) <= '0' & PROCESSED_DATA;
                RX_COUNTER <= RX_COUNTER + 1;
            end if;
            if PARALLEL_FRAME_VALID = '0' then
                RX_COUNTER <= 0;
            end if;
        end loop;
    end process;
end architecture;
