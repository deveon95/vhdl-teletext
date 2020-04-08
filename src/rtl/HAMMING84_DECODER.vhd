library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HAMMING84_DECODER is
    port (
    DATA_IN : in std_logic_vector(7 downto 0);
    DATA_OUT : out std_logic_vector(3 downto 0);
    DATA_VALID_OUT : out std_logic
    );
end entity;

architecture rtl of HAMMING84_DECODER is
signal P1,D1,P2,D2,P3,D3,P4,D4 : std_logic;
signal A,B,C,D : std_logic;
begin
    P1 <= DATA_IN(0);
    D1 <= DATA_IN(1);
    P2 <= DATA_IN(2);
    D2 <= DATA_IN(3);
    P3 <= DATA_IN(4);
    D3 <= DATA_IN(5);
    P4 <= DATA_IN(6);
    D4 <= DATA_IN(7);
    A <= P1 XOR D1 XOR D3 XOR D4;
    B <= D1 XOR P2 XOR D2 XOR D4;
    C <= D1 XOR D2 XOR P3 XOR D3;
    D <= P1 XOR D1 XOR P2 XOR D2 XOR P3 XOR D3 XOR P4 XOR D4;

    --when "111-" =>
        -- All correct = No errors / Accept data bits
        -- ABC correct and D incorrect = Error in P4 / Accept data bits
    --when "---1" => 
        -- ABC not all correct and D correct = Double error / Reject data bits
    --when "---0" =>
        -- ABC not all correct and D not correct = Single error / Error bit identification required
    DATA_OUT <= (D4 & D3 & D2 & D1) when (A AND B AND C) = '1' else
                (D4 XOR ((NOT A) AND (NOT B) AND C)) &
                (D3 XOR ((NOT A) AND B AND (NOT C))) &
                (D2 XOR (A AND (NOT B) AND (NOT C))) &
                (D1 XOR ((NOT A) AND (NOT B) AND (NOT C))) when (D = '0') else "0000";
                
    DATA_VALID_OUT <=  (A AND B AND C) OR (NOT D);
        
    
end architecture;
