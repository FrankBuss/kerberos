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


entity cart_easyflash is
    port (
            clk:                in  std_logic;
            n_sys_reset:        in  std_logic;
            reset_to_menu:      in  std_logic;
            n_reset:            in  std_logic;
            enable:             in  std_logic;
            phi2:               in  std_logic;
            n_roml:             in  std_logic;
            n_romh:             in  std_logic;
            rd:                 in  std_logic;
            wr:                 in  std_logic;
            wp:                 in  std_logic;
            cycle_start:        in  std_logic;
            addr:               in  std_logic_vector(15 downto 0);
            data:               in  std_logic_vector(7 downto 0);
            io1_addr_0x:        in  std_logic;
            button_crt_reset:   in  std_logic;
            button_special_fn:  in  std_logic;
            slot:               out std_logic_vector(2 downto 0);
            bank_hi:            out std_logic_vector(2 downto 0);
            set_bank_lo:        out std_logic;
            new_bank_lo:        out std_logic_vector(2 downto 0);
            n_game:             out std_logic;
            n_exrom:            out std_logic;
            start_reset:        out std_logic;
            flash_read:         out std_logic;
            flash_write:        out std_logic;
            data_out:           out std_logic_vector(7 downto 0);
            data_out_valid:     out std_logic;
            led:                out std_logic
    );
end cart_easyflash;

-- Memory mapping:
-- Bit                        98765432109876543210
--                            1111111111  .
-- Bits needed for Flash:            .    .
--   Flash (8 Mi * 8)         ******************** (19..0)
-- Used in EF mode:
--   mem_addr(19 downto 15)   HHHLB                (19..15)
--   mem_addr(14 downto 13)        MM              (14..13)
--   mem_addr(12 downto 0)           AAAAAAAAAAAAA (12..0)
--
-- A    = Address from C64 bus to address 8k per bank
-- H    = Bank number (high bits) as set with $de00
-- B/M  = Bank number (low bits) as set with $de00
-- M    = Shared between RAM and Flash, 00 for RAM, flash_bank(1 downto 0) for Flash
-- L    = ROML/ROMH, 0 for ROML banks
--
-- Only flash_bank(1 downto 0) is saved in this entity. This is needed because
-- these bits are used by RAM and ROM.
-- The other banking and new_slot bits are written to and read from mem_addr_out
-- and mem_addr_in directly.

architecture behav of cart_easyflash is

    -- boot enabled?
    signal easyflash_boot:      std_logic := '1';

    signal data_out_valid_i:    std_logic;
    signal start_reset_i:       std_logic;

    signal slot_i:              std_logic_vector(2 downto 0);
    signal bank_hi_i:           std_logic_vector(2 downto 0);
    signal ctrl_game:           std_logic;
    signal ctrl_exrom:          std_logic;
    signal ctrl_no_vicii:       std_logic;
begin

    ---------------------------------------------------------------------------
    --
    ---------------------------------------------------------------------------
    reset_boot_or_no_boot: process(n_sys_reset, reset_to_menu, clk)
    begin
        if n_sys_reset = '0' or reset_to_menu = '1' then
            easyflash_boot <= '1';
        elsif rising_edge(clk) then
            start_reset_i <= '0';
            if enable = '1' then
                if button_special_fn = '1' then
                    easyflash_boot <= '0';
                    start_reset_i <= '1';
                elsif button_crt_reset = '1' then
                    easyflash_boot <= '1';
                    start_reset_i <= '1';
                end if;
            end if;
        end if;
    end process;

    start_reset <= start_reset_i;

    ---------------------------------------------------------------------------
    -- Combinatorial process to prepare output signals set_bank_low and
    -- new_bank_lo.
    ---------------------------------------------------------------------------
    update_bank_lo: process(enable, addr, data, wp, io1_addr_0x,
                            start_reset_i, reset_to_menu)
    begin
        set_bank_lo <= '0';
        new_bank_lo <= (others => '0');

        if enable = '1' then
            if wp = '1' and io1_addr_0x = '1' and addr(3 downto 0) = x"0" then
                new_bank_lo <= data(2 downto 0);
                set_bank_lo <= '1';
            end if;
        end if;
        if start_reset_i = '1' or reset_to_menu = '1' then
            set_bank_lo <= '1';
            new_bank_lo <= (others => '0');
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Combinatorial process to prepare data read from a register.
    ---------------------------------------------------------------------------
    create_data_out: process(data_out_valid_i, slot_i)
    begin
        data_out <= (others => '0');
        if data_out_valid_i = '1' then
            data_out <= "00000" & slot_i;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Process to read and write control registers.
    ---------------------------------------------------------------------------
    rw_control_regs: process(clk, n_reset, n_sys_reset, enable,
                             easyflash_boot, reset_to_menu)
    begin
        if n_reset = '0' then
            ctrl_exrom <= '0';
            ctrl_game  <= easyflash_boot;
            data_out_valid_i <= '0';
            ctrl_no_vicii <= '0';
            led <= '0';
            if n_sys_reset = '0' or reset_to_menu = '1' then
                -- Slot and Bank are used for all cartridges, so reset them in
                -- these situations only
                slot_i <= (others => '0');
                bank_hi_i <= (others => '0');
            end if;
            if start_reset_i = '1' then
                -- Reset Bank (not Slot) when current EF is restarted
                bank_hi_i <= (others => '0');
            end if;
        elsif rising_edge(clk) then
            if enable = '1' then
                if io1_addr_0x = '1' then
                    if wp = '1' then
                        -- write control register
                        case addr(3 downto 0) is
                            when x"0" =>
                                -- $de00
                                bank_hi_i <= data(5 downto 3);
                                -- for bank_lo refer to combinatorial logic new_bank_lo

                            when x"1" =>
                                -- $de01
                                slot_i <= data(2 downto 0);

                            when x"2" =>
                                -- $de02
                                ctrl_exrom <= data(1);
                                if data(2) = '0' then
                                    ctrl_game <= easyflash_boot;
                                else
                                    ctrl_game <= data(0);
                                end if;
                                ctrl_no_vicii <= data(3);
                                led <= data(7);

                            when others => null;
                        end case;
                    elsif rd = '1' then
                        -- read control register
                        if addr(3 downto 0) = x"1" then
                            -- $de01
                            data_out_valid_i <= '1';
                        end if;
                    end if;
                end if;
                if cycle_start = '1' then
                    data_out_valid_i <= '0';
                end if;
            else
                data_out_valid_i <= '0';
                led <= '0';
            end if; -- enable
       end if; -- clk
    end process;

    data_out_valid <= data_out_valid_i;
    slot <= slot_i;
    bank_hi <= bank_hi_i;

    ---------------------------------------------------------------------------
    -- Leave GAME and EXROM in VIC-II cycles to avoid flickering when software
    -- uses the Ultimax mode. This seems to be the case with the RR loader.
    ---------------------------------------------------------------------------
    set_game_exrom: process(enable, ctrl_exrom, ctrl_game, phi2,
                            ctrl_no_vicii)
    begin
        if enable = '1' and (phi2 = '1' or ctrl_no_vicii = '0') then
            n_exrom <= not ctrl_exrom;
            n_game  <= not ctrl_game;
        else
            n_exrom <= '1';
            n_game  <= '1';
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Combinatorial process to prepare a memory read or write access.
    ---------------------------------------------------------------------------
    rw_mem: process(enable, n_roml, n_romh, rd, wr)
    begin
        flash_write <= '0';
        flash_read <= '0';
        if enable = '1' then
            if n_roml = '0' or n_romh = '0' then
                if rd = '1' then
                    flash_read <= '1';
                elsif wr = '1' then
                    flash_write <= '1';
                end if;
            end if;
        end if;
    end process;


end architecture behav;
