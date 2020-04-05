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
signal PIXEL_COUNTER : integer range 0 to 767;
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
    NEW_SCREEN_OUT => open,
    R_OUT => R_OUT,
    G_OUT => G_OUT,
    B_OUT => B_OUT,
    HSYNC_OUT => HSYNC_OUT,
    VSYNC_OUT => VSYNC_OUT);

PATTERN_GEN: process(CLK_25, RESET)
    begin
        if RESET = '1' then
            R <= '0';
            G <= '0';
            B <= '0';
            PIXEL_COUNTER <= 0;
        elsif rising_edge(CLK_25) then
            if NEW_ROW = '1' then
                PIXEL_COUNTER <= 0;
            else
                PIXEL_COUNTER <= PIXEL_COUNTER + 1;
                if PIXEL_COUNTER < 96 then
                    R <= '1';
                    G <= '0';
                    B <= '0';
                elsif PIXEL_COUNTER < 192 then
                    R <= '0';
                    G <= '1';
                    B <= '0';
                elsif PIXEL_COUNTER < 288 then
                    R <= '1';
                    G <= '1';
                    B <= '0';
                elsif PIXEL_COUNTER < 384 then
                    R <= '0';
                    G <= '0';
                    B <= '1';
                elsif PIXEL_COUNTER < 480 then
                    R <= '1';
                    G <= '0';
                    B <= '1';
                elsif PIXEL_COUNTER < 576 then
                    R <= '0';
                    G <= '1';
                    B <= '1';
                elsif PIXEL_COUNTER < 672 then
                    R <= '1';
                    G <= '1';
                    B <= '1';
                elsif PIXEL_COUNTER < 767 then
                    R <= '0';
                    G <= '0';
                    B <= '0';
                else
                    -- Generate vertical white line at right edge of screen
                    R <= '1';
                    G <= '1';
                    B <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;
    