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
use ieee.numeric_std.all;


entity freezer is
    port (
            clk:                in  std_logic;
            n_reset:            in  std_logic;
            phi2:               in  std_logic;
            ba:                 in  std_logic;
            rp:                 in  std_logic;
            wp:                 in  std_logic;
            start_freezer:      in  std_logic;
            reset_freezer:      in  std_logic;
            freezer_irq:        out std_logic;
            freezer_ready:      out std_logic
    );
end freezer;


architecture behav of freezer is

    -- This counter has two semantics (to save macro cells):
    --
    -- a) If freeze_pending is '1', it counts the write accesses
    --    Count from 3 to 0 to find 3 consecutive write accesses which only
    --    happen when an IRQ or NMI is started.
    -- b) If freeze_pending is '0', it contains the state if the freezer:
    --    0 = Idle, start_freezer can start the freezer
    --    1 = Locked, start_freezer is ignored (to avoid double freezes)
    --
    signal freeze_counter:          integer range 0 to 3;

    signal freeze_pending:          std_logic;
    
    signal cpu_read:                std_logic;
    signal cpu_write:               std_logic;
begin
	cpu_read  <= phi2 and ba and rp;
	cpu_write <= phi2 and wp;

    ---------------------------------------------------------------------------
    -- When the freeze button is being pressed during a bus read access we
    -- start the Freeze Pending state.
    ---------------------------------------------------------------------------
    the_freezer: process(clk, n_reset, reset_freezer)
    begin
        if n_reset = '0' or reset_freezer = '1' then
            freeze_counter <= 1; -- locked
            freezer_ready <= '0';
            freeze_pending <= '0';
        elsif rising_edge(clk) then

            if freeze_pending = '0' then
                if start_freezer = '0' then
                    -- Unlock the Freezer only if the button has been released
                    freeze_counter <= 0; -- unlocked
                else
                    if freeze_counter = 0 and rp = '1' then
                        freeze_pending <= '1';
                        freeze_counter <= 3;
                    end if;
                end if;

            else
            	if cpu_write = '1' then
                    if freeze_counter /= 0 then
                        freeze_counter <= freeze_counter - 1;
                    end if;
                    if freeze_counter = 1 then
                        freezer_ready <= '1';
                    end if;
                elsif cpu_read = '1' then
                    freeze_counter <= 3;
                end if;
            end if;
        end if; -- clk
    end process;

    freezer_irq <= freeze_pending;

end behav;
