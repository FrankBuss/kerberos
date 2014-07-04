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


entity freezer is
    port (
            clk:                    in std_logic;
            bus_wr_start:           in std_logic;
            bus_read_start:         in std_logic;
            n_reset:                in std_logic;
            start_freezer:          in std_logic;
            n_generated_irq:        out std_logic
    );
end freezer;


architecture freezer_arc of freezer is

    -- count write accesses
    signal write_access_cnt:      std_logic_vector(1 downto 0);

    signal freeze_pending:          std_logic;
begin

    ---------------------------------------------------------------------------
    -- When the freeze button is pressed during a bus read access we start 
    -- the Freeze Pending state.
    --
    -- Currently the Freeze Pending state is only left on reset.
    ---------------------------------------------------------------------------
    freezer_start: process(clk, n_reset)
    begin
        if n_reset = '0' then
            freeze_pending <= '0';
        elsif rising_edge(clk) then
            if start_freezer = '1' and bus_read_start = '1' then
                freeze_pending <= '1';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Count from 3 to 0 to find 3 consecutive write accesses which only
    -- happen when an IRQ or NMI is started.
    --
    -- The counter is reset to 3 on reset, when not being in Freeze Pending
    -- state and on every read access.
    -- It is decremented in Freeze Pending state whenever a write access takes
    -- place.
    ---------------------------------------------------------------------------
    freezer_count: process(clk, n_reset)
    begin
        if n_reset = '0' then
            write_access_cnt <= "11";
        elsif rising_edge(clk) then
            if freeze_pending = '1' and bus_wr_start = '1' then
                write_access_cnt <= write_access_cnt - 1;
            elsif (freeze_pending = '1' and bus_read_start = '1') or
                  (freeze_pending = '0') then
                write_access_cnt <= "11";
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    freezer_ready: process(clk, n_reset)
    begin
        if n_reset = '0' then
            n_generated_irq <= '1';
        elsif rising_edge(clk) then
            if write_access_cnt = "00" then
                n_generated_irq <= '0';
            end if;
        end if;
    end process;

end freezer_arc;
