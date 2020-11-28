-- HDMI.vhd
-- HDMI display controller using Double Data Rate IO
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HDMI is
    generic (
    H_SIZE_1        : integer;
    H_FRONT_PORCH_1 : integer;
    H_SYNC_PULSE_1  : integer;
    H_BACK_PORCH_1  : integer;
    V_SIZE_1        : integer;
    V_FRONT_PORCH_1 : integer;
    V_SYNC_PULSE_1  : integer;
    V_BACK_PORCH_1  : integer;
    H_SIZE_2        : integer;
    H_FRONT_PORCH_2 : integer;
    H_SYNC_PULSE_2  : integer;
    H_BACK_PORCH_2  : integer;
    V_SIZE_2        : integer;
    V_FRONT_PORCH_2 : integer;
    V_SYNC_PULSE_2  : integer;
    V_BACK_PORCH_2  : integer);
    port (
    CLK_PIXEL       : in  std_logic;        -- Pixel clock
    CLK_BIT         : in  std_logic;        -- 5x pixel clock from PLL
    RESET           : in  std_logic;
    RESOLUTION_SELECT_IN : in std_logic;
    R_IN            : in std_logic_vector(7 downto 0);
    G_IN            : in std_logic_vector(7 downto 0);
    B_IN            : in std_logic_vector(7 downto 0);
    NEW_ROW_OUT     : out std_logic;
    NEW_SCREEN_OUT  : out std_logic;
    R_OUT           : out std_logic_vector(1 downto 0);
    G_OUT           : out std_logic_vector(1 downto 0);
    B_OUT           : out std_logic_vector(1 downto 0);
    CLK_OUT         : out std_logic_vector(1 downto 0));
end entity HDMI;

architecture RTL of HDMI is

constant H_COUNT_MAX_1 : integer := H_SIZE_1 + H_FRONT_PORCH_1 + H_SYNC_PULSE_1 + H_BACK_PORCH_1 - 1;
constant H_COUNT_MAX_2 : integer := H_SIZE_2 + H_FRONT_PORCH_2 + H_SYNC_PULSE_2 + H_BACK_PORCH_2 - 1;
signal H_COUNT : integer range 0 to H_COUNT_MAX_2;
signal H_ACTIVE : std_logic;
constant V_COUNT_MAX_1 : integer := V_SIZE_1 + V_FRONT_PORCH_1 + V_SYNC_PULSE_1 + V_BACK_PORCH_1 - 1;
constant V_COUNT_MAX_2 : integer := V_SIZE_2 + V_FRONT_PORCH_2 + V_SYNC_PULSE_2 + V_BACK_PORCH_2 - 1;
signal V_COUNT : integer range 0 to V_COUNT_MAX_2;
signal V_ACTIVE : std_logic;
signal HSYNC : std_logic;
signal VSYNC : std_logic;
signal VIDEO_ACTIVE : std_logic;
signal RESOLUTION_SELECT, RES_SYNCER : std_logic;

signal R_RAW : std_logic_vector(7 downto 0);
signal G_RAW : std_logic_vector(7 downto 0);
signal B_RAW : std_logic_vector(7 downto 0);
signal SHIFT_CLK : std_logic_vector(9 downto 0);
signal SHIFT_R : std_logic_vector(9 downto 0);
signal SHIFT_G : std_logic_vector(9 downto 0);
signal SHIFT_B : std_logic_vector(9 downto 0);
signal ENCODED_R : std_logic_vector(9 downto 0);
signal ENCODED_G : std_logic_vector(9 downto 0);
signal ENCODED_B : std_logic_vector(9 downto 0);
signal LATCHED_R : std_logic_vector(9 downto 0);
signal LATCHED_G : std_logic_vector(9 downto 0);
signal LATCHED_B : std_logic_vector(9 downto 0);

begin

VIDEO_ACTIVE <= H_ACTIVE and V_ACTIVE;


COUNTER: process (CLK_PIXEL, RESET)
    begin
        if RESET = '1' then
            NEW_ROW_OUT <= '0';
            NEW_SCREEN_OUT <= '0';
            H_COUNT <= 0;
            V_COUNT <= 0;
        elsif rising_edge(CLK_PIXEL) then
            if (H_COUNT = H_COUNT_MAX_1 - 1 and RESOLUTION_SELECT = '0') or (H_COUNT = H_COUNT_MAX_2 - 1 and RESOLUTION_SELECT = '1') then
                -- New Row Out goes high for one clock cycle
                NEW_ROW_OUT <= '1';
                H_COUNT <= H_COUNT + 1;
            elsif (H_COUNT = H_COUNT_MAX_1 and RESOLUTION_SELECT = '0') or (H_COUNT = H_COUNT_MAX_2 and RESOLUTION_SELECT = '1') then
                H_COUNT <= 0;
                if (V_COUNT = V_COUNT_MAX_1 - 1 and RESOLUTION_SELECT = '0') or (V_COUNT = V_COUNT_MAX_2 - 1 and RESOLUTION_SELECT = '1') then
                    -- New Screen Out goes high for one line
                    NEW_SCREEN_OUT <= '1';
                    V_COUNT <= V_COUNT + 1;
                elsif (V_COUNT = V_COUNT_MAX_1 and RESOLUTION_SELECT = '0') or (V_COUNT = V_COUNT_MAX_2 and RESOLUTION_SELECT = '1') then
                    V_COUNT <= 0;
                    NEW_SCREEN_OUT <= '0';
                else
                    V_COUNT <= V_COUNT + 1;
                end if;
                NEW_ROW_OUT <= '0';
            else
                H_COUNT <= H_COUNT + 1;
            end if;
        end if;
    end process;
    
SYNC_GENERATOR: process (CLK_PIXEL, RESET)
    begin
        if RESET = '1' then
            H_ACTIVE <= '0';
            HSYNC <= '0';
            V_ACTIVE <= '0';
            VSYNC <= '0';
            RESOLUTION_SELECT <= '0';
            RES_SYNCER <= '0';
        elsif rising_edge(CLK_PIXEL) then
            RES_SYNCER <= RESOLUTION_SELECT_IN;
            RESOLUTION_SELECT <= RES_SYNCER;
            
            if RESOLUTION_SELECT = '0' then
                if H_COUNT < H_SIZE_1 then
                    H_ACTIVE <= '1';
                    HSYNC <= '0';
                elsif H_COUNT < H_SIZE_1 + H_FRONT_PORCH_1 then
                    H_ACTIVE <= '0';
                    HSYNC <= '0';
                elsif H_COUNT < H_SIZE_1 + H_FRONT_PORCH_1 + H_SYNC_PULSE_1 then
                    H_ACTIVE <= '0';
                    HSYNC <= '1';
                else
                    H_ACTIVE <= '0';
                    HSYNC <= '0';
                end if;
                
                if V_COUNT < V_SIZE_1 then
                    V_ACTIVE <= '1';
                    VSYNC <= '0';
                elsif V_COUNT < V_SIZE_1 + V_FRONT_PORCH_1 then
                    V_ACTIVE <= '0';
                    VSYNC <= '0';
                elsif V_COUNT < V_SIZE_1 + V_FRONT_PORCH_1 + V_SYNC_PULSE_1 then
                    V_ACTIVE <= '0';
                    VSYNC <= '1';
                else
                    V_ACTIVE <= '0';
                    VSYNC <= '0';
                end if;
            else
                if H_COUNT < H_SIZE_2 then
                    H_ACTIVE <= '1';
                    HSYNC <= '0';
                elsif H_COUNT < H_SIZE_2 + H_FRONT_PORCH_2 then
                    H_ACTIVE <= '0';
                    HSYNC <= '0';
                elsif H_COUNT < H_SIZE_2 + H_FRONT_PORCH_2 + H_SYNC_PULSE_2 then
                    H_ACTIVE <= '0';
                    HSYNC <= '1';
                else
                    H_ACTIVE <= '0';
                    HSYNC <= '0';
                end if;
                
                if V_COUNT < V_SIZE_2 then
                    V_ACTIVE <= '1';
                    VSYNC <= '0';
                elsif V_COUNT < V_SIZE_2 + V_FRONT_PORCH_2 then
                    V_ACTIVE <= '0';
                    VSYNC <= '0';
                elsif V_COUNT < V_SIZE_2 + V_FRONT_PORCH_2 + V_SYNC_PULSE_2 then
                    V_ACTIVE <= '0';
                    VSYNC <= '1';
                else
                    V_ACTIVE <= '0';
                    VSYNC <= '0';
                end if;
            end if;
        end if;
    end process;

INPUT_REG: process (CLK_PIXEL)
    begin
        if rising_edge(CLK_PIXEL) then
            R_RAW <= R_IN;
            G_RAW <= G_IN;
            B_RAW <= B_IN;
        end if;
    end process;
    
ENCODER_R: entity work.TMDS_ENCODER
    port map(
    CLK => CLK_PIXEL,
    VIDEO_IN => R_RAW,
    CONTROL_IN => "00",
    VIDEO_ACTIVE_IN => VIDEO_ACTIVE,
    TMDS_OUT => ENCODED_R);
    
ENCODER_G: entity work.TMDS_ENCODER
    port map(
    clk => CLK_PIXEL,
    VIDEO_IN => G_RAW,
    CONTROL_IN => "00",
    VIDEO_ACTIVE_IN => VIDEO_ACTIVE,
    TMDS_OUT => ENCODED_G);
    
ENCODER_B: entity work.TMDS_ENCODER
    port map(
    clk => CLK_PIXEL,
    VIDEO_IN => B_RAW,
    CONTROL_IN => VSYNC & HSYNC,
    VIDEO_ACTIVE_IN => VIDEO_ACTIVE,
    TMDS_OUT => ENCODED_B);
    
ENCODED_REG: process (CLK_PIXEL)
    begin
        if rising_edge(CLK_PIXEL) then
            LATCHED_R <= ENCODED_R;
            LATCHED_G <= ENCODED_G;
            LATCHED_B <= ENCODED_B;
        end if;
    end process;

OUTPUT_SHIFTER: process (CLK_BIT, RESET)
    begin
        if RESET = '1' then
            SHIFT_CLK <= "0000011111";
        elsif rising_edge(CLK_BIT) then
            if SHIFT_CLK = "0000011111" then
                SHIFT_R <= LATCHED_R;
                SHIFT_G <= LATCHED_G;
                SHIFT_B <= LATCHED_B;
            else
                SHIFT_R <= "00" & SHIFT_R(9 downto 2);
                SHIFT_G <= "00" & SHIFT_G(9 downto 2);
                SHIFT_B <= "00" & SHIFT_B(9 downto 2);
            end if;
            SHIFT_CLK <= SHIFT_CLK(1) & SHIFT_CLK(0) & SHIFT_CLK(9 downto 2);
        end if;
    end process;
    
    R_OUT <= SHIFT_R(1) & SHIFT_R(0);
    G_OUT <= SHIFT_G(1) & SHIFT_G(0);
    B_OUT <= SHIFT_B(1) & SHIFT_B(0);
    CLK_OUT <= SHIFT_CLK(1) & SHIFT_CLK(0);
    
end architecture;
