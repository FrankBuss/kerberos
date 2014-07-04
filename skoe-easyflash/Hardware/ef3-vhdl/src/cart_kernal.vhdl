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

entity cart_kernal is
    port (
        clk:                in  std_logic;
        n_reset:            in  std_logic;
        enable:             in  std_logic;
        phi2:               in  std_logic;
        ba:                 in  std_logic;
        n_romh:             in  std_logic;
        n_wr:               in  std_logic;
        cycle_time:         in  std_logic_vector(10 downto 0);
        cycle_start:        in  std_logic;
        addr:               in  std_logic_vector(15 downto 0);
        button_crt_reset:   in  std_logic;
        a14:                out std_logic;
        n_game:             out std_logic;
        n_exrom:            out std_logic;
        start_reset:        out std_logic;
        flash_read:         out std_logic;
        test:               out std_logic
    );
end cart_kernal;

architecture behav of cart_kernal is
    signal kernal_space_addressed:  boolean;
    signal kernal_space_cpu_read:   boolean;
    signal kernal_read_active:      boolean;
    signal cpu_port_changed:        boolean;
    signal n_hiram_state:           std_logic;

    attribute KEEP : string; -- keep buffer from being optimized out
    attribute KEEP of kernal_space_addressed: signal is "TRUE";

begin

    kernal_space_addressed <= true when addr(15 downto 13) = "111" else false;

    kernal_space_cpu_read <= true when kernal_space_addressed and
        phi2 = '1' and ba = '1' and n_wr = '1'
        else false;

    start_reset <= enable and button_crt_reset;
    --test <= enable;

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    detect_hiram: process(n_reset, phi2, clk)
    begin
        if n_reset = '0' then
            flash_read <= '0';
            n_game  <= '1';
            n_exrom <= '1';
            a14 <= 'Z';
            kernal_read_active <= false;
            cpu_port_changed <= true;
            n_hiram_state <= '1';

        elsif rising_edge(clk) then
            if enable = '1' then

                if cycle_time(5) = '1' then
                    -- check every write access to $0000 and $0001
                    if addr(15 downto 1) = "000000000000000" and n_wr = '0' then
                        cpu_port_changed <= true;
                    end if;

                    if kernal_space_cpu_read then
                        kernal_read_active <= true;
                        -- start speculative flash read to hide its latency
                        flash_read <= '1';
                        if cpu_port_changed then
                            -- start detection
                            n_game  <= '0';
                            n_exrom <= '0';
                            a14 <= '0';
                        else
                            -- use previously detected HIRAM state
                            if n_hiram_state = '1' then
                                -- ram
                                n_game  <= '1';
                                n_exrom <= '1';
                            else
                                -- rom
                                n_game  <= '0';
                                n_exrom <= '1'; -- Ultimax mode
                            end if;
                        end if;
                    end if;
                end if;

                if kernal_read_active and
                   cycle_time(7) = '1' and cpu_port_changed then
                    -- evaluate HIRAM detection
                    -- ROMH reflects n_hiram now
                    n_hiram_state <= n_romh;
                    if n_romh = '1' then
                        -- ram
                        n_game  <= '1';
                        n_exrom <= '1';
                    else
                        -- rom
                        n_game  <= '0';
                        n_exrom <= '1'; -- Ultimax mode
                    end if;
                    cpu_port_changed <= false;
                    a14 <= 'Z';
                end if;

                if cycle_start = '1' then
                    -- KERNAL read complete
                    flash_read <= '0';
                    n_game  <= '1';
                    n_exrom <= '1';
                    a14 <= 'Z';
                    kernal_read_active <= false;
                end if;
            else -- enable
                flash_read <= '0';
                n_game  <= '1';
                n_exrom <= '1';
                a14 <= 'Z';
                kernal_read_active <= false;
                cpu_port_changed <= true;
            end if; -- enable
        end if; -- clk
    end process;

    test <= '1' when n_hiram_state = '1' else '0';

end architecture behav;
