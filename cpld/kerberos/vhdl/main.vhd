library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity main is
	port(
		-- LEDs
		led1: out std_logic;
		led2: out std_logic;
		
		-- 24 MHz input clock
		clk24: in std_logic;
		
		-- RAM/flash
		at: out std_logic_vector(20 downto 0);
		flash_ce: out std_logic;
		ram_ce: out std_logic;
		we: out std_logic;
		oe: out std_logic;

		-- data bus
		dt: in std_logic_vector(7 downto 0);
		dir: out std_logic;

		-- 68B50 MIDI
		midiThru: out std_logic;
		mc6850_rxData: in std_logic;
		mc6850_CS2: out std_logic;
		mc6850_rxTxClk: out std_logic;
		mc6850_txData: in std_logic;
		mc6850_rs: out std_logic;
		mc6850_irq: in std_logic;

		-- C64 expansion port
		ba: in std_logic;
		s02: in std_logic;
		io1: in std_logic;
		io2: in std_logic;
		c64_a: in std_logic_vector(13 downto 0);
		c64_a14: inout std_logic;
		c64_a15: in std_logic;
		romL: in std_logic;
		romH: in std_logic;
		exrom: out std_logic;
		game: out std_logic;
		reset: inout std_logic;
		rw: in std_logic;
		nmi: inout std_logic;
		irq: inout std_logic
	);
end main;

architecture rtl of main is

-- registers    
signal midi_address: std_logic_vector(7 downto 0);
signal midi_config: std_logic_vector(7 downto 0);
signal cart_control: std_logic_vector(7 downto 0);
signal cart_config: std_logic_vector(7 downto 0);
signal flash_address_extension: std_logic_vector(7 downto 0);
signal ram_address_extension: std_logic_vector(7 downto 0);
signal address_extension2: std_logic_vector(7 downto 0);

-- bits
constant MIDI_CONFIG_IRQ : integer := 0;
constant MIDI_CONFIG_NMI : integer := 1;
constant MIDI_CONFIG_CLOCK : integer := 2;
constant MIDI_CONFIG_THRU_IN : integer := 3;
constant MIDI_CONFIG_THRU_OUT : integer := 4;
constant MIDI_CONFIG_ENABLE : integer := 5;
constant CART_CONTROL_GAME : integer := 0;
constant CART_CONTROL_EXROM : integer := 1;
constant CART_CONTROL_LED1 : integer := 2;
constant CART_CONTROL_LED2 : integer := 3;
constant CART_CONTROL_RESET : integer := 4;
constant CART_CONFIG_EASYFLASH : integer := 0;
constant CART_CONFIG_RAM_AS_ROM : integer := 1;
constant CART_CONFIG_KERNAL_HACK : integer := 2;
constant CART_CONFIG_BASIC_HACK : integer := 3;
constant CART_CONFIG_HIRAM_HACK : integer := 4;
constant ADDRESS_EXTENSION2_RAM : integer := 0;
constant ADDRESS_EXTENSION2_FLASH : integer := 1;

constant AFTERGLOW_COUNTER_MAX : integer := 8191;

signal io1_latched: std_logic_vector(1 downto 0);
signal io2_latched: std_logic_vector(1 downto 0);
signal s02_latched: std_logic;
signal prev_s02: std_logic;
signal romL_latched: std_logic_vector(1 downto 0);
signal romH_latched: std_logic_vector(1 downto 0);
signal rw_latched: std_logic;
signal easyflashLed: std_logic;

signal ram_write: std_logic := '0';
signal flash_write: std_logic := '0';
signal mem_access_allowed: boolean;

signal counter: integer range 0 to 23;
signal mc6850_clkBuffer: std_logic;

signal afterglow_counter: integer range 0 to AFTERGLOW_COUNTER_MAX;
signal led1_afterglow: std_logic;
signal led2_afterglow: std_logic;

signal reset_i: std_logic;
signal reset_running: std_logic := '0';
signal ignore_reset: std_logic := '0';
signal romL_filtered: std_logic;
signal romH_filtered: std_logic;
signal io1_filtered: std_logic;
signal io2_filtered: std_logic;
signal adr: std_logic_vector(15 downto 0);

-- HIRAM hack
signal cpu_port_changed: boolean;
signal kernal_read_active: boolean;
signal hiram_state: std_logic;

type state_type is (
    idle,
    address_valid,
    delay,
    delay2,
    delay3,
    delay4,
    delay5,
    delay6,
    delay7
);
signal state: state_type := idle;


begin

    -- synchronize inputs
    process(clk24)
    begin
        if rising_edge(clk24) then
            -- filter IO glitches: max. measured glitch is 20 ns, filter for 83 ns
            io1_latched <= io1_latched(0) & io1;
            io2_latched <= io2_latched(0) & io2;

            -- latch inputs
            romL_latched <= romL_latched(0) & romL;
            romH_latched <= romH_latched(0) & romH;
            s02_latched <= s02;
            prev_s02 <= s02_latched;
            rw_latched <= rw;
            reset_i <= reset;

        end if;
    end process;


    -- main statemachine
    
    -- C64/C128 timings:
    -- address from CPU is valid 12 ns after rising edge of s02 on a fast C64, but needs up to 95 ns on a C128
    -- data from CPU is valid 70 ns after rising edge of s02 (but needs up to 330 ns after falling edge on C128 in 2 MHz mode)
    -- address from CPU can be valid until 31 ns after falling edge of s02
    -- on a C128, RW can be low 50 ns after falling edge of s02, for a full cycle of s02
    -- the RAM from the internal C64 can be as slow as valid 330 ns after rising edge of s02
    -- IO1/IO2 goes low 80-120 ns after rising edge of s02
    
    -- implementation:
    -- s02 is latched with 24 MHz, which means a delay from 41 ns to 82 ns
    -- statemachine starts with rising edge detection on s02
    -- after one more delay, address_valid state is reached 120-160 ns after s02

    -- register write access with IO1:
    -- the filtered IO1/IO2 signal is valid 230-270 ns after rising edge of s02
    -- sample address and data for register write 325-365 ns after rising edge s02
    process(clk24, s02)
    begin
        if rising_edge(clk24) then
            if reset_i = '0' and ignore_reset = '0' then
                cart_control <= "00000001";  -- game = 1, exrom = 0
                midi_config <= (others => '0');
                midi_config <= (others => '0');
                midi_address <= (others => '0');
                midi_address <= (others => '0');
                cart_config <= (others => '0');
                ram_address_extension <= (others => '0');
                flash_address_extension <= (others => '0');
                address_extension2 <= (others => '0');
                mc6850_rxTxClk <= '0';
                easyflashLed <= '0';
                reset <= 'Z';
                dir <= '0';
                ram_ce <= '1';
                oe <= '1';
                flash_ce <= '1';
                game <= '1';
                exrom <= '1';
                c64_a14 <= 'Z';
                cpu_port_changed <= true;
                hiram_state <= '0';
            else
                if reset_running = '1' then
                    -- reset counter mode
                    if counter = 12 then
                        reset <= 'Z';
                    end if;
                    if counter = 23 then
                        ignore_reset <= '0';
                        reset_running <= '0';
                    else
                        -- count s02 cycles
                        if s02_latched = '1' and prev_s02 = '0' then
                            counter <= counter + 1;
                        end if;
                    end if;
                else
                    -- generate clock for the MC6850
                    if midi_config(MIDI_CONFIG_CLOCK) = '1' then
                        -- 2 MHz
                        if counter = 5 then
                            counter <= 0;
                            mc6850_clkBuffer <= not mc6850_clkBuffer;
                        else
                            counter <= counter + 1;
                        end if;
                    else
                        -- 500 kHz
                        if counter = 23 then
                            counter <= 0;
                            mc6850_clkBuffer <= not mc6850_clkBuffer;
                        else
                            counter <= counter + 1;
                        end if;
                    end if;
                    mc6850_rxTxClk <= mc6850_clkBuffer;
                end if;

                -- reset generator
                if cart_control(CART_CONTROL_RESET) = '1' then
                    -- reset for 3 cycles, reset ignore for 7 cycles
                    counter <= 0;
                    ignore_reset <= '1';
                    cart_control(CART_CONTROL_RESET) <= '0';
                    reset <= '0';
                    reset_running <= '1';
                end if;

                -- main statemachine
                case state is
                    when idle => null;

                    -- 80-120 ns after rising edge of s02
                    when delay =>
                        if s02_latched = '1' then
                            -- game and exrom can be overwritten by hacks
                            -- KERNAL hack: read from RAM for KERNAL hack
                            if cart_config(CART_CONFIG_KERNAL_HACK) = '1' then
                                if cart_config(CART_CONFIG_HIRAM_HACK) = '1' then
                                    -- with HIRAM hack; doesn't work on C128, so address is valid earlier for C64
                                    if adr(15 downto 13) = "111" and ba = '1' and rw_latched = '1' then
                                        kernal_read_active <= true;
                                        if cpu_port_changed then
                                            -- start detection
                                            game  <= '0';
                                            exrom <= '0';
                                            c64_a14 <= '0';
                                        else
                                            -- use previously detected HIRAM state
                                            if hiram_state = '1' then
                                                -- ram
                                                game  <= '1';
                                                exrom <= '1';
                                            else
                                                -- rom
                                                game  <= '0';
                                                exrom <= '1'; -- Ultimax mode
                                            end if;
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;

                        state <= delay2;
                        
                    -- 120-160 ns after rising edge of s02
                    when delay2 =>
                        mem_access_allowed <= true;
                        if s02_latched = '1' then
                            -- detect CPU port writes for HIRAM hack
                            if adr(15 downto 1) = "000000000000000" and rw_latched= '0' then
                                cpu_port_changed <= true;
                            end if;

                            -- game and exrom can be overwritten by hacks
                            -- KERNAL hack: read from RAM for KERNAL hack
                            if cart_config(CART_CONFIG_KERNAL_HACK) = '1' then
                                if cart_config(CART_CONFIG_HIRAM_HACK) = '0' then
                                    -- without HIRAM hack (enable Ultimax mode, read always ROM; works for C128, too)
                                    if adr(15 downto 13) = "111" and ba = '1' and rw_latched = '1' then
                                        game <= '0';
                                        exrom <= '1';
                                    end if;
                                end if;
                            end if;
                            
                            -- BASIC hack: enable ROM for BASIC read
                            if cart_config(CART_CONFIG_BASIC_HACK) = '1' and not kernal_read_active then
                                if adr(15 downto 13) = "101" and ba = '1' and rw_latched = '1' then
                                    game <= '0';
                                    exrom <= '0';
                                end if;
                            end if;
                        end if;
                        state <= address_valid;

                    -- 161-201 ns after rising edge of s02
                    when address_valid =>
                        if s02_latched = '1' then
                            -- evaluate HIRAM detection (only for C64)
                            -- ROMH reflects hiram now
                            if kernal_read_active and cpu_port_changed then
                                hiram_state <= romh;
                                if romh = '1' then
                                    -- ram
                                    game  <= '1';
                                    exrom <= '1';
                                else
                                    -- rom
                                    game  <= '0';
                                    exrom <= '1'; -- Ultimax mode
                                end if;
                                cpu_port_changed <= false;
                            end if;
                        end if;
                        c64_a14 <= 'Z';
                        state <= delay3;

                    -- 202-242 ns after rising edge of s02
                    when delay3 =>
                        state <= delay4;

                    -- 243-283 ns after rising edge of s02
                    when delay4 =>
                        state <= delay5;

                    -- 284-324 ns after rising edge of s02
                    when delay5 =>
                        -- register write access
                        if s02_latched = '1' and rw_latched = '0' then
                            -- flash / RAM write
                            if flash_write = '1' and (romL_filtered = '0' or romH_filtered = '0') then
                                we <= '0';
                                flash_ce <= '0';
                            elsif ram_write = '1' and io2_filtered = '0' then
                                we <= '0';
                                ram_ce <= '0';
                            end if;
                        end if;
                        state <= delay6;

                    -- 325-365 ns after rising edge of s02
                    when delay6 =>
                        state <= delay7;

                    -- 366-486 ns after rising edge of s02
                    when delay7 =>
                        -- register write access
                        if s02_latched = '1' and rw_latched = '0' then
                            if io1_filtered = '0' then
                                if adr(7 downto 0) = x"39" then
                                    midi_address <= dt;
                                elsif adr(7 downto 0) = x"3a" then
                                    midi_config <= dt;
                                elsif adr(7 downto 0) = x"3b" then
                                    cart_control <= dt;
                                elsif adr(7 downto 0) = x"3c" then
                                    cart_config <= dt;
                                elsif adr(7 downto 0) = x"3d" then
                                    flash_address_extension <= dt;
                                elsif adr(7 downto 0) = x"3e" then
                                    ram_address_extension <= dt;
                                elsif adr(7 downto 0) = x"3f" then
                                    address_extension2 <= dt;
                                elsif adr(7 downto 4) = "0000" then
                                    if cart_config(CART_CONFIG_EASYFLASH) = '1' then
                                        -- EasyFlash mode
                                        if adr(3 downto 0) = x"0" then
                                            -- $de00
                                            flash_address_extension <= "00" & dt(5 downto 0);
                                        elsif adr(3 downto 0) = x"2" then
                                            -- $de02
                                            easyflashLed <= dt(7);
                                            cart_control(CART_CONTROL_EXROM) <= not dt(1);
                                            cart_control(CART_CONTROL_GAME) <= not dt(0);
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;

                        -- stop flash / RAM write
                        if flash_write = '1' then
                            we <= '1';
                            flash_ce <= '1';
                        elsif ram_write = '1' then
                            we <= '1';
                            ram_ce <= '1';
                        end if;

                        state <= idle;
                end case;

                -- set default for exrom and game with rising edge of s02
                if s02 = '1' and prev_s02 = '0' then
                    exrom <= cart_control(CART_CONTROL_EXROM);
                    game <= cart_control(CART_CONTROL_GAME);
                end if;
                
                -- and set default for VIC, if KERNAL or BASIC hack is active
                if s02 = '0' and (cart_config(CART_CONFIG_BASIC_HACK) = '1' or cart_config(CART_CONFIG_KERNAL_HACK) = '1') then
                    exrom <= cart_control(CART_CONTROL_EXROM);
                    game <= cart_control(CART_CONTROL_GAME);
                end if;
                
                -- memory access allowed from address_valid state until s02=0
                if mem_access_allowed then
                    -- prepare RAM/flash access
                    if io2_filtered = '0' and rw_latched = '0' and s02_latched = '1' then
                        ram_write <= '1';
                    end if;
                    if (romL_filtered = '0' or romH_filtered = '0') and rw_latched = '0' and s02_latched = '1' then
                        flash_write <= '1';
                    end if;

                    -- RAM/flash read
                    -- special case for C128: ignore rw=0 for s02=0, because it is wrong
                    if (s02_latched = '0') or (rw_latched = '1') then
                        if (((romL_filtered = '0') or (romH_filtered = '0')) and cart_config(CART_CONFIG_RAM_AS_ROM) = '1') or (io2_filtered = '0') then
                            we <= '1';
                            ram_ce <= '0';
                            oe <= '0';
                            dir <= '1';
                        elsif (romL_filtered = '0') or (romH_filtered = '0') then
                            we <= '1';
                            flash_ce <= '0';
                            oe <= '0';
                            dir <= '1';
                        end if;
                    end if;
                end if;

                -- if there is some activiy on the RX/TX lines, restart afterglow counter
                if mc6850_txData = '0' or mc6850_rxData = '0' then
                    if mc6850_rxData = '0' then
                        led1_afterglow <= '1';
                    end if;
                    if mc6850_txData = '0' then
                        led2_afterglow <= '1';
                    end if;
                    afterglow_counter <= AFTERGLOW_COUNTER_MAX;
                end if;

                -- cycle start detection
                if s02_latched /= prev_s02 then
                    if afterglow_counter > 0 then
                        afterglow_counter <= afterglow_counter - 1;
                    else
                        led1_afterglow <= '0';
                        led2_afterglow <= '0';
                    end if;
                    
                    -- disable outputs on cycle start
                    dir <= '0';
                    oe <= '1';
                    flash_ce <= '1';
                    ram_ce <= '1';
                    
                    -- init variables
                    flash_write <= '0';
                    ram_write <= '0';
                    mem_access_allowed <= false;
                    kernal_read_active <= false;
                    state <= delay;
                end if;
                
            end if;

        end if;

    end process;

    -- MIDI, LEDs and IRQs, not clocked
    process(reset, midi_config, io1_filtered, s02_latched, rw_latched, adr, midi_address, mc6850_rxData, mc6850_txData, mc6850_irq, cart_config, easyflashLed, cart_control)
    begin
        if reset = '0' then
            mc6850_CS2 <= '1';
            led1 <= '1';
            led2 <= '1';
            irq <= 'Z';
            nmi <= 'Z';
        else
            -- MIDI access
            -- "chip select setup time before E" is violated, because the C64 address is not stable at that moment,
            -- but all other timings are met, so the MC68B50 has enough time to sample the address and for data IO
            mc6850_CS2 <= '1';
            if midi_config(MIDI_CONFIG_ENABLE) = '1' and io1_filtered = '0' and s02_latched = '1' then
                if rw_latched = '0' then
                    -- write
                    if adr(7 downto 4) = "0000" and (adr(3 downto 1) = midi_address(7 downto 5) or midi_address(7 downto 5) = "111") then
                        mc6850_CS2 <= '0';
                    end if;
                else
                    -- read
                    if adr(7 downto 4) = "0000" and (adr(3 downto 1) = midi_address(3 downto 1) or midi_address(3 downto 1) = "111") then
                        mc6850_CS2 <= '0';
                    end if;
                end if;
            end if;
            midiThru <= (not midi_config(MIDI_CONFIG_THRU_OUT) or mc6850_txData) and (not midi_config(MIDI_CONFIG_THRU_IN) or mc6850_rxData);

            -- LED defaults
            led1 <= led1_afterglow;
            led2 <= led2_afterglow;

            -- IRQ/NMI if not in EasyFlash mode
            irq <= 'Z';
            nmi <= 'Z';
            if mc6850_irq = '0' then
                if midi_config(MIDI_CONFIG_IRQ) = '1' then
                    irq <= '0';
                end if;
                if midi_config(MIDI_CONFIG_NMI) = '1' then
                    nmi <= '0';
                end if;
            end if;

            -- LED2 EasyFlash overwrite
            if cart_config(CART_CONFIG_EASYFLASH) = '1' then
                -- EasyFlash mode
                if easyflashLed = '1' then
                    led2 <= '1';
                end if;
            end if;

            -- global LED overwrite
            if cart_control(CART_CONTROL_LED1) = '1' then
                led1 <= '1';
            end if;
            if cart_control(CART_CONTROL_LED2) = '1' then
                led2 <= '1';
            end if;
        end if;

    end process;

    -- generate address
    process(io2, address_extension2, ram_address_extension, cart_config, flash_address_extension, adr, romL, romH)
    begin
        at(20 downto 8) <= (others => '0');
        if io2 = '0' then
            -- RAM address
            at(16 downto 8) <= address_extension2(ADDRESS_EXTENSION2_RAM) & ram_address_extension;
        else
            -- flash address
            if cart_config(CART_CONFIG_EASYFLASH) = '0' then
                if cart_config(CART_CONFIG_RAM_AS_ROM) = '0' then
                    -- standard mode
                    at(20 downto 13) <= flash_address_extension;
                    at(12 downto 8) <= adr(12 downto 8);
                else
                    -- RAM as ROM mode
                    at(15 downto 8) <= adr(15 downto 8);
                end if;
            else
                -- EasyFlash mode
                at(18 downto 13) <= flash_address_extension(5 downto 0);
                at(12 downto 8) <= adr(12 downto 8);
                if romL = '0' then
                    at(19) <= '0';
                elsif romH = '0' then
                    at(19) <= '1';
                end if;
                at(20) <= address_extension2(ADDRESS_EXTENSION2_FLASH);
            end if;
        end if;
    end process;

    -- generate filtered outputs
    romL_filtered <= '0' when romL_latched = "00" else '1';
    romH_filtered <= '0' when romH_latched = "00" else '1';
    io1_filtered <= '0' when io1_latched = "00" else '1';
    io2_filtered <= '0' when io2_latched = "00" else '1';

    -- fixed connections
    mc6850_rs <= adr(0);
    at(7 downto 0) <= adr(7 downto 0);

    -- internal helper signal
    adr <= c64_a15 & c64_a14 & c64_a;
    
end architecture rtl;
