library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
    port (
    CLK             : in  std_logic;
    RESET           : in  std_logic;
    R_IN            : in std_logic;
    G_IN            : in std_logic;
    B_IN            : in std_logic;
    NEW_ROW_OUT     : out std_logic;
    NEW_SCREEN_OUT  : out std_logic;
    R_OUT           : out std_logic;
    G_OUT           : out std_logic;
    B_OUT           : out std_logic;
    HSYNC_OUT       : out std_logic;
    VSYNC_OUT       : out std_logic);
end entity VGA;

architecture RTL of VGA is
-- Parameters for 720x576 resolution
constant H_SIZE : integer := 720;
constant H_FRONT_PORCH : integer := 16;
constant H_SYNC_PULSE : integer := 96;
constant H_BACK_PORCH : integer := 16;
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

constant H_COUNT_MAX : integer := H_SIZE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH - 1;
signal H_COUNT : integer range 0 to H_COUNT_MAX;
signal H_ACTIVE : std_logic;
constant V_COUNT_MAX : integer := V_SIZE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH - 1;
signal V_COUNT : integer range 0 to V_COUNT_MAX;
signal V_ACTIVE : std_logic;
signal VIDEO_ACTIVE : std_logic;

constant TEXT_BORDER_SIZE : integer := (V_SIZE * 10) / 9;
signal VIDEO_BORDER : std_logic;

begin

-- Draw border around the area which should be adjusted to 4:3 size on the monitor for proper text aspect ratio
VIDEO_BORDER <= '1' when H_COUNT = (H_SIZE - TEXT_BORDER_SIZE) / 2 or H_COUNT = (H_SIZE + TEXT_BORDER_SIZE) / 2 or
                        ((V_COUNT = 0 or V_COUNT = V_SIZE - 1) and H_COUNT > (H_SIZE - TEXT_BORDER_SIZE) / 2 and H_COUNT < (H_SIZE + TEXT_BORDER_SIZE) / 2) else '0';

VIDEO_ACTIVE <= H_ACTIVE and V_ACTIVE;
R_OUT <= R_IN or VIDEO_BORDER when VIDEO_ACTIVE = '1' else '0';
G_OUT <= G_IN or VIDEO_BORDER when VIDEO_ACTIVE = '1' else '0';
B_OUT <= B_IN or VIDEO_BORDER when VIDEO_ACTIVE = '1' else '0';

COUNTER: process (CLK, RESET)
    begin
        if RESET = '1' then
            NEW_ROW_OUT <= '0';
            NEW_SCREEN_OUT <= '0';
            H_COUNT <= 0;
            V_COUNT <= 0;
        elsif rising_edge(CLK) then
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
    
SYNC_GENERATOR: process (CLK, RESET)
    begin
        if RESET = '1' then
            H_ACTIVE <= '0';
            HSYNC_OUT <= '1';
            V_ACTIVE <= '0';
            VSYNC_OUT <= '1';
        elsif rising_edge(CLK) then
            if H_COUNT < H_SIZE then
                H_ACTIVE <= '1';
                HSYNC_OUT <= '1';
            elsif H_COUNT < H_SIZE + H_FRONT_PORCH then
                H_ACTIVE <= '0';
                HSYNC_OUT <= '1';
            elsif H_COUNT < H_SIZE + H_FRONT_PORCH + H_SYNC_PULSE then
                H_ACTIVE <= '0';
                HSYNC_OUT <= '0';
            else
                H_ACTIVE <= '0';
                HSYNC_OUT <= '1';
            end if;
            
            if V_COUNT < V_SIZE then
                V_ACTIVE <= '1';
                VSYNC_OUT <= '1';
            elsif V_COUNT < V_SIZE + V_FRONT_PORCH then
                V_ACTIVE <= '0';
                VSYNC_OUT <= '1';
            elsif V_COUNT < V_SIZE + V_FRONT_PORCH + V_SYNC_PULSE then
                V_ACTIVE <= '0';
                VSYNC_OUT <= '0';
            else
                V_ACTIVE <= '0';
                VSYNC_OUT <= '1';
            end if;
        end if;
    end process;
    
end architecture;
