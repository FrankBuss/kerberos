----------------------------------------------------------------------------------
-- 
-- (c) 2010 Thomas 'skoe' Giesel
--
-- This software is provided 'as-is', without any express or implied
-- warranty.  In no event will the authors be held liable for any damages
-- arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
-- 
-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software. If you use this software
--    in a product, an acknowledgment in the product documentation would be
--    appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be
--    misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- When there is a rising edge of clk and start_soft_reset is high, a reset
-- starts to be generated. It remains active for 8 cycles of clk_cnt 0=>0.
-- The reset signal is ouputted at n_generated_reset. 

entity reset_generator is
    port ( 
            clk:                    in std_logic;
            phi2_cycle_start:       in std_logic;
            start_reset_generator:  in std_logic;
            n_generated_reset:      out std_logic
    );
end reset_generator;


architecture reset_generator_arc of reset_generator is

    -- count cycles, one cycle is cycle_start to cycle_start
    signal cycle_cnt:     std_logic_vector(2 downto 0);

begin

    ---------------------------------------------------------------------------
    cycle_counter: process(clk)
    begin
        if rising_edge(clk) then
            if start_reset_generator = '1' then
                cycle_cnt <= "111";
                n_generated_reset <= '0';
            elsif cycle_cnt /= "000" then
                if phi2_cycle_start = '1' then
                    cycle_cnt <= cycle_cnt - 1;
                end if;
                n_generated_reset <= '0';
            else
                n_generated_reset <= '1';
            end if;                            
        end if;
    end process cycle_counter; 

end reset_generator_arc;
