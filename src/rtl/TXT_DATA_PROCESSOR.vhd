library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_DATA_PROCESSOR is
    port (
    CLK_27_750      : in  std_logic;
    RESET           : in  std_logic;
    
    SERIAL_DATA_IN  : in  std_logic;
    SERIAL_CLOCK_IN : in  std_logic;
    FRAME_VALID_IN  : in  std_logic;
    
    WORD_OUT        : out std_logic_vector(6 downto 0);
    WORD_CLOCK_OUT  : out std_logic;
    WORD_VALID_OUT  : out std_logic;
    MAGAZINE_OUT    : out std_logic_vector(2 downto 0);
    ROW_OUT         : out std_logic_vector(4 downto 0);
    PAGE_OUT        : out std_logic_vector(7 downto 0);
    SUBCODE_OUT     : out std_logic_vector(12 downto 0)
    );
    
end entity TXT_DATA_PROCESSOR;

architecture RTL of TXT_DATA_PROCESSOR is
type T_PAGE_AND_SUBPAGE_CACHE is array (integer range <>) of std_logic_vector(20 downto 0);
signal PAGE_AND_SUBPAGE_CACHE : T_PAGE_AND_SUBPAGE_CACHE(7 downto 0);
begin

end architecture;
