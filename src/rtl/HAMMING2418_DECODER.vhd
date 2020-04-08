library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HAMMING2418_DECODER is
    port (
    DATA_IN : in std_logic_vector(23 downto 0);
    DATA_OUT : out std_logic_vector(17 downto 0);
    DATA_VALID_OUT : out std_logic
    );
end entity;

architecture rtl of HAMMING2418_DECODER is
signal P1,P2,D1,P3,D2,D3,D4,P4,D5,D6,D7,D8,D9,D10,D11,P5,D12,D13,D14,D15,D16,D17,D18,P6 : std_logic;
signal A,B,C,D,E,F : std_logic;
begin
    P1 <= DATA_IN(0);
    P2 <= DATA_IN(1);
    D1 <= DATA_IN(2);
    P3 <= DATA_IN(3);
    D2 <= DATA_IN(4);
    D3 <= DATA_IN(5);
    D4 <= DATA_IN(6);
    P4 <= DATA_IN(7);
    D5 <= DATA_IN(8);
    D6 <= DATA_IN(9);
    D7 <= DATA_IN(10);
    D8 <= DATA_IN(11);
    D9 <= DATA_IN(12);
    D10 <= DATA_IN(13);
    D11 <= DATA_IN(14);
    P5 <= DATA_IN(15);
    D12 <= DATA_IN(16);
    D13 <= DATA_IN(17);
    D14 <= DATA_IN(18);
    D15 <= DATA_IN(19);
    D16 <= DATA_IN(20);
    D17 <= DATA_IN(21);
    D18 <= DATA_IN(22);
    P6 <= DATA_IN(23);
    A <= P1 XOR D1 XOR D2 XOR D4 XOR D5 XOR D7 XOR D9 XOR D11 XOR D12 XOR D14 XOR D16 XOR D18;
    B <= P2 XOR D1 XOR D3 XOR D4 XOR D6 XOR D7 XOR D10 XOR D11 XOR D13 XOR D14 XOR D17 XOR D18;
    C <= P3 XOR D2 XOR D3 XOR D4 XOR D8 XOR D9 XOR D10 XOR D11 XOR D15 XOR D16 XOR D17 XOR D18;
    D <= P4 XOR D5 XOR D6 XOR D7 XOR D8 XOR D9 XOR D10 XOR D11;
    E <= P5 XOR D12 XOR D13 XOR D14 XOR D15 XOR D16 XOR D17 XOR D18;
    F <= P1 XOR P2 XOR D1 XOR P3 XOR D2 XOR D3 XOR D4 XOR P4 XOR D5 XOR D6 XOR D7 XOR D8 XOR D9 XOR D10 XOR D11 XOR P5 XOR D12 XOR D13 XOR D14 XOR D15 XOR D16 XOR D17 XOR D18 XOR P6;
    
    --when "11111-" =>
        -- All correct = No errors / Accept data bits
        -- ABCDE correct and F incorrect = Error in P4 / Accept data bits
    --when "-----1" => 
        -- ABCDE not all correct and F correct = Double error / Reject data bits
    --when "-----0" =>
        -- ABCDE not all correct and F not correct = Single error / Error bit identification required
    
    DATA_OUT <= (D18 & D17 & D16 & D15 & D14 & D13 & D12 & D11 & D10 & D9 & D8 & D7 & D6 & D5 & D4 & D3 & D2 & D1) when (A AND B AND C AND D AND E) = '1' else
                (D18 XOR ((NOT A) AND (NOT B) AND (NOT C) AND      D  AND (NOT E))) &
                (D17 XOR (     A  AND (NOT B) AND (NOT C) AND      D  AND (NOT E))) &
                (D16 XOR ((NOT A) AND      B  AND (NOT C) AND      D  AND (NOT E))) &
                (D15 XOR (     A  AND      B  AND (NOT C) AND      D  AND (NOT E))) &
                (D14 XOR ((NOT A) AND (NOT B) AND      C  AND      D  AND (NOT E))) &
                (D13 XOR (     A  AND (NOT B) AND      C  AND      D  AND (NOT E))) &
                (D12 XOR ((NOT A) AND      B  AND      C  AND      D  AND (NOT E))) &
                (D11 XOR ((NOT A) AND (NOT B) AND (NOT C) AND (NOT D) AND      E)) &
                (D10 XOR (     A  AND (NOT B) AND (NOT C) AND (NOT D) AND      E)) &
                (D9  XOR ((NOT A) AND      B  AND (NOT C) AND (NOT D) AND      E)) &
                (D8  XOR (     A  AND      B  AND (NOT C) AND (NOT D) AND      E)) &
                (D7  XOR ((NOT A) AND (NOT B) AND      C  AND (NOT D) AND      E)) &
                (D6  XOR (     A  AND (NOT B) AND      C  AND (NOT D) AND      E)) &
                (D5  XOR ((NOT A) AND      B  AND      C  AND (NOT D) AND      E)) &
                (D4  XOR ((NOT A) AND (NOT B) AND (NOT C) AND      D  AND      E)) &
                (D3  XOR (     A  AND (NOT B) AND (NOT C) AND      D  AND      E)) &
                (D2  XOR ((NOT A) AND      B  AND (NOT C) AND      D  AND      E)) &
                (D1  XOR ((NOT A) AND (NOT B) AND      C  AND      D  AND      E)) when (F = '0')
                else "000000000000000000";
    
    DATA_VALID_OUT <=  (A AND B AND C AND D AND E) OR (NOT F);
end architecture;
