-- TXT_DATA_RECOVERY.vhd
-- Detects the preamble of VBI lines and extracts the data bits
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_DATA_RECOVERY is
    port (
    CLK_27_750      : in  std_logic;
    RESET           : in  std_logic;
    RX_IN           : in  std_logic;
    SERIAL_DATA_OUT : out std_logic;
    SERIAL_CLOCK_OUT : out std_logic;
    FRAME_VALID_OUT : out std_logic
    );
end entity TXT_DATA_RECOVERY;

architecture RTL of TXT_DATA_RECOVERY is
-- ETSI EN 300 706 V1.2.1 Section 6.1: First two 1s may be missing, so these are not checked
constant RUN_IN : std_logic_vector(79 downto 0) := "-111-000-111-000-111-000-111-000-111-000-111-000-11111111111-0000000-111-0000000";
signal RX_SHIFT_REGISTER : std_logic_vector(79 downto 0);
signal LOCKED : std_logic;
constant BIT_SAMPLE_COUNTER_MAX : integer := 3;
signal BIT_SAMPLE_COUNTER : integer range 0 to BIT_SAMPLE_COUNTER_MAX;
constant BIT_NUMBER_COUNTER_MAX : integer := 336;
signal BIT_NUMBER_COUNTER : integer range 0 to BIT_NUMBER_COUNTER_MAX;
signal RX_SYNCED : std_logic;
signal RX_SYNCER : std_logic;

begin
    FRAME_VALID_OUT <= LOCKED;

    process(RESET, CLK_27_750)
    begin    
        if RESET = '1' then
            RX_SHIFT_REGISTER <= (others => '0');
            LOCKED <= '0';
            BIT_SAMPLE_COUNTER <= 0;
            BIT_NUMBER_COUNTER <= 0;
            SERIAL_CLOCK_OUT <= '0';
            SERIAL_DATA_OUT <= '0';
            RX_SYNCED <= '0';
            RX_SYNCER <= '0';
        elsif rising_edge(CLK_27_750) then
            RX_SHIFT_REGISTER <= RX_SHIFT_REGISTER(RX_SHIFT_REGISTER'left - 1 downto 0) & RX_SYNCED;
            RX_SYNCED <= RX_SYNCER;
            RX_SYNCER <= RX_IN;
            if LOCKED = '0' then
                if std_match(RX_SHIFT_REGISTER, RUN_IN) then
                    LOCKED <= '1';
                    BIT_SAMPLE_COUNTER <= 0;
                    BIT_NUMBER_COUNTER <= 0;
                end if;
            else
                if BIT_NUMBER_COUNTER < BIT_NUMBER_COUNTER_MAX then
                    if BIT_SAMPLE_COUNTER < BIT_SAMPLE_COUNTER_MAX then
                        BIT_SAMPLE_COUNTER <= BIT_SAMPLE_COUNTER + 1;
                        if BIT_SAMPLE_COUNTER = 1 then
                            SERIAL_DATA_OUT <= RX_SYNCED;
                            SERIAL_CLOCK_OUT <= '1';
                        end if;
                    else
                        BIT_SAMPLE_COUNTER <= 0;
                        BIT_NUMBER_COUNTER <= BIT_NUMBER_COUNTER + 1;
                        SERIAL_CLOCK_OUT <= '0';
                    end if;
                else
                    BIT_SAMPLE_COUNTER <= 0;
                    BIT_NUMBER_COUNTER <= 0;
                    LOCKED <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture RTL;
