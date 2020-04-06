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
    SERIAL_DATA_OUT : out std_logic;
    SERIAL_CLOCK_OUT : out std_logic;
    FRAME_VALID_OUT : out std_logic;
    
    R_OUT : out std_logic;
    G_OUT : out std_logic;
    B_OUT : out std_logic;
    HSYNC_OUT : out std_logic;
    VSYNC_OUT : out std_logic
    );
end entity TXT_TOP_LEVEL;

architecture rtl of TXT_TOP_LEVEL is
signal RESET : std_logic;
signal R : std_logic;
signal G : std_logic;
signal B : std_logic;
signal NEW_ROW : std_logic;
signal NEW_SCREEN : std_logic;
signal DPR_READ_DATA : std_logic_vector(6 downto 0);
signal DPR_READ_ADDRESS : std_logic_vector(9 downto 0);
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
    SERIAL_DATA_OUT => SERIAL_DATA_OUT,
    SERIAL_CLOCK_OUT => SERIAL_CLOCK_OUT,
    FRAME_VALID_OUT => FRAME_VALID_OUT);

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

DUAL_PORT_RAM: entity work.DPR_IP_VARIATION
    port map(
    data => "0000000",
    rdaddress => DPR_READ_ADDRESS,
    rdclock => CLK_25,
    wraddress => "0000000000",
    wrclock => CLK_27_750,
    wren => '0',
    q => DPR_READ_DATA);

end architecture;
    