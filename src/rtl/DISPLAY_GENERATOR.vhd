-- DISPLAY_GENERATOR.vhd
-- Generates the teletext display using data from RAM
-- Supports selection of two resolutions; the second resolution must be the larger of the two
-- Copyright 2020 Nick Schollar

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DISPLAY_GENERATOR is
    generic (
    H_SIZE_1        : integer;
    V_SIZE_1        : integer;
    H_SIZE_2        : integer;
    V_SIZE_2        : integer);
port (
    CLK : in std_logic;
    RESET : in std_logic;
    
    REVEAL_IN : in std_logic;
    MIX_IN : in std_logic;
    AB_EN_IN : in std_logic;
    SIZE_SELECT_IN : in std_logic;
    
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

constant FLASH_DURATION : integer := 25000000;

constant H_CHAR_SIZE : integer := 6;        -- This parameter must be set to suit the CGROM
constant V_CHAR_SIZE : integer := 11;
constant V_CHAR_SIZE_BITS : integer := 4;   -- Number of bits required for std_logic_vector representation of the above
constant MOSAIC_DIV1 : integer := 3;
constant MOSAIC_DIV2 : integer := 7;
constant TEXT_LINES : integer := 25;
constant TEXT_COLS : integer := 40;
constant V_PIXEL_STRETCH : integer := 2;
constant H_PIXEL_STRETCH : integer := 2;

constant DISPLAY_AREA_WIDTH : integer := H_CHAR_SIZE * H_PIXEL_STRETCH * TEXT_COLS;
constant DISPLAY_AREA_HEIGHT : integer := V_CHAR_SIZE * V_PIXEL_STRETCH * TEXT_LINES;
constant DISPLAY_AREA_1_LEFT : integer := (H_SIZE_1 - DISPLAY_AREA_WIDTH) / 2;
constant DISPLAY_AREA_1_RIGHT : integer := (H_SIZE_1 + DISPLAY_AREA_WIDTH) / 2;
constant DISPLAY_AREA_1_TOP : integer := (V_SIZE_1 - DISPLAY_AREA_HEIGHT) / 2;
constant DISPLAY_AREA_1_BOTTOM : integer := (V_SIZE_1 + DISPLAY_AREA_HEIGHT) / 2;
constant DISPLAY_AREA_2_LEFT : integer := (H_SIZE_2 - DISPLAY_AREA_WIDTH) / 2;
constant DISPLAY_AREA_2_RIGHT : integer := (H_SIZE_2 + DISPLAY_AREA_WIDTH) / 2;
constant DISPLAY_AREA_2_TOP : integer := (V_SIZE_2 - DISPLAY_AREA_HEIGHT) / 2;
constant DISPLAY_AREA_2_BOTTOM : integer := (V_SIZE_2 + DISPLAY_AREA_HEIGHT) / 2;

signal MEMORY_DATA : std_logic_vector(6 downto 0);
signal PIXEL_COUNTER : integer range 0 to H_SIZE_2 - 1;
signal ROW_COUNTER : integer range 0 to V_SIZE_2 - 1;
signal V_PIXEL_STRETCH_COUNTER : integer range 0 to V_PIXEL_STRETCH - 1;
signal H_PIXEL_STRETCH_COUNTER : integer range 0 to V_PIXEL_STRETCH - 1;
signal CHAR_COUNTER : integer range 0 to TEXT_LINES * TEXT_COLS - 1;
signal CHAR_COL_COUNTER, CHAR_COL_COUNTER_D : integer range 0 to H_CHAR_SIZE - 1;
signal CHAR_ROW_COUNTER : integer range 0 to V_CHAR_SIZE - 1;
signal CHAR_ROW_SELECT : integer range 0 to V_CHAR_SIZE - 1;
signal IN_DISPLAY_AREA : std_logic;
signal CGROM_LINE : std_logic_vector(4 downto 0);
signal CHAR_TO_DISPLAY : std_logic_vector(6 downto 0);
signal NEXT_V_PIXEL : std_logic;
signal NEXT_H_PIXEL : std_logic;
signal NEXT_H_PIXEL_D : std_logic;
signal END_OF_ROW : std_logic;

signal FG_R, FG_R_D : std_logic;
signal FG_G, FG_G_D : std_logic;
signal FG_B, FG_B_D : std_logic;
signal NEXT_FG_R : std_logic;
signal NEXT_FG_G : std_logic;
signal NEXT_FG_B : std_logic;
signal BG_R, BG_R_D : std_logic;
signal BG_G, BG_G_D : std_logic;
signal BG_B, BG_B_D : std_logic;
signal CONCEAL : std_logic;
signal NEXT_CONCEAL : std_logic;
signal FLASH : std_logic;
signal FLASH_TIMER : integer range 0 to FLASH_DURATION;
signal FLASH_TIMER_PULSE : std_logic;
signal MOSAIC_ENABLE : std_logic;
signal NEXT_MOSAIC_ENABLE : std_logic;
signal MOSAIC_HOLD : std_logic;
signal NEXT_MOSAIC_HOLD : std_logic;
signal CONTIGUOUS : std_logic;
signal LAST_CONTIGUOUS : std_logic;
signal MOSAIC : std_logic_vector(5 downto 0);
signal MOSAIC_PIXEL : std_logic;
signal LAST_MOSAIC_PIXEL : std_logic;
signal LAST_MOSAIC : std_logic_vector(5 downto 0);
signal DH_THIS_ROW : std_logic;
signal DH_LAST_ROW : std_logic;
signal DH : std_logic;
signal NEXT_DH : std_logic;
signal CURRENT_PIXEL : std_logic;
signal DISP_ATTRIBUTE : std_logic;
signal SIZE_SELECT : std_logic;
signal MIX_SYNCER, MIX_SYNCED : std_logic;
signal REVEAL_SYNCER, REVEAL_SYNCED : std_logic;
signal AB_EN_SYNCER, AB_EN_SYNCED : std_logic;
signal SIZE_SELECT_SYNCER, SIZE_SELECT_SYNCED : std_logic;
-- Needed for some non-compliant services
signal FOREGROUND_BLACK_ENABLE : std_logic;

constant BLANK_CHAR : std_logic_vector(6 downto 0) := "0100000";

begin
    -- Read from previous row when last line was double height
    MEMORY_ADDRESS_OUT <= std_logic_vector(to_unsigned(CHAR_COUNTER,10)) when DH_LAST_ROW = '0' else std_logic_vector(to_unsigned(CHAR_COUNTER - TEXT_COLS,10));
    
    MEMORY_DATA <= MEMORY_DATA_IN;
    
    FOREGROUND_BLACK_ENABLE <= AB_EN_SYNCED;

CGROM: entity work.CGROM
    port map(
    ADDRESS_IN => CHAR_TO_DISPLAY,
    ROW_SELECT_IN => std_logic_vector(to_unsigned(CHAR_ROW_SELECT - 1,4)),
    DATA_OUT => CGROM_LINE);
    
    -- Generate the mosaic character
    -- 0 1
    -- 2 3
    -- 4 5
    MOSAIC(0) <= CHAR_TO_DISPLAY(0);
    MOSAIC(1) <= CHAR_TO_DISPLAY(1);
    MOSAIC(2) <= CHAR_TO_DISPLAY(2);
    MOSAIC(3) <= CHAR_TO_DISPLAY(3);
    MOSAIC(4) <= CHAR_TO_DISPLAY(4);
    MOSAIC(5) <= CHAR_TO_DISPLAY(6);
    MOSAIC_PIXEL <= '0' when CONTIGUOUS = '0' and (CHAR_COL_COUNTER_D = 0 or CHAR_COL_COUNTER_D = H_CHAR_SIZE / 2 or CHAR_ROW_SELECT = MOSAIC_DIV1 or CHAR_ROW_SELECT = MOSAIC_DIV2-1 or CHAR_ROW_SELECT = V_CHAR_SIZE-1) else
                    MOSAIC(0) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV1 else
                    MOSAIC(1) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV1 else
                    MOSAIC(2) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV2 else
                    MOSAIC(3) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV2 else
                    MOSAIC(4) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < V_CHAR_SIZE else
                    MOSAIC(5) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < V_CHAR_SIZE else '0';
    LAST_MOSAIC_PIXEL <= '0' when LAST_CONTIGUOUS = '0' and (CHAR_COL_COUNTER_D = 0 or CHAR_COL_COUNTER_D = H_CHAR_SIZE / 2 or CHAR_ROW_SELECT = MOSAIC_DIV1 or CHAR_ROW_SELECT = MOSAIC_DIV2-1 or CHAR_ROW_SELECT = V_CHAR_SIZE-1) else
                    LAST_MOSAIC(0) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV1 else
                    LAST_MOSAIC(1) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV1 else
                    LAST_MOSAIC(2) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV2 else
                    LAST_MOSAIC(3) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < MOSAIC_DIV2 else
                    LAST_MOSAIC(4) when CHAR_COL_COUNTER_D < H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < V_CHAR_SIZE else
                    LAST_MOSAIC(5) when CHAR_COL_COUNTER_D >= H_CHAR_SIZE / 2 and CHAR_ROW_SELECT < V_CHAR_SIZE else '0';
                    
    -- CGROM row selector for double-height characters
    CHAR_ROW_SELECT <= to_integer(to_unsigned(CHAR_ROW_COUNTER, V_CHAR_SIZE_BITS)(V_CHAR_SIZE_BITS - 1 downto 1)) when DH = '1' and DH_THIS_ROW = '1' else to_integer(to_unsigned(CHAR_ROW_COUNTER + V_CHAR_SIZE, V_CHAR_SIZE_BITS + 1)(V_CHAR_SIZE_BITS downto 1)) when DH = '1' and DH_LAST_ROW = '1' else CHAR_ROW_COUNTER;
                    
ACTIVE_AREA_CONTROLLER: process(CLK, RESET)
    begin
        if RESET = '1' then
            PIXEL_COUNTER <= 0;
            ROW_COUNTER <= 0;
            NEXT_V_PIXEL <= '0';
            V_PIXEL_STRETCH_COUNTER <= 0;
            H_PIXEL_STRETCH_COUNTER <= 0;
            END_OF_ROW <= '0';
            SIZE_SELECT <= '0';
        elsif rising_edge(CLK) then
            if NEW_SCREEN_IN = '1' then
                ROW_COUNTER <= 0;
                NEXT_V_PIXEL <= '0';
                V_PIXEL_STRETCH_COUNTER <= 0;
                H_PIXEL_STRETCH_COUNTER <= 0;
                SIZE_SELECT <= SIZE_SELECT_SYNCED;
            else
                if NEW_ROW_IN = '1' then
                    PIXEL_COUNTER <= 0;
                    if (ROW_COUNTER < (V_SIZE_1 - 1) and SIZE_SELECT = '0') or (ROW_COUNTER < (V_SIZE_2 - 1) and SIZE_SELECT = '1') then
                        ROW_COUNTER <= ROW_COUNTER + 1;
                    end if;
                    if ((ROW_COUNTER >= DISPLAY_AREA_1_TOP and ROW_COUNTER < DISPLAY_AREA_1_BOTTOM and SIZE_SELECT = '0') or (ROW_COUNTER >= DISPLAY_AREA_2_TOP and ROW_COUNTER < DISPLAY_AREA_2_BOTTOM and SIZE_SELECT = '1')) then
                        if V_PIXEL_STRETCH_COUNTER = V_PIXEL_STRETCH - 1 then
                            V_PIXEL_STRETCH_COUNTER <= 0;
                            NEXT_V_PIXEL <= '1';
                        else
                            V_PIXEL_STRETCH_COUNTER <= V_PIXEL_STRETCH_COUNTER + 1;
                            NEXT_V_PIXEL <= '0';
                        end if;
                    end if;
                else
                    if (PIXEL_COUNTER < (H_SIZE_1 - 1) and SIZE_SELECT = '0') or (PIXEL_COUNTER < (H_SIZE_2 - 1) and SIZE_SELECT = '1') then
                        PIXEL_COUNTER <= PIXEL_COUNTER + 1;
                    end if;
                    if IN_DISPLAY_AREA = '1' then
                        if H_PIXEL_STRETCH_COUNTER = H_PIXEL_STRETCH - 1 then
                            H_PIXEL_STRETCH_COUNTER <= 0;
                        else
                            H_PIXEL_STRETCH_COUNTER <= H_PIXEL_STRETCH_COUNTER + 1;
                        end if;
                    end if;
                    if ((ROW_COUNTER >= DISPLAY_AREA_1_TOP and ROW_COUNTER < DISPLAY_AREA_1_BOTTOM and PIXEL_COUNTER = DISPLAY_AREA_1_RIGHT and SIZE_SELECT = '0') or (ROW_COUNTER >= DISPLAY_AREA_2_TOP and ROW_COUNTER < DISPLAY_AREA_2_BOTTOM and PIXEL_COUNTER = DISPLAY_AREA_2_RIGHT and SIZE_SELECT = '1')) then
                        END_OF_ROW <= '1';
                    else
                        END_OF_ROW <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    IN_DISPLAY_AREA <= '1' when (ROW_COUNTER >= DISPLAY_AREA_1_TOP and ROW_COUNTER < DISPLAY_AREA_1_BOTTOM and PIXEL_COUNTER >= DISPLAY_AREA_1_LEFT and PIXEL_COUNTER < DISPLAY_AREA_1_RIGHT and SIZE_SELECT = '0') or (ROW_COUNTER >= DISPLAY_AREA_2_TOP and ROW_COUNTER < DISPLAY_AREA_2_BOTTOM and PIXEL_COUNTER >= DISPLAY_AREA_2_LEFT and PIXEL_COUNTER < DISPLAY_AREA_2_RIGHT and SIZE_SELECT = '1') else '0';
    NEXT_H_PIXEL <= '1' when IN_DISPLAY_AREA = '1' and H_PIXEL_STRETCH_COUNTER = 0 else '0';
    
    
DISPLAY_GEN: process(CLK, RESET)
    begin
    if RESET = '1' then
            CURRENT_PIXEL <= '0';
            CHAR_COUNTER <= 0;
            CHAR_COL_COUNTER <= 0;
            CHAR_COL_COUNTER_D <= 0;
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
            FG_R_D <= '0';
            FG_G_D <= '0';
            FG_B_D <= '0';
            BG_R_D <= '0';
            BG_G_D <= '0';
            BG_B_D <= '0';
            CHAR_TO_DISPLAY <= (others => '0');
            MOSAIC_ENABLE <= '0';
            NEXT_MOSAIC_ENABLE <= '0';
            MOSAIC_HOLD <= '0';
            NEXT_MOSAIC_HOLD <= '0';
            CONCEAL <= '0';
            NEXT_CONCEAL <= '0';
            FLASH <= '0';
            FLASH_TIMER <= 0;
            CONTIGUOUS <= '1';
            LAST_CONTIGUOUS <= '1';
            LAST_MOSAIC <= (others => '0');
            NEXT_H_PIXEL_D <= '0';
            DH_LAST_ROW <= '0';
            DH_THIS_ROW <= '0';
            DH <= '0';
            NEXT_DH <= '0';
            MIX_SYNCER <= '0';
            MIX_SYNCED <= '0';
        elsif rising_edge(CLK) then
            DISP_ATTRIBUTE <= ((NOT CONCEAL) OR REVEAL_SYNCED) AND ((NOT FLASH) OR FLASH_TIMER_PULSE);
            NEXT_H_PIXEL_D <= NEXT_H_PIXEL;
            CHAR_COL_COUNTER_D <= CHAR_COL_COUNTER;
            FG_R_D <= FG_R;
            FG_G_D <= FG_G;
            FG_B_D <= FG_B;
            BG_R_D <= BG_R;
            BG_G_D <= BG_G;
            BG_B_D <= BG_B;
            MIX_SYNCER <= MIX_IN;
            REVEAL_SYNCER <= REVEAL_IN;
            AB_EN_SYNCER <= AB_EN_IN;
            SIZE_SELECT_SYNCER <= SIZE_SELECT_IN;
            SIZE_SELECT_SYNCED <= SIZE_SELECT_SYNCER;
            
            if FLASH_TIMER < FLASH_DURATION then
                FLASH_TIMER <= FLASH_TIMER + 1;
            else
                FLASH_TIMER <= 0;
            end if;
            
            if NEW_SCREEN_IN = '1' then
                CHAR_COUNTER <= 0;
                CHAR_COL_COUNTER <= 0;
                CHAR_ROW_COUNTER <= 0;
                MIX_SYNCED <= MIX_SYNCER;
                REVEAL_SYNCED <= REVEAL_SYNCER;
                AB_EN_SYNCED <= AB_EN_SYNCER;
            end if;
            
            if NEW_ROW_IN = '1' and NEXT_V_PIXEL = '1' then
                if CHAR_ROW_COUNTER < V_CHAR_SIZE - 1 then
                    -- start of next line in the same row of data
                    CHAR_ROW_COUNTER <= CHAR_ROW_COUNTER + 1;
                else
                    -- proceed to next part of character set
                    CHAR_COUNTER <= CHAR_COUNTER + TEXT_COLS;
                    CHAR_ROW_COUNTER <= 0;
                    DH_LAST_ROW <= DH_THIS_ROW AND (NOT DH_LAST_ROW);
                    DH_THIS_ROW <= '0';
                end if;
            end if;
            
            if NEXT_H_PIXEL = '1' then
                if CHAR_COL_COUNTER = 0 then
                    CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                    CHAR_TO_DISPLAY <= MEMORY_DATA;
                    FG_R <= NEXT_FG_R;
                    FG_G <= NEXT_FG_G;
                    FG_B <= NEXT_FG_B;
                    CONCEAL <= NEXT_CONCEAL;
                    MOSAIC_ENABLE <= NEXT_MOSAIC_ENABLE;
                    MOSAIC_HOLD <= NEXT_MOSAIC_HOLD;
                    DH <= NEXT_DH;
                    case MEMORY_DATA is
                    when "0000001"|"0000010"|"0000011"|"0000100"|"0000101"|"0000110"|"0000111" =>
                        NEXT_FG_R <= MEMORY_DATA(0);
                        NEXT_FG_G <= MEMORY_DATA(1);
                        NEXT_FG_B <= MEMORY_DATA(2);
                        NEXT_MOSAIC_ENABLE <= '0';
                        NEXT_CONCEAL <= '0';
                    when "0000000" =>
                        if FOREGROUND_BLACK_ENABLE = '1' then
                            NEXT_FG_R <= MEMORY_DATA(0);
                            NEXT_FG_G <= MEMORY_DATA(1);
                            NEXT_FG_B <= MEMORY_DATA(2);
                            NEXT_MOSAIC_ENABLE <= '0';
                            NEXT_CONCEAL <= '0';
                        end if;
                    when "0001100" =>
                        -- Normal Height (Set-After)
                        if NEXT_DH = '1' then
                            -- Clear held mosaic only if new size is different
                            LAST_MOSAIC <= (others => '0');
                            LAST_CONTIGUOUS <= '1';
                        end if;
                        NEXT_DH <= '0';
                    when "0001101" =>
                        -- Double Height (Set-After)
                        if NEXT_DH = '0' then
                            -- Clear held mosaic only if new size is different
                            LAST_MOSAIC <= (others => '0');
                            LAST_CONTIGUOUS <= '1';
                        end if;
                        DH_THIS_ROW <= '1' AND (NOT DH_LAST_ROW);
                        NEXT_DH <= '1';
                    when "0001000" =>
                        -- Flash (Set-After)
                        FLASH <= '1';
                    when "0001001" =>
                        -- Steady (Set-At)
                        FLASH <= '0';
                    when "0010001"|"0010010"|"0010011"|"0010100"|"0010101"|"0010110"|"0010111" =>
                        NEXT_FG_R <= MEMORY_DATA(0);
                        NEXT_FG_G <= MEMORY_DATA(1);
                        NEXT_FG_B <= MEMORY_DATA(2);
                        NEXT_MOSAIC_ENABLE <= '1';
                        NEXT_CONCEAL <= '0';
                    when "0010000" =>
                        if FOREGROUND_BLACK_ENABLE = '1' then
                            NEXT_FG_R <= MEMORY_DATA(0);
                            NEXT_FG_G <= MEMORY_DATA(1);
                            NEXT_FG_B <= MEMORY_DATA(2);
                            NEXT_MOSAIC_ENABLE <= '1';
                            NEXT_CONCEAL <= '0';
                        end if;
                    when "0011000" =>
                        -- Conceal (Set-At)
                        CONCEAL <= '1';
                        NEXT_CONCEAL <= '1';
                    when "0011001" =>
                        CONTIGUOUS <= '1';
                    when "0011010" =>
                        CONTIGUOUS <= '0';
                    when "0011100" =>
                        -- Black Background (Set-At)
                        BG_R <= '0';
                        BG_G <= '0';
                        BG_B <= '0';
                    when "0011110" =>
                        -- Mosaic Hold (Set-At)
                        MOSAIC_HOLD <= '1';
                        NEXT_MOSAIC_HOLD <= '1';
                    when "0011111" =>
                        -- Mosaic Hold (should be Set-After)
                        NEXT_MOSAIC_HOLD <= '0';
                    when "0011101" =>
                        -- New Background (Set-At)
                        BG_R <= NEXT_FG_R;
                        BG_G <= NEXT_FG_G;
                        BG_B <= NEXT_FG_B;
                    when others =>
                        if NEXT_DH = '0' and DH_LAST_ROW = '1' then
                            CHAR_TO_DISPLAY <= BLANK_CHAR;
                        end if;
                    end case;
                else
                    CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                end if;
                if CHAR_COL_COUNTER = H_CHAR_SIZE - 1 then
                    CHAR_COL_COUNTER <= 0;
                    CHAR_COUNTER <= CHAR_COUNTER + 1;
                end if;
            end if;
            
            if NEXT_H_PIXEL_D = '1' then
                if MOSAIC_ENABLE = '0' or (CHAR_TO_DISPLAY(6) = '1' and CHAR_TO_DISPLAY(5) = '0') then
                    -- Display character when mosaics disabled or mosaic is enabled and CAPITAL LETTER address is in memory
                    if CHAR_COL_COUNTER_D = H_CHAR_SIZE - 1 then
                        -- Display background for the column between characters
                        CURRENT_PIXEL <= '0';
                    else
                        -- Display character glyph
                        CURRENT_PIXEL <= CGROM_LINE(H_CHAR_SIZE - 2 - CHAR_COL_COUNTER_D);
                    end if;
                elsif CHAR_TO_DISPLAY(5) = '1' then
                    -- Display mosaic when MOSAIC_ENABLE = '1' and a mosaic address is in memory
                    CURRENT_PIXEL <= MOSAIC_PIXEL;
                    -- Store mosaic and contiguousity in case of held mosaic
                    LAST_MOSAIC <= MOSAIC;
                    LAST_CONTIGUOUS <= CONTIGUOUS;
                else
                    -- Put mosaic hold stuff here
                    if MOSAIC_HOLD = '1' then
                        CURRENT_PIXEL <= LAST_MOSAIC_PIXEL;
                    else
                        CURRENT_PIXEL <= '0';
                    end if;
                end if;
            end if;
            
            if END_OF_ROW = '1' then
                -- Need to subtract TEXT_COLS because we've only printed one row of pixels
                -- and need to print from the same characters again
                CHAR_COUNTER <= CHAR_COUNTER - TEXT_COLS;
                CHAR_COL_COUNTER <= 0;
                CURRENT_PIXEL <= '0';
                FG_R <= '1';
                FG_G <= '1';
                FG_B <= '1';
                NEXT_FG_R <= '1';
                NEXT_FG_G <= '1';
                NEXT_FG_B <= '1';
                BG_R <= '0';
                BG_G <= '0';
                BG_B <= '0';
                BG_R_D <= '0';
                BG_G_D <= '0';
                BG_B_D <= '0';
                MOSAIC_ENABLE <= '0';
                NEXT_MOSAIC_ENABLE <= '0';
                MOSAIC_HOLD <= '0';
                NEXT_MOSAIC_HOLD <= '0';
                CONCEAL <= '0';
                NEXT_CONCEAL <= '0';
                FLASH <= '0';
                CONTIGUOUS <= '1';
                LAST_CONTIGUOUS <= '1';
                LAST_MOSAIC <= (others => '0');
                DH <= '0';
                NEXT_DH <= '0';
            end if;
        end if;
    end process;
    R_OUT <= ((CURRENT_PIXEL AND FG_R_D AND DISP_ATTRIBUTE) or (((NOT CURRENT_PIXEL) OR (NOT DISP_ATTRIBUTE)) AND BG_R_D AND (NOT MIX_SYNCED)));
    G_OUT <= ((CURRENT_PIXEL AND FG_G_D AND DISP_ATTRIBUTE) or (((NOT CURRENT_PIXEL) OR (NOT DISP_ATTRIBUTE)) AND BG_G_D AND (NOT MIX_SYNCED)));
    B_OUT <= ((CURRENT_PIXEL AND FG_B_D AND DISP_ATTRIBUTE) or (((NOT CURRENT_PIXEL) OR (NOT DISP_ATTRIBUTE)) AND BG_B_D AND (NOT MIX_SYNCED)));
    
    FLASH_TIMER_PULSE <= '1' when FLASH_TIMER < FLASH_DURATION / 2 else '0';
end architecture;
