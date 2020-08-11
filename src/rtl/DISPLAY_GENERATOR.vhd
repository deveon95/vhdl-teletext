-- DISPLAY_GENERATOR.vhd
-- Generates the teletext display using data from RAM
-- Supports selection of two resolutions; the second resolution must be the larger of the two
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

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
    MEMORY_ADDRESS_OUT : out std_logic_vector(10 downto 0);
    
    NEW_ROW_IN : in std_logic;
    NEW_SCREEN_IN : in std_logic;
    LEVEL_2_5_ENABLE_IN : in std_logic;
    
    R_OUT : out std_logic_vector(3 downto 0);
    G_OUT : out std_logic_vector(3 downto 0);
    B_OUT : out std_logic_vector(3 downto 0)
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

signal FG_COLOUR, FG_COLOUR_D, NEXT_FG_COLOUR, BG_COLOUR, BG_COLOUR_D : std_logic_vector(2 downto 0);
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
signal BLACK_BACKGROUND : std_logic;
signal MIX_SYNCER, MIX_SYNCED : std_logic;
signal REVEAL_SYNCER, REVEAL_SYNCED : std_logic;
signal AB_EN_SYNCER, AB_EN_SYNCED : std_logic;
signal SIZE_SELECT_SYNCER, SIZE_SELECT_SYNCED : std_logic;
-- Needed for some non-compliant services
signal FOREGROUND_BLACK_ENABLE : std_logic;

constant BLANK_CHAR : std_logic_vector(6 downto 0) := "0100000";

-- Level 2.5 enhancements
-- Level 2.5 enhancement controller control signals
signal CLEAR_LEVEL_2_5_DATA : std_logic;
signal CONFIGURE_LEVEL_2_5_DATA : std_logic;
signal CONFIGURE_LEVEL_2_5_DATA_DONE : std_logic;
signal PROCESSING_ENHANCEMENTS : std_logic;
signal NEW_SCREEN_D : std_logic;
-- Level 2.5 enhancement memory addresses
signal MEMORY_ADDRESS : integer range 0 to 2047;
constant READ_LATENCY : integer := 1;
signal MEMORY_ADDRESS_LAT : integer range 0 to 2047;
constant ENHANCEMENTS_START : integer := 1024;
constant ENHANCEMENTS_END : integer := 1803;
-- Below constants are relative to ENHANCEMENTS_START
constant ADDRESS_PACKET_28_0 : integer := 0;
constant ADDRESS_PACKET_28_1 : integer := 39;
constant ADDRESS_PACKET_28_3 : integer := 78;
constant ADDRESS_PACKET_28_4 : integer := 117;
constant ADDRESS_PACKET_26 : integer := 273;
-- Extracted Level 2.5 enhancement data
type COLOUR_ARRAY is array (integer range <>) of std_logic_vector(11 downto 0);
signal CLUT0 : COLOUR_ARRAY(0 to 7);        -- Redefinable at Level 3.5 only
signal CLUT1 : COLOUR_ARRAY(0 to 7);        -- Redefinable at Level 3.5 only
signal CLUT2 : COLOUR_ARRAY(0 to 7);        -- Redefinable at Level 2.5
signal CLUT3 : COLOUR_ARRAY(0 to 7);        -- Redefinable at Level 2.5
constant CLUT0_DEFAULT : COLOUR_ARRAY(0 to 7) := ("000000000000", "000000001111", "000011110000", "000011111111", "111100000000", "111100001111", "111111110000", "111111111111");
constant CLUT1_DEFAULT : COLOUR_ARRAY(0 to 7) := ("000000000000", "000000000111", "000001110000", "000001110111", "011100000000", "011100000111", "011101110000", "011101110111");
constant CLUT2_DEFAULT : COLOUR_ARRAY(0 to 7) := ("010100001111", "000001111111", "011111110000", "101111111111", "101011000000", "000000000101", "001001010110", "011101111100");
constant CLUT3_DEFAULT : COLOUR_ARRAY(0 to 7) := ("010100001111", "000001111111", "011111110000", "101111111111", "101011000000", "000000000101", "001001010110", "011101111100");
signal CT_REMAPPING : std_logic_vector(2 downto 0);
signal DEFAULT_ROW_COLOUR : std_logic_vector(4 downto 0);
signal DEFAULT_SCREEN_COLOUR : std_logic_vector(4 downto 0);
signal BLACK_BACKGROUND_COLOUR_SUBSTITUTION : std_logic;
-- Combinational signals
signal FOREGROUND_CLUT : COLOUR_ARRAY(0 to 7);
signal BACKGROUND_CLUT : COLOUR_ARRAY(0 to 7);


begin

ENHANCEMENTS_CONTROLLER: process(CLK, RESET)
    begin
        if RESET = '1' then
            DEFAULT_ROW_COLOUR <= (others => '0');
            DEFAULT_SCREEN_COLOUR <= (others => '0');
            BLACK_BACKGROUND_COLOUR_SUBSTITUTION <= '0';
            CT_REMAPPING <= (others => '0');
            CLUT0 <= CLUT0_DEFAULT;
            CLUT1 <= CLUT1_DEFAULT;
            CLUT2 <= CLUT2_DEFAULT;
            CLUT3 <= CLUT3_DEFAULT;
            MEMORY_ADDRESS <= 0;
            PROCESSING_ENHANCEMENTS <= '0';
            CONFIGURE_LEVEL_2_5_DATA <= '0';
            CLEAR_LEVEL_2_5_DATA <= '0';
            NEW_SCREEN_D <= '0';
            CONFIGURE_LEVEL_2_5_DATA_DONE <= '0';
        elsif rising_edge(CLK) then
            -- Pulse for one clock cycle when a new screen starts (may need to create an end of screen signal for this later)
            CLEAR_LEVEL_2_5_DATA <= NEW_SCREEN_IN AND not NEW_SCREEN_D;
            NEW_SCREEN_D <= NEW_SCREEN_IN;
            -- Pulse for one clock cycle after CLEAR_LEVEL_2_5_DATA
            CONFIGURE_LEVEL_2_5_DATA <= CLEAR_LEVEL_2_5_DATA;
            
            if CLEAR_LEVEL_2_5_DATA = '1' then
                CONFIGURE_LEVEL_2_5_DATA_DONE <= '0';
            end if;
                
            if LEVEL_2_5_ENABLE_IN = '1' and CONFIGURE_LEVEL_2_5_DATA_DONE = '0' then
                if CONFIGURE_LEVEL_2_5_DATA = '1' then
                    MEMORY_ADDRESS <= ENHANCEMENTS_START;
                    PROCESSING_ENHANCEMENTS <= '1';
                elsif MEMORY_ADDRESS = ENHANCEMENTS_END + READ_LATENCY then
                    CONFIGURE_LEVEL_2_5_DATA_DONE <= '1';
                    PROCESSING_ENHANCEMENTS <= '0';
                elsif MEMORY_DATA_IN(6) = '1' then
                    -- MEMORY_DATA_IN(6) is set if a valid packet has been written to RAM by the Memory Controller
                    -- Case statement for storing the configuration
                    -- Remember that the Memory Controller reverses the data order, so bit 18 is address 0 bit 5 and bit 1 is address 2 bit 0
                    case MEMORY_ADDRESS_LAT is
                    
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 4 =>
                        CLUT2(0)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 3 =>
                        CLUT2(0)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 8 =>
                        CLUT2(0)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(1)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 7 =>
                        CLUT2(1)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 6 =>
                        CLUT2(1)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(2)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 11 =>
                        CLUT2(2)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 10 =>
                        CLUT2(2)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(3)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 9 =>
                        CLUT2(3)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 14 =>
                        CLUT2(3)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(4)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 13 =>
                        CLUT2(4)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 12 =>
                        CLUT2(4)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(5)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 17 =>
                        CLUT2(5)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 16 =>
                        CLUT2(5)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(6)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 15 =>
                        CLUT2(6)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 20 =>
                        CLUT2(6)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT2(7)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 19 =>
                        CLUT2(7)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 18 =>
                        CLUT2(7)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(0)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 23 =>
                        CLUT3(0)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 22 =>
                        CLUT3(0)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(1)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 21 =>
                        CLUT3(1)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 26 =>
                        CLUT3(1)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(2)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 25 =>
                        CLUT3(2)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 24 =>
                        CLUT3(2)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(3)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 29 =>
                        CLUT3(3)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 28 =>
                        CLUT3(3)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(4)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 27 =>
                        CLUT3(4)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 32 =>
                        CLUT3(4)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(5)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 31 =>
                        CLUT3(5)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 30 =>
                        CLUT3(5)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(6)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 35 =>
                        CLUT3(6)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 34 =>
                        CLUT3(6)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        CLUT3(7)(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 33 =>
                        CLUT3(7)(7 downto 2) <= MEMORY_DATA_IN(5 downto 0);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 38 =>
                        CLUT3(7)(11 downto 8) <= MEMORY_DATA_IN(3 downto 0);
                        DEFAULT_SCREEN_COLOUR(1 downto 0) <= MEMORY_DATA_IN(5 downto 4);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 37 =>
                        DEFAULT_SCREEN_COLOUR(4 downto 2) <= MEMORY_DATA_IN(2 downto 0);
                        DEFAULT_ROW_COLOUR(2 downto 0) <= MEMORY_DATA_IN(5 downto 3);
                    when ENHANCEMENTS_START + ADDRESS_PACKET_28_0 + 36 =>
                        DEFAULT_ROW_COLOUR(4 downto 3) <= MEMORY_DATA_IN(1 downto 0);
                        BLACK_BACKGROUND_COLOUR_SUBSTITUTION <= MEMORY_DATA_IN(2);
                        CT_REMAPPING <= MEMORY_DATA_IN(5 downto 3);
                        
                    when others =>
                    end case;
                
                    MEMORY_ADDRESS <= MEMORY_ADDRESS + 1;
                    PROCESSING_ENHANCEMENTS <= '1';
                else
                    MEMORY_ADDRESS <= MEMORY_ADDRESS + 1;
                    PROCESSING_ENHANCEMENTS <= '1';
                end if;
            end if;
            
        end if;
    end process;
    
    FOREGROUND_CLUT <= CLUT1 when CT_REMAPPING = "011" or CT_REMAPPING = "100" else
                       CLUT2 when CT_REMAPPING = "101" or CT_REMAPPING = "110" or CT_REMAPPING = "111" else
                       CLUT0;
    BACKGROUND_CLUT <= CLUT1 when CT_REMAPPING = "001" or CT_REMAPPING = "011" or CT_REMAPPING = "101" else
                       CLUT2 when CT_REMAPPING = "010" or CT_REMAPPING = "100" or CT_REMAPPING = "110" else
                       CLUT3 when CT_REMAPPING = "111" else
                       CLUT0;
    
    -- Read from previous row when last line was double height
    MEMORY_ADDRESS_OUT <= std_logic_vector(to_unsigned(CHAR_COUNTER,11)) when DH_LAST_ROW = '0' and PROCESSING_ENHANCEMENTS = '0' else
                          std_logic_vector(to_unsigned(CHAR_COUNTER - TEXT_COLS,11)) when PROCESSING_ENHANCEMENTS = '0' else
                          std_logic_vector(to_unsigned(MEMORY_ADDRESS,11));
    
    MEMORY_ADDRESS_LAT <= MEMORY_ADDRESS - READ_LATENCY;
    
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
            FG_COLOUR <= (others => '0');
            NEXT_FG_COLOUR <= (others => '0');
            BG_COLOUR <= (others => '0');
            FG_COLOUR_D <= (others => '0');
            BG_COLOUR_D <= (others => '0');
            CHAR_TO_DISPLAY <= (others => '0');
            MOSAIC_ENABLE <= '0';
            NEXT_MOSAIC_ENABLE <= '0';
            MOSAIC_HOLD <= '0';
            NEXT_MOSAIC_HOLD <= '0';
            BLACK_BACKGROUND <= '1';
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
            FG_COLOUR_D <= FG_COLOUR;
            BG_COLOUR_D <= BG_COLOUR;
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
                    FG_COLOUR <= NEXT_FG_COLOUR;
                    CONCEAL <= NEXT_CONCEAL;
                    MOSAIC_ENABLE <= NEXT_MOSAIC_ENABLE;
                    MOSAIC_HOLD <= NEXT_MOSAIC_HOLD;
                    DH <= NEXT_DH;
                    case MEMORY_DATA is
                    when "0000001"|"0000010"|"0000011"|"0000100"|"0000101"|"0000110"|"0000111" =>
                        NEXT_FG_COLOUR <= MEMORY_DATA(2 downto 0);
                        NEXT_MOSAIC_ENABLE <= '0';
                        NEXT_CONCEAL <= '0';
                    when "0000000" =>
                        if FOREGROUND_BLACK_ENABLE = '1' then
                            NEXT_FG_COLOUR <= MEMORY_DATA(2 downto 0);
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
                        NEXT_FG_COLOUR <= MEMORY_DATA(2 downto 0);
                        NEXT_MOSAIC_ENABLE <= '1';
                        NEXT_CONCEAL <= '0';
                    when "0010000" =>
                        if FOREGROUND_BLACK_ENABLE = '1' then
                            NEXT_FG_COLOUR <= MEMORY_DATA(2 downto 0);
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
                        BG_COLOUR <= (others => '0');
                        -- Black Background flag required for correct Level 2.5 substitution
                        BLACK_BACKGROUND <= '1';
                    when "0011110" =>
                        -- Mosaic Hold (Set-At)
                        MOSAIC_HOLD <= '1';
                        NEXT_MOSAIC_HOLD <= '1';
                    when "0011111" =>
                        -- Mosaic Hold (should be Set-After)
                        NEXT_MOSAIC_HOLD <= '0';
                    when "0011101" =>
                        -- New Background (Set-At)
                        BG_COLOUR <= NEXT_FG_COLOUR;
                        BLACK_BACKGROUND <= '0';
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
                FG_COLOUR <= (others => '1');
                NEXT_FG_COLOUR <= (others => '1');
                BG_COLOUR <= (others => '0');
                BG_COLOUR_D <= (others => '0');
                MOSAIC_ENABLE <= '0';
                NEXT_MOSAIC_ENABLE <= '0';
                MOSAIC_HOLD <= '0';
                NEXT_MOSAIC_HOLD <= '0';
                BLACK_BACKGROUND <= '1';
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
    
    
    -- Add black background colour substitution stuff
    R_OUT <= FOREGROUND_CLUT(to_integer(unsigned(FG_COLOUR_D)))(3 downto 0) when (CURRENT_PIXEL AND DISP_ATTRIBUTE) = '1' else 
             BACKGROUND_CLUT(to_integer(unsigned(BG_COLOUR_D)))(3 downto 0) when MIX_SYNCED = '0' else
             "0000";
    G_OUT <= FOREGROUND_CLUT(to_integer(unsigned(FG_COLOUR_D)))(7 downto 4) when (CURRENT_PIXEL AND DISP_ATTRIBUTE) = '1' else 
             BACKGROUND_CLUT(to_integer(unsigned(BG_COLOUR_D)))(7 downto 4) when MIX_SYNCED = '0' else
             "0000";
    B_OUT <= FOREGROUND_CLUT(to_integer(unsigned(FG_COLOUR_D)))(11 downto 8) when (CURRENT_PIXEL AND DISP_ATTRIBUTE) = '1' else 
             BACKGROUND_CLUT(to_integer(unsigned(BG_COLOUR_D)))(11 downto 8) when MIX_SYNCED = '0' else
             "0000";
    
    FLASH_TIMER_PULSE <= '1' when FLASH_TIMER < FLASH_DURATION / 2 else '0';
end architecture;
