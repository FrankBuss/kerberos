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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity reset_generator is
    port (
            clk:                in  std_logic;
            cycle_start:        in  std_logic;
            phi2:               in  std_logic;
            start_reset:        in  std_logic;
            go_64:              in  std_logic; -- for C128: go to C64 mode
            n_reset_in:         in  std_logic;
            n_romh:             in  std_logic;
            n_reset:            out std_logic; -- any reset
            n_generated_reset:  out std_logic; -- reset from host
            n_sys_reset:        out std_logic; -- reset by us
            n_game:             out std_logic
    );
end reset_generator;


architecture reset_generator_arc of reset_generator is

    -- count cycles, a cycle starts at phi2 = '0' and cycle_start = '1'
    signal cycle_cnt:           std_logic_vector(2 downto 0);

    -- as long as this is '1', n_reset_in is ignored
    signal ignore_reset:        std_logic := '0';

    signal n_generated_reset_i: std_logic;
    signal n_sys_reset_i:       std_logic;
    signal n_game_i:            std_logic;
begin

    ---------------------------------------------------------------------------
    cycle_counter: process(clk)
    begin
        if rising_edge(clk) then
            if start_reset = '1' then
                cycle_cnt <= "111";
                n_generated_reset_i <= '0';
                ignore_reset <= '1';
            elsif phi2 = '0' and cycle_start = '1' then
                cycle_cnt <= cycle_cnt - 1;

                if cycle_cnt = "000" then
                    n_generated_reset_i <= '1';

                    -- another 8 cycles later:
                    if n_reset_in = '1' then
                        ignore_reset <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process cycle_counter;


    ---------------------------------------------------------------------------
    -- When C64 mode is wanted, pull n_game low until the first n_romh low is
    -- seen after reset.
    ---------------------------------------------------------------------------
    check_c64_mode: process(clk)
    begin
        if rising_edge(clk) then
            if start_reset = '1' then
                n_game_i <= not go_64;
            elsif n_romh = '0' and n_generated_reset_i = '1' then
                n_game_i <= '1';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    sync_reset: process(clk)
    begin
        if rising_edge(clk) then
            -- synchronize reset from C64
            n_sys_reset_i <= ignore_reset or n_reset_in;
        end if;
    end process sync_reset;


    n_sys_reset <= n_sys_reset_i;
    n_reset <= n_generated_reset_i and n_sys_reset_i;
    n_generated_reset <= n_generated_reset_i;
    n_game <= n_game_i;

end reset_generator_arc;
