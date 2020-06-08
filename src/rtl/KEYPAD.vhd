-- KEYPAD.vhd
-- This module detects keypresses on a keypad of arbitrary size and outputs
-- individual signals corresponding to the button states.
-- Buttons with a '0' in MOMENTARY_MASK have their current state reported
-- (0 for unpressed and 1 for pressed) and buttons with a '1' in
-- MOMENTARY_MASK generate a pulse of DELAY * ROWS on the corresponding
-- BUTTONS_OUT signal when pressed down.
-- FIRST_PASS_OUT goes high once the whole keypad has been sampled for the
-- first time; this is used to configure other parts of the design with the
-- settings of DIP switches wired as part of the keypad;
-- The external keypad is connected to FPGA I/O with internal pull-ups
-- enabled on the input pins.
--
-- Copyright 2020 Nick Schollar

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity KEYPAD is
    generic (
    COLS           : integer;
    ROWS           : integer;
    DELAY          : integer;
    MOMENTARY_MASK : std_logic_vector);
    port (
    CLK            : in  std_logic;
    RESET          : in  std_logic;
    COLS_IN        : in std_logic_vector(COLS - 1 downto 0);
    ROWS_OUT       : inout std_logic_vector(ROWS - 1 downto 0);
    BUTTONS_OUT    : out std_logic_vector(COLS * ROWS - 1 downto 0);
    FIRST_PASS_OUT : out std_logic);
end entity KEYPAD;

architecture RTL of KEYPAD is

signal ROW_COUNTER : integer range 0 to ROWS - 1;
signal DELAY_COUNTER : integer range 0 to DELAY - 1;
signal BUTTONS_LAST_STATE : std_logic_vector(COLS * ROWS - 1 downto 0);
signal BUTTON_INDEX : integer range 0 to COLS * ROWS - 1;
signal COLS_SYNCER : std_logic_vector(COLS - 1 downto 0);
signal COLS_SYNCED : std_logic_vector(COLS - 1 downto 0);

begin

GEN_ROW_OUT:
    for I in 0 to ROWS - 1 generate
        ROWS_OUT(I) <= '0' when ROW_COUNTER = I else 'Z';
    end generate;

MAIN:
    process (CLK, RESET)
    begin
        if RESET = '1' then
            ROW_COUNTER <= 0;
            DELAY_COUNTER <= 0;
            BUTTONS_LAST_STATE <= (others => '0');
            BUTTONS_OUT <= (others => '0');
            FIRST_PASS_OUT <= '0';
            COLS_SYNCER <= (others => '0');
            COLS_SYNCED <= (others => '0');
        elsif rising_edge(CLK) then
            COLS_SYNCED <= COLS_SYNCER;
            COLS_SYNCER <= COLS_IN;
            if DELAY_COUNTER < DELAY - 1 then
                DELAY_COUNTER <= DELAY_COUNTER + 1;
            else
                DELAY_COUNTER <= 0;
                
                BUTTONS_OUT(BUTTON_INDEX + COLS - 1 downto BUTTON_INDEX) <= (not COLS_SYNCED) and (not (MOMENTARY_MASK(BUTTON_INDEX + COLS - 1 downto BUTTON_INDEX) and BUTTONS_LAST_STATE(BUTTON_INDEX + COLS - 1 downto BUTTON_INDEX)));
                BUTTONS_LAST_STATE(BUTTON_INDEX + COLS - 1 downto BUTTON_INDEX) <= not COLS_SYNCED;
                
                if ROW_COUNTER < ROWS - 1 then
                    ROW_COUNTER <= ROW_COUNTER + 1;
                    BUTTON_INDEX <= BUTTON_INDEX + COLS;
                else
                    ROW_COUNTER <= 0;
                    BUTTON_INDEX <= 0;
                    FIRST_PASS_OUT <= '1';
                end if;
            end if;
        end if;
    end process;
    
end architecture;
