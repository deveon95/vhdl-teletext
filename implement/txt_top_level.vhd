-- ********** Use Clock Controller to set CLK1 to 27750 and CLK2 to 31000 for 60Hz on C10 Dev Board **
-- ********** Use Clock Controller to set CLK2 to 27750 and CLK2 to 26500 for 50Hz

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
    KEYPAD_ROWS : inout std_logic_vector(5 downto 0);
    KEYPAD_COLS : in  std_logic_vector(5 downto 0);
    -- LED
    LED_OUT : out std_logic;
    -- HDMI interface
    HDMI_SDA : inout std_logic;
    HDMI_SCL : inout std_logic;
    TMDS_CLK : out std_logic;
    --TMDS_CLK_N : out std_logic;
    TMDS_D0 : out std_logic;
    --TMDS_D0_N : out std_logic;
    TMDS_D1 : out std_logic;
    --TMDS_D1_N : out std_logic;
    TMDS_D2 : out std_logic;
    --TMDS_D2_N : out std_logic;
    HDMI_HPD : in std_logic;
    -- SRAM for future use (optional)
    SRAM_ADDR : out std_logic_vector(18 downto 0);
    SRAM_DATA : inout std_logic_vector(7 downto 0);
    SRAM_OE_N : out std_logic;
    SRAM_WE_N : out std_logic;
    SRAM_CE_N : out std_logic;
    -- SAA7113 Video Processor (optional) - use same pins as oscillator for I2C
    VP_DATA_IN : in std_logic_vector(7 downto 0);
    VP_RTCO_IN : in std_logic;
    VP_RTS0_IN : in std_logic;
    VP_RTS1_IN : in std_logic;
    VP_LLC_IN : in std_logic;
    -- VGA interface (PMOD connector)
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
-- to be reassigned to keypad controller - moved here to enable compilation for pin planner
signal MIX_IN     : std_logic := '1';
signal REVEAL_IN  : std_logic := '1';
signal PAGE_UP    : std_logic := '1';
signal PAGE_DOWN  : std_logic := '1';
signal KEYPAD_ROWS_INT : std_logic_vector(5 downto 0);
-- end of temporary signals

-- Parameters for 720x576 resolution
constant H_SIZE : integer := 720;
constant H_FRONT_PORCH : integer := 16;
constant H_SYNC_PULSE : integer := 96;
constant H_BACK_PORCH : integer := 32;
constant V_SIZE : integer := 576;
constant V_FRONT_PORCH : integer := 23;
constant V_SYNC_PULSE : integer := 3;
constant V_BACK_PORCH : integer := 23;
-- Parameters for 640x480 resolution
--constant H_SIZE : integer := 640;
--constant H_FRONT_PORCH : integer := 16;
--constant H_SYNC_PULSE : integer := 96;
--constant H_BACK_PORCH : integer := 48;
--constant V_SIZE : integer := 480;
--constant V_FRONT_PORCH : integer := 11;
--constant V_SYNC_PULSE : integer := 2;
--constant V_BACK_PORCH : integer := 31;
    
constant BUTTON_DELAY_COUNTER_MAX : integer := 2775000;

constant MOMENTARY_MASK : std_logic_vector(35 downto 0) := "001111001111001111001111001111000000";
-- END OF CONSTANTS
    
signal PAGE_NUMBER : integer range 0 to 2047;
signal PAGE_NUMBER_SLV : std_logic_vector(10 downto 0);
signal BUTTON_DELAY_COUNTER : integer range 0 to BUTTON_DELAY_COUNTER_MAX;   --10 increments per second
signal PAGE_UP_SYNC, PAGE_UP_SYNC_2, PAGE_DOWN_SYNC, PAGE_DOWN_SYNC_2 : std_logic;

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
signal KEYPAD_BUTTONS : std_logic_vector(35 downto 0);
signal KEYPAD_FIRST_PASS : std_logic;
    
signal DPR_READ_DATA : std_logic_vector(6 downto 0);
signal DPR_READ_ADDRESS : std_logic_vector(9 downto 0);
signal DPR_WRITE_ADDRESS : std_logic_vector(9 downto 0);
signal DPR_WRITE_EN : std_logic;
signal DPR_WRITE_DATA : std_logic_vector(6 downto 0);
signal NEW_ROW : std_logic;
signal NEW_SCREEN : std_logic;
signal R : std_logic;
signal G : std_logic;
signal B : std_logic;

-- Full component instantiation of Verilog module required due to Quartus bug
component HDMI
port (inclk, R_IN, G_IN, B_IN : in std_logic;
      NEW_ROW_OUT, NEW_SCREEN_OUT, TMDS2, TMDS1, TMDS0, TMDS_clock : out std_logic);
end component;

begin

    RESET <= not RESETn;
    
-- A very simple page number entry system for testing
-- PAGE_NUMBER_CONTROLLER: process(CLK_27_750, RESET)
    -- begin
        -- if RESET = '1' then
            -- PAGE_NUMBER <= 1939;
            -- PAGE_UP_SYNC <= '0';
            -- PAGE_UP_SYNC_2 <= '0';
            -- PAGE_DOWN_SYNC <= '0';
            -- PAGE_DOWN_SYNC_2 <= '0';
        -- elsif rising_edge(CLK_27_750) then
            -- PAGE_UP_SYNC <= not PAGE_UP;
            -- PAGE_UP_SYNC_2 <= PAGE_UP_SYNC;
            -- PAGE_DOWN_SYNC <= not PAGE_DOWN;
            -- PAGE_DOWN_SYNC_2 <= PAGE_DOWN_SYNC;
            -- if PAGE_UP_SYNC_2 = '1' then
                -- if BUTTON_DELAY_COUNTER = BUTTON_DELAY_COUNTER_MAX / 2 then
                    -- if PAGE_NUMBER > 0 then
                        -- PAGE_NUMBER <= PAGE_NUMBER - 1;
                    -- else
                        -- PAGE_NUMBER <= 2047;
                    -- end if;
                -- end if;
                -- if BUTTON_DELAY_COUNTER < BUTTON_DELAY_COUNTER_MAX then
                    -- BUTTON_DELAY_COUNTER <= BUTTON_DELAY_COUNTER + 1;
                -- else
                    -- BUTTON_DELAY_COUNTER <= 0;
                -- end if;
            -- elsif PAGE_DOWN_SYNC_2 = '1' then
                -- if BUTTON_DELAY_COUNTER = BUTTON_DELAY_COUNTER_MAX / 2 then
                    -- if PAGE_NUMBER < 2047 then
                        -- PAGE_NUMBER <= PAGE_NUMBER + 1;
                    -- else
                        -- PAGE_NUMBER <= 0;
                    -- end if;
                -- end if;
                -- if BUTTON_DELAY_COUNTER < BUTTON_DELAY_COUNTER_MAX then
                    -- BUTTON_DELAY_COUNTER <= BUTTON_DELAY_COUNTER + 1;
                -- else
                    -- BUTTON_DELAY_COUNTER <= 0;
                -- end if;
            -- else
                -- BUTTON_DELAY_COUNTER <= 0;
            -- end if;
        -- end if;
    -- end process;

DATA_RECOVERY: entity work.TXT_DATA_RECOVERY
    port map(
    RESET => RESET,
    CLK_27_750 => CLK_27_750,
    RX_IN => not RX_IN,
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
    COLS => 6,
    ROWS => 6,
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
    PAGE_NUMBER <= to_integer(unsigned(PAGE_NUMBER_SLV));
    PAGE_NUMBER_SLV <= KEYPAD_BUTTONS(28) & KEYPAD_BUTTONS(22) & KEYPAD_BUTTONS(16) &
    KEYPAD_BUTTONS(10) & KEYPAD_BUTTONS(4) & KEYPAD_BUTTONS(35) &
    KEYPAD_BUTTONS(29) & KEYPAD_BUTTONS(23) & KEYPAD_BUTTONS(17) &
    KEYPAD_BUTTONS(11) & KEYPAD_BUTTONS(5);

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
    
    REQ_MAGAZINE_IN => std_logic_vector(to_unsigned(PAGE_NUMBER, 11))(10 downto 8),
    REQ_PAGE_IN => std_logic_vector(to_unsigned(PAGE_NUMBER, 11))(7 downto 0),
    REQ_SUBCODE_IN => "0000000000000",
    REQ_SUBCODE_SPEC_IN => '0'
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
    port map(
    RESET => RESET,
    CLK => CLK_VIDEO,
    
    MEMORY_DATA_IN => DPR_READ_DATA,
    MEMORY_ADDRESS_OUT => DPR_READ_ADDRESS,
    
    MIX_IN => not MIX_IN,
    REVEAL_IN => not REVEAL_IN,
    
    NEW_ROW_IN => NEW_ROW,
    NEW_SCREEN_IN => NEW_SCREEN,
    
    R_OUT => R,
    G_OUT => G,
    B_OUT => B);

VGA: entity work.VGA
    generic map(
    H_SIZE => H_SIZE,
    H_FRONT_PORCH => H_FRONT_PORCH,
    H_SYNC_PULSE => H_SYNC_PULSE,
    H_BACK_PORCH => H_BACK_PORCH,
    V_SIZE => V_SIZE,
    V_FRONT_PORCH => V_FRONT_PORCH,
    V_SYNC_PULSE => V_SYNC_PULSE,
    V_BACK_PORCH => V_BACK_PORCH)
    port map(
    RESET => RESET,
    CLK => CLK_VIDEO,
    R_IN => R,
    G_IN => G,
    B_IN => B,
    NEW_ROW_OUT => open,
    NEW_SCREEN_OUT => open,
    R_OUT => R_OUT,
    G_OUT => G_OUT,
    B_OUT => B_OUT,
    HSYNC_OUT => HSYNC_OUT,
    VSYNC_OUT => VSYNC_OUT);
    
HDMI_FPGA4FUN: HDMI
    port map(
    inclk => CLK_VIDEO,
    R_IN => R,
    G_IN => G,
    B_IN => B,
    NEW_ROW_OUT => NEW_ROW,
    NEW_SCREEN_OUT => NEW_SCREEN,
    TMDS2 => TMDS_D2,
    TMDS1 => TMDS_D1,
    TMDS0 => TMDS_D0,
    TMDS_clock => TMDS_CLK
    );
    
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
    COMPLETE_OUT => open);--LED_OUT);
    
    PRCLK_SDA <= '0' when PRCLK_SDA_INT = '0' else 'Z';
    PRCLK_SCL <= '0' when PRCLK_SCL_INT = '0' else 'Z';
    --PRCLK_SDA <= 'Z';
    --PRCLK_SCL <= 'Z';

end architecture;
    