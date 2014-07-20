library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
	port(
		-- LEDs
		led1: out std_logic;
		led2: out std_logic;
		
		-- 24 MHz input clock
		clk24: in std_logic;
		
		-- RAM/flash
		at: out std_logic_vector(20 downto 0);
		flashCE: out std_logic;
		ramCE: out std_logic;
		we: out std_logic;
		oe: out std_logic;

		-- data bus
		dt: inout std_logic_vector(7 downto 0);
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
		a: in std_logic_vector(15 downto 0);
		romL: in std_logic;
		romH: in std_logic;
		exRom: inout std_logic;
		game: inout std_logic;
		reset: in std_logic;
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
signal address_extension: std_logic_vector(7 downto 0);
signal address_extension2: std_logic_vector(7 downto 0);

-- bits
constant MIDI_CONFIG_IRQ : integer := 0;
constant MIDI_CONFIG_NMI : integer := 1;
constant MIDI_CONFIG_CLOCK : integer := 2;
constant MIDI_CONFIG_THRU : integer := 3;
constant MIDI_CONFIG_ENABLE : integer := 4;
constant CART_CONTROL_GAME : integer := 0;
constant CART_CONTROL_EXROM : integer := 1;
constant CART_CONTROL_LED1 : integer := 2;
constant CART_CONTROL_LED2 : integer := 3;
constant CART_CONTROL_RESET : integer := 4;
constant CART_CONFIG_RAM : integer := 0;
constant CART_CONFIG_KERNAL_HACK : integer := 1;
constant CART_CONFIG_HIGHRAM_HACK : integer := 2;
constant CART_CONFIG_EASYFLASH : integer := 3;
constant CART_CONFIG_RAM_AS_ROM : integer := 4;
constant ADDRESS_EXTENSION2_A16 : integer := 0;
constant ADDRESS_EXTENSION2_A20 : integer := 1;

signal io1_latched: std_logic_vector(2 downto 0);
signal io2_latched: std_logic_vector(2 downto 0);
signal s02_latched: std_logic_vector(2 downto 0);
signal romL_latched: std_logic_vector(2 downto 0);
signal romH_latched: std_logic_vector(2 downto 0);
signal rw_latched: std_logic;
signal easyflashLed: std_logic;

signal ramWrite: std_logic := '0';
signal ramRead: std_logic := '0';

signal flashWrite: std_logic := '0';
signal flashRead: std_logic := '0';

signal counter: integer range 0 to 23;
signal mc6850_clkBuffer: std_logic;

signal prev_phi2:       std_logic;
signal phi2_s:          std_logic;
signal cycle_time:     std_logic_vector(10 downto 0);
signal cycle_middle: std_logic;
signal reset_i: std_logic;
signal romL_filtered: std_logic;
signal romH_filtered: std_logic;
signal io1_filtered: std_logic;
signal io2_filtered: std_logic;
signal s02_filtered: std_logic;

begin

    ---------------------------------------------------------------------------
    -- Create a synchronized version of Phi2 (phi2_s) and a copy of phi2_s
    -- which is delayed by one clock cycle (prev_phi2).
    ---------------------------------------------------------------------------
    synchronize_stuff: process(clk24)
    begin
        if rising_edge(clk24) then
            prev_phi2 <= phi2_s;
            phi2_s <= s02;
            reset_i <= reset;

            -- filter IO and ROML/ROMH glitches: max. measured glitch is 20 ns, filter for 83 ns
            io1_latched <= io1_latched(1 downto 0) & io1;
            io2_latched <= io2_latched(1 downto 0) & io2;

            -- ROMH is still low for 60 ns after rising edge of s02, if the VIC access the memory in Ultimax mode, mask it
            romL_latched <= romL_latched(1 downto 0) & (not ((not romL) and s02_filtered and s02));
            romH_latched <= romH_latched(1 downto 0) & (not ((not romH) and s02_filtered and s02));
            
            -- latch inputs
            s02_latched <= s02_latched(1 downto 0) & s02;
            rw_latched <= rw;

            -- generate filtered outputs
            if romL_latched = "000" then
                romL_filtered <= '0';
            else
                romL_filtered <= '1';
            end if;
            if romH_latched = "000" then
                romH_filtered <= '0';
            else
                romH_filtered <= '1';
            end if;
            if io1_latched = "000" then
                io1_filtered <= '0';
            else
                io1_filtered <= '1';
            end if;
            if io2_latched = "000" then
                io2_filtered <= '0';
            else
                io2_filtered <= '1';
            end if;
            if s02_latched = "000" then
                s02_filtered <= '0';
            else
                s02_filtered <= '1';
            end if;
        end if;

    end process synchronize_stuff;

    ---------------------------------------------------------------------------
    -- count clk24 cycles in both phases of phi2 with a shift register
    ---------------------------------------------------------------------------
    clk_time_shift: process(clk24, prev_phi2, phi2_s)
    begin
        if rising_edge(clk24) then
            if prev_phi2 /= phi2_s then
                cycle_time <= (others => '0');
                cycle_time(0) <= '1';
            else
                cycle_time <= cycle_time(9 downto 0) & '0';
            end if;
        end if;
    end process;

	process(flashWrite, flashRead, ramWrite, ramRead, rw, romL, romH, io2, cart_config, address_extension, address_extension2, s02, cycle_middle, a)
	begin
        -- generate address
        at(20 downto 8) <= (others => '0');
        if io2 = '0' then
            -- RAM address
            if cart_config(CART_CONFIG_EASYFLASH) = '0' then
                -- standard mode
                at(16 downto 8) <= address_extension2(ADDRESS_EXTENSION2_A16) & address_extension;
            else
                -- EasyFlash mode
                at(16 downto 8) <= (others => '0');
            end if;
        else
            -- flash address
            if cart_config(CART_CONFIG_EASYFLASH) = '0' then
                if cart_config(CART_CONFIG_RAM_AS_ROM) = '0' then
                    -- standard mode
                    at(20 downto 13) <= address_extension;
                    at(12 downto 8) <= a(12 downto 8);
                else
                    -- RAM as ROM mode
                    at(12 downto 8) <= a(12 downto 8);
                    if romL = '0' then
                        at(13) <= '0';
                    elsif romH = '0' then
                        at(13) <= '1';
                    end if;
                end if;
            else
                -- EasyFlash mode
                at(18 downto 13) <= address_extension(5 downto 0);
                at(12 downto 8) <= a(12 downto 8);
                if romL = '0' then
                    at(19) <= '0';
                elsif romH = '0' then
                    at(19) <= '1';
                end if;
                at(20) <= address_extension2(ADDRESS_EXTENSION2_A20);
            end if;
        end if;

        -- generate read/write signals
        dir <= '0';
        ramCE <= '1';
        oe <= '1';
        flashCE <= '1';
        we <= rw;
        if s02 = '1' then
            if flashWrite = '1' and rw = '0' and (romL = '0' or romH = '0') and cycle_middle = '1' then
                flashCE <= '0';
            elsif ramWrite = '1' and rw = '0' and io2 = '0' and cycle_middle = '1' then
                ramCE <= '0';
            elsif flashRead = '1' and rw = '1' and (romL = '0' or romH = '0') then
                flashCE <= '0';
                oe <= '0';
                dir <= '1';
            elsif ramRead = '1' and rw = '1' and
                (io2 = '0' or 
                ((romL = '0' or romH = '0') and cart_config(CART_CONFIG_RAM_AS_ROM) = '1'))
            then
                ramCE <= '0';
                oe <= '0';
                dir <= '1';
            end if;
        end if;

    end process;
    
	process(clk24, mc6850_rxData, mc6850_irq, rw, s02, a, reset, midi_config, mc6850_txData)
	begin
		-- 68B50 MIDI
        if midi_config(MIDI_CONFIG_THRU) = '1' then
            midiThru <= mc6850_txData;
        else
            midiThru <= mc6850_rxData;
        end if;
		mc6850_rs <= a(0);

		if rising_edge(clk24) then 
            if reset_i = '0' then
                cart_control <= "00000001";  -- game = 1, exrom = 0
                midi_config <= (others => '0');
                midi_config <= "00010101";
                midi_address <= (others => '0');
                midi_address <= "01000110";
                cart_config <= (others => '0');
                address_extension <= (others => '0');
                address_extension2 <= (others => '0');
                dt <= (others => 'Z');
                exRom <= 'Z';
                game <= 'Z';
                irq <= 'Z';
                nmi <= 'Z';
                mc6850_rxTxClk <= '0';
                easyflashLed <= '0';
                ramWrite <= '0';
                ramRead <= '0';
                flashWrite <= '0';
                flashRead <= '0';
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
				
				mc6850_CS2 <= '1';
				
				-- defaults
				irq <= 'Z';
				nmi <= 'Z';
				dt <= (others => 'Z');
                ramWrite <= '0';
                ramRead <= '0';
                flashWrite <= '0';
                flashRead <= '0';
                led1 <= not mc6850_rxData;
                led2 <= '0';

                -- IRQ/NMI if not in EasyFlash mode
                if mc6850_irq = '0' and cart_config(CART_CONFIG_EASYFLASH) = '0' then
					if midi_config(MIDI_CONFIG_IRQ) = '1' then
						irq <= '0';
					end if;
					if midi_config(MIDI_CONFIG_NMI) = '1' then
						nmi <= '0';
					end if;
                    led2 <= not mc6850_txData;
				end if;

                -- LED2
				if cart_config(CART_CONFIG_EASYFLASH) = '1' then
                    -- EasyFlash mode
                    led2 <= easyflashLed;
                else
                    -- from 6850
                    led2 <= not mc6850_txData;
				end if;

				-- RAM access
				if io2_filtered = '1' and cart_config(CART_CONFIG_RAM) = '1' then
                    if rw_latched = '0' then
                        ramWrite <= '1';
                    else
                        ramRead <= '1';
                    end if;
				end if;

				-- register write access
				if io1_filtered = '0' then
					if a(7 downto 0) = x"3a" then
						if rw_latched = '0' and cycle_middle = '1' then
							midi_address <= dt;
						end if;
					elsif a(7 downto 0) = x"3b" then
						if rw_latched = '0' and cycle_middle = '1' then
							midi_config <= dt;
						end if;
					elsif a(7 downto 0) = x"3c" then
						if rw_latched = '0' and cycle_middle = '1' then
							cart_control <= dt;
						end if;
					elsif a(7 downto 0) = x"3d" then
						if rw_latched = '0' and cycle_middle = '1' then
							cart_config <= dt;
						end if;
					elsif a(7 downto 0) = x"3e" then
						if rw_latched = '0' and cycle_middle = '1' then
							address_extension <= dt;
						end if;
					elsif a(7 downto 0) = x"3f" then
						if rw_latched = '0' and cycle_middle = '1' then
							address_extension2 <= dt;
						end if;
					elsif a(7 downto 4) = "0000" then
                        if cart_config(CART_CONFIG_EASYFLASH) = '1' then
                            -- EasyFlash mode
                            if rw_latched = '0' and cycle_middle = '1' then
                                if a(3 downto 0) = x"0" then
                                    -- $de00
                                    address_extension <= "00" & dt(5 downto 0);
                                elsif a(3 downto 0) = x"2" then
                                    -- $de02
                                    easyflashLed <= dt(7);
                                    cart_control(CART_CONTROL_EXROM) <= not dt(1);
                                    cart_control(CART_CONTROL_GAME) <= not dt(0);
                                end if;
                            end if;
                        elsif midi_config(MIDI_CONFIG_ENABLE) = '1' then
                            -- MIDI access
                            if rw_latched = '0' then
                                -- write
                                if a(7 downto 4) = "0000" and (a(3 downto 1) = midi_address(7 downto 5) or midi_address(7 downto 5) = "111") then
                                    mc6850_CS2 <= '0';
                                end if;
                            else
                                -- read
                                if a(7 downto 4) = "0000" and (a(3 downto 1) = midi_address(3 downto 1) or midi_address(3 downto 1) = "111") then
                                    mc6850_CS2 <= '0';
                                end if;
                            end if;
                        end if;
                    end if;
				end if;
				
				-- flash access
				if cart_config(CART_CONFIG_EASYFLASH) = '0' then
                    -- standard mode
                    if cart_config(CART_CONFIG_RAM_AS_ROM) = '0' then
                        if romL_filtered = '0' then
                            if rw_latched = '0' then
                                flashWrite <= '1';
                            else
                                flashRead <= '1';
                            end if;
                        end if;
                    else
                        -- RAM as ROM mode
                        if (romL_filtered = '0' or romH_filtered = '0') and rw_latched = '1' then
                            ramRead <= '1';
                        end if;
                    end if;
                else
                    -- EasyFlash mode
                    if romL_filtered = '0' or romH_filtered = '0' then
                        if rw_latched = '0' then
                            flashWrite <= '1';
                        else
                            flashRead <= '1';
                        end if;
                    end if;
                end if;
				
				-- game and exrom
				if cart_control(CART_CONTROL_EXROM) = '0' then
					exRom <= '0';
				else
					exRom <= 'Z';
				end if;
				if cart_control(CART_CONTROL_GAME) = '0' then
					game <= '0';
				else
					game <= 'Z';
				end if;

				-- kernal hack: enable ultimax mode for kernal read
				--if a(15 downto 13) = "111" and s02 = '1' and ba = '1' and rw = '1' then
				--	game <= '0';
				--	exRom <= 'Z';
				--end if;

				--if romH = '0' and rw_latched = '1' and a(15 downto 13) = "111" then
					-- read from flash
				--	at(12 downto 8) <= a(12 downto 8);
				--	at(16) <= '1';
				--	we <= '1';
				--	flashCE <= '0';
				--	oe <= '0';
				--	dir <= '1';
				--end if;
                
                -- LED overwrite
                if cart_control(CART_CONTROL_LED1) = '1' then
                    led1 <= '1';
                end if;
                if cart_control(CART_CONTROL_LED2) = '1' then
                    led2 <= '1';
                end if;
				
			end if;
		end if;

	end process;
	
    cycle_middle <= cycle_time(3) or cycle_time(4) or cycle_time(5);
	at(7 downto 0) <= a(7 downto 0);

end architecture rtl;
