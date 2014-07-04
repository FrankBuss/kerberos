----------------------------------------------------------------------------------
--
-- (c) 2012 Thomas 'skoe' Giesel
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


entity exp_bus_ctrl is
    port (
        clk:                in  std_logic;
        phi2:               in  std_logic;
        n_wr:               in  std_logic;
        rd:                 out std_logic;
        wr:                 out std_logic;
        rp:                 out std_logic;
        wp:                 out std_logic;
        wp_end:             out std_logic;

        -- The time in a Phi2 half cycle as shift register. This is used
        -- as one-hot encoded state machine.
        cycle_time:         out std_logic_vector(10 downto 0);

        -- This combinatorial signal is '1' for one clk cycle
        -- at the beginning of each Phi2 half cycle
        cycle_start:        out std_logic
    );
end exp_bus_ctrl;


architecture a of exp_bus_ctrl is
    signal prev_phi2:       std_logic;
    signal phi2_s:          std_logic;
    signal cycle_time_i:     std_logic_vector(10 downto 0);
begin

    ---------------------------------------------------------------------------
    -- Create a synchronized version of Phi2 (phi2_s) and a copy of phi2_s
    -- which is delayed by one clock cycle (prev_phi2).
    ---------------------------------------------------------------------------
    synchronize_stuff: process(clk)
    begin
        if rising_edge(clk) then
            prev_phi2 <= phi2_s;
            phi2_s <= phi2;
        end if;
    end process synchronize_stuff;

    ---------------------------------------------------------------------------
    -- Count clk cycles in both phases of phi2 with a shift register.
    ---------------------------------------------------------------------------
    clk_time_shift: process(clk, prev_phi2, phi2_s)
    begin
        if rising_edge(clk) then
            if prev_phi2 /= phi2_s then
                cycle_time_i <= (others => '0');
                cycle_time_i(0) <= '1';
            else
                cycle_time_i <= cycle_time_i(9 downto 0) & '0';
            end if;
        end if;
    end process;

    cycle_time <= cycle_time_i;

    ---------------------------------------------------------------------------
    -- Write is only allowed at phi2 = '1', because on C128 it happens
    -- that n_wr = '0' when phi2 = '0', which is not a write access.
    --
    -- We have partial support for C128 2 MHz mode. C128 read accesses with
    -- 2 MHz are at least to be supported for EasyFlash mode (e.g. for PoP)
    -- For this we allow read accesses to be evaluated asynchronously.
    --
    ---------------------------------------------------------------------------
    check_rw: process(phi2_s, n_wr)
    begin
            wr <= '0';
            rd <= '0';

            if n_wr = '1' or phi2_s = '0' then
                rd <= '1';
            end if;

            if n_wr = '0' and phi2_s = '1' then
                wr <= '1';
            end if;
    end process;

    ---------------------------------------------------------------------------
    -- Create control signals depending from clk counter
    --
    -- These signals are generated combinatorially, they are to be used on the
    -- next rising edge of clk.
    --
    ---------------------------------------------------------------------------
    cycle_start <= phi2_s xor prev_phi2;

    -- Write pulse for internal registers
    -- or to start a write signal for external memory
    wp <= not n_wr and phi2_s and cycle_time_i(7);

    -- end of write access, we need 80 ns for external chips
    wp_end <= cycle_time_i(9);

    -- Read pulse (for synchronous read accesses, e.g. USB)
    rp <= (n_wr or not phi2_s) and cycle_time_i(6);
end a;
