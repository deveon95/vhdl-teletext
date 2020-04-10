library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXT_MEMORY_CONTROLLER is
    port (
    CLK_27_750      : in  std_logic;
    RESET           : in  std_logic;
    
    WORD_IN         : in  std_logic_vector(6 downto 0);
    WORD_CLOCK_IN   : in  std_logic;
    FRAME_VALID_IN  : in  std_logic;
    UPCOMING_FRAME_IN : in std_logic;
    
    MAGAZINE_IN     : in  std_logic_vector(2 downto 0);
    ROW_IN          : in  std_logic_vector(4 downto 0);
    PAGE_IN         : in  std_logic_vector(7 downto 0);
    SUBCODE_IN      : in  std_logic_vector(12 downto 0);
    CONTROL_BITS_IN : in  std_logic_vector(10 downto 0);
    
    MEM_DATA_OUT    : out std_logic_vector(6 downto 0);
    MEM_ADDRESS_OUT : out std_logic_vector(9 downto 0);
    MEM_WREN_OUT    : out std_logic;
    
    REQ_MAGAZINE_IN : in  std_logic_vector(2 downto 0);
    REQ_PAGE_IN     : in  std_logic_vector(7 downto 0);
    REQ_SUBCODE_IN  : in  std_logic_vector(12 downto 0);
    REQ_SUBCODE_SPEC_IN : in std_logic
    );
    
end entity TXT_MEMORY_CONTROLLER;

architecture RTL of TXT_MEMORY_CONTROLLER is

signal MEMORY_ERASE_REQUIRED : std_logic;
signal VISIBLE_PACKET : std_logic;
signal PAGE_FOUND     : std_logic;          -- Updated at beginning of packet
signal PAGE_FOUND_END : std_logic;          -- Updated at end of packet
signal STATUS_NEEDS_UPDATING : std_logic;
signal STATUS_UPDATED : std_logic;
signal LAST_LOADED_MAGAZINE : std_logic_vector(2 downto 0);
signal LAST_LOADED_PAGE : std_logic_vector(7 downto 0);
signal LAST_LOADED_SUBCODE : std_logic_vector(12 downto 0);
signal LINE_START_ADDRESS : integer range 0 to 1023;
signal ADDRESS_COUNTER : integer range 0 to 1023;
signal ROW_INTEGER : integer range 0 to 31;

type STATE_TYPE is (WAIT_FOR_FRAME, RECEIVE_FRAME, NEXT_WORD, ERASE_MEMORY_START, ERASE_MEMORY, UPDATE_STATUS, UPDATE_STATUS_NEXT);
signal STATE : STATE_TYPE;
type STATUS_ARRAY_TYPE is array (0 to 7) of std_logic_vector(6 downto 0);
signal STATUS_ARRAY : STATUS_ARRAY_TYPE;
signal STATUS_ARRAY_LAST : STATUS_ARRAY_TYPE;

begin
MAIN: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            MEMORY_ERASE_REQUIRED <= '0';
            MEM_WREN_OUT <= '0';
            STATE <= WAIT_FOR_FRAME;
            MEM_DATA_OUT <= (others => '0');
            ADDRESS_COUNTER <= 0;
            STATUS_UPDATED <= '0';
            LAST_LOADED_MAGAZINE <= (others => '0');
            LAST_LOADED_PAGE <= (others => '1');
            LAST_LOADED_SUBCODE <= (others => '0');
            PAGE_FOUND_END <= '0';
        elsif rising_edge(CLK_27_750) then
            
            case STATE is
            when WAIT_FOR_FRAME =>
                MEM_WREN_OUT <= '0';
                -- Load page when correct page is broadcast
                if FRAME_VALID_IN = '1' and MAGAZINE_IN = REQ_MAGAZINE_IN 
                and (PAGE_IN = REQ_PAGE_IN and (REQ_SUBCODE_IN = SUBCODE_IN or REQ_SUBCODE_SPEC_IN = '0')) then
                    ADDRESS_COUNTER <= LINE_START_ADDRESS;
                    MEMORY_ERASE_REQUIRED <= CONTROL_BITS_IN(0);
                    LAST_LOADED_PAGE <= PAGE_IN;
                    LAST_LOADED_SUBCODE <= SUBCODE_IN;
                    LAST_LOADED_MAGAZINE <= MAGAZINE_IN;
                    STATE <= RECEIVE_FRAME;
                end if;
                -- Show rolling header when waiting for page
                if FRAME_VALID_IN = '1' and MAGAZINE_IN = REQ_MAGAZINE_IN 
                and (ROW_INTEGER = 0) then
                    ADDRESS_COUNTER <= LINE_START_ADDRESS;
                    MEMORY_ERASE_REQUIRED <= '0';
                    STATE <= RECEIVE_FRAME;
                end if;
                -- Update status when change in the eight status characters is detected
                if STATUS_NEEDS_UPDATING = '1' and UPCOMING_FRAME_IN = '0' then
                    ADDRESS_COUNTER <= 0;
                    STATE <= UPDATE_STATUS;
                    STATUS_UPDATED <= '1';
                end if;
            when RECEIVE_FRAME =>
                if FRAME_VALID_IN = '0' then
                    if MEMORY_ERASE_REQUIRED = '1' and LINE_START_ADDRESS = 0 then
                        STATE <= ERASE_MEMORY_START;
                    else
                        STATE <= WAIT_FOR_FRAME;
                    end if;
                    PAGE_FOUND_END <= PAGE_FOUND;
                elsif WORD_CLOCK_IN = '1' then
                    MEM_DATA_OUT <= WORD_IN;
                    -- IF statement suppresses write enable for header row prior to clock when page has been found
                    if ROW_INTEGER /= 0 or PAGE_FOUND_END = '0' or ADDRESS_COUNTER >= 32 then
                        MEM_WREN_OUT <= VISIBLE_PACKET;
                    end if;
                    STATE <= NEXT_WORD;
                end if;
            when NEXT_WORD =>
                ADDRESS_COUNTER <= ADDRESS_COUNTER + 1;
                MEM_WREN_OUT <= '0';
                STATE <= RECEIVE_FRAME;
            when ERASE_MEMORY_START =>
                ADDRESS_COUNTER <= 40;
                MEM_DATA_OUT <= "0100000";
                MEM_WREN_OUT <= '1';
                STATE <= ERASE_MEMORY;
            when ERASE_MEMORY =>
                if ADDRESS_COUNTER < 1000 then
                    ADDRESS_COUNTER <= ADDRESS_COUNTER + 1;
                else
                    STATE <= WAIT_FOR_FRAME;
                end if;
            when UPDATE_STATUS =>
                MEM_DATA_OUT <= STATUS_ARRAY(ADDRESS_COUNTER);
                MEM_WREN_OUT <= '1';
                STATUS_UPDATED <= '0';
                STATE <= UPDATE_STATUS_NEXT;
            when UPDATE_STATUS_NEXT =>
                MEM_WREN_OUT <= '1';
                if ADDRESS_COUNTER = 7 or UPCOMING_FRAME_IN = '1' then
                    STATE <= WAIT_FOR_FRAME;
                else
                    ADDRESS_COUNTER <= ADDRESS_COUNTER + 1;
                    STATE <= UPDATE_STATUS;
                end if;
            when others =>
                STATE <= WAIT_FOR_FRAME;
            end case;
        end if;
    end process;
    
    LINE_START_ADDRESS <=       8 when ROW_IN = "00000" else
                          40 *  1 when ROW_IN = "00001" else
                          40 *  2 when ROW_IN = "00010" else
                          40 *  3 when ROW_IN = "00011" else
                          40 *  4 when ROW_IN = "00100" else
                          40 *  5 when ROW_IN = "00101" else
                          40 *  6 when ROW_IN = "00110" else
                          40 *  7 when ROW_IN = "00111" else
                          40 *  8 when ROW_IN = "01000" else
                          40 *  9 when ROW_IN = "01001" else
                          40 * 10 when ROW_IN = "01010" else
                          40 * 11 when ROW_IN = "01011" else
                          40 * 12 when ROW_IN = "01100" else
                          40 * 13 when ROW_IN = "01101" else
                          40 * 14 when ROW_IN = "01110" else
                          40 * 15 when ROW_IN = "01111" else
                          40 * 16 when ROW_IN = "10000" else
                          40 * 17 when ROW_IN = "10001" else
                          40 * 18 when ROW_IN = "10010" else
                          40 * 19 when ROW_IN = "10011" else
                          40 * 20 when ROW_IN = "10100" else
                          40 * 21 when ROW_IN = "10101" else
                          40 * 22 when ROW_IN = "10110" else
                          40 * 23 when ROW_IN = "10111" else
                          40 * 24 when ROW_IN = "11000" else 0;

    ROW_INTEGER <= to_integer(unsigned(ROW_IN));
    
    VISIBLE_PACKET <= '1' when ROW_INTEGER <= 24 else '0';
    
    MEM_ADDRESS_OUT <= std_logic_vector(to_unsigned(ADDRESS_COUNTER, 10));
    
    STATUS_ARRAY(0) <= "0000111";
    STATUS_ARRAY(1) <= "01100" & REQ_SUBCODE_IN(12 downto 11) when REQ_SUBCODE_SPEC_IN = '1' else "1010000";
    STATUS_ARRAY(2) <= "011" & REQ_SUBCODE_IN(10 downto 7) when REQ_SUBCODE_SPEC_IN = '1' else "0110" & REQ_MAGAZINE_IN;
    STATUS_ARRAY(3) <= "0110" & REQ_SUBCODE_IN(6 downto 4) when REQ_SUBCODE_SPEC_IN = '1' else "011" & REQ_PAGE_IN(7 downto 4);
    STATUS_ARRAY(4) <= "011" & REQ_SUBCODE_IN(3 downto 0) when REQ_SUBCODE_SPEC_IN = '1' else "011" & REQ_PAGE_IN(3 downto 0);
    STATUS_ARRAY(5) <= "0100000";
    STATUS_ARRAY(6) <= "0100000";
    STATUS_ARRAY(7) <= "0000010" when PAGE_FOUND = '0' else "0000111";

    PAGE_FOUND <= '1' when LAST_LOADED_PAGE = REQ_PAGE_IN and LAST_LOADED_MAGAZINE = REQ_MAGAZINE_IN and (REQ_SUBCODE_SPEC_IN = '0' or LAST_LOADED_SUBCODE = REQ_SUBCODE_IN) else '0';
    
STATUS_ARRAY_MONITOR: process(CLK_27_750, RESET)
    begin
        if RESET = '1' then
            STATUS_NEEDS_UPDATING <= '0';
            STATUS_ARRAY_LAST <= (others => (others => '0'));
        elsif rising_edge(CLK_27_750) then
            if STATUS_ARRAY /= STATUS_ARRAY_LAST then
                STATUS_ARRAY_LAST <= STATUS_ARRAY;
                STATUS_NEEDS_UPDATING <= '1';
            end if;
            if STATUS_UPDATED = '1' then
                STATUS_NEEDS_UPDATING <= '0';
            end if;
        end if;
    end process;
    
end architecture;
