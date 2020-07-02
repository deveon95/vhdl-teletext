-- TXT_DESERIALISER.vhd
-- Converts serial VBI data to parallel
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_DESERIALISER is
    port (
    CLK_27_750      : in  std_logic;
    RESET           : in  std_logic;
    
    SERIAL_DATA_IN  : in  std_logic;
    SERIAL_CLOCK_IN : in  std_logic;
    FRAME_VALID_IN  : in  std_logic;
    
    BYTE_OUT        : out std_logic_vector(7 downto 0);
    BYTE_CLOCK_OUT  : out std_logic;
    FRAME_VALID_OUT : out std_logic
    );
end entity TXT_DESERIALISER;

architecture RTL of TXT_DESERIALISER is
signal BYTE : std_logic_vector(7 downto 0);
signal BIT_COUNTER : integer range 0 to 7;
type STATE_TYPE is (IDLE, WAIT_FOR_BIT, NEXT_BIT);
signal STATE : STATE_TYPE;

begin
    DESERIALISE: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            BYTE <= (others => '0');
            BIT_COUNTER <= 0;
            BYTE_OUT <= (others => '0');
            BYTE_CLOCK_OUT <= '0';
            FRAME_VALID_OUT <= '0';
            STATE <= IDLE;
        elsif rising_edge(CLK_27_750) then
            case STATE is
            when IDLE =>
                BYTE <= (others => '0');
                BIT_COUNTER <= 0;
                BYTE_CLOCK_OUT <= '0';
                FRAME_VALID_OUT <= '0';
                if FRAME_VALID_IN = '1' then
                    STATE <= WAIT_FOR_BIT;
                end if;
            when WAIT_FOR_BIT =>
                BYTE_CLOCK_OUT <= '0';
                FRAME_VALID_OUT <= '1';
                if SERIAL_CLOCK_IN = '1' then
                    BYTE(BIT_COUNTER) <= SERIAL_DATA_IN;
                    STATE <= NEXT_BIT;
                elsif FRAME_VALID_IN = '0' then
                    STATE <= IDLE;
                end if;
            when NEXT_BIT =>
                if BIT_COUNTER = 7 then
                    BIT_COUNTER <= 0;
                    BYTE_OUT <= BYTE;
                    BYTE_CLOCK_OUT <= '1';
                else
                    BIT_COUNTER <= BIT_COUNTER + 1;
                end if;
                STATE <= WAIT_FOR_BIT;
            when others =>
                STATE <= IDLE;
            end case;
        end if;
    end process;
end architecture;
