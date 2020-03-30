library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HAMMING2418_DECODER is
    port (
    DATA_IN : in std_logic_vector(23 downto 0);
    DATA_OUT : out std_logic_vector(17 downto 0)
    );
end entity;

architecture rtl of HAMMING2418_DECODER is
begin
end architecture;
