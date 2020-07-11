-- TXT_DATA_PROCESSOR
-- Processes VBI lines and performs error correction
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_DATA_PROCESSOR is
    port (
    CLK_27_750      : in  std_logic;
    RESET           : in  std_logic;
    
    BYTE_IN         : in  std_logic_vector(7 downto 0);
    BYTE_CLOCK_IN   : in  std_logic;
    FRAME_VALID_IN  : in  std_logic;
    
    WORD_OUT        : out std_logic_vector(6 downto 0);
    WORD_CLOCK_OUT  : out std_logic;
    FRAME_VALID_OUT : out std_logic;
    MAGAZINE_OUT    : out std_logic_vector(2 downto 0);
    ROW_OUT         : out std_logic_vector(4 downto 0);
    PAGE_OUT        : out std_logic_vector(7 downto 0);
    SUBCODE_OUT     : out std_logic_vector(12 downto 0);
    CONTROL_BITS_OUT: out std_logic_vector(10 downto 0);
    
    STATUS_LED_OUT  : out std_logic
    );
    
end entity TXT_DATA_PROCESSOR;

architecture RTL of TXT_DATA_PROCESSOR is
constant BLANK_CHAR : std_logic_vector(6 downto 0) := "0100000";

type T_PAGE_AND_SUBCODE_CACHE is array (integer range <>) of std_logic_vector(31 downto 0);
signal PAGE_AND_SUBCODE_CACHE : T_PAGE_AND_SUBCODE_CACHE(7 downto 0);
signal GOOD_HEADER_RECEIVED : std_logic_vector(7 downto 0);

signal ODD_PARITY_ENCODED : std_logic_vector(7 downto 0);
signal ODD_PARITY_DECODED : std_logic_vector(6 downto 0);
signal ODD_PARITY_VALID : std_logic;
signal HAMMING84_ENCODED : std_logic_vector(7 downto 0);
signal HAMMING84_DECODED : std_logic_vector(3 downto 0);
signal HAMMING84_VALID : std_logic;
signal HAMMING2418_ENCODED : std_logic_vector(23 downto 0);
signal HAMMING2418_DECODED : std_logic_vector(17 downto 0);
signal HAMMING2418_VALID : std_logic;

type RX_BYTE_TYPES is (MAGROW1, MAGROW2, PAGEUNITS, PAGETENS, SUBCODE1, SUBCODE2, SUBCODE3, SUBCODE4, CONTROLBITS1, CONTROLBITS2, DATA, HAMMING84_DATA, BAD);
signal RX_BYTE : RX_BYTE_TYPES;
signal CURRENT_MAGAZINE : std_logic_vector(2 downto 0);
signal CURRENT_LINE : std_logic_vector(4 downto 0);
signal CURRENT_MAGROW_PARITY : std_logic;
signal CURRENT_PAGE        : std_logic_vector(7 downto 0);
signal CURRENT_SUBCODE     : std_logic_vector(12 downto 0);
signal CURRENT_CONTROL_BITS : std_logic_vector(10 downto 0);

signal BYTE_CLOCK_DELAYED : std_logic;
signal BYTE_CLOCK_DELAYED_2 : std_logic;

constant LED_TIMEOUT : integer := 1110000;          -- Timeout period: 1 frame
signal LED_COUNTER : integer range 0 to LED_TIMEOUT;

begin

ODDPAR: entity work.ODD_PARITY_DECODER
    port map(
    DATA_IN => ODD_PARITY_ENCODED,
    DATA_OUT => ODD_PARITY_DECODED,
    DATA_VALID_OUT => ODD_PARITY_VALID);

H84: entity work.HAMMING84_DECODER
    port map(
    DATA_IN => HAMMING84_ENCODED,
    DATA_OUT => HAMMING84_DECODED,
    DATA_VALID_OUT => HAMMING84_VALID);

H2418: entity work.HAMMING2418_DECODER
    port map(
    DATA_IN => HAMMING2418_ENCODED,
    DATA_OUT => HAMMING2418_DECODED,
    DATA_VALID_OUT => HAMMING2418_VALID);
    
LED_CONTROL: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            STATUS_LED_OUT <= '0';
            LED_COUNTER <= 0;
        elsif rising_edge(CLK_27_750) then
            if RX_BYTE = BAD then
                STATUS_LED_OUT <= '0';
            elsif RX_BYTE = DATA then
                STATUS_LED_OUT <= '1';
                LED_COUNTER <= 0;
            elsif LED_COUNTER >= LED_TIMEOUT then
                STATUS_LED_OUT <= '0';
            else
                LED_COUNTER <= LED_COUNTER + 1;
            end if;
        end if;
    end process;

MAIN: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            PAGE_AND_SUBCODE_CACHE <= (others => (others => '1'));
            ODD_PARITY_ENCODED <= (others => '0');
            HAMMING84_ENCODED <= (others => '0');
            HAMMING2418_ENCODED <= (others => '0');
            RX_BYTE <= MAGROW1;
            CURRENT_MAGAZINE <= (others => '0');
            CURRENT_LINE <= (others => '0');
            CURRENT_MAGROW_PARITY <= '0';
            CURRENT_PAGE <= (others => '0');
            CURRENT_SUBCODE <= (others => '0');
            CURRENT_CONTROL_BITS <= (others => '0');
            BYTE_CLOCK_DELAYED_2 <= '0';
            BYTE_CLOCK_DELAYED <= '0';
            WORD_OUT <= (others => '0');
            WORD_CLOCK_OUT <= '0';
            FRAME_VALID_OUT <= '0';
            MAGAZINE_OUT <= (others => '0');
            ROW_OUT <= (others => '0');
            PAGE_OUT <= (others => '0');
            SUBCODE_OUT <= (others => '0');
            CONTROL_BITS_OUT <= (others => '0');
            GOOD_HEADER_RECEIVED <= (others => '0');
        elsif rising_edge(CLK_27_750) then
            BYTE_CLOCK_DELAYED <= BYTE_CLOCK_IN;
            BYTE_CLOCK_DELAYED_2 <= BYTE_CLOCK_DELAYED;
            if FRAME_VALID_IN = '1' then
                case RX_BYTE is
                when MAGROW1 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        CURRENT_MAGAZINE <= HAMMING84_DECODED(2 downto 0);
                        CURRENT_LINE(0) <= HAMMING84_DECODED(3);
                        CURRENT_MAGROW_PARITY <= HAMMING84_VALID;
                        RX_BYTE <= MAGROW2;
                    end if;
                    
                when MAGROW2 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        CURRENT_LINE(4 downto 1) <= HAMMING84_DECODED;
                        CURRENT_MAGROW_PARITY <= CURRENT_MAGROW_PARITY and HAMMING84_VALID;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if CURRENT_MAGROW_PARITY = '0' then
                            RX_BYTE <= BAD;
                        else
                            MAGAZINE_OUT <= CURRENT_MAGAZINE;
                            ROW_OUT <= CURRENT_LINE;
                            if CURRENT_LINE = "00000" then
                                RX_BYTE <= PAGEUNITS;
                            elsif GOOD_HEADER_RECEIVED(to_integer(unsigned(CURRENT_MAGAZINE))) = '1' then
                                -- Proceed to data processing only when a good header has been received
                                if CURRENT_LINE = "11011" then
                                    RX_BYTE <= HAMMING84_DATA;
                                else
                                    RX_BYTE <= DATA;
                                end if;
                                -- Restore Subcode and Page from cache; needed in case of magazine change during parallel transmission
                                CURRENT_SUBCODE <= PAGE_AND_SUBCODE_CACHE(to_integer(unsigned(CURRENT_MAGAZINE)))(20 downto 8);
                                CURRENT_PAGE <= PAGE_AND_SUBCODE_CACHE(to_integer(unsigned(CURRENT_MAGAZINE)))(7 downto 0);
                                CURRENT_CONTROL_BITS <= PAGE_AND_SUBCODE_CACHE(to_integer(unsigned(CURRENT_MAGAZINE)))(31 downto 21);
                            else
                                RX_BYTE <= BAD;
                            end if;
                        end if;
                    end if;
                    
                when PAGEUNITS =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_PAGE(3 downto 0) <= HAMMING84_DECODED;
                            RX_BYTE <= PAGETENS;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when PAGETENS =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        CURRENT_PAGE(7 downto 4) <= HAMMING84_DECODED;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            RX_BYTE <= SUBCODE1;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when SUBCODE1 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_SUBCODE(3 downto 0) <= HAMMING84_DECODED;
                            RX_BYTE <= SUBCODE2;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when SUBCODE2 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_SUBCODE(6 downto 4) <= HAMMING84_DECODED(2 downto 0);
                            CURRENT_CONTROL_BITS(0) <= HAMMING84_DECODED(3);
                            RX_BYTE <= SUBCODE3;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when SUBCODE3 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_SUBCODE(10 downto 7) <= HAMMING84_DECODED;
                            RX_BYTE <= SUBCODE4;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when SUBCODE4 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_SUBCODE(12 downto 11) <= HAMMING84_DECODED(1 downto 0);
                            CURRENT_CONTROL_BITS(2 downto 1) <= HAMMING84_DECODED(3 downto 2);
                        else
                            RX_BYTE <= BAD;
                        end if;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        RX_BYTE <= CONTROLBITS1;
                    end if;
                
                when CONTROLBITS1 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            CURRENT_CONTROL_BITS(6 downto 3) <= HAMMING84_DECODED;
                            RX_BYTE <= CONTROLBITS2;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                
                when CONTROLBITS2 =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        CURRENT_CONTROL_BITS(10 downto 7) <= HAMMING84_DECODED;
                    elsif BYTE_CLOCK_DELAYED_2 = '1' then
                        if HAMMING84_VALID = '1' then
                            GOOD_HEADER_RECEIVED(to_integer(unsigned(CURRENT_MAGAZINE))) <= '1';
                            PAGE_AND_SUBCODE_CACHE(to_integer(unsigned(CURRENT_MAGAZINE))) <= CURRENT_CONTROL_BITS & CURRENT_SUBCODE & CURRENT_PAGE;
                            RX_BYTE <= DATA;
                        else
                            RX_BYTE <= BAD;
                        end if;
                    end if;
                    
                when DATA =>
                    if BYTE_CLOCK_IN = '1' then
                        ODD_PARITY_ENCODED <= BYTE_IN;
                        PAGE_OUT <= CURRENT_PAGE;
                        SUBCODE_OUT <= CURRENT_SUBCODE;
                        CONTROL_BITS_OUT <= CURRENT_CONTROL_BITS;
                        FRAME_VALID_OUT <= '1';
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        if ODD_PARITY_VALID = '1' then
                            WORD_OUT <= ODD_PARITY_DECODED;
                        else
                            WORD_OUT <= BLANK_CHAR;
                        end if;
                        WORD_CLOCK_OUT <= '1';
                    else
                        WORD_CLOCK_OUT <= '0';
                    end if;
                    
                when HAMMING84_DATA =>
                    if BYTE_CLOCK_IN = '1' then
                        HAMMING84_ENCODED <= BYTE_IN;
                        PAGE_OUT <= CURRENT_PAGE;
                        SUBCODE_OUT <= CURRENT_SUBCODE;
                        CONTROL_BITS_OUT <= CURRENT_CONTROL_BITS;
                        FRAME_VALID_OUT <= '1';
                    elsif BYTE_CLOCK_DELAYED = '1' then
                        if HAMMING84_VALID = '1' then
                            WORD_OUT <= "000" & HAMMING84_DECODED;
                        else
                            WORD_OUT <= "1111111";
                        end if;
                        WORD_CLOCK_OUT <= '1';
                    else
                        WORD_CLOCK_OUT <= '0';
                    end if;
                
                when BAD =>
                    -- Stay here until the end of the frame when the line number / magazine is bad
                    -- Current page number cannot be trusted so disable data reception until good header packet received
                    GOOD_HEADER_RECEIVED(to_integer(unsigned(CURRENT_MAGAZINE))) <= '0';
                    
                WHEN OTHERS =>
                    RX_BYTE <= MAGROW1;
                end case;
            else
                RX_BYTE <= MAGROW1;
                FRAME_VALID_OUT <= '0';
                WORD_CLOCK_OUT <= '0';
            end if;
        end if;
    end process;

end architecture;
