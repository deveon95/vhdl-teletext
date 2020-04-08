-- ********** Use Clock Controller to set the CLK1 (not CLK2) freq to 27750 on C10 Dev Board **
-- ********** Use Clock Controller to set CLK2 to 28800

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_TOP_LEVEL is
    port (
    CLK_27_750      : in  std_logic;
    CLK_25          : in  std_logic;
    RESETn          : in  std_logic;
    CLK_REPEATER    : out std_logic;
    CLK_REPEATER2   : out std_logic;
    RESET_REPEATER  : out std_logic;
    RX_IN           : in  std_logic;
    
    R_OUT : out std_logic;
    G_OUT : out std_logic;
    B_OUT : out std_logic;
    HSYNC_OUT : out std_logic;
    VSYNC_OUT : out std_logic
    );
end entity TXT_TOP_LEVEL;

architecture rtl of TXT_TOP_LEVEL is
signal RESET : std_logic;
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
begin

    CLK_REPEATER <= CLK_27_750;
    CLK_REPEATER2 <= CLK_27_750;
    RESET <= not RESETn;
    RESET_REPEATER <= RESETn;

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

MEMORY_CONTROLLER: entity work.TXT_MEMORY_CONTROLLER
    port map(
    CLK_27_750 => CLK_27_750,
    RESET => RESET,
    
    WORD_IN => WORD_DATA,
    WORD_CLOCK_IN => WORD_CLOCK,
    FRAME_VALID_IN => WORD_FRAME_VALID,
    
    MAGAZINE_IN => MAGAZINE,
    ROW_IN => ROW,
    PAGE_IN => PAGE,
    SUBCODE_IN => SUBCODE,
    CONTROL_BITS_IN => CONTROL_BITS,
    
    MEM_DATA_OUT => DPR_WRITE_DATA,
    MEM_ADDRESS_OUT => DPR_WRITE_ADDRESS,
    MEM_WREN_OUT => DPR_WRITE_EN,
    
    REQ_MAGAZINE_IN => "001",
    REQ_PAGE_IN => "01010010",
    REQ_SUBCODE_IN => "0000000000000",
    REQ_SUBCODE_SPEC_IN => '0'
    );

DUAL_PORT_RAM: entity work.DPR_IP_VARIATION
    port map(
    data => DPR_WRITE_DATA,
    rdaddress => DPR_READ_ADDRESS,
    rdclock => CLK_25,
    wraddress => DPR_WRITE_ADDRESS,
    wrclock => CLK_27_750,
    wren => DPR_WRITE_EN,
    q => DPR_READ_DATA);

DISPLAY_GENERATOR: entity work.DISPLAY_GENERATOR
    port map(
    RESET => RESET,
    CLK => CLK_25,
    
    MEMORY_DATA_IN => DPR_READ_DATA,
    MEMORY_ADDRESS_OUT => DPR_READ_ADDRESS,
    
    NEW_ROW_IN => NEW_ROW,
    NEW_SCREEN_IN => NEW_SCREEN,
    
    R_OUT => R,
    G_OUT => G,
    B_OUT => B);

VGA: entity work.VGA
    port map(
    RESET => RESET,
    CLK => CLK_25,
    R_IN => R,
    G_IN => G,
    B_IN => B,
    NEW_ROW_OUT => NEW_ROW,
    NEW_SCREEN_OUT => NEW_SCREEN,
    R_OUT => R_OUT,
    G_OUT => G_OUT,
    B_OUT => B_OUT,
    HSYNC_OUT => HSYNC_OUT,
    VSYNC_OUT => VSYNC_OUT);

end architecture;
    