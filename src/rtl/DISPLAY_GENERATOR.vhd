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
signal CHAR_COUNTER : integer range 0 to 25 * 40 - 1;
signal CHAR_COL_COUNTER : integer range 0 to 5;
signal CHAR_ROW_COUNTER : integer range 0 to 10;
signal CGROM_LINE : std_logic_vector(4 downto 0);
signal CHAR_TO_DISPLAY : std_logic_vector(6 downto 0);

signal FG_R : std_logic;
signal FG_G : std_logic;
signal FG_B : std_logic;
signal NEXT_FG_R : std_logic;
signal NEXT_FG_G : std_logic;
signal NEXT_FG_B : std_logic;
signal BG_R : std_logic;
signal BG_G : std_logic;
signal BG_B : std_logic;
signal MOSAIC_ENABLE : std_logic;
signal MOSAIC_HOLD : std_logic;
signal CONTIGUOUS : std_logic;
signal MOSAIC : std_logic_vector(5 downto 0);
signal MOSAIC_PIXEL, LAST_MOSAIC_PIXEL : std_logic;
signal LAST_MOSAIC : std_logic_vector(5 downto 0);

constant BLANK_CHAR : std_logic_vector(6 downto 0) := "0100000";
begin
    MEMORY_ADDRESS_OUT <= std_logic_vector(to_unsigned(CHAR_COUNTER,10));
    

CGROM: entity work.CGROM
    port map(
    ADDRESS_IN => CHAR_TO_DISPLAY,
    ROW_SELECT_IN => std_logic_vector(to_unsigned(CHAR_ROW_COUNTER,4)),
    DATA_OUT => CGROM_LINE);
    
    -- Generate the mosaic character
    -- 0 1
    -- 2 3
    -- 4 5
    MOSAIC(0) <= MEMORY_DATA_IN(0);
    MOSAIC(1) <= MEMORY_DATA_IN(1);
    MOSAIC(2) <= MEMORY_DATA_IN(2);
    MOSAIC(3) <= MEMORY_DATA_IN(3);
    MOSAIC(4) <= MEMORY_DATA_IN(4);
    MOSAIC(5) <= MEMORY_DATA_IN(6);
    MOSAIC_PIXEL <= MOSAIC(0) when CHAR_COL_COUNTER < 3 and CHAR_ROW_COUNTER < 3 else
                    MOSAIC(1) when CHAR_COL_COUNTER >= 3 and CHAR_ROW_COUNTER < 3 else
                    MOSAIC(2) when CHAR_COL_COUNTER < 3 and CHAR_ROW_COUNTER < 7 else
                    MOSAIC(3) when CHAR_COL_COUNTER >= 3 and CHAR_ROW_COUNTER < 7 else
                    MOSAIC(4) when CHAR_COL_COUNTER < 3 else
                    MOSAIC(5);
    LAST_MOSAIC_PIXEL <= LAST_MOSAIC(0) when CHAR_COL_COUNTER < 3 and CHAR_ROW_COUNTER < 3 else
                    LAST_MOSAIC(1) when CHAR_COL_COUNTER >= 3 and CHAR_ROW_COUNTER < 3 else
                    LAST_MOSAIC(2) when CHAR_COL_COUNTER < 3 and CHAR_ROW_COUNTER < 7 else
                    LAST_MOSAIC(3) when CHAR_COL_COUNTER >= 3 and CHAR_ROW_COUNTER < 7 else
                    LAST_MOSAIC(4) when CHAR_COL_COUNTER < 3 else
                    LAST_MOSAIC(5);
                    
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
            FG_R <= '1';
            FG_G <= '1';
            FG_B <= '1';
            NEXT_FG_R <= '0';
            NEXT_FG_G <= '0';
            NEXT_FG_B <= '0';
            BG_R <= '0';
            BG_G <= '0';
            BG_B <= '0';
            CHAR_TO_DISPLAY <= (others => '0');
            MOSAIC_ENABLE <= '0';
            MOSAIC_HOLD <= '0';
            CONTIGUOUS <= '0';
            LAST_MOSAIC <= (others => '0');
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
                    FG_R <= '1';
                    FG_G <= '1';
                    FG_B <= '1';
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
                            if CHAR_COL_COUNTER = 0 then
                                CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                                FG_R <= NEXT_FG_R;
                                FG_G <= NEXT_FG_G;
                                FG_B <= NEXT_FG_B;
                                CHAR_TO_DISPLAY <= BLANK_CHAR;
                                case MEMORY_DATA_IN is
                                when "0000001"|"0000010"|"0000011"|"0000100"|"0000101"|"0000110"|"0000111" =>
                                    NEXT_FG_R <= MEMORY_DATA_IN(0);
                                    NEXT_FG_G <= MEMORY_DATA_IN(1);
                                    NEXT_FG_B <= MEMORY_DATA_IN(2);
                                    MOSAIC_ENABLE <= '0';
                                when "0010001"|"0010010"|"0010011"|"0010100"|"0010101"|"0010110"|"0010111" =>
                                    NEXT_FG_R <= MEMORY_DATA_IN(0);
                                    NEXT_FG_G <= MEMORY_DATA_IN(1);
                                    NEXT_FG_B <= MEMORY_DATA_IN(2);
                                    MOSAIC_ENABLE <= '1';
                                    -- Put hold mosaic stuff here
                                when "0011001" =>
                                    CONTIGUOUS <= '1';
                                when "0011010" =>
                                    CONTIGUOUS <= '0';
                                when "0011110" =>
                                    MOSAIC_HOLD <= '1';
                                when "0011111" =>
                                    MOSAIC_HOLD <= '0';
                                when "0011101" =>
                                    BG_R <= NEXT_FG_R;
                                    BG_G <= NEXT_FG_G;
                                    BG_B <= NEXT_FG_B;
                                when others =>
                                    CHAR_TO_DISPLAY <= MEMORY_DATA_IN;
                                end case;
                            else
                                CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                            end if;
                            if MOSAIC_ENABLE = '0' or (MEMORY_DATA_IN(6) = '1' and MEMORY_DATA_IN(5) = '0') then
                                if CHAR_COL_COUNTER = 0 then
                                    R_OUT <= BG_R;
                                    G_OUT <= BG_G;
                                    B_OUT <= BG_B;
                                else
                                    R_OUT <= (CGROM_LINE(5 - CHAR_COL_COUNTER) and FG_R) or (NOT CGROM_LINE(5 - CHAR_COL_COUNTER) and BG_R);
                                    G_OUT <= (CGROM_LINE(5 - CHAR_COL_COUNTER) and FG_G) or (NOT CGROM_LINE(5 - CHAR_COL_COUNTER) and BG_G);
                                    B_OUT <= (CGROM_LINE(5 - CHAR_COL_COUNTER) and FG_B) or (NOT CGROM_LINE(5 - CHAR_COL_COUNTER) and BG_B);
                                end if;
                            elsif MEMORY_DATA_IN(5) = '1' then
                                R_OUT <= (MOSAIC_PIXEL and FG_R) or (NOT MOSAIC_PIXEL and BG_R);
                                G_OUT <= (MOSAIC_PIXEL and FG_G) or (NOT MOSAIC_PIXEL and BG_G);
                                B_OUT <= (MOSAIC_PIXEL and FG_B) or (NOT MOSAIC_PIXEL and BG_B);
                                LAST_MOSAIC <= MOSAIC;
                            else
                                -- Put mosaic hold stuff here
                                if MOSAIC_HOLD = '1' then
                                    R_OUT <= (LAST_MOSAIC_PIXEL and FG_R) or (NOT LAST_MOSAIC_PIXEL and BG_R);
                                    G_OUT <= (LAST_MOSAIC_PIXEL and FG_G) or (NOT LAST_MOSAIC_PIXEL and BG_G);
                                    B_OUT <= (LAST_MOSAIC_PIXEL and FG_B) or (NOT LAST_MOSAIC_PIXEL and BG_B);
                                else
                                    R_OUT <= BG_R;
                                    G_OUT <= BG_G;
                                    B_OUT <= BG_B;
                                end if;
                            end if;
                            if CHAR_COL_COUNTER = 5 then
                                CHAR_COL_COUNTER <= 0;
                                CHAR_COUNTER <= CHAR_COUNTER + 1;
                            end if;
                        elsif PIXEL_COUNTER = 624 then
                            -- Need to subtract 40 because we've only printed one row of pixels
                            -- and need to print from the same characters again
                            CHAR_COUNTER <= CHAR_COUNTER - 40;
                            H_DOUBLER <= '0';
                            R_OUT <= '0';
                            G_OUT <= '0';
                            B_OUT <= '0';
                            FG_R <= '1';
                            FG_G <= '1';
                            FG_B <= '1';
                            NEXT_FG_R <= '1';
                            NEXT_FG_G <= '1';
                            NEXT_FG_B <= '1';
                            BG_R <= '0';
                            BG_G <= '0';
                            BG_B <= '0';
                            MOSAIC_ENABLE <= '0';
                            MOSAIC_HOLD <= '0';
                            CONTIGUOUS <= '0';
                            LAST_MOSAIC <= (others => '0');
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
