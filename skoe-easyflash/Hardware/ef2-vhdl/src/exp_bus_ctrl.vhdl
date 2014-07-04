----------------------------------------------------------------------------------
-- 
-- (c) 2009 Thomas 'skoe' Giesel
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

----------------------------------------------------------------------------------
-- Expansion Port Bus Control
----------------------------------------------------------------------------------
-- 
-- dotclk: T ~ 125 ns
--       ---     ---     ---     ---     ---     ---     ---     ---     ---
--  \ 0 /   \ 1 /   \ 2 /   \ 3 /   \ 4 /   \ 5 /   \ 6 /   \ 7 /   \ 0 /   \
--   ---     ---     ---     ---     ---     ---     ---     ---     ---     -
-- clk:
--   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
--  / \ /0\ /1\ /2\ /3\ /4\ /5\ /6\ /7\ /8\ /9\ /A\ /B\ /C\ /D\ /E\ /F\ /0\ /1\ 
--     -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
-- phi2:    .       .       .       .       .       .   .   .   .   .   .   .
-- ~40..~90ns       .       .     ~60..~90ns        .   .   .   .   .   .   .
--  .==>    .       .       .       .=====> .       .   .   .   .   .   .   .
-- ------                                --------------------------------
--      \\             VIC              /XX/              CPU           \\
--       ----------------------------------                              -----
--          .       .       .       .       .       .   .   .   .   .   .   .
-- bus states:      .       .       .       .       .   .   .   .   .   .   .
--          .       .       .       .       .       .   .   .   .   .   .   .
--          .       .       .       .       .  if RW is 0:  X > X ====> X   .
--          .       .       .       .       .       .   . Write Write  Idle .
--          .       .       .       .       .       .   . valid enable      .
--          .       .       .       .       .       .   .  (1)   (2)        .
--          .       .       .       .       .       .   .   .       .       .
--          .       .       .       .   if RW is 1: X ====> X ============> X
--          .       .       .       .       .     Read  . Read      .   . Idle
--          .       .       .       .       .     valid .complete   .   .  (4)
--          .       .       .       .       .      (3)  .   .       .   .   .
--          .       .       .       .       .     >--------Out-enable-----< .
--          .       .       .       .       .       .   .   .  (5)
--          .       .       .       .       .       
-- if LOROM is 0 or HIROM is 0 (read from VIC):
--                          X ====> X ====> X
--                        Read    Read     Idle
--                        valid  complete   (4)
--                         (3)
--              >-------Out-enable---------<
--                         (5)
-- 
-- Note (1): Due to AEC from VIC-II, addresses and data are not stable 
-- immediately after the phi2 edge. We generate a safe timing using (n_)dotclk.
-- At the beginning of dotclk cycle 7 the address and data for a write access 
-- can be clocked from the c64 bus to our memory bus.
-- 
-- Note (2): One dotclock cycle after applying address, data and /CE to our
-- memory bus, we can activate /WE to the memory chip.
-- 
-- Note (3): Same as (1), but for read access. The signals /CS and /OE of the
-- addressed memory chip are activated in this step. Note that we need one 
-- cycle more for the CPU-reads-kernal-from-cartridge stuff
-- 
-- Note (4): We leave the memory chip enabled for a while. It is deactivated
-- after output is disabled.
--
-- Note (5): Output enable for expansion port data bus. It is generated 
-- asynchronously when one of /IO1, /IO2, /ROML or /ROMH is low.
--

-- dotclk: T ~ 125 ns
--       ---     ---     ---     ---     ---     ---     ---     ---     ---
--  \ 0 /   \ 1 /   \ 2 /   \ 3 /   \ 4 /   \ 5 /   \ 6 /   \ 7 /   \ 0 /   \
--   ---     ---     ---     ---     ---     ---     ---     ---     ---     -
-- clk:
--   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
--  / \ /0\ /1\ /2\ /3\ /4\ /5\ /6\ /7\ /8\ /9\ /A\ /B\ /C\ /D\ /E\ /F\ /0\ /1\ 
--     -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
-- phi2:    .   .   .       .       .       .       .   .   .   .   .   .   .
-- ~40..~90ns   .   .       .     ~60..~90ns        .   .   .   .   .   .   .
--  .==>    .   .   .       .       .=====> .       .   .   .   .   .   .   .
-- ------                                --------------------------------
--      \\             VIC              /XX/              CPU           \\
--       ----------------------------------                              -----
--          .   .
-- phi2_cycle_start:
--           --
--          /  \
-- ---------    --------------------------------------------------------------


-- Minimal number of Macrocells used:
-- 
-- component exp_bus_ctrl (u0):
--  3 FDCPE_u0/bus_current_state_i
--
--  3 FTCPE_u0/dotclk_cnt
--  1 FDCPE_u0/prev_phi2
-- ==
--  6
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.ef2_types.all;

entity exp_bus_ctrl is
    port ( 
            n_roml:             in std_logic;
            n_romh:             in std_logic;
            n_io1:              in std_logic;
            n_io2:              in std_logic;
            n_wr:               in std_logic;
            n_reset:            in std_logic;
            clk:                in std_logic;
            phi2:               in std_logic;
            ba:                 in std_logic;
            addr:               in std_logic_vector(15 downto 12);
            phi2_cycle_start:   out std_logic;
            bus_out_enable:     out std_logic;
            hrdet_next_state:   out hiram_det_state_type;
            hrdet_current_state: out hiram_det_state_type;
            bus_read_start:     out std_logic;
            bus_wr_start:       out std_logic;
            bus_we_start:       out std_logic;
            bus_to_idle:        out std_logic
    );
end exp_bus_ctrl;


architecture exp_bus_ctrl_arc of exp_bus_ctrl is

    -- current state of the hiram detection
    signal hrdet_current_state_i:   hiram_det_state_type;

    -- next state of the hiram detection
    signal hrdet_next_state_i:      hiram_det_state_type;

    -- count clk cycles in a phi2 cycle, 0 when falling edge of phi2 happens
    signal clk_cnt:                 std_logic_vector(3 downto 0);

    -- Remember the state of phi2 on previous clk edge
    signal prev_phi2:               std_logic;

    -- This is '1' when the CPU addresses kernal space
    signal kernal_space_addressed: std_logic;

    -- This is '1' when the CPU reads from the kernal address space
    signal kernal_space_cpu_read:   std_logic;

begin

    ---------------------------------------------------------------------------
    -- Combinatorical logic used here and there
    ---------------------------------------------------------------------------
    kernal_space_addressed <= '1' when addr(15 downto 13) = "111" else '0';

    kernal_space_cpu_read <= '1' when kernal_space_addressed = '1' and 
        ba = '1' and n_wr = '1' 
        else '0';

    ---------------------------------------------------------------------------
    -- Count cycles of clk 0..15
    --
    -- Our CPLD has async CLRs and we know that phi2 changes somewhere in the 
    -- middle between two rising edges of our clk. Therefore we reset the
    -- counter asynchronously when phi2 changes from 1 to 0.                      <= todo: update
    ---------------------------------------------------------------------------
    clk_counter: process(clk, prev_phi2, phi2, clk_cnt)
    begin
        if prev_phi2 = '1' and phi2 = '0' and clk_cnt /= x"0" then
            clk_cnt <= (others => '0');
        elsif rising_edge(clk) then
            clk_cnt <= clk_cnt + 1;
        end if;
    end process clk_counter;

    ---------------------------------------------------------------------------
    -- Remember the phi2 state on each clk edge, used to synchronize
    -- dotclk_cnt to phi2, see process clk_counter
    ---------------------------------------------------------------------------
    save_prev_phi2: process(clk)
    begin
        if rising_edge(clk) then
            prev_phi2 <= phi2;
        end if;
    end process save_prev_phi2;
    

    ---------------------------------------------------------------------------
    -- Set phi2_cycle_start to '1' during clk_cnt = 1 for one cycle, then turn
    -- it low again.
    ---------------------------------------------------------------------------
    check_phi2_cycle_start: process(clk)
    begin
        if rising_edge(clk) then
            if clk_cnt = x"0" then
                phi2_cycle_start <= '1';
            else
                phi2_cycle_start <= '0';
            end if;
        end if;
    end process check_phi2_cycle_start;

    ---------------------------------------------------------------------------
    -- 
    --   --                  -- On C128 in Ultimax mode n_wr is don't care
    ---------------------------------------------------------------------------
    check_bus_read_start: process(clk_cnt, n_wr)
    begin
        if clk_cnt = x"C" and n_wr = '1' then
            bus_read_start <= '1';
        else
            bus_read_start <= '0';
        end if;
    end process check_bus_read_start;


    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------
    check_bus_wr_start: process(clk_cnt, n_wr)
    begin
        if clk_cnt = x"C" and n_wr = '0' then
            bus_wr_start <= '1';
        else
            bus_wr_start <= '0';
        end if;
    end process check_bus_wr_start;

    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------
    check_bus_we_start: process(clk_cnt, n_wr)
    begin
        if clk_cnt = x"D" and n_wr = '0' then
            bus_we_start <= '1';
        else
            bus_we_start <= '0';
        end if;
    end process check_bus_we_start;

    ---------------------------------------------------------------------------
    -- 
    ---------------------------------------------------------------------------
    check_bus_to_idle: process(clk_cnt, n_wr)
    begin
        if (clk_cnt = x"F" and n_wr = '0') or 
           clk_cnt = x"0" or 
           clk_cnt = x"8" then
            bus_to_idle <= '1';
        else
            bus_to_idle <= '0';
        end if;
    end process check_bus_to_idle;


    ---------------------------------------------------------------------------
    -- Create the output enable signal for the expansion port data bus.
    -- It is activated asynchronously when there's a read access to the 
    -- cartridge address space.
    --
    -- Remember that VIC-II can read data from cartridge ROM e.g. in Ultimax
    -- mode when phi2 is low. In this case n_wr is don't care because it has
    -- a wrong state on C128.
    -- 
    -- When I did this synchronously I had some timing problems with different
    -- C64 types. However, in this way it's quite similar to classical ROM 
    -- cartridges. Seems the C64 knows best when it wants to read our data :)
    ---------------------------------------------------------------------------
    check_port_out_enable: process(phi2, n_wr, n_io1, n_io2, n_roml, n_romh)
    begin
        if (n_io1 = '0' or n_io2 = '0' or n_roml = '0' or n_romh = '0') and
           (n_wr = '1') -- or phi2 = '0')
        then
            bus_out_enable <= '1';
        else
            bus_out_enable <= '0';
        end if;
    end process check_port_out_enable;


    ---------------------------------------------------------------------------
    -- 
    -- This ist the state machine for the HIRAM detection. The state of this
    -- signal is essential to implement an external kernal. But as it is not
    -- available on the Expansion Port, we derive it from the PLA equatation.
    -- The signals shown in the following diagram are not set in this
    -- process, thei're show fyi only.
    -- 
    --        -   -   -   -   -   -   -   -   -   -   -   -
    -- clk:  /6\ /7\ /8\ /9\ /A\ /B\ /C\ /D\ /E\ /F\ /0\ /1\ 
    --          -   -   -   -   -   -   -   -   -   -   -   
    --           .       .   .   .   .   .               .
    --                --------------------------------
    -- phi2:         /XX/              CPU           \\
    --        ----------                              -----
    --           .       .   .       .   .               .
    --           .       .   .       .   .               .
    --           if RW is 1 and kernal addressed by CPU:
    --        ---------------             -----------------
    -- /DMA:                 \           /
    --           .       .   .-----------                .
    --           .       .   .       .   .               .
    --        -----------------------     -----------------
    --  A14:  XXXXXXXXXXXXXXXXXXXXXXX\   /XXXXXXXXXXXXXXXXX
    --        ---------------------------------------------
    --           .       .   .       .   .               .
    --        ---------------                             -
    -- /GAME:                \                           /                 
    --           .       .   .---------------------------
    --           .       .   .       .   .               .
    --        ---------------             -----------------
    -- /EXROM:               \           /
    --           .       .   .-----------
    --           .       .   .       .   .               .
    --        ------------------------- --- ---
    -- /ROMH:                          X   X   \           /
    --                       .       .  ---     -----------
    --                       .       .   .               .
    --                       .       .   .               .
    --                       x ====> X > X ==============>
    --                      DMA     Dtct Read          Idle
    -- 
    ---------------------------------------------------------------------------
    check_hiram_detect_next_state : process(clk_cnt, 
                                            hrdet_current_state_i,
                                            kernal_space_cpu_read)
    begin
        case hrdet_current_state_i is
            when HRDET_STATE_IDLE =>
                if clk_cnt = x"9" and kernal_space_cpu_read = '1' then
                    hrdet_next_state_i <= HRDET_STATE_DMA;
                else
                    hrdet_next_state_i <= HRDET_STATE_IDLE;
                end if;

            when HRDET_STATE_DMA =>
                if clk_cnt = x"b" then
                    hrdet_next_state_i <= HRDET_STATE_DETECT;
                else
                    hrdet_next_state_i <= HRDET_STATE_DMA;
                end if;                

            when HRDET_STATE_DETECT =>
                hrdet_next_state_i <= HRDET_STATE_READ;

            when HRDET_STATE_READ =>
                if clk_cnt = x"0" then
                    hrdet_next_state_i <= HRDET_STATE_IDLE;
                else 
                    hrdet_next_state_i <= HRDET_STATE_READ;
                end if;
        end case;
    end process check_hiram_detect_next_state;

    hrdet_next_state <= hrdet_next_state_i;


    ---------------------------------------------------------------------------
    -- Make the next state of hiram detection to the current state
    ---------------------------------------------------------------------------
    enter_next_hrdet_state: process(clk, n_reset)
    begin
        if n_reset = '0' then
            hrdet_current_state_i <= HRDET_STATE_IDLE;
        elsif rising_edge(clk) then
            hrdet_current_state_i <= hrdet_next_state_i;
        end if;
    end process enter_next_hrdet_state;

    hrdet_current_state <= hrdet_current_state_i;

end exp_bus_ctrl_arc;
