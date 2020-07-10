-- TXT_TOP_LEVEL.vhd
-- VHDL-Teletext top level entity for the RTL code
-- This file links all of the modules together to create a teletext decoder.
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_TOP_LEVEL is
    port (
    RESETn     : in  std_logic;
    -- programmable oscillator
    CLK_27_750 : in  std_logic;
    CLK_VIDEO  : in  std_logic;
    CLK_SPARE  : in  std_logic;
    PRCLK_SDA  : inout std_logic;
    PRCLK_SCL  : inout std_logic;
    -- data in
    RX_IN      : in  std_logic;
    -- keypad and DIP switches
    KEYPAD_ROWS : inout std_logic_vector(8 downto 0);
    KEYPAD_COLS : in  std_logic_vector(3 downto 0);
    -- LED
    LED_OUT    : out std_logic;
    -- HDMI interface
    HDMI_SDA   : inout std_logic;
    HDMI_SCL   : inout std_logic;
    TMDS_CLK   : out std_logic;
    --TMDS_CLK_N : out std_logic;
    TMDS_D0    : out std_logic;
    --TMDS_D0_N : out std_logic;
    TMDS_D1    : out std_logic;
    --TMDS_D1_N : out std_logic;
    TMDS_D2    : out std_logic;
    --TMDS_D2_N : out std_logic;
    HDMI_HPD   : in std_logic;
    -- SRAM for future use (optional)
    SRAM_ADDR  : out std_logic_vector(18 downto 0);
    SRAM_DATA  : inout std_logic_vector(7 downto 0);
    SRAM_OE_N  : out std_logic;
    SRAM_WE_N  : out std_logic;
    SRAM_CE_N  : out std_logic;
    -- SAA7113 Video Processor (optional) - use same pins as oscillator for I2C
    VP_DATA_IN : in std_logic_vector(7 downto 0);
    VP_RTCO_IN : in std_logic;
    VP_RTS0_IN : in std_logic;
    VP_RTS1_IN : in std_logic;
    VP_LLC_IN  : in std_logic;
    -- VGA interface
    R_OUT      : out std_logic;
    G_OUT      : out std_logic;
    B_OUT      : out std_logic;
    HSYNC_OUT  : out std_logic;
    VSYNC_OUT  : out std_logic;
    HSYNC_IN   : in  std_logic;
    VSYNC_IN   : in  std_logic;
    R_EN_OUT   : out std_logic;
    G_EN_OUT   : out std_logic;
    B_EN_OUT   : out std_logic
    );
end entity TXT_TOP_LEVEL;

architecture rtl of TXT_TOP_LEVEL is

-- Parameters for 720x576 resolution
constant H_SIZE_1 : integer := 720;
constant H_FRONT_PORCH_1 : integer := 16;
constant H_SYNC_PULSE_1 : integer := 64;
constant H_BACK_PORCH_1 : integer := 64;
constant V_SIZE_1 : integer := 576;
constant V_FRONT_PORCH_1 : integer := 10;
constant V_SYNC_PULSE_1 : integer := 2;
constant V_BACK_PORCH_1 : integer := 37;
-- Parameters for 800x600 resolution
constant H_SIZE_2 : integer := 800;
constant H_FRONT_PORCH_2 : integer := 40;
constant H_SYNC_PULSE_2 : integer := 128;
constant H_BACK_PORCH_2 : integer := 88;
constant V_SIZE_2 : integer := 600;
constant V_FRONT_PORCH_2 : integer := 1;
constant V_SYNC_PULSE_2 : integer := 4;
constant V_BACK_PORCH_2 : integer := 23;

-- constant H_SIZE : integer := 720;
-- constant H_FRONT_PORCH : integer := 16;
-- constant H_SYNC_PULSE : integer := 96;
-- constant H_BACK_PORCH : integer := 32;
-- constant V_SIZE : integer := 576;
-- constant V_FRONT_PORCH : integer := 23;
-- constant V_SYNC_PULSE : integer := 3;
-- constant V_BACK_PORCH : integer := 23;
-- Parameters for 640x480 resolution
--constant H_SIZE : integer := 640;
--constant H_FRONT_PORCH : integer := 16;
--constant H_SYNC_PULSE : integer := 96;
--constant H_BACK_PORCH : integer := 48;
--constant V_SIZE : integer := 480;
--constant V_FRONT_PORCH : integer := 11;
--constant V_SYNC_PULSE : integer := 2;
--constant V_BACK_PORCH : integer := 31;

-- Button repeat delay (Page Up and Page Down only)
constant BUTTON_DELAY_COUNTER_MAX : integer := 2775000;

-- '1' for keypad buttons except Page Up and Page Down, '0' for DIP switches
constant MOMENTARY_MASK : std_logic_vector(35 downto 0) := 
"111111111111101011110000000000000000";
-- END OF CONSTANTS
    
signal PAGE_NUMBER : std_logic_vector(10 downto 0);
signal SUBPAGE_NUMBER : std_logic_vector(12 downto 0);
signal PAGE_NUMBER_DIPSW : std_logic_vector(10 downto 0);
signal BUTTON_DELAY_COUNTER : integer range 0 to BUTTON_DELAY_COUNTER_MAX;   --10 increments per second

signal RESET : std_logic;
signal CLK_INTERNAL : std_logic;
signal PRCLK_SDA_INT : std_logic;
signal PRCLK_SCL_INT : std_logic;
signal SERIAL_DATA : std_logic;
signal SERIAL_CLOCK : std_logic;
signal SERIAL_FRAME_VALID : std_logic;
signal BYTE_DATA : std_logic_vector(7 downto 0);
signal BYTE_CLOCK : std_logic;
signal BYTE_FRAME_VALID : std_logic;
signal WORD_DATA : std_logic_vector(6 downto 0);
signal WORD_CLOCK : std_logic;
signal WORD_FRAME_VALID : std_logic;
signal MAGAZINE    : std_logic_vector(2 downto 0);
signal ROW         : std_logic_vector(4 downto 0);
signal PAGE        : std_logic_vector(7 downto 0);
signal SUBCODE     : std_logic_vector(12 downto 0);
signal CONTROL_BITS : std_logic_vector(10 downto 0);

-- Keypad Signals
signal KEYPAD_BUTTONS : std_logic_vector(35 downto 0);
signal KEYPAD_FIRST_PASS : std_logic;
signal KEYPAD_FIRST_PASS_LAST : std_logic;

signal MIX_BUTTON     : std_logic;
signal SUBPAGE_BUTTON : std_logic;
signal REVEAL_BUTTON  : std_logic;
signal PAGE_UP_BUTTON    : std_logic;
signal PAGE_DOWN_BUTTON  : std_logic;
signal RED_BUTTON : std_logic;
signal GRN_BUTTON : std_logic;
signal YEL_BUTTON : std_logic;
signal BLU_BUTTON : std_logic;
signal IDX_BUTTON : std_logic;
signal KEY_0 : std_logic;
signal KEY_1 : std_logic;
signal KEY_2 : std_logic;
signal KEY_3 : std_logic;
signal KEY_4 : std_logic;
signal KEY_5 : std_logic;
signal KEY_6 : std_logic;
signal KEY_7 : std_logic;
signal KEY_8 : std_logic;
signal KEY_9 : std_logic;
signal KEY_ACTIVE : std_logic;
signal KEY_VALUE : std_logic_vector(3 downto 0);
signal KEYPAD_ROWS_INT : std_logic_vector(KEYPAD_ROWS'length-1 downto 0);

signal MIX_ENABLE  : std_logic;
signal SUBPAGE_ENABLE : std_logic;
signal REVEAL_ENABLE  : std_logic;
signal AB_ENABLE : std_logic;
signal REFRESH_RATE_SELECT : std_logic;
signal RESOLUTION_SELECT : std_logic;
signal MIX_LAST  : std_logic;
signal SUBPAGE_LAST  : std_logic;
signal REVEAL_LAST  : std_logic;
signal DIGIT_INDEX : integer range 0 to 3;
signal KEY_ACTIVE_LAST : std_logic;

-- Subpage number of currently loaded page
signal LAST_SUBCODE : std_logic_vector(12 downto 0);
-- Editorial links for currently loaded page
signal RED_PAGE     : std_logic_vector(10 downto 0);
signal GRN_PAGE     : std_logic_vector(10 downto 0);
signal YEL_PAGE     : std_logic_vector(10 downto 0);
signal BLU_PAGE     : std_logic_vector(10 downto 0);
signal IDX_PAGE     : std_logic_vector(10 downto 0);
-- Page number display characters
signal STATUS_1     : std_logic_vector(6 downto 0);
signal STATUS_2     : std_logic_vector(6 downto 0);
signal STATUS_3     : std_logic_vector(6 downto 0);
signal STATUS_4     : std_logic_vector(6 downto 0);
-- Temporary digits used when keying in the page number
signal TEMP_DIG_1   : std_logic_vector(1 downto 0);
signal TEMP_DIG_2   : std_logic_vector(3 downto 0);
signal TEMP_DIG_3   : std_logic_vector(3 downto 0);

-- Dual Port RAM signals
signal DPR_READ_DATA : std_logic_vector(6 downto 0);
signal DPR_READ_ADDRESS : std_logic_vector(9 downto 0);
signal DPR_WRITE_ADDRESS : std_logic_vector(9 downto 0);
signal DPR_WRITE_EN : std_logic;
signal DPR_WRITE_DATA : std_logic_vector(6 downto 0);

-- Video signals
signal NEW_ROW : std_logic;
signal NEW_SCREEN : std_logic;
signal R : std_logic;
signal G : std_logic;
signal B : std_logic;
signal TMDS_D0_UNBUF : std_logic;
signal TMDS_D1_UNBUF : std_logic;
signal TMDS_D2_UNBUF : std_logic;
signal TMDS_CLK_UNBUF : std_logic;
signal CLK_VIDEO_PIXEL : std_logic;
signal CLK_VIDEO_BIT : std_logic;

-- HEX_TO_ASCII: converts a 4-bit binary number into a 7-bit character for display
function HEX_TO_ASCII(HEX_IN : std_logic_vector)
        return std_logic_vector is
begin
    if HEX_IN = "1010" then
        return "1000001";
    elsif HEX_IN = "1011" then
        return "1000010";
    elsif HEX_IN = "1100" then
        return "1000011";
    elsif HEX_IN = "1101" then
        return "1000100";
    elsif HEX_IN = "1110" then
        return "1000101";
    elsif HEX_IN = "1111" then
        return "1000110";
    else
        return "011" & HEX_IN;
    end if;
end HEX_TO_ASCII;

-- Full component instantiation of Verilog module required due to Quartus bug
component obuf_iobuf_out_tvs
port (datain : in std_logic;
      dataout : out std_logic);
end component;

component pll
port (inclk0 : in std_logic;
      c0 : out std_logic;
      c1 : out std_logic);
end component;

begin

    RESET <= not RESETn;
    
-- A very simple page number entry system for testing
PAGE_NUMBER_CONTROLLER: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            PAGE_NUMBER <= "00000000000";
            SUBPAGE_NUMBER <= "0000000000000";
            KEYPAD_FIRST_PASS_LAST <= '0';
            MIX_ENABLE <= '0';
            REVEAL_ENABLE <= '0';
            MIX_LAST <= '0';
            REVEAL_LAST <= '0';
            DIGIT_INDEX <= 0;
            KEY_ACTIVE_LAST <= '0';
            TEMP_DIG_1 <= (others => '0');
            TEMP_DIG_2 <= (others => '0');
            TEMP_DIG_3 <= (others => '0');
        elsif rising_edge(CLK_27_750) then
            if KEYPAD_FIRST_PASS = '1' then
                if KEYPAD_FIRST_PASS_LAST = '0' then
                    KEYPAD_FIRST_PASS_LAST <= '1';
                    PAGE_NUMBER <= PAGE_NUMBER_DIPSW;
                else
                    if KEY_ACTIVE = '1' and KEY_ACTIVE_LAST = '0' then
                        -- Page number entry
                        if SUBPAGE_ENABLE = '1' then
                            -- For subcode page
                            if DIGIT_INDEX = 0 and KEY_VALUE(3 downto 2) = "00" then
                                TEMP_DIG_1 <= KEY_VALUE(1 downto 0);
                                DIGIT_INDEX <= 1;
                            elsif DIGIT_INDEX = 1 then
                                TEMP_DIG_2 <= KEY_VALUE;
                                DIGIT_INDEX <= 2;
                            elsif DIGIT_INDEX = 2 and KEY_VALUE(3) = '0' then
                                TEMP_DIG_3 <= '0' & KEY_VALUE(2 downto 0);
                                DIGIT_INDEX <= 3;
                            elsif DIGIT_INDEX = 3 then
                                SUBPAGE_NUMBER(12 downto 11) <= TEMP_DIG_1;
                                SUBPAGE_NUMBER(10 downto 7) <= TEMP_DIG_2;
                                SUBPAGE_NUMBER(6 downto 4) <= TEMP_DIG_3(2 downto 0);
                                SUBPAGE_NUMBER(3 downto 0) <= KEY_VALUE;
                                DIGIT_INDEX <= 0;
                            end if;
                        else
                            -- For page number
                            if DIGIT_INDEX = 0 and KEY_VALUE /= "1001" and KEY_VALUE /= "0000" then
                                TEMP_DIG_2 <= '0' & KEY_VALUE(2 downto 0);
                                DIGIT_INDEX <= 2;
                            elsif DIGIT_INDEX = 2 then
                                TEMP_DIG_3 <= KEY_VALUE;
                                DIGIT_INDEX <= 3;
                            elsif DIGIT_INDEX = 3 then
                                PAGE_NUMBER(10 downto 8) <= TEMP_DIG_2(2 downto 0);
                                PAGE_NUMBER(7 downto 4) <= TEMP_DIG_3;
                                PAGE_NUMBER(3 downto 0) <= KEY_VALUE;
                                DIGIT_INDEX <= 0;
                            end if;
                        end if;
                    elsif PAGE_DOWN_BUTTON = '1' then
                        if BUTTON_DELAY_COUNTER = BUTTON_DELAY_COUNTER_MAX / 2 then
                            DIGIT_INDEX <= 0;
                            if SUBPAGE_ENABLE = '1' then
                                if SUBPAGE_NUMBER /= "0000000000000" then
                                    SUBPAGE_NUMBER <= std_logic_vector(unsigned(SUBPAGE_NUMBER) - 1);
                                else
                                    SUBPAGE_NUMBER <= "1111111111111";
                                end if;
                            else
                                if PAGE_NUMBER /= "00000000000" then
                                    PAGE_NUMBER <= std_logic_vector(unsigned(PAGE_NUMBER) - 1);
                                else
                                    PAGE_NUMBER <= "11111111111";
                                end if;
                            end if;
                        end if;
                        if BUTTON_DELAY_COUNTER < BUTTON_DELAY_COUNTER_MAX then
                            BUTTON_DELAY_COUNTER <= BUTTON_DELAY_COUNTER + 1;
                        else
                            BUTTON_DELAY_COUNTER <= 0;
                        end if;
                    elsif PAGE_UP_BUTTON = '1' then
                        if BUTTON_DELAY_COUNTER = BUTTON_DELAY_COUNTER_MAX / 2 then
                            DIGIT_INDEX <= 0;
                            if SUBPAGE_ENABLE = '1' then
                                if SUBPAGE_NUMBER /= "1111111111111" then
                                    SUBPAGE_NUMBER <= std_logic_vector(unsigned(SUBPAGE_NUMBER) + 1);
                                else
                                    SUBPAGE_NUMBER <= "0000000000000";
                                end if;
                            else
                                if PAGE_NUMBER /= "11111111111" then
                                    PAGE_NUMBER <= std_logic_vector(unsigned(PAGE_NUMBER) + 1);
                                else
                                    PAGE_NUMBER <= "00000000000";
                                end if;
                            end if;
                        end if;
                        if BUTTON_DELAY_COUNTER < BUTTON_DELAY_COUNTER_MAX then
                            BUTTON_DELAY_COUNTER <= BUTTON_DELAY_COUNTER + 1;
                        else
                            BUTTON_DELAY_COUNTER <= 0;
                        end if;
                    else
                        BUTTON_DELAY_COUNTER <= 0;
                    end if;
                end if;
                
                if MIX_BUTTON = '1' then
                    if MIX_LAST = '0' then
                        MIX_ENABLE <= not MIX_ENABLE;
                        MIX_LAST <= '1';
                    end if;
                else
                    MIX_LAST <= '0';
                end if;
                
                if SUBPAGE_BUTTON = '1' then
                    if SUBPAGE_LAST = '0' then
                        SUBPAGE_ENABLE <= not SUBPAGE_ENABLE;
                        DIGIT_INDEX <= 0;
                        SUBPAGE_LAST <= '1';
                        SUBPAGE_NUMBER <= LAST_SUBCODE;
                    end if;
                else
                    SUBPAGE_LAST <= '0';
                end if;
                
                if REVEAL_BUTTON = '1' then
                    if REVEAL_LAST = '0' then
                        REVEAL_ENABLE <= not REVEAL_ENABLE;
                        REVEAL_LAST <= '1';
                    end if;
                else
                    REVEAL_LAST <= '0';
                end if;
                
                if RED_BUTTON = '1' and RED_PAGE(7 downto 0) /= "11111111" then
                    DIGIT_INDEX <= 0;
                    PAGE_NUMBER <= RED_PAGE;
                    SUBPAGE_ENABLE <= '0';
                end if;
                
                if GRN_BUTTON = '1' and GRN_PAGE(7 downto 0) /= "11111111" then
                    DIGIT_INDEX <= 0;
                    PAGE_NUMBER <= GRN_PAGE;
                    SUBPAGE_ENABLE <= '0';
                end if;
                
                if YEL_BUTTON = '1' and YEL_PAGE(7 downto 0) /= "11111111" then
                    DIGIT_INDEX <= 0;
                    PAGE_NUMBER <= YEL_PAGE;
                    SUBPAGE_ENABLE <= '0';
                end if;
                
                if BLU_BUTTON = '1' and BLU_PAGE(7 downto 0) /= "11111111" then
                    DIGIT_INDEX <= 0;
                    PAGE_NUMBER <= BLU_PAGE;
                    SUBPAGE_ENABLE <= '0';
                end if;
                
                if IDX_BUTTON = '1' and IDX_PAGE(7 downto 0) /= "11111111" then
                    DIGIT_INDEX <= 0;
                    PAGE_NUMBER <= IDX_PAGE;
                    SUBPAGE_ENABLE <= '0';
                end if;
                
                KEY_ACTIVE_LAST <= KEY_ACTIVE;
            end if;
        end if;
    end process;
    
-- Status display assignments (for the characters in the top left corner of the display)
    STATUS_1 <= "01100" & TEMP_DIG_1                        when SUBPAGE_ENABLE = '1' and DIGIT_INDEX > 0 else
                "01100" & SUBPAGE_NUMBER(12 downto 11)      when SUBPAGE_ENABLE = '1' else
                "1010000";
    
    STATUS_2 <= HEX_TO_ASCII(TEMP_DIG_2)                    when DIGIT_INDEX > 1 and SUBPAGE_ENABLE = '1' else
                HEX_TO_ASCII(NOT (TEMP_DIG_2(2) OR TEMP_DIG_2(1) OR TEMP_DIG_2(0)) & TEMP_DIG_2(2 downto 0)) when DIGIT_INDEX > 1 and SUBPAGE_ENABLE = '0' else
                "0101101"                                   when DIGIT_INDEX = 1 else
                HEX_TO_ASCII(SUBPAGE_NUMBER(10 downto 7))   when SUBPAGE_ENABLE = '1' else
                HEX_TO_ASCII(NOT (PAGE_NUMBER(10) OR PAGE_NUMBER(9) OR PAGE_NUMBER(8)) & PAGE_NUMBER(10 downto 8));
    
    STATUS_3 <= HEX_TO_ASCII(TEMP_DIG_3)                    when DIGIT_INDEX > 2 else
                "0101101"                                   when DIGIT_INDEX <= 2 and DIGIT_INDEX > 0 else
                "0110" & SUBPAGE_NUMBER(6 downto 4)         when SUBPAGE_ENABLE = '1' else
                HEX_TO_ASCII(PAGE_NUMBER(7 downto 4));
    
    STATUS_4 <= "0101101"                                   when DIGIT_INDEX > 0 else
                HEX_TO_ASCII(SUBPAGE_NUMBER(3 downto 0))    when SUBPAGE_ENABLE = '1' else
                HEX_TO_ASCII(PAGE_NUMBER(3 downto 0));

DATA_RECOVERY: entity work.TXT_DATA_RECOVERY
    port map(
    RESET => RESET,
    CLK_27_750 => CLK_27_750,
    RX_IN => RX_IN,
    SERIAL_DATA_OUT => SERIAL_DATA,
    SERIAL_CLOCK_OUT => SERIAL_CLOCK,
    FRAME_VALID_OUT => SERIAL_FRAME_VALID);
    
DESERIALISER: entity work.TXT_DESERIALISER
    port map(
    CLK_27_750 => CLK_27_750,
    RESET => RESET,
    
    SERIAL_DATA_IN => SERIAL_DATA,
    SERIAL_CLOCK_IN => SERIAL_CLOCK,
    FRAME_VALID_IN => SERIAL_FRAME_VALID,
    
    BYTE_OUT => BYTE_DATA,
    BYTE_CLOCK_OUT => BYTE_CLOCK,
    FRAME_VALID_OUT => BYTE_FRAME_VALID);
    
DATA_PROCESSOR: entity work.TXT_DATA_PROCESSOR
    port map(
    CLK_27_750 => CLK_27_750,
    RESET => RESET,
    
    BYTE_IN => BYTE_DATA,
    BYTE_CLOCK_IN => BYTE_CLOCK,
    FRAME_VALID_IN => BYTE_FRAME_VALID,
    
    WORD_OUT        => WORD_DATA,
    WORD_CLOCK_OUT  => WORD_CLOCK,
    FRAME_VALID_OUT => WORD_FRAME_VALID,
    MAGAZINE_OUT    => MAGAZINE,
    ROW_OUT         => ROW,
    PAGE_OUT        => PAGE,
    SUBCODE_OUT     => SUBCODE,
    CONTROL_BITS_OUT => CONTROL_BITS);
    
KEYPAD_CONTROLLER: entity work.KEYPAD
    generic map(
    COLS => KEYPAD_COLS'length,
    ROWS => KEYPAD_ROWS'length,
    DELAY => 277500,    -- 10ms per row
    MOMENTARY_MASK => MOMENTARY_MASK
    )
    port map(
    RESET => RESET,
    CLK => CLK_27_750,
    COLS_IN => KEYPAD_COLS,
    ROWS_OUT => KEYPAD_ROWS_INT,
    BUTTONS_OUT => KEYPAD_BUTTONS,
    FIRST_PASS_OUT => KEYPAD_FIRST_PASS);
    
    KEYPAD_ROWS <= KEYPAD_ROWS_INT;
    
    PAGE_NUMBER_DIPSW <= KEYPAD_BUTTONS(9) & KEYPAD_BUTTONS(10) & KEYPAD_BUTTONS(11) &
    KEYPAD_BUTTONS(4) & KEYPAD_BUTTONS(5) & KEYPAD_BUTTONS(6) &
    KEYPAD_BUTTONS(7) & KEYPAD_BUTTONS(0) & KEYPAD_BUTTONS(1) &
    KEYPAD_BUTTONS(2) & KEYPAD_BUTTONS(3);
    PAGE_DOWN_BUTTON <= KEYPAD_BUTTONS(20);
    PAGE_UP_BUTTON <= KEYPAD_BUTTONS(22);
    KEY_0 <= KEYPAD_BUTTONS(21);
    KEY_1 <= KEYPAD_BUTTONS(32);
    KEY_2 <= KEYPAD_BUTTONS(33);
    KEY_3 <= KEYPAD_BUTTONS(34);
    KEY_4 <= KEYPAD_BUTTONS(28);
    KEY_5 <= KEYPAD_BUTTONS(29);
    KEY_6 <= KEYPAD_BUTTONS(30);
    KEY_7 <= KEYPAD_BUTTONS(24);
    KEY_8 <= KEYPAD_BUTTONS(25);
    KEY_9 <= KEYPAD_BUTTONS(26);
    KEY_ACTIVE <= KEY_0 or KEY_1 or KEY_2 or KEY_3 or KEY_4 or KEY_5 or KEY_6 or KEY_7 or KEY_8 or KEY_9;
    KEY_VALUE <= "0000" when KEY_0 = '1' else
                 "0001" when KEY_1 = '1' else
                 "0010" when KEY_2 = '1' else
                 "0011" when KEY_3 = '1' else
                 "0100" when KEY_4 = '1' else
                 "0101" when KEY_5 = '1' else
                 "0110" when KEY_6 = '1' else
                 "0111" when KEY_7 = '1' else
                 "1000" when KEY_8 = '1' else
                 "1001" when KEY_9 = '1' else "0000";
    RED_BUTTON <= KEYPAD_BUTTONS(35);
    GRN_BUTTON <= KEYPAD_BUTTONS(31);
    YEL_BUTTON <= KEYPAD_BUTTONS(27);
    BLU_BUTTON <= KEYPAD_BUTTONS(23);
    IDX_BUTTON <= KEYPAD_BUTTONS(19);
    MIX_BUTTON <= KEYPAD_BUTTONS(16);
    SUBPAGE_BUTTON <= KEYPAD_BUTTONS(17);
    REVEAL_BUTTON <= KEYPAD_BUTTONS(18);
    AB_ENABLE <= KEYPAD_BUTTONS(8);
    RESOLUTION_SELECT <= KEYPAD_BUTTONS(13);
    REFRESH_RATE_SELECT <= KEYPAD_BUTTONS(14);

MEMORY_CONTROLLER: entity work.TXT_MEMORY_CONTROLLER
    port map(
    CLK_27_750 => CLK_27_750,
    RESET => RESET,
    
    WORD_IN => WORD_DATA,
    WORD_CLOCK_IN => WORD_CLOCK,
    FRAME_VALID_IN => WORD_FRAME_VALID,
    UPCOMING_FRAME_IN => BYTE_FRAME_VALID,
    
    MAGAZINE_IN => MAGAZINE,
    ROW_IN => ROW,
    PAGE_IN => PAGE,
    SUBCODE_IN => SUBCODE,
    CONTROL_BITS_IN => CONTROL_BITS,
    
    MEM_DATA_OUT => DPR_WRITE_DATA,
    MEM_ADDRESS_OUT => DPR_WRITE_ADDRESS,
    MEM_WREN_OUT => DPR_WRITE_EN,
    
    REQ_MAGAZINE_IN => PAGE_NUMBER(10 downto 8),
    REQ_PAGE_IN => PAGE_NUMBER(7 downto 0),
    REQ_SUBCODE_IN => SUBPAGE_NUMBER,
    REQ_SUBCODE_SPEC_IN => SUBPAGE_ENABLE,
    
    LAST_SUBCODE_OUT => LAST_SUBCODE,
    RED_PAGE_OUT => RED_PAGE,
    GRN_PAGE_OUT => GRN_PAGE,
    YEL_PAGE_OUT => YEL_PAGE,
    BLU_PAGE_OUT => BLU_PAGE,
    IDX_PAGE_OUT => IDX_PAGE,
    
    STATUS_IN_1 => STATUS_1,
    STATUS_IN_2 => STATUS_2,
    STATUS_IN_3 => STATUS_3,
    STATUS_IN_4 => STATUS_4
    );

DUAL_PORT_RAM: entity work.DPR_IP_VARIATION
    port map(
    data => DPR_WRITE_DATA,
    rdaddress => DPR_READ_ADDRESS,
    rdclock => CLK_VIDEO,
    wraddress => DPR_WRITE_ADDRESS,
    wrclock => CLK_27_750,
    wren => DPR_WRITE_EN,
    q => DPR_READ_DATA);

DISPLAY_GENERATOR: entity work.DISPLAY_GENERATOR
    generic map(
    H_SIZE_1 => H_SIZE_1,
    V_SIZE_1 => V_SIZE_1,
    H_SIZE_2 => H_SIZE_2,
    V_SIZE_2 => V_SIZE_2)
    port map(
    RESET => RESET,
    CLK => CLK_VIDEO,
    
    MEMORY_DATA_IN => DPR_READ_DATA,
    MEMORY_ADDRESS_OUT => DPR_READ_ADDRESS,
    
    MIX_IN => MIX_ENABLE,
    REVEAL_IN => REVEAL_ENABLE,
    AB_EN_IN => AB_ENABLE,
    SIZE_SELECT_IN => RESOLUTION_SELECT,
    
    NEW_ROW_IN => NEW_ROW,
    NEW_SCREEN_IN => NEW_SCREEN,
    
    R_OUT => R,
    G_OUT => G,
    B_OUT => B);

PLL_HDMI: pll
    port map(
    inclk0 => CLK_VIDEO,
    c0 => CLK_VIDEO_PIXEL,
    c1 => CLK_VIDEO_BIT);

HDMI: entity work.HDMI
    generic map(
    H_SIZE_1 => H_SIZE_1,
    H_FRONT_PORCH_1 => H_FRONT_PORCH_1,
    H_SYNC_PULSE_1 => H_SYNC_PULSE_1,
    H_BACK_PORCH_1 => H_BACK_PORCH_1,
    V_SIZE_1 => V_SIZE_1,
    V_FRONT_PORCH_1 => V_FRONT_PORCH_1,
    V_SYNC_PULSE_1 => V_SYNC_PULSE_1,
    V_BACK_PORCH_1 => V_BACK_PORCH_1,
    H_SIZE_2 => H_SIZE_2,
    H_FRONT_PORCH_2 => H_FRONT_PORCH_2,
    H_SYNC_PULSE_2 => H_SYNC_PULSE_2,
    H_BACK_PORCH_2 => H_BACK_PORCH_2,
    V_SIZE_2 => V_SIZE_2,
    V_FRONT_PORCH_2 => V_FRONT_PORCH_2,
    V_SYNC_PULSE_2 => V_SYNC_PULSE_2,
    V_BACK_PORCH_2 => V_BACK_PORCH_2)
    port map(
    RESET => RESET,
    CLK_PIXEL => CLK_VIDEO_PIXEL,
    CLK_BIT => CLK_VIDEO_BIT,
    RESOLUTION_SELECT_IN => RESOLUTION_SELECT,
    R_IN => R & R & R & R & R & R & R & R,
    G_IN => G & G & G & G & G & G & G & G,
    B_IN => B & B & B & B & B & B & B & B,
    NEW_ROW_OUT => NEW_ROW,
    NEW_SCREEN_OUT => NEW_SCREEN,
    R_OUT => TMDS_D2_UNBUF,
    G_OUT => TMDS_D1_UNBUF,
    B_OUT => TMDS_D0_UNBUF,
    CLK_OUT => TMDS_CLK_UNBUF);
    
BUF_D0: obuf_iobuf_out_tvs
    port map(
    datain => TMDS_D0_UNBUF,
    dataout => TMDS_D0);
    
BUF_D1: obuf_iobuf_out_tvs
    port map(
    datain => TMDS_D1_UNBUF,
    dataout => TMDS_D1);
    
BUF_D2: obuf_iobuf_out_tvs
    port map(
    datain => TMDS_D2_UNBUF,
    dataout => TMDS_D2);
    
BUF_CLK: obuf_iobuf_out_tvs
    port map(
    datain => TMDS_CLK_UNBUF,
    dataout => TMDS_CLK);
    
INTERNAL_OSCILLATOR: entity work.intosc
    port map(
    oscena => '1',
    clkout => CLK_INTERNAL);
    
CLOCK_CONTROLLER: entity work.SI5351
    port map(
    RESET => RESET,
    CLOCK => CLK_INTERNAL,
    SDA_OUT => PRCLK_SDA_INT,
    SCL_OUT => PRCLK_SCL_INT,
    SDA_IN => PRCLK_SDA,
    SCL_IN => PRCLK_SCL,
    REFRESH_RATE_SELECT_IN => REFRESH_RATE_SELECT,
    RESOLUTION_SELECT_IN => RESOLUTION_SELECT,
    COMPLETE_OUT => LED_OUT);
    
    PRCLK_SDA <= '0' when PRCLK_SDA_INT = '0' else 'Z';
    PRCLK_SCL <= '0' when PRCLK_SCL_INT = '0' else 'Z';

end architecture;
    