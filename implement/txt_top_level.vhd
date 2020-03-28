-- ********** Use Clock Controller to set the CLK1 (not CLK2) freq to 27750 on C10 Dev Board **

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_TOP_LEVEL is
    port (
    CLK_27_750      : in  std_logic;
    RESETn          : in  std_logic;
    CLK_REPEATER    : out std_logic;
    CLK_REPEATER2   : out std_logic;
    RESET_REPEATER  : out std_logic;
    RX_IN           : in  std_logic;
    SERIAL_DATA_OUT : out std_logic;
    SERIAL_CLOCK_OUT : out std_logic;
    FRAME_VALID_OUT : out std_logic
    );
end entity TXT_TOP_LEVEL;

architecture rtl of TXT_TOP_LEVEL is
begin

    CLK_REPEATER <= CLK_27_750;
    CLK_REPEATER2 <= CLK_27_750;
    RESET_REPEATER <= RESETn;

DATA_RECOVERY: entity work.TXT_DATA_RECOVERY
    port map(
    RESET => not RESETn,
    CLK_27_750 => CLK_27_750,
    RX_IN => RX_IN,
    SERIAL_DATA_OUT => SERIAL_DATA_OUT,
    SERIAL_CLOCK_OUT => SERIAL_CLOCK_OUT,
    FRAME_VALID_OUT => FRAME_VALID_OUT);

end architecture;
    