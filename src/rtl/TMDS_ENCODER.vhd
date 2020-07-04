-- TMDS_ENCODER.vhd
-- Converts one 8-bit video channel into 10 bits of TMDS-encoded data
--
-- Copyright 2020 Nick Schollar
-- This code is subject to the licence in the LICENSE.TXT file in the project directory

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TMDS_ENCODER is
port (
    CLK             : in std_logic;
    
    VIDEO_IN        : in std_logic_vector(7 downto 0);
    VIDEO_ACTIVE_IN : in std_logic;
    CONTROL_IN      : in std_logic_vector(1 downto 0);
    TMDS_OUT        : out std_logic_vector(9 downto 0)
    );
end entity TMDS_ENCODER;

architecture RTL of TMDS_ENCODER is
    signal TMDATA : std_logic_vector(8 downto 0);
    signal VIDEO_1S : integer range 0 to 8;
    signal VIDEO_XNOR : std_logic;
    signal TMDATA_1S : integer range 0 to 8;
    signal BALANCE_1S : integer range 0 to 8;
    signal DISPARITY : integer range -16 to 15;
    signal CONTROL_DATA : std_logic_vector(9 downto 0);
    signal ENCODED_DATA : std_logic_vector(9 downto 0);
    
begin

    -- Count number of ones in the input data
VIDEO_ONES_COUNTER: process(VIDEO_IN)
        variable ONES : integer range 0 to 8;
    begin
        ONES := 0;
        for I in 0 to 7 loop
            if VIDEO_IN(I) = '1' then
                ONES := ONES + 1;
            end if;
        end loop;
        VIDEO_1S <= ONES;
    end process;
    
    -- Calculate whether VIDEO_IN should be XORed or XNORed with TMDATA
    VIDEO_XNOR <= '1' when VIDEO_1S > 4 or (VIDEO_1S = 4 and VIDEO_IN(0) = '0') else '0';
    
    -- Generate intermediate data
VIDEO_XOR: process(VIDEO_IN, VIDEO_XNOR)
    begin
        if VIDEO_XNOR = '1' then
            TMDATA(0) <= VIDEO_IN(0);
            TMDATA(1) <= VIDEO_IN(1) XNOR TMDATA(0);
            TMDATA(2) <= VIDEO_IN(2) XNOR TMDATA(1);
            TMDATA(3) <= VIDEO_IN(3) XNOR TMDATA(2);
            TMDATA(4) <= VIDEO_IN(4) XNOR TMDATA(3);
            TMDATA(5) <= VIDEO_IN(5) XNOR TMDATA(4);
            TMDATA(6) <= VIDEO_IN(6) XNOR TMDATA(5);
            TMDATA(7) <= VIDEO_IN(7) XNOR TMDATA(6);
            TMDATA(8) <= '0';
        else
            TMDATA(0) <= VIDEO_IN(0);
            TMDATA(1) <= VIDEO_IN(1) XOR TMDATA(0);
            TMDATA(2) <= VIDEO_IN(2) XOR TMDATA(1);
            TMDATA(3) <= VIDEO_IN(3) XOR TMDATA(2);
            TMDATA(4) <= VIDEO_IN(4) XOR TMDATA(3);
            TMDATA(5) <= VIDEO_IN(5) XOR TMDATA(4);
            TMDATA(6) <= VIDEO_IN(6) XOR TMDATA(5);
            TMDATA(7) <= VIDEO_IN(7) XOR TMDATA(6);
            TMDATA(8) <= '1';
        end if;
    end process;
    
    -- Count number of ones in the input data
TM_ONES_COUNTER: process(VIDEO_IN)
        variable ONES : integer range 0 to 8;
    begin
        ONES := 0;
        for I in 0 to 7 loop
            if TMDATA(I) = '1' then
                ONES := ONES + 1;
            end if;
        end loop;
        TMDATA_1S <= ONES;
        BALANCE_1S <= ONES - (8 - ONES);
    end process;
    
    -- Generate TMDS-encoded data
ENCODE: process(CLK)
    begin
        if rising_edge(CLK) then
            if DISPARITY = 0 or TMDATA_1S = 4 then
                if TMDATA(8) = '0' then
                    ENCODED_DATA <= not TMDATA(8) & TMDATA(8) & not TMDATA(7 downto 0);
                    DISPARITY <= DISPARITY - BALANCE_1S;
                else
                    ENCODED_DATA <= not TMDATA(8) & TMDATA(8) & TMDATA(7 downto 0);
                    DISPARITY <= DISPARITY + BALANCE_1S;
                end if;
            elsif (DISPARITY > 0 and TMDATA_1S > 4) or (DISPARITY < 0 and TMDATA_1S < 4) then
                ENCODED_DATA <= '1' & TMDATA(8) & not TMDATA(7 downto 0);
                if TMDATA(8) = '0' then
                    DISPARITY <= DISPARITY - BALANCE_1S;
                else
                    DISPARITY <= DISPARITY - BALANCE_1S + 2;
                end if;
            else
                ENCODED_DATA <= '0' & TMDATA(8) & TMDATA(7 downto 0);
                if TMDATA(8) = '0' then
                    DISPARITY <= DISPARITY + BALANCE_1S - 2;
                else
                    DISPARITY <= DISPARITY + BALANCE_1S;
                end if;
            end if;
        end if;
    end process;
    
    -- Determine the control word
    CONTROL_DATA <= "1101010100" when CONTROL_IN = "00" else
                    "0010101011" when CONTROL_IN = "01" else
                    "0101010100" when CONTROL_IN = "10" else
                    "1010101011";
    
    TMDS_OUT <= CONTROL_DATA when VIDEO_ACTIVE_IN = '0' else ENCODED_DATA;

end architecture;
