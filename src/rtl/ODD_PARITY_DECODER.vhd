library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ODD_PARITY_DECODER is
    port (
    DATA_IN : in std_logic_vector(7 downto 0);
    DATA_OUT : out std_logic_vector(6 downto 0);
    DATA_VALID_OUT : out std_logic
    );
end entity;

architecture rtl of ODD_PARITY_DECODER is
begin
    DATA_VALID_OUT <= DATA_IN(0) XOR DATA_IN(1) XOR DATA_IN(2) XOR DATA_IN(3) XOR DATA_IN(4) XOR DATA_IN(5) XOR DATA_IN(6) XOR DATA_IN(7);
    DATA_OUT <= DATA_IN(6 downto 0);
end architecture;
