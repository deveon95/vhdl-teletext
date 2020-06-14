library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HDMI is
    generic (
    H_SIZE          : integer;
    H_FRONT_PORCH   : integer;
    H_SYNC_PULSE    : integer;
    H_BACK_PORCH    : integer;
    V_SIZE          : integer;
    V_FRONT_PORCH   : integer;
    V_SYNC_PULSE    : integer;
    V_BACK_PORCH    : integer);
    port (
    CLK_PIXEL       : in  std_logic;        -- Pixel clock
    CLK_BIT         : in  std_logic;        -- 10x pixel clock from PLL
    RESET           : in  std_logic;
    R_IN            : in std_logic_vector(7 downto 0);
    G_IN            : in std_logic_vector(7 downto 0);
    B_IN            : in std_logic_vector(7 downto 0);
    NEW_ROW_OUT     : out std_logic;
    NEW_SCREEN_OUT  : out std_logic;
    R_OUT           : out std_logic;
    G_OUT           : out std_logic;
    B_OUT           : out std_logic;
    CLK_OUT         : out std_logic);
end entity HDMI;

architecture RTL of HDMI is

constant H_COUNT_MAX : integer := H_SIZE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1;
signal H_COUNT : integer range 0 to H_COUNT_MAX;
signal H_ACTIVE : std_logic;
constant V_COUNT_MAX : integer := V_SIZE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH - 1;
signal V_COUNT : integer range 0 to V_COUNT_MAX;
signal V_ACTIVE : std_logic;
signal HSYNC : std_logic;
signal VSYNC : std_logic;
signal VIDEO_ACTIVE : std_logic;

constant TEXT_BORDER_SIZE : integer := (V_SIZE * 10) / 9;
signal VIDEO_BORDER : std_logic;

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

component TMDS_encoder
port (clk : in std_logic;
      VD : in std_logic_vector(7 downto 0);
      CD : in std_logic_vector(1 downto 0);
      VDE : in std_logic;
      TMDS : out std_logic_vector(9 downto 0));
end component;

begin

-- Draw border around the area which should be adjusted to 4:3 size on the monitor for proper text aspect ratio
VIDEO_BORDER <= '1' when H_COUNT = (H_SIZE - TEXT_BORDER_SIZE) / 2 or H_COUNT = (H_SIZE + TEXT_BORDER_SIZE) / 2 or
                        ((V_COUNT = 0 or V_COUNT = V_SIZE - 1) and H_COUNT > (H_SIZE - TEXT_BORDER_SIZE) / 2 and H_COUNT < (H_SIZE + TEXT_BORDER_SIZE) / 2) else '0';
VIDEO_ACTIVE <= H_ACTIVE and V_ACTIVE;


COUNTER: process (CLK_PIXEL, RESET)
    begin
        if RESET = '1' then
            NEW_ROW_OUT <= '0';
            NEW_SCREEN_OUT <= '0';
            H_COUNT <= 0;
            V_COUNT <= 0;
        elsif rising_edge(CLK_PIXEL) then
            if H_COUNT = H_COUNT_MAX - 1 then
                -- New Row Out goes high for one clock cycle
                NEW_ROW_OUT <= '1';
                H_COUNT <= H_COUNT + 1;
            elsif H_COUNT = H_COUNT_MAX then
                H_COUNT <= 0;
                if V_COUNT = V_COUNT_MAX - 1 then
                    -- New Screen Out goes high for one line
                    NEW_SCREEN_OUT <= '1';
                    V_COUNT <= V_COUNT + 1;
                elsif V_COUNT = V_COUNT_MAX then
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
        elsif rising_edge(CLK_PIXEL) then
            if H_COUNT < H_SIZE then
                H_ACTIVE <= '1';
                HSYNC <= '0';
            elsif H_COUNT < H_SIZE + H_FRONT_PORCH then
                H_ACTIVE <= '0';
                HSYNC <= '0';
            elsif H_COUNT < H_SIZE + H_FRONT_PORCH + H_SYNC_PULSE then
                H_ACTIVE <= '0';
                HSYNC <= '1';
            else
                H_ACTIVE <= '0';
                HSYNC <= '0';
            end if;
            
            if V_COUNT < V_SIZE then
                V_ACTIVE <= '1';
                VSYNC <= '0';
            elsif V_COUNT < V_SIZE + V_FRONT_PORCH then
                V_ACTIVE <= '0';
                VSYNC <= '0';
            elsif V_COUNT < V_SIZE + V_FRONT_PORCH + V_SYNC_PULSE then
                V_ACTIVE <= '0';
                VSYNC <= '1';
            else
                V_ACTIVE <= '0';
                VSYNC <= '0';
            end if;
        end if;
    end process;

INPUT_REG: process (CLK_PIXEL)
    begin
        if rising_edge(CLK_PIXEL) then
            R_RAW <= R_IN;-- or VIDEO_BORDER;
            G_RAW <= G_IN;-- or VIDEO_BORDER;
            B_RAW <= B_IN;-- or VIDEO_BORDER;
        end if;
    end process;
    
ENCODER_R: TMDS_encoder
    port map(
    clk => CLK_PIXEL,
    VD => R_RAW,
    CD => "00",
    VDE => VIDEO_ACTIVE,
    TMDS => ENCODED_R);
    
ENCODER_G: TMDS_encoder
    port map(
    clk => CLK_PIXEL,
    VD => G_RAW,
    CD => "00",
    VDE => VIDEO_ACTIVE,
    TMDS => ENCODED_G);
    
ENCODER_B: TMDS_encoder
    port map(
    clk => CLK_PIXEL,
    VD => B_RAW,
    CD => VSYNC & HSYNC,
    VDE => VIDEO_ACTIVE,
    TMDS => ENCODED_B);
    
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
                SHIFT_R <= '0' & SHIFT_R(9 downto 1);
                SHIFT_G <= '0' & SHIFT_G(9 downto 1);
                SHIFT_B <= '0' & SHIFT_B(9 downto 1);
            end if;
            SHIFT_CLK <= SHIFT_CLK(0) & SHIFT_CLK(9 downto 1);
        end if;
    end process;
    
    R_OUT <= SHIFT_R(0);
    G_OUT <= SHIFT_G(0);
    B_OUT <= SHIFT_B(0);
    CLK_OUT <= SHIFT_CLK(0);
    
end architecture;
