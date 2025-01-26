-- Single Language Version
-- Replace CGROM.vhd with this file to force English only.
-- Takes up less resources on the FPGA, freeing up room for adding other custom features.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CGROM is
port (
    ADDRESS_IN : in std_logic_vector(6 downto 0);
    NATIONAL_OPTION_IN : in std_logic_vector(2 downto 0);       -- Need to add the actual characters next
    ROW_SELECT_IN : in std_logic_vector(3 downto 0);
    DATA_OUT : out std_logic_vector(4 downto 0));
end entity CGROM;

architecture RTL of CGROM is
    signal ADDRESS : std_logic_vector(10 downto 0);
    -- NATIONAL_OPTION_IN determines language (15.6.2)
    -- Characters affected are 0x23, 0x24, 0x40, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x7B, 0x7C, 0x7D, 0x7E
    -- Languages are:
    -- 000 English
    -- 001 German
    -- 010 Swedish / Finnish / Hungarian
    -- 011 Italian
    -- 100 French
    -- 101 Portuguese/Spanish
    -- 110 Czech/Slovak
    
begin
    ADDRESS <= ADDRESS_IN & ROW_SELECT_IN;
    
    DATA_OUT <= "00000" when ADDRESS = B"0100000_0000" else
                "00000" when ADDRESS = B"0100000_0001" else
                "00000" when ADDRESS = B"0100000_0010" else
                "00000" when ADDRESS = B"0100000_0011" else
                "00000" when ADDRESS = B"0100000_0100" else
                "00000" when ADDRESS = B"0100000_0101" else
                "00000" when ADDRESS = B"0100000_0110" else
                "00000" when ADDRESS = B"0100000_0111" else
                "00000" when ADDRESS = B"0100000_1000" else
                
                "00100" when ADDRESS = B"0100001_0000" else
                "00100" when ADDRESS = B"0100001_0001" else
                "00100" when ADDRESS = B"0100001_0010" else
                "00100" when ADDRESS = B"0100001_0011" else
                "00000" when ADDRESS = B"0100001_0100" else
                "00100" when ADDRESS = B"0100001_0101" else
                "00000" when ADDRESS = B"0100001_0110" else
                "00000" when ADDRESS = B"0100001_0111" else
                "00000" when ADDRESS = B"0100001_1000" else
                
                "00000" when ADDRESS = B"0100010_0000" else
                "01010" when ADDRESS = B"0100010_0001" else
                "01010" when ADDRESS = B"0100010_0010" else
                "01010" when ADDRESS = B"0100010_0011" else
                "00000" when ADDRESS = B"0100010_0100" else
                "00000" when ADDRESS = B"0100010_0101" else
                "00000" when ADDRESS = B"0100010_0110" else
                "00000" when ADDRESS = B"0100010_0111" else
                "00000" when ADDRESS = B"0100010_1000" else
                -- Character 0x23
                "00110" when ADDRESS = B"0100011_0000" else
                "01001" when ADDRESS = B"0100011_0001" else
                "01000" when ADDRESS = B"0100011_0010" else
                "01110" when ADDRESS = B"0100011_0011" else
                "01000" when ADDRESS = B"0100011_0100" else
                "01000" when ADDRESS = B"0100011_0101" else
                "10111" when ADDRESS = B"0100011_0110" else
                "00000" when ADDRESS = B"0100011_0111" else
                "00000" when ADDRESS = B"0100011_1000" else
                
                "00100" when ADDRESS = B"0100100_0000" else
                "01111" when ADDRESS = B"0100100_0001" else
                "10100" when ADDRESS = B"0100100_0010" else
                "01110" when ADDRESS = B"0100100_0011" else
                "00101" when ADDRESS = B"0100100_0100" else
                "11110" when ADDRESS = B"0100100_0101" else
                "00100" when ADDRESS = B"0100100_0110" else
                "00000" when ADDRESS = B"0100100_0111" else
                "00000" when ADDRESS = B"0100100_1000" else
                
                "11000" when ADDRESS = B"0100101_0000" else
                "11001" when ADDRESS = B"0100101_0001" else
                "00010" when ADDRESS = B"0100101_0010" else
                "00100" when ADDRESS = B"0100101_0011" else
                "01000" when ADDRESS = B"0100101_0100" else
                "10011" when ADDRESS = B"0100101_0101" else
                "00011" when ADDRESS = B"0100101_0110" else
                "00000" when ADDRESS = B"0100101_0111" else
                "00000" when ADDRESS = B"0100101_1000" else
                
                "00100" when ADDRESS = B"0100110_0000" else
                "01010" when ADDRESS = B"0100110_0001" else
                "01010" when ADDRESS = B"0100110_0010" else
                "01100" when ADDRESS = B"0100110_0011" else
                "10101" when ADDRESS = B"0100110_0100" else
                "10010" when ADDRESS = B"0100110_0101" else
                "01101" when ADDRESS = B"0100110_0110" else
                "00000" when ADDRESS = B"0100110_0111" else
                "00000" when ADDRESS = B"0100110_1000" else
                
                "00100" when ADDRESS = B"0100111_0000" else
                "00100" when ADDRESS = B"0100111_0001" else
                "01000" when ADDRESS = B"0100111_0010" else
                "00000" when ADDRESS = B"0100111_0011" else
                "00000" when ADDRESS = B"0100111_0100" else
                "00000" when ADDRESS = B"0100111_0101" else
                "00000" when ADDRESS = B"0100111_0110" else
                "00000" when ADDRESS = B"0100111_0111" else
                "00000" when ADDRESS = B"0100111_1000" else
                
                
                "00010" when ADDRESS = B"0101000_0000" else
                "00100" when ADDRESS = B"0101000_0001" else
                "01000" when ADDRESS = B"0101000_0010" else
                "01000" when ADDRESS = B"0101000_0011" else
                "01000" when ADDRESS = B"0101000_0100" else
                "00100" when ADDRESS = B"0101000_0101" else
                "00010" when ADDRESS = B"0101000_0110" else
                "00000" when ADDRESS = B"0101000_0111" else
                "00000" when ADDRESS = B"0101000_1000" else
                
                "01000" when ADDRESS = B"0101001_0000" else
                "00100" when ADDRESS = B"0101001_0001" else
                "00010" when ADDRESS = B"0101001_0010" else
                "00010" when ADDRESS = B"0101001_0011" else
                "00010" when ADDRESS = B"0101001_0100" else
                "00100" when ADDRESS = B"0101001_0101" else
                "01000" when ADDRESS = B"0101001_0110" else
                "00000" when ADDRESS = B"0101001_0111" else
                "00000" when ADDRESS = B"0101001_1000" else
                
                "00000" when ADDRESS = B"0101010_0000" else
                "00100" when ADDRESS = B"0101010_0001" else
                "10101" when ADDRESS = B"0101010_0010" else
                "01110" when ADDRESS = B"0101010_0011" else
                "10101" when ADDRESS = B"0101010_0100" else
                "00100" when ADDRESS = B"0101010_0101" else
                "00000" when ADDRESS = B"0101010_0110" else
                "00000" when ADDRESS = B"0101010_0111" else
                "00000" when ADDRESS = B"0101010_1000" else
                
                "00000" when ADDRESS = B"0101011_0000" else
                "00100" when ADDRESS = B"0101011_0001" else
                "00100" when ADDRESS = B"0101011_0010" else
                "11111" when ADDRESS = B"0101011_0011" else
                "00100" when ADDRESS = B"0101011_0100" else
                "00100" when ADDRESS = B"0101011_0101" else
                "00000" when ADDRESS = B"0101011_0110" else
                "00000" when ADDRESS = B"0101011_0111" else
                "00000" when ADDRESS = B"0101011_1000" else
                
                "00000" when ADDRESS = B"0101100_0000" else
                "00000" when ADDRESS = B"0101100_0001" else
                "00000" when ADDRESS = B"0101100_0010" else
                "00000" when ADDRESS = B"0101100_0011" else
                "00000" when ADDRESS = B"0101100_0100" else
                "01000" when ADDRESS = B"0101100_0101" else
                "01000" when ADDRESS = B"0101100_0110" else
                "10000" when ADDRESS = B"0101100_0111" else
                "00000" when ADDRESS = B"0101100_1000" else
                
                "00000" when ADDRESS = B"0101101_0000" else
                "00000" when ADDRESS = B"0101101_0001" else
                "00000" when ADDRESS = B"0101101_0010" else
                "01110" when ADDRESS = B"0101101_0011" else
                "00000" when ADDRESS = B"0101101_0100" else
                "00000" when ADDRESS = B"0101101_0101" else
                "00000" when ADDRESS = B"0101101_0110" else
                "00000" when ADDRESS = B"0101101_0111" else
                "00000" when ADDRESS = B"0101101_1000" else
                
                "00000" when ADDRESS = B"0101110_0000" else
                "00000" when ADDRESS = B"0101110_0001" else
                "00000" when ADDRESS = B"0101110_0010" else
                "00000" when ADDRESS = B"0101110_0011" else
                "00000" when ADDRESS = B"0101110_0100" else
                "00000" when ADDRESS = B"0101110_0101" else
                "10000" when ADDRESS = B"0101110_0110" else
                "00000" when ADDRESS = B"0101110_0111" else
                "00000" when ADDRESS = B"0101110_1000" else
                
                "00000" when ADDRESS = B"0101111_0000" else
                "00001" when ADDRESS = B"0101111_0001" else
                "00010" when ADDRESS = B"0101111_0010" else
                "00100" when ADDRESS = B"0101111_0011" else
                "01000" when ADDRESS = B"0101111_0100" else
                "10000" when ADDRESS = B"0101111_0101" else
                "00000" when ADDRESS = B"0101111_0110" else
                "00000" when ADDRESS = B"0101111_0111" else
                "00000" when ADDRESS = B"0101111_1000" else
                
                
                "01110" when ADDRESS = B"0110000_0000" else
                "10001" when ADDRESS = B"0110000_0001" else
                "10001" when ADDRESS = B"0110000_0010" else
                "10001" when ADDRESS = B"0110000_0011" else
                "10001" when ADDRESS = B"0110000_0100" else
                "10001" when ADDRESS = B"0110000_0101" else
                "01110" when ADDRESS = B"0110000_0110" else
                "00000" when ADDRESS = B"0110000_0111" else
                "00000" when ADDRESS = B"0110000_1000" else
                
                "00100" when ADDRESS = B"0110001_0000" else
                "01100" when ADDRESS = B"0110001_0001" else
                "00100" when ADDRESS = B"0110001_0010" else
                "00100" when ADDRESS = B"0110001_0011" else
                "00100" when ADDRESS = B"0110001_0100" else
                "00100" when ADDRESS = B"0110001_0101" else
                "01110" when ADDRESS = B"0110001_0110" else
                "00000" when ADDRESS = B"0110001_0111" else
                "00000" when ADDRESS = B"0110001_1000" else
                
                "01110" when ADDRESS = B"0110010_0000" else
                "10001" when ADDRESS = B"0110010_0001" else
                "00001" when ADDRESS = B"0110010_0010" else
                "00110" when ADDRESS = B"0110010_0011" else
                "01000" when ADDRESS = B"0110010_0100" else
                "10000" when ADDRESS = B"0110010_0101" else
                "11111" when ADDRESS = B"0110010_0110" else
                "00000" when ADDRESS = B"0110010_0111" else
                "00000" when ADDRESS = B"0110010_1000" else
                
                "11111" when ADDRESS = B"0110011_0000" else
                "00001" when ADDRESS = B"0110011_0001" else
                "00010" when ADDRESS = B"0110011_0010" else
                "00110" when ADDRESS = B"0110011_0011" else
                "00001" when ADDRESS = B"0110011_0100" else
                "10001" when ADDRESS = B"0110011_0101" else
                "01110" when ADDRESS = B"0110011_0110" else
                "00000" when ADDRESS = B"0110011_0111" else
                "00000" when ADDRESS = B"0110011_1000" else
                
                "00010" when ADDRESS = B"0110100_0000" else
                "00110" when ADDRESS = B"0110100_0001" else
                "01010" when ADDRESS = B"0110100_0010" else
                "10010" when ADDRESS = B"0110100_0011" else
                "11111" when ADDRESS = B"0110100_0100" else
                "00010" when ADDRESS = B"0110100_0101" else
                "00010" when ADDRESS = B"0110100_0110" else
                "00000" when ADDRESS = B"0110100_0111" else
                "00000" when ADDRESS = B"0110100_1000" else
                
                "11111" when ADDRESS = B"0110101_0000" else
                "10000" when ADDRESS = B"0110101_0001" else
                "11110" when ADDRESS = B"0110101_0010" else
                "00001" when ADDRESS = B"0110101_0011" else
                "00001" when ADDRESS = B"0110101_0100" else
                "10001" when ADDRESS = B"0110101_0101" else
                "01110" when ADDRESS = B"0110101_0110" else
                "00000" when ADDRESS = B"0110101_0111" else
                "00000" when ADDRESS = B"0110101_1000" else
                
                "00111" when ADDRESS = B"0110110_0000" else
                "01000" when ADDRESS = B"0110110_0001" else
                "10000" when ADDRESS = B"0110110_0010" else
                "11110" when ADDRESS = B"0110110_0011" else
                "10001" when ADDRESS = B"0110110_0100" else
                "10001" when ADDRESS = B"0110110_0101" else
                "01110" when ADDRESS = B"0110110_0110" else
                "00000" when ADDRESS = B"0110110_0111" else
                "00000" when ADDRESS = B"0110110_1000" else
                
                "11111" when ADDRESS = B"0110111_0000" else
                "00001" when ADDRESS = B"0110111_0001" else
                "00010" when ADDRESS = B"0110111_0010" else
                "00100" when ADDRESS = B"0110111_0011" else
                "01000" when ADDRESS = B"0110111_0100" else
                "01000" when ADDRESS = B"0110111_0101" else
                "01000" when ADDRESS = B"0110111_0110" else
                "00000" when ADDRESS = B"0110111_0111" else
                "00000" when ADDRESS = B"0110111_1000" else
                
                
                "01110" when ADDRESS = B"0111000_0000" else
                "10001" when ADDRESS = B"0111000_0001" else
                "10001" when ADDRESS = B"0111000_0010" else
                "01110" when ADDRESS = B"0111000_0011" else
                "10001" when ADDRESS = B"0111000_0100" else
                "10001" when ADDRESS = B"0111000_0101" else
                "01110" when ADDRESS = B"0111000_0110" else
                "00000" when ADDRESS = B"0111000_0111" else
                "00000" when ADDRESS = B"0111000_1000" else
                
                "01110" when ADDRESS = B"0111001_0000" else
                "10001" when ADDRESS = B"0111001_0001" else
                "10001" when ADDRESS = B"0111001_0010" else
                "01111" when ADDRESS = B"0111001_0011" else
                "00001" when ADDRESS = B"0111001_0100" else
                "00010" when ADDRESS = B"0111001_0101" else
                "11100" when ADDRESS = B"0111001_0110" else
                "00000" when ADDRESS = B"0111001_0111" else
                "00000" when ADDRESS = B"0111001_1000" else
                
                "00000" when ADDRESS = B"0111010_0000" else
                "00000" when ADDRESS = B"0111010_0001" else
                "00000" when ADDRESS = B"0111010_0010" else
                "00000" when ADDRESS = B"0111010_0011" else
                "01000" when ADDRESS = B"0111010_0100" else
                "00000" when ADDRESS = B"0111010_0101" else
                "01000" when ADDRESS = B"0111010_0110" else
                "00000" when ADDRESS = B"0111010_0111" else
                "00000" when ADDRESS = B"0111010_1000" else
                
                "00000" when ADDRESS = B"0111011_0000" else
                "00000" when ADDRESS = B"0111011_0001" else
                "00000" when ADDRESS = B"0111011_0010" else
                "00100" when ADDRESS = B"0111011_0011" else
                "00000" when ADDRESS = B"0111011_0100" else
                "00100" when ADDRESS = B"0111011_0101" else
                "00100" when ADDRESS = B"0111011_0110" else
                "01000" when ADDRESS = B"0111011_0111" else
                "00000" when ADDRESS = B"0111011_1000" else
                
                "00010" when ADDRESS = B"0111100_0000" else
                "00100" when ADDRESS = B"0111100_0001" else
                "01000" when ADDRESS = B"0111100_0010" else
                "10000" when ADDRESS = B"0111100_0011" else
                "01000" when ADDRESS = B"0111100_0100" else
                "00100" when ADDRESS = B"0111100_0101" else
                "00010" when ADDRESS = B"0111100_0110" else
                "00000" when ADDRESS = B"0111100_0111" else
                "00000" when ADDRESS = B"0111100_1000" else
                
                "00000" when ADDRESS = B"0111101_0000" else
                "00000" when ADDRESS = B"0111101_0001" else
                "11111" when ADDRESS = B"0111101_0010" else
                "00000" when ADDRESS = B"0111101_0011" else
                "11111" when ADDRESS = B"0111101_0100" else
                "00000" when ADDRESS = B"0111101_0101" else
                "00000" when ADDRESS = B"0111101_0110" else
                "00000" when ADDRESS = B"0111101_0111" else
                "00000" when ADDRESS = B"0111101_1000" else
                
                "01000" when ADDRESS = B"0111110_0000" else
                "00100" when ADDRESS = B"0111110_0001" else
                "00010" when ADDRESS = B"0111110_0010" else
                "00001" when ADDRESS = B"0111110_0011" else
                "00010" when ADDRESS = B"0111110_0100" else
                "00100" when ADDRESS = B"0111110_0101" else
                "01000" when ADDRESS = B"0111110_0110" else
                "00000" when ADDRESS = B"0111110_0111" else
                "00000" when ADDRESS = B"0111110_1000" else
                
                "01110" when ADDRESS = B"0111111_0000" else
                "10001" when ADDRESS = B"0111111_0001" else
                "00001" when ADDRESS = B"0111111_0010" else
                "00010" when ADDRESS = B"0111111_0011" else
                "00100" when ADDRESS = B"0111111_0100" else
                "00000" when ADDRESS = B"0111111_0101" else
                "00100" when ADDRESS = B"0111111_0110" else
                "00000" when ADDRESS = B"0111111_0111" else
                "00000" when ADDRESS = B"0111111_1000" else
                
                
                "01110" when ADDRESS = B"1000000_0000" else
                "10001" when ADDRESS = B"1000000_0001" else
                "10111" when ADDRESS = B"1000000_0010" else
                "10101" when ADDRESS = B"1000000_0011" else
                "10111" when ADDRESS = B"1000000_0100" else
                "10000" when ADDRESS = B"1000000_0101" else
                "01110" when ADDRESS = B"1000000_0110" else
                "00000" when ADDRESS = B"1000000_0111" else
                "00000" when ADDRESS = B"1000000_1000" else
                
                "00100" when ADDRESS = B"1000001_0000" else
                "01010" when ADDRESS = B"1000001_0001" else
                "10001" when ADDRESS = B"1000001_0010" else
                "11111" when ADDRESS = B"1000001_0011" else
                "10001" when ADDRESS = B"1000001_0100" else
                "10001" when ADDRESS = B"1000001_0101" else
                "10001" when ADDRESS = B"1000001_0110" else
                "00000" when ADDRESS = B"1000001_0111" else
                "00000" when ADDRESS = B"1000001_1000" else
                
                "11110" when ADDRESS = B"1000010_0000" else
                "10001" when ADDRESS = B"1000010_0001" else
                "10001" when ADDRESS = B"1000010_0010" else
                "11110" when ADDRESS = B"1000010_0011" else
                "10001" when ADDRESS = B"1000010_0100" else
                "10001" when ADDRESS = B"1000010_0101" else
                "11110" when ADDRESS = B"1000010_0110" else
                "00000" when ADDRESS = B"1000010_0111" else
                "00000" when ADDRESS = B"1000010_1000" else
                
                "01110" when ADDRESS = B"1000011_0000" else
                "10001" when ADDRESS = B"1000011_0001" else
                "10000" when ADDRESS = B"1000011_0010" else
                "10000" when ADDRESS = B"1000011_0011" else
                "10000" when ADDRESS = B"1000011_0100" else
                "10001" when ADDRESS = B"1000011_0101" else
                "01110" when ADDRESS = B"1000011_0110" else
                "00000" when ADDRESS = B"1000011_0111" else
                "00000" when ADDRESS = B"1000011_1000" else
                
                "11110" when ADDRESS = B"1000100_0000" else
                "01001" when ADDRESS = B"1000100_0001" else
                "01001" when ADDRESS = B"1000100_0010" else
                "01001" when ADDRESS = B"1000100_0011" else
                "01001" when ADDRESS = B"1000100_0100" else
                "01001" when ADDRESS = B"1000100_0101" else
                "11110" when ADDRESS = B"1000100_0110" else
                "00000" when ADDRESS = B"1000100_0111" else
                "00000" when ADDRESS = B"1000100_1000" else
                
                "11111" when ADDRESS = B"1000101_0000" else
                "10000" when ADDRESS = B"1000101_0001" else
                "10000" when ADDRESS = B"1000101_0010" else
                "11110" when ADDRESS = B"1000101_0011" else
                "10000" when ADDRESS = B"1000101_0100" else
                "10000" when ADDRESS = B"1000101_0101" else
                "11111" when ADDRESS = B"1000101_0110" else
                "00000" when ADDRESS = B"1000101_0111" else
                "00000" when ADDRESS = B"1000101_1000" else
                
                "11111" when ADDRESS = B"1000110_0000" else
                "10000" when ADDRESS = B"1000110_0001" else
                "10000" when ADDRESS = B"1000110_0010" else
                "11110" when ADDRESS = B"1000110_0011" else
                "10000" when ADDRESS = B"1000110_0100" else
                "10000" when ADDRESS = B"1000110_0101" else
                "10000" when ADDRESS = B"1000110_0110" else
                "00000" when ADDRESS = B"1000110_0111" else
                "00000" when ADDRESS = B"1000110_1000" else
                
                "01110" when ADDRESS = B"1000111_0000" else
                "10001" when ADDRESS = B"1000111_0001" else
                "10000" when ADDRESS = B"1000111_0010" else
                "10000" when ADDRESS = B"1000111_0011" else
                "10011" when ADDRESS = B"1000111_0100" else
                "10001" when ADDRESS = B"1000111_0101" else
                "01111" when ADDRESS = B"1000111_0110" else
                "00000" when ADDRESS = B"1000111_0111" else
                "00000" when ADDRESS = B"1000111_1000" else
                
                
                "10001" when ADDRESS = B"1001000_0000" else
                "10001" when ADDRESS = B"1001000_0001" else
                "10001" when ADDRESS = B"1001000_0010" else
                "11111" when ADDRESS = B"1001000_0011" else
                "10001" when ADDRESS = B"1001000_0100" else
                "10001" when ADDRESS = B"1001000_0101" else
                "10001" when ADDRESS = B"1001000_0110" else
                "00000" when ADDRESS = B"1001000_0111" else
                "00000" when ADDRESS = B"1001000_1000" else
                
                "01110" when ADDRESS = B"1001001_0000" else
                "00100" when ADDRESS = B"1001001_0001" else
                "00100" when ADDRESS = B"1001001_0010" else
                "00100" when ADDRESS = B"1001001_0011" else
                "00100" when ADDRESS = B"1001001_0100" else
                "00100" when ADDRESS = B"1001001_0101" else
                "01110" when ADDRESS = B"1001001_0110" else
                "00000" when ADDRESS = B"1001001_0111" else
                "00000" when ADDRESS = B"1001001_1000" else
                
                "00001" when ADDRESS = B"1001010_0000" else
                "00001" when ADDRESS = B"1001010_0001" else
                "00001" when ADDRESS = B"1001010_0010" else
                "00001" when ADDRESS = B"1001010_0011" else
                "00001" when ADDRESS = B"1001010_0100" else
                "10001" when ADDRESS = B"1001010_0101" else
                "01110" when ADDRESS = B"1001010_0110" else
                "00000" when ADDRESS = B"1001010_0111" else
                "00000" when ADDRESS = B"1001010_1000" else
                
                "10001" when ADDRESS = B"1001011_0000" else
                "10010" when ADDRESS = B"1001011_0001" else
                "10100" when ADDRESS = B"1001011_0010" else
                "11000" when ADDRESS = B"1001011_0011" else
                "10100" when ADDRESS = B"1001011_0100" else
                "10010" when ADDRESS = B"1001011_0101" else
                "10001" when ADDRESS = B"1001011_0110" else
                "00000" when ADDRESS = B"1001011_0111" else
                "00000" when ADDRESS = B"1001011_1000" else
                
                "10000" when ADDRESS = B"1001100_0000" else
                "10000" when ADDRESS = B"1001100_0001" else
                "10000" when ADDRESS = B"1001100_0010" else
                "10000" when ADDRESS = B"1001100_0011" else
                "10000" when ADDRESS = B"1001100_0100" else
                "10000" when ADDRESS = B"1001100_0101" else
                "11111" when ADDRESS = B"1001100_0110" else
                "00000" when ADDRESS = B"1001100_0111" else
                "00000" when ADDRESS = B"1001100_1000" else
                
                "10001" when ADDRESS = B"1001101_0000" else
                "11011" when ADDRESS = B"1001101_0001" else
                "10101" when ADDRESS = B"1001101_0010" else
                "10101" when ADDRESS = B"1001101_0011" else
                "10001" when ADDRESS = B"1001101_0100" else
                "10001" when ADDRESS = B"1001101_0101" else
                "10001" when ADDRESS = B"1001101_0110" else
                "00000" when ADDRESS = B"1001101_0111" else
                "00000" when ADDRESS = B"1001101_1000" else
                
                "10001" when ADDRESS = B"1001110_0000" else
                "10001" when ADDRESS = B"1001110_0001" else
                "11001" when ADDRESS = B"1001110_0010" else
                "10101" when ADDRESS = B"1001110_0011" else
                "10011" when ADDRESS = B"1001110_0100" else
                "10001" when ADDRESS = B"1001110_0101" else
                "10001" when ADDRESS = B"1001110_0110" else
                "00000" when ADDRESS = B"1001110_0111" else
                "00000" when ADDRESS = B"1001110_1000" else
                
                "01110" when ADDRESS = B"1001111_0000" else
                "10001" when ADDRESS = B"1001111_0001" else
                "10001" when ADDRESS = B"1001111_0010" else
                "10001" when ADDRESS = B"1001111_0011" else
                "10001" when ADDRESS = B"1001111_0100" else
                "10001" when ADDRESS = B"1001111_0101" else
                "01110" when ADDRESS = B"1001111_0110" else
                "00000" when ADDRESS = B"1001111_0111" else
                "00000" when ADDRESS = B"1001111_1000" else
                
                
                "11110" when ADDRESS = B"1010000_0000" else
                "10001" when ADDRESS = B"1010000_0001" else
                "10001" when ADDRESS = B"1010000_0010" else
                "11110" when ADDRESS = B"1010000_0011" else
                "10000" when ADDRESS = B"1010000_0100" else
                "10000" when ADDRESS = B"1010000_0101" else
                "10000" when ADDRESS = B"1010000_0110" else
                "00000" when ADDRESS = B"1010000_0111" else
                "00000" when ADDRESS = B"1010000_1000" else
                
                "01110" when ADDRESS = B"1010001_0000" else
                "10001" when ADDRESS = B"1010001_0001" else
                "10001" when ADDRESS = B"1010001_0010" else
                "10001" when ADDRESS = B"1010001_0011" else
                "10101" when ADDRESS = B"1010001_0100" else
                "10010" when ADDRESS = B"1010001_0101" else
                "01101" when ADDRESS = B"1010001_0110" else
                "00000" when ADDRESS = B"1010001_0111" else
                "00000" when ADDRESS = B"1010001_1000" else
                
                "11110" when ADDRESS = B"1010010_0000" else
                "10001" when ADDRESS = B"1010010_0001" else
                "10001" when ADDRESS = B"1010010_0010" else
                "11110" when ADDRESS = B"1010010_0011" else
                "10100" when ADDRESS = B"1010010_0100" else
                "10010" when ADDRESS = B"1010010_0101" else
                "10001" when ADDRESS = B"1010010_0110" else
                "00000" when ADDRESS = B"1010010_0111" else
                "00000" when ADDRESS = B"1010010_1000" else
                
                "01110" when ADDRESS = B"1010011_0000" else
                "10001" when ADDRESS = B"1010011_0001" else
                "10000" when ADDRESS = B"1010011_0010" else
                "01110" when ADDRESS = B"1010011_0011" else
                "00001" when ADDRESS = B"1010011_0100" else
                "10001" when ADDRESS = B"1010011_0101" else
                "01110" when ADDRESS = B"1010011_0110" else
                "00000" when ADDRESS = B"1010011_0111" else
                "00000" when ADDRESS = B"1010011_1000" else
                
                "11111" when ADDRESS = B"1010100_0000" else
                "00100" when ADDRESS = B"1010100_0001" else
                "00100" when ADDRESS = B"1010100_0010" else
                "00100" when ADDRESS = B"1010100_0011" else
                "00100" when ADDRESS = B"1010100_0100" else
                "00100" when ADDRESS = B"1010100_0101" else
                "00100" when ADDRESS = B"1010100_0110" else
                "00000" when ADDRESS = B"1010100_0111" else
                "00000" when ADDRESS = B"1010100_1000" else
                
                "10001" when ADDRESS = B"1010101_0000" else
                "10001" when ADDRESS = B"1010101_0001" else
                "10001" when ADDRESS = B"1010101_0010" else
                "10001" when ADDRESS = B"1010101_0011" else
                "10001" when ADDRESS = B"1010101_0100" else
                "10001" when ADDRESS = B"1010101_0101" else
                "01110" when ADDRESS = B"1010101_0110" else
                "00000" when ADDRESS = B"1010101_0111" else
                "00000" when ADDRESS = B"1010101_1000" else
                
                "10001" when ADDRESS = B"1010110_0000" else
                "10001" when ADDRESS = B"1010110_0001" else
                "10001" when ADDRESS = B"1010110_0010" else
                "01010" when ADDRESS = B"1010110_0011" else
                "01010" when ADDRESS = B"1010110_0100" else
                "00100" when ADDRESS = B"1010110_0101" else
                "00100" when ADDRESS = B"1010110_0110" else
                "00000" when ADDRESS = B"1010110_0111" else
                "00000" when ADDRESS = B"1010110_1000" else
                
                "10001" when ADDRESS = B"1010111_0000" else
                "10001" when ADDRESS = B"1010111_0001" else
                "10001" when ADDRESS = B"1010111_0010" else
                "10101" when ADDRESS = B"1010111_0011" else
                "10101" when ADDRESS = B"1010111_0100" else
                "10101" when ADDRESS = B"1010111_0101" else
                "01010" when ADDRESS = B"1010111_0110" else
                "00000" when ADDRESS = B"1010111_0111" else
                "00000" when ADDRESS = B"1010111_1000" else
                
                
                "10001" when ADDRESS = B"1011000_0000" else
                "10001" when ADDRESS = B"1011000_0001" else
                "01010" when ADDRESS = B"1011000_0010" else
                "00100" when ADDRESS = B"1011000_0011" else
                "01010" when ADDRESS = B"1011000_0100" else
                "10001" when ADDRESS = B"1011000_0101" else
                "10001" when ADDRESS = B"1011000_0110" else
                "00000" when ADDRESS = B"1011000_0111" else
                "00000" when ADDRESS = B"1011000_1000" else
                
                "10001" when ADDRESS = B"1011001_0000" else
                "10001" when ADDRESS = B"1011001_0001" else
                "01010" when ADDRESS = B"1011001_0010" else
                "00100" when ADDRESS = B"1011001_0011" else
                "00100" when ADDRESS = B"1011001_0100" else
                "00100" when ADDRESS = B"1011001_0101" else
                "00100" when ADDRESS = B"1011001_0110" else
                "00000" when ADDRESS = B"1011001_0111" else
                "00000" when ADDRESS = B"1011001_1000" else
                
                "11111" when ADDRESS = B"1011010_0000" else
                "00001" when ADDRESS = B"1011010_0001" else
                "00010" when ADDRESS = B"1011010_0010" else
                "00100" when ADDRESS = B"1011010_0011" else
                "01000" when ADDRESS = B"1011010_0100" else
                "10000" when ADDRESS = B"1011010_0101" else
                "11111" when ADDRESS = B"1011010_0110" else
                "00000" when ADDRESS = B"1011010_0111" else
                "00000" when ADDRESS = B"1011010_1000" else
                
                "00000" when ADDRESS = B"1011011_0000" else
                "00100" when ADDRESS = B"1011011_0001" else
                "01000" when ADDRESS = B"1011011_0010" else
                "11111" when ADDRESS = B"1011011_0011" else
                "01000" when ADDRESS = B"1011011_0100" else
                "00100" when ADDRESS = B"1011011_0101" else
                "00000" when ADDRESS = B"1011011_0110" else
                "00000" when ADDRESS = B"1011011_0111" else
                "00000" when ADDRESS = B"1011011_1000" else
                
                "01000" when ADDRESS = B"1011100_0000" else
                "11000" when ADDRESS = B"1011100_0001" else
                "01000" when ADDRESS = B"1011100_0010" else
                "01000" when ADDRESS = B"1011100_0011" else
                "01010" when ADDRESS = B"1011100_0100" else
                "00101" when ADDRESS = B"1011100_0101" else
                "00001" when ADDRESS = B"1011100_0110" else
                "00010" when ADDRESS = B"1011100_0111" else
                "00101" when ADDRESS = B"1011100_1000" else
                
                "00000" when ADDRESS = B"1011101_0000" else
                "00100" when ADDRESS = B"1011101_0001" else
                "00010" when ADDRESS = B"1011101_0010" else
                "11111" when ADDRESS = B"1011101_0011" else
                "00010" when ADDRESS = B"1011101_0100" else
                "00100" when ADDRESS = B"1011101_0101" else
                "00000" when ADDRESS = B"1011101_0110" else
                "00000" when ADDRESS = B"1011101_0111" else
                "00000" when ADDRESS = B"1011101_1000" else
                
                "00100" when ADDRESS = B"1011110_0000" else
                "01110" when ADDRESS = B"1011110_0001" else
                "10101" when ADDRESS = B"1011110_0010" else
                "00100" when ADDRESS = B"1011110_0011" else
                "00100" when ADDRESS = B"1011110_0100" else
                "00100" when ADDRESS = B"1011110_0101" else
                "00100" when ADDRESS = B"1011110_0110" else
                "00000" when ADDRESS = B"1011110_0111" else
                "00000" when ADDRESS = B"1011110_1000" else
                
                "01010" when ADDRESS = B"1011111_0000" else
                "11111" when ADDRESS = B"1011111_0001" else
                "01010" when ADDRESS = B"1011111_0010" else
                "01010" when ADDRESS = B"1011111_0011" else
                "01010" when ADDRESS = B"1011111_0100" else
                "11111" when ADDRESS = B"1011111_0101" else
                "01010" when ADDRESS = B"1011111_0110" else
                "00000" when ADDRESS = B"1011111_0111" else
                "00000" when ADDRESS = B"1011111_1000" else
                
                "00000" when ADDRESS = B"1100000_0000" else
                "00000" when ADDRESS = B"1100000_0001" else
                "00000" when ADDRESS = B"1100000_0010" else
                "11111" when ADDRESS = B"1100000_0011" else
                "00000" when ADDRESS = B"1100000_0100" else
                "00000" when ADDRESS = B"1100000_0101" else
                "00000" when ADDRESS = B"1100000_0110" else
                "00000" when ADDRESS = B"1100000_0111" else
                "00000" when ADDRESS = B"1100000_1000" else
                
                "00000" when ADDRESS = B"1100001_0000" else
                "00000" when ADDRESS = B"1100001_0001" else
                "01110" when ADDRESS = B"1100001_0010" else
                "00001" when ADDRESS = B"1100001_0011" else
                "01111" when ADDRESS = B"1100001_0100" else
                "10001" when ADDRESS = B"1100001_0101" else
                "01111" when ADDRESS = B"1100001_0110" else
                "00000" when ADDRESS = B"1100001_0111" else
                "00000" when ADDRESS = B"1100001_1000" else
                
                "10000" when ADDRESS = B"1100010_0000" else
                "10000" when ADDRESS = B"1100010_0001" else
                "11110" when ADDRESS = B"1100010_0010" else
                "10001" when ADDRESS = B"1100010_0011" else
                "10001" when ADDRESS = B"1100010_0100" else
                "10001" when ADDRESS = B"1100010_0101" else
                "11110" when ADDRESS = B"1100010_0110" else
                "00000" when ADDRESS = B"1100010_0111" else
                "00000" when ADDRESS = B"1100010_1000" else
                
                "00000" when ADDRESS = B"1100011_0000" else
                "00000" when ADDRESS = B"1100011_0001" else
                "01111" when ADDRESS = B"1100011_0010" else
                "10000" when ADDRESS = B"1100011_0011" else
                "10000" when ADDRESS = B"1100011_0100" else
                "10000" when ADDRESS = B"1100011_0101" else
                "01111" when ADDRESS = B"1100011_0110" else
                "00000" when ADDRESS = B"1100011_0111" else
                "00000" when ADDRESS = B"1100011_1000" else
                
                "00001" when ADDRESS = B"1100100_0000" else
                "00001" when ADDRESS = B"1100100_0001" else
                "01111" when ADDRESS = B"1100100_0010" else
                "10001" when ADDRESS = B"1100100_0011" else
                "10001" when ADDRESS = B"1100100_0100" else
                "10001" when ADDRESS = B"1100100_0101" else
                "01111" when ADDRESS = B"1100100_0110" else
                "00000" when ADDRESS = B"1100100_0111" else
                "00000" when ADDRESS = B"1100100_1000" else
                
                "00000" when ADDRESS = B"1100101_0000" else
                "00000" when ADDRESS = B"1100101_0001" else
                "01110" when ADDRESS = B"1100101_0010" else
                "10001" when ADDRESS = B"1100101_0011" else
                "11111" when ADDRESS = B"1100101_0100" else
                "10000" when ADDRESS = B"1100101_0101" else
                "01110" when ADDRESS = B"1100101_0110" else
                "00000" when ADDRESS = B"1100101_0111" else
                "00000" when ADDRESS = B"1100101_1000" else
                
                "00010" when ADDRESS = B"1100110_0000" else
                "00100" when ADDRESS = B"1100110_0001" else
                "00100" when ADDRESS = B"1100110_0010" else
                "01110" when ADDRESS = B"1100110_0011" else
                "00100" when ADDRESS = B"1100110_0100" else
                "00100" when ADDRESS = B"1100110_0101" else
                "00100" when ADDRESS = B"1100110_0110" else
                "00000" when ADDRESS = B"1100110_0111" else
                "00000" when ADDRESS = B"1100110_1000" else
                
                "00000" when ADDRESS = B"1100111_0000" else
                "00000" when ADDRESS = B"1100111_0001" else
                "01111" when ADDRESS = B"1100111_0010" else
                "10001" when ADDRESS = B"1100111_0011" else
                "10001" when ADDRESS = B"1100111_0100" else
                "10001" when ADDRESS = B"1100111_0101" else
                "01111" when ADDRESS = B"1100111_0110" else
                "00001" when ADDRESS = B"1100111_0111" else
                "00110" when ADDRESS = B"1100111_1000" else
                
                
                "10000" when ADDRESS = B"1101000_0000" else
                "10000" when ADDRESS = B"1101000_0001" else
                "11110" when ADDRESS = B"1101000_0010" else
                "10001" when ADDRESS = B"1101000_0011" else
                "10001" when ADDRESS = B"1101000_0100" else
                "10001" when ADDRESS = B"1101000_0101" else
                "10001" when ADDRESS = B"1101000_0110" else
                "00000" when ADDRESS = B"1101000_0111" else
                "00000" when ADDRESS = B"1101000_1000" else
                
                "00000" when ADDRESS = B"1101001_0000" else
                "00100" when ADDRESS = B"1101001_0001" else
                "00000" when ADDRESS = B"1101001_0010" else
                "00100" when ADDRESS = B"1101001_0011" else
                "00100" when ADDRESS = B"1101001_0100" else
                "00100" when ADDRESS = B"1101001_0101" else
                "00100" when ADDRESS = B"1101001_0110" else
                "00000" when ADDRESS = B"1101001_0111" else
                "00000" when ADDRESS = B"1101001_1000" else
                
                "00000" when ADDRESS = B"1101010_0000" else
                "00100" when ADDRESS = B"1101010_0001" else
                "00000" when ADDRESS = B"1101010_0010" else
                "00100" when ADDRESS = B"1101010_0011" else
                "00100" when ADDRESS = B"1101010_0100" else
                "00100" when ADDRESS = B"1101010_0101" else
                "00100" when ADDRESS = B"1101010_0110" else
                "00100" when ADDRESS = B"1101010_0111" else
                "01000" when ADDRESS = B"1101010_1000" else
                
                "01000" when ADDRESS = B"1101011_0000" else
                "01000" when ADDRESS = B"1101011_0001" else
                "01001" when ADDRESS = B"1101011_0010" else
                "01010" when ADDRESS = B"1101011_0011" else
                "01100" when ADDRESS = B"1101011_0100" else
                "01010" when ADDRESS = B"1101011_0101" else
                "01001" when ADDRESS = B"1101011_0110" else
                "00000" when ADDRESS = B"1101011_0111" else
                "00000" when ADDRESS = B"1101011_1000" else
                
                "00100" when ADDRESS = B"1101100_0000" else
                "00100" when ADDRESS = B"1101100_0001" else
                "00100" when ADDRESS = B"1101100_0010" else
                "00100" when ADDRESS = B"1101100_0011" else
                "00100" when ADDRESS = B"1101100_0100" else
                "00100" when ADDRESS = B"1101100_0101" else
                "00100" when ADDRESS = B"1101100_0110" else
                "00000" when ADDRESS = B"1101100_0111" else
                "00000" when ADDRESS = B"1101100_1000" else
                
                "00000" when ADDRESS = B"1101101_0000" else
                "00000" when ADDRESS = B"1101101_0001" else
                "11010" when ADDRESS = B"1101101_0010" else
                "10101" when ADDRESS = B"1101101_0011" else
                "10101" when ADDRESS = B"1101101_0100" else
                "10101" when ADDRESS = B"1101101_0101" else
                "10101" when ADDRESS = B"1101101_0110" else
                "00000" when ADDRESS = B"1101101_0111" else
                "00000" when ADDRESS = B"1101101_1000" else
                
                "00000" when ADDRESS = B"1101110_0000" else
                "00000" when ADDRESS = B"1101110_0001" else
                "01110" when ADDRESS = B"1101110_0010" else
                "01001" when ADDRESS = B"1101110_0011" else
                "01001" when ADDRESS = B"1101110_0100" else
                "01001" when ADDRESS = B"1101110_0101" else
                "01001" when ADDRESS = B"1101110_0110" else
                "00000" when ADDRESS = B"1101110_0111" else
                "00000" when ADDRESS = B"1101110_1000" else
                
                "00000" when ADDRESS = B"1101111_0000" else
                "00000" when ADDRESS = B"1101111_0001" else
                "01110" when ADDRESS = B"1101111_0010" else
                "10001" when ADDRESS = B"1101111_0011" else
                "10001" when ADDRESS = B"1101111_0100" else
                "10001" when ADDRESS = B"1101111_0101" else
                "01110" when ADDRESS = B"1101111_0110" else
                "00000" when ADDRESS = B"1101111_0111" else
                "00000" when ADDRESS = B"1101111_1000" else
                
                
                "00000" when ADDRESS = B"1110000_0000" else
                "00000" when ADDRESS = B"1110000_0001" else
                "11110" when ADDRESS = B"1110000_0010" else
                "10001" when ADDRESS = B"1110000_0011" else
                "10001" when ADDRESS = B"1110000_0100" else
                "10001" when ADDRESS = B"1110000_0101" else
                "11110" when ADDRESS = B"1110000_0110" else
                "10000" when ADDRESS = B"1110000_0111" else
                "10000" when ADDRESS = B"1110000_1000" else
                
                "00000" when ADDRESS = B"1110001_0000" else
                "00000" when ADDRESS = B"1110001_0001" else
                "01111" when ADDRESS = B"1110001_0010" else
                "10001" when ADDRESS = B"1110001_0011" else
                "10001" when ADDRESS = B"1110001_0100" else
                "10001" when ADDRESS = B"1110001_0101" else
                "01111" when ADDRESS = B"1110001_0110" else
                "00001" when ADDRESS = B"1110001_0111" else
                "00001" when ADDRESS = B"1110001_1000" else
                
                "00000" when ADDRESS = B"1110010_0000" else
                "00000" when ADDRESS = B"1110010_0001" else
                "01011" when ADDRESS = B"1110010_0010" else
                "01100" when ADDRESS = B"1110010_0011" else
                "01000" when ADDRESS = B"1110010_0100" else
                "01000" when ADDRESS = B"1110010_0101" else
                "01000" when ADDRESS = B"1110010_0110" else
                "00000" when ADDRESS = B"1110010_0111" else
                "00000" when ADDRESS = B"1110010_1000" else
                
                "00000" when ADDRESS = B"1110011_0000" else
                "00000" when ADDRESS = B"1110011_0001" else
                "01111" when ADDRESS = B"1110011_0010" else
                "10000" when ADDRESS = B"1110011_0011" else
                "01110" when ADDRESS = B"1110011_0100" else
                "00001" when ADDRESS = B"1110011_0101" else
                "11110" when ADDRESS = B"1110011_0110" else
                "00000" when ADDRESS = B"1110011_0111" else
                "00000" when ADDRESS = B"1110011_1000" else
                
                "00000" when ADDRESS = B"1110100_0000" else
                "00100" when ADDRESS = B"1110100_0001" else
                "01110" when ADDRESS = B"1110100_0010" else
                "00100" when ADDRESS = B"1110100_0011" else
                "00100" when ADDRESS = B"1110100_0100" else
                "00100" when ADDRESS = B"1110100_0101" else
                "00010" when ADDRESS = B"1110100_0110" else
                "00000" when ADDRESS = B"1110100_0111" else
                "00000" when ADDRESS = B"1110100_1000" else
                
                "00000" when ADDRESS = B"1110101_0000" else
                "00000" when ADDRESS = B"1110101_0001" else
                "10001" when ADDRESS = B"1110101_0010" else
                "10001" when ADDRESS = B"1110101_0011" else
                "10001" when ADDRESS = B"1110101_0100" else
                "10001" when ADDRESS = B"1110101_0101" else
                "01111" when ADDRESS = B"1110101_0110" else
                "00000" when ADDRESS = B"1110101_0111" else
                "00000" when ADDRESS = B"1110101_1000" else
                
                "00000" when ADDRESS = B"1110110_0000" else
                "00000" when ADDRESS = B"1110110_0001" else
                "10001" when ADDRESS = B"1110110_0010" else
                "10001" when ADDRESS = B"1110110_0011" else
                "01010" when ADDRESS = B"1110110_0100" else
                "01010" when ADDRESS = B"1110110_0101" else
                "00100" when ADDRESS = B"1110110_0110" else
                "00000" when ADDRESS = B"1110110_0111" else
                "00000" when ADDRESS = B"1110110_1000" else
                
                "00000" when ADDRESS = B"1110111_0000" else
                "00000" when ADDRESS = B"1110111_0001" else
                "10001" when ADDRESS = B"1110111_0010" else
                "10001" when ADDRESS = B"1110111_0011" else
                "10001" when ADDRESS = B"1110111_0100" else
                "10101" when ADDRESS = B"1110111_0101" else
                "01010" when ADDRESS = B"1110111_0110" else
                "00000" when ADDRESS = B"1110111_0111" else
                "00000" when ADDRESS = B"1110111_1000" else
                
                
                "00000" when ADDRESS = B"1111000_0000" else
                "00000" when ADDRESS = B"1111000_0001" else
                "10001" when ADDRESS = B"1111000_0010" else
                "01010" when ADDRESS = B"1111000_0011" else
                "00100" when ADDRESS = B"1111000_0100" else
                "01010" when ADDRESS = B"1111000_0101" else
                "10001" when ADDRESS = B"1111000_0110" else
                "00000" when ADDRESS = B"1111000_0111" else
                "00000" when ADDRESS = B"1111000_1000" else
                
                "00000" when ADDRESS = B"1111001_0000" else
                "00000" when ADDRESS = B"1111001_0001" else
                "10001" when ADDRESS = B"1111001_0010" else
                "10001" when ADDRESS = B"1111001_0011" else
                "10001" when ADDRESS = B"1111001_0100" else
                "10001" when ADDRESS = B"1111001_0101" else
                "01111" when ADDRESS = B"1111001_0110" else
                "00001" when ADDRESS = B"1111001_0111" else
                "01111" when ADDRESS = B"1111001_1000" else
                
                "00000" when ADDRESS = B"1111010_0000" else
                "00000" when ADDRESS = B"1111010_0001" else
                "11111" when ADDRESS = B"1111010_0010" else
                "00010" when ADDRESS = B"1111010_0011" else
                "00100" when ADDRESS = B"1111010_0100" else
                "01000" when ADDRESS = B"1111010_0101" else
                "11111" when ADDRESS = B"1111010_0110" else
                "00000" when ADDRESS = B"1111010_0111" else
                "00000" when ADDRESS = B"1111010_1000" else
                
                "01000" when ADDRESS = B"1111011_0000" else
                "11000" when ADDRESS = B"1111011_0001" else
                "01000" when ADDRESS = B"1111011_0010" else
                "01000" when ADDRESS = B"1111011_0011" else
                "00001" when ADDRESS = B"1111011_0100" else
                "00011" when ADDRESS = B"1111011_0101" else
                "00101" when ADDRESS = B"1111011_0110" else
                "01111" when ADDRESS = B"1111011_0111" else
                "00001" when ADDRESS = B"1111011_1000" else
                
                "11011" when ADDRESS = B"1111100_0000" else
                "11011" when ADDRESS = B"1111100_0001" else
                "11011" when ADDRESS = B"1111100_0010" else
                "11011" when ADDRESS = B"1111100_0011" else
                "11011" when ADDRESS = B"1111100_0100" else
                "11011" when ADDRESS = B"1111100_0101" else
                "11011" when ADDRESS = B"1111100_0110" else
                "00000" when ADDRESS = B"1111100_0111" else
                "00000" when ADDRESS = B"1111100_1000" else
                
                "11000" when ADDRESS = B"1111101_0000" else
                "00100" when ADDRESS = B"1111101_0001" else
                "11000" when ADDRESS = B"1111101_0010" else
                "00100" when ADDRESS = B"1111101_0011" else
                "11001" when ADDRESS = B"1111101_0100" else
                "00011" when ADDRESS = B"1111101_0101" else
                "00101" when ADDRESS = B"1111101_0110" else
                "01111" when ADDRESS = B"1111101_0111" else
                "00001" when ADDRESS = B"1111101_1000" else
                
                "00000" when ADDRESS = B"1111110_0000" else
                "00100" when ADDRESS = B"1111110_0001" else
                "00000" when ADDRESS = B"1111110_0010" else
                "11111" when ADDRESS = B"1111110_0011" else
                "00000" when ADDRESS = B"1111110_0100" else
                "00100" when ADDRESS = B"1111110_0101" else
                "00000" when ADDRESS = B"1111110_0110" else
                "00000" when ADDRESS = B"1111110_0111" else
                "00000" when ADDRESS = B"1111110_1000" else
                
                "11111" when ADDRESS = B"1111111_0000" else
                "11111" when ADDRESS = B"1111111_0001" else
                "11111" when ADDRESS = B"1111111_0010" else
                "11111" when ADDRESS = B"1111111_0011" else
                "11111" when ADDRESS = B"1111111_0100" else
                "11111" when ADDRESS = B"1111111_0101" else
                "11111" when ADDRESS = B"1111111_0110" else
                "00000" when ADDRESS = B"1111111_0111" else
                "00000" when ADDRESS = B"1111111_1000" else
                
                "00000";
end architecture;