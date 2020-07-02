-- SI5351.vhd
-- A really simple controller for the SI5351
-- Clocked by the MAX10 built-in oscillator
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SI5351 is
    port (
    RESET                   : in  std_logic;
    CLOCK                   : in  std_logic;
    SDA_OUT                 : out std_logic;
    SCL_OUT                 : out std_logic;
    SDA_IN                  : in  std_logic;
    SCL_IN                  : in  std_logic;
    REFRESH_RATE_SELECT_IN  : in  std_logic;
    RESOLUTION_SELECT_IN    : in  std_logic;
    COMPLETE_OUT            : out std_logic
    );
end entity SI5351;

architecture RTL of SI5351 is
-- Length of each bit in clock cycles (I2C speed of roughly 25kHz)
constant SUBBIT_LENGTH : integer := 250;
-- power-on delay
constant INIT_LENGTH : integer := 100000;
-- Number of data bytes to write to slave
constant CONFIG_DATA_SIZE : integer := 233;

signal DELAY_COUNTER : integer range 0 to INIT_LENGTH;
signal SUBBIT_COUNTER : integer range 0 to 3;
signal BIT_COUNTER : integer range 0 to 10;
signal BYTE_COUNTER : integer range 0 to CONFIG_DATA_SIZE - 1;
signal BYTE_COUNTER_SLV : std_logic_vector(7 downto 0);
signal SDA_SYNCED, SDA_SYNCER, SCL_SYNCED, SCL_SYNCER : std_logic;
signal REF_SYNCER, REF_SYNCED : std_logic;
signal RES_SYNCER, RES_SYNCED : std_logic;
signal REFRESH_RATE_SELECT_LATCHED : std_logic;
signal RESOLUTION_SELECT_LATCHED : std_logic;

type DATA_ARRAY is array (0 to CONFIG_DATA_SIZE - 1) of std_logic_vector(7 downto 0);

-- To update the configuration:
-- 1. Open si5351.txt in a diff tool
-- 2. Generate new configuration using "Save device registers (not for factory programming)" in Clockbuilder Desktop
-- 3. Compare new configuration with old using the diff tool to see which bytes below must be changed
-- 4. LEAVE ALL REGISTERS 188 and above set to 0 even if ClockBuilder tells you different. Non-zero values will cause the slave to NACK and the clock configuration will not be accepted.

-- CLK0: 27.750 MHz
-- CLK1: 27.000 MHz
-- CLK2: disabled
constant DATA_576P50 : DATA_ARRAY := (
x"00", x"00", x"18", x"00", x"00", x"00", x"00", x"00",         -- 0..7
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 8..15
x"6F", x"4F", x"83", x"80", x"80", x"80", x"80", x"80",         -- 16..23
x"00", x"00", x"00", x"05", x"00", x"0E", x"33", x"00",         -- 24..31
x"00", x"01", x"00", x"32", x"00", x"0C", x"6E", x"00",         -- 32..39
x"00", x"04", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 40..47
x"00", x"00", x"00", x"01", x"00", x"0D", x"00", x"00",         -- 48..55
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 56..63
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 64..71
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 72..79
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 80..87
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 88..95
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 96..103
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 104..111
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 112..119
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 120..127
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 128..135
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 136..143
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 144..151
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 152..159
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 160..167
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 168..175
x"00", x"00", x"00", x"00", x"00", x"30", x"00", x"D2",         -- 176..183
x"60", x"60", x"00", x"C0", x"00", x"00", x"00", x"00",         -- 184..191
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 192..199
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 200..207
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 208..215
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 216..223
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 224..231
x"00");

-- CLK0: 27.750 MHz
-- CLK1: 32.400 MHz
-- CLK2: disabled
constant DATA_576P60 : DATA_ARRAY := (
x"00", x"00", x"18", x"00", x"00", x"00", x"00", x"00",         -- 0..7
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 8..15
x"6F", x"4F", x"83", x"80", x"80", x"80", x"80", x"80",         -- 16..23
x"00", x"00", x"00", x"7D", x"00", x"0E", x"D9", x"00",         -- 24..31
x"00", x"0B", x"00", x"32", x"00", x"0C", x"6E", x"00",         -- 32..39
x"00", x"04", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 40..47
x"00", x"00", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 48..55
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 56..63
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 64..71
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 72..79
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 80..87
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 88..95
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 96..103
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 104..111
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 112..119
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 120..127
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 128..135
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 136..143
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 144..151
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 152..159
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 160..167
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 168..175
x"00", x"00", x"00", x"00", x"00", x"30", x"00", x"D2",         -- 176..183
x"60", x"60", x"00", x"C0", x"00", x"00", x"00", x"00",         -- 184..191
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 192..199
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 200..207
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 208..215
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 216..223
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 224..231
x"00");

-- CLK0: 27.750 MHz
-- CLK1: 33.333 MHz
-- CLK2: disabled
constant DATA_600P50 : DATA_ARRAY := (
x"00", x"00", x"18", x"00", x"00", x"00", x"00", x"00",         -- 0..7
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 8..15
x"6F", x"4F", x"83", x"80", x"80", x"80", x"80", x"80",         -- 16..23
x"00", x"00", x"E8", x"48", x"00", x"0F", x"55", x"10",         -- 24..31
x"A2", x"98", x"00", x"32", x"00", x"0C", x"6E", x"00",         -- 32..39
x"00", x"04", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 40..47
x"00", x"00", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 48..55
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 56..63
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 64..71
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 72..79
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 80..87
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 88..95
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 96..103
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 104..111
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 112..119
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 120..127
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 128..135
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 136..143
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 144..151
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 152..159
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 160..167
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 168..175
x"00", x"00", x"00", x"00", x"00", x"30", x"00", x"D2",         -- 176..183
x"60", x"60", x"00", x"C0", x"00", x"00", x"00", x"00",         -- 184..191
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 192..199
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 200..207
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 208..215
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 216..223
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 224..231
x"00");

-- CLK0: 27.750 MHz
-- CLK1: 40.000 MHz
-- CLK2: disabled
constant DATA_600P60 : DATA_ARRAY := (
x"00", x"00", x"18", x"00", x"00", x"00", x"00", x"00",         -- 0..7
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 8..15
x"6F", x"4F", x"83", x"80", x"80", x"80", x"C0", x"80",         -- 16..23
x"00", x"00", x"00", x"01", x"00", x"0E", x"00", x"00",         -- 24..31
x"00", x"00", x"00", x"32", x"00", x"0C", x"6E", x"00",         -- 32..39
x"00", x"04", x"00", x"01", x"00", x"0B", x"00", x"00",         -- 40..47
x"00", x"00", x"00", x"01", x"00", x"08", x"00", x"00",         -- 48..55
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 56..63
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 64..71
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 72..79
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 80..87
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 88..95
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 96..103
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 104..111
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 112..119
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 120..127
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 128..135
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 136..143
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 144..151
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 152..159
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 160..167
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 168..175
x"00", x"00", x"00", x"00", x"00", x"30", x"00", x"D2",         -- 176..183
x"60", x"60", x"00", x"C0", x"00", x"00", x"00", x"00",         -- 184..191
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 192..199
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 200..207
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 208..215
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 216..223
x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",         -- 224..231
x"00");

constant SLAVE_ADDRESS_VALUE : std_logic_vector(7 downto 0) := "11000000";

type STATE_TYPE is (INIT, SLAVE_ADDRESS, REGISTER_ADDRESS, WRITE_DATA, STOP, IDLE);
signal STATE : STATE_TYPE;

begin

BYTE_COUNTER_SLV <= std_logic_vector(to_unsigned(BYTE_COUNTER, 8));

process(CLOCK, RESET)
begin
    if RESET = '1' then
        STATE <= INIT;
        SDA_OUT <= '1';
        SCL_OUT <= '1';
        DELAY_COUNTER <= 0;
        SUBBIT_COUNTER <= 0;
        BIT_COUNTER <= 0;
        BYTE_COUNTER <= 0;
        COMPLETE_OUT <= '0';
        SDA_SYNCER <= '0';
        SDA_SYNCED <= '0';
        SCL_SYNCER <= '0';
        SCL_SYNCED <= '0';
        REF_SYNCER <= '0';
        RES_SYNCER <= '0';
        REF_SYNCED <= '0';
        RES_SYNCED <= '0';
        REFRESH_RATE_SELECT_LATCHED <= '0';
        RESOLUTION_SELECT_LATCHED <= '0';
    elsif rising_edge(CLOCK) then
        SDA_SYNCER <= SDA_IN;
        SDA_SYNCED <= SDA_SYNCER;
        SCL_SYNCER <= SCL_IN;
        SCL_SYNCED <= SCL_SYNCER;
        RES_SYNCER <= RESOLUTION_SELECT_IN;
        RES_SYNCED <= RES_SYNCER;
        REF_SYNCER <= REFRESH_RATE_SELECT_IN;
        REF_SYNCED <= REF_SYNCER;
        case STATE is
            when INIT =>
                SDA_OUT <= '1';
                SCL_OUT <= '1';
                DELAY_COUNTER <= 0;
                SUBBIT_COUNTER <= 0;
                BIT_COUNTER <= 0;
                BYTE_COUNTER <= 0;
                REFRESH_RATE_SELECT_LATCHED <= REF_SYNCED;
                RESOLUTION_SELECT_LATCHED <= RES_SYNCED;
                if DELAY_COUNTER >= INIT_LENGTH then
                    STATE <= SLAVE_ADDRESS;
                    DELAY_COUNTER <= 0;
                else
                    DELAY_COUNTER <= DELAY_COUNTER + 1;
                end if;
            when SLAVE_ADDRESS | REGISTER_ADDRESS | WRITE_DATA =>
                -- Counter control
                if DELAY_COUNTER >= SUBBIT_LENGTH then
                    DELAY_COUNTER <= 0;
                    if SUBBIT_COUNTER = 3 then
                        SUBBIT_COUNTER <= 0;
                        if BIT_COUNTER = 10 then
                            BIT_COUNTER <= 1;               -- Only use BIT_COUNTER = 0 for start bit
                            if STATE = SLAVE_ADDRESS then
                                STATE <= REGISTER_ADDRESS;
                            elsif STATE = REGISTER_ADDRESS then
                                STATE <= WRITE_DATA;
                            elsif BYTE_COUNTER = CONFIG_DATA_SIZE - 1 then
                                STATE <= STOP;
                            else
                                BYTE_COUNTER <= BYTE_COUNTER + 1;
                            end if;
                        else
                            BIT_COUNTER <= BIT_COUNTER + 1;
                        end if;
                    else
                        --if SUBBIT_COUNTER = 2 and SCL_SYNCED = '0' then
                            -- Clock stretch detection
                        --    SUBBIT_COUNTER <= SUBBIT_COUNTER;
                        --else
                            SUBBIT_COUNTER <= SUBBIT_COUNTER + 1;
                        --end if;
                    end if;
                else
                    DELAY_COUNTER <= DELAY_COUNTER + 1;
                end if;
                -- SCL control
                if BIT_COUNTER = 10 then
                    SCL_OUT <= '0';
                elsif SUBBIT_COUNTER = 1 then
                    SCL_OUT <= '1';
                elsif SUBBIT_COUNTER = 3 then
                    SCL_OUT <= '0';
                end if;
                -- SDA control
                if BIT_COUNTER = 0 then
                    SDA_OUT <= '0';
                elsif BIT_COUNTER = 9 then
                    SDA_OUT <= '1';
                    -- Check for lack of ACK and restart configuration
                    if SUBBIT_COUNTER = 2 and SDA_SYNCED = '1' then
                        STATE <= INIT;
                    end if;
                elsif BIT_COUNTER = 10 then
                    if STATE = SLAVE_ADDRESS then
                        SDA_OUT <= '1';
                    else
                        SDA_OUT <= '0';
                    end if;
                else
                    if STATE = SLAVE_ADDRESS then
                        SDA_OUT <= SLAVE_ADDRESS_VALUE(8 - BIT_COUNTER);
                    elsif STATE = REGISTER_ADDRESS then
                        -- Starting at register address 0 so '0' for every bit
                        SDA_OUT <= BYTE_COUNTER_SLV(8 - BIT_COUNTER);
                    else
                        -- Select output data according to resolution and refresh rate selection
                        if REFRESH_RATE_SELECT_LATCHED = '1' and RESOLUTION_SELECT_LATCHED = '1' then
                            SDA_OUT <= DATA_600P60(BYTE_COUNTER)(8 - BIT_COUNTER);
                        elsif REFRESH_RATE_SELECT_LATCHED = '0' and RESOLUTION_SELECT_LATCHED = '1' then
                            SDA_OUT <= DATA_600P50(BYTE_COUNTER)(8 - BIT_COUNTER);
                        elsif REFRESH_RATE_SELECT_LATCHED = '1' and RESOLUTION_SELECT_LATCHED = '0' then
                            SDA_OUT <= DATA_576P60(BYTE_COUNTER)(8 - BIT_COUNTER);
                        else
                            SDA_OUT <= DATA_576P50(BYTE_COUNTER)(8 - BIT_COUNTER);
                        end if;
                    end if;
                end if;
            when STOP =>
                SDA_OUT <= '0';
                SCL_OUT <= '1';
                if DELAY_COUNTER >= SUBBIT_LENGTH then
                    STATE <= IDLE;
                else
                    DELAY_COUNTER <= DELAY_COUNTER + 1;
                end if;
            when IDLE =>
                SDA_OUT <= '1';
                SCL_OUT <= '1';
                COMPLETE_OUT <= '1';
                -- Reconfigure when a change is made to the resolution and refresh rate selection
                -- Note that the SI5351 will always be reconfigured a second time at start-up whenever
                -- any mode other than 576p50 is selected because the keypad controller uses one of the
                -- programmable clocks, so the DIP switch positions are not read until after the clock
                -- has been programmed for the first time.
                if REFRESH_RATE_SELECT_LATCHED /= REF_SYNCED or RESOLUTION_SELECT_LATCHED /= RES_SYNCED then
                    STATE <= INIT;
                end if;
            when OTHERS =>
                SDA_OUT <= '1';
                SCL_OUT <= '1';
                COMPLETE_OUT <= '0';
        end case;
    end if;
end process;
end architecture RTL;
