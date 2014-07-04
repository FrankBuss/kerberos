----------------------------------------------------------------------------------
--
-- (c) 2011 Thomas 'skoe' Giesel
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
use ieee.numeric_std.all;


entity cart_io2ram is
    port (
        enable:         in  std_logic;
        n_io2:          in  std_logic;
        rd:             in  std_logic;
        wr:             in  std_logic;
        ram_bank:       out std_logic_vector(1 downto 0);
        ram_read:       out std_logic;
        ram_write:      out std_logic
    );
end cart_io2ram;

architecture behav of cart_io2ram is
begin

    ---------------------------------------------------------------------------
    -- Combinatorially create the next memory address.
    ---------------------------------------------------------------------------
    ram_bank <= "00";

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    rw_mem: process(enable, n_io2, rd, wr)
    begin
        ram_write <= '0';
        ram_read <= '0';
        if enable = '1' then
            if n_io2 = '0' then
                if rd = '1' then
                    ram_read <= '1';
                end if;
                if wr = '1' then
                    ram_write <= '1';
                end if;
            end if;
        end if;
    end process;


end architecture behav;
