library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DISPLAY_GENERATOR is
port (
    CLK : in std_logic;
    RESET : in std_logic;
    
    MEMORY_DATA_IN : in std_logic_vector(6 downto 0);
    MEMORY_ADDRESS_OUT : out std_logic_vector(9 downto 0);
    
    NEW_ROW_IN : in std_logic;
    NEW_SCREEN_IN : in std_logic;
    
    R_OUT : out std_logic;
    G_OUT : out std_logic;
    B_OUT : out std_logic
    );
end entity DISPLAY_GENERATOR;

architecture RTL of DISPLAY_GENERATOR is

signal PIXEL_COUNTER : integer range 0 to 767;
signal ROW_COUNTER : integer range 0 to 575;
signal H_DOUBLER : std_logic;
signal V_DOUBLER : std_logic;
signal CHAR_COUNTER : integer range 0 to 127;
signal CHAR_COL_COUNTER : integer range 0 to 5;
signal CHAR_ROW_COUNTER : integer range 0 to 10;
signal CGROM_LINE : std_logic_vector(4 downto 0);

begin

CGROM: entity work.CGROM
    port map(
    ADDRESS_IN => std_logic_vector(to_unsigned(CHAR_COUNTER,7)),
    ROW_SELECT_IN => std_logic_vector(to_unsigned(CHAR_ROW_COUNTER,4)),
    DATA_OUT => CGROM_LINE);

PATTERN_GEN: process(CLK, RESET)
    begin
        if RESET = '1' then
            R_OUT <= '0';
            G_OUT <= '0';
            B_OUT <= '0';
            PIXEL_COUNTER <= 0;
            ROW_COUNTER <= 0;
            H_DOUBLER <= '0';
            V_DOUBLER <= '0';
            CHAR_COUNTER <= 0;
            CHAR_COL_COUNTER <= 0;
            CHAR_ROW_COUNTER <= 0;
        elsif rising_edge(CLK) then
            if NEW_SCREEN_IN = '1' then
                ROW_COUNTER <= 0;
                CHAR_COUNTER <= 0;
                CHAR_ROW_COUNTER <= 0;
                CHAR_COL_COUNTER <= 0;
                H_DOUBLER <= '0';
                V_DOUBLER <= '0';
            else
                if NEW_ROW_IN = '1' then
                    PIXEL_COUNTER <= 0;
                    if ROW_COUNTER < 575 then
                        ROW_COUNTER <= ROW_COUNTER + 1;
                    end if;
                    if ROW_COUNTER >= 16 and ROW_COUNTER < 563 then
                        V_DOUBLER <= NOT V_DOUBLER;
                        if V_DOUBLER = '1' then
                            if CHAR_ROW_COUNTER < 10 then
                                -- start of next line in the same row of data
                                CHAR_ROW_COUNTER <= CHAR_ROW_COUNTER + 1;
                            else
                                -- proceed to next part of character set
                                CHAR_COUNTER <= CHAR_COUNTER + 40;
                                CHAR_ROW_COUNTER <= 0;
                            end if;
                        end if;
                    end if;
                else
                    if PIXEL_COUNTER < 767 then
                        PIXEL_COUNTER <= PIXEL_COUNTER + 1;
                    end if;
                    H_DOUBLER <= not H_DOUBLER;
                    if ROW_COUNTER >= 16 and ROW_COUNTER < 563 then
                        if H_DOUBLER = '1' and PIXEL_COUNTER >= 144 and PIXEL_COUNTER < 624 then
                            if CHAR_COL_COUNTER < 5 then
                                CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                                R_OUT <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                                G_OUT <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                                B_OUT <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                            else
                                CHAR_COL_COUNTER <= 0;
                                R_OUT <= '0';
                                G_OUT <= '0';
                                B_OUT <= '0';
                                CHAR_COUNTER <= CHAR_COUNTER + 1;
                            end if;
                        elsif PIXEL_COUNTER = 624 then
                            -- Need to subtract 40 because we've only printed one row of pixels
                            -- and need to print from the same characters again
                            CHAR_COUNTER <= CHAR_COUNTER - 40;
                            H_DOUBLER <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
