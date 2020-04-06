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
signal PIXEL_COUNTER : integer range 0 to 767;
signal ROW_COUNTER : integer range 0 to 575;
signal H_DOUBLER : std_logic;
signal V_DOUBLER : std_logic;
signal CHAR_COUNTER : integer range 0 to 127;
signal CHAR_COL_COUNTER : integer range 0 to 5;
signal CHAR_ROW_COUNTER : integer range 0 to 10;
signal CGROM_LINE : std_logic_vector(4 downto 0);
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

CGROM: entity work.CGROM
    port map(
    ADDRESS_IN => std_logic_vector(to_unsigned(CHAR_COUNTER,7)),
    ROW_SELECT_IN => std_logic_vector(to_unsigned(CHAR_ROW_COUNTER,4)),
    DATA_OUT => CGROM_LINE);

PATTERN_GEN: process(CLK_25, RESET)
    begin
        if RESET = '1' then
            R <= '0';
            G <= '0';
            B <= '0';
            PIXEL_COUNTER <= 0;
            ROW_COUNTER <= 0;
            H_DOUBLER <= '0';
            V_DOUBLER <= '0';
            CHAR_COUNTER <= 0;
            CHAR_COL_COUNTER <= 0;
            CHAR_ROW_COUNTER <= 0;
        elsif rising_edge(CLK_25) then
            if NEW_SCREEN = '1' then
                ROW_COUNTER <= 0;
                CHAR_COUNTER <= 0;
                CHAR_ROW_COUNTER <= 0;
                CHAR_COL_COUNTER <= 0;
                H_DOUBLER <= '0';
                V_DOUBLER <= '0';
            else
                if NEW_ROW = '1' then
                    PIXEL_COUNTER <= 0;
                    if ROW_COUNTER < 575 then
                        ROW_COUNTER <= ROW_COUNTER + 1;
                        if ROW_COUNTER >= 144 or ROW_COUNTER < 432 then
                            V_DOUBLER <= NOT V_DOUBLER;
                            if V_DOUBLER = '1' then
                                if CHAR_ROW_COUNTER < 10 then
                                    CHAR_ROW_COUNTER <= CHAR_ROW_COUNTER + 1;
                                else
                                    -- proceed to next part of character set
                                    CHAR_COUNTER <= CHAR_COUNTER + 40;
                                    CHAR_ROW_COUNTER <= 0;
                                    R <= '0';
                                    G <= '0';
                                    B <= '0';
                                end if;
                            end if;
                        end if;
                    end if;
                else
                    if PIXEL_COUNTER < 767 then
                        PIXEL_COUNTER <= PIXEL_COUNTER + 1;
                    end if;
                    if ROW_COUNTER < 144 or ROW_COUNTER >= 432 then
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
                    else
                        H_DOUBLER <= not H_DOUBLER;
                        if H_DOUBLER = '1' and PIXEL_COUNTER >= 144 and PIXEL_COUNTER < 624 then
                            if CHAR_COL_COUNTER < 5 then
                                CHAR_COL_COUNTER <= CHAR_COL_COUNTER + 1;
                                R <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                                G <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                                B <= CGROM_LINE(4 - CHAR_COL_COUNTER);
                            else
                                CHAR_COL_COUNTER <= 0;
                                R <= '0';
                                G <= '0';
                                B <= '0';
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
    