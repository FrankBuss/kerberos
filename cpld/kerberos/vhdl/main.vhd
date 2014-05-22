library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- mconfig (0xdf3d, 57149)
-- 0: enable MIDI IRQ
-- 1: enable MIDI NMI
-- 2: MIDI clock: 0 = 500 kHz, 1 = 2 MHz
-- 3: MIDI thru: 0 = MIDI in, 1 = MIDI out
-- 4-5: read offset: 0 => any, 1 => 2, 2 => 6, 3 => 8
-- 6-7: write offset: 0 => any, 1 => 0, 2 => 4, 3 => 8

-- control (0xdf3e, 57150)
-- 0: game level
-- 1: exrom level
-- 2: 1: RAM enabled
-- 3: 1: MIDI enabled
-- 4: a16: RAM address 16

-- address extension (0xdf3f, 57151)

-- RAM bank: a16 & address extension
-- content: 0xde00-0xdeff (56832-57087)

-- MIDI interfaces:
-- SEQUENTIAL CIRCUITS INC. 
-- 500 kHz
-- IRQ
-- control: $de00
-- status: $de02
-- tx: $de01
-- tx: $de03


entity main is
	port(
		-- LEDs
		led1: out std_logic;
		led2: out std_logic;
		
		-- 48 MHz input clock
		clk: in std_logic;
		
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

signal control: std_logic_vector(4 downto 0);
signal mconfig: std_logic_vector(7 downto 0);
signal io1_latched: std_logic_vector(2 downto 0);
signal io2_latched: std_logic_vector(2 downto 0);
signal s02_latched: std_logic;
signal romL_latched: std_logic;
signal rw_latched: std_logic;

signal counter: integer range 0 to 47;
signal mc6850_clkBuffer: std_logic;

begin

	process(clk, mc6850_rxData, mc6850_irq, rw, s02)
	begin
		-- 68B50 MIDI
		midiThru <= mc6850_rxData;  -- mc6850_txData
		mc6850_rs <= a(0);

		-- C64 expansion port
		--s02: in std_logic;
		--io1: in std_logic;
		--io2: in std_logic;
		--a: in std_logic_vector(15 downto 0);
		--romL: in std_logic;
		--romH: in std_logic;
		-- reset 
		-- rw: in std_logic;
		
		if reset = '0' then
			control <= "01001";  -- game = 1, exrom = 0, enable MIDI
			--control <= "01011";  -- game = 1, exrom = 1, enable MIDI
			mconfig <= "00000101";  -- enable IRQ, 2 MHz (Datel emulation, with any address)
			dir <= '0';
			ramCE <= '1';
			oe <= '1';
			flashCE <= '1';
			dt <= (others => 'Z');
			exRom <= 'Z';
			game <= 'Z';
			irq <= 'Z';
			nmi <= 'Z';
			mc6850_rxTxClk <= '0';
			at(20 downto 8) <= (others => '0');
		else
			if rising_edge(clk) then 
				-- generate clock for the MC6850
				if mconfig(2) = '1' then
					-- 2 MHz
					if counter = 11 then
						counter <= 0;
						mc6850_clkBuffer <= not mc6850_clkBuffer;
					else
						counter <= counter + 1;
					end if;
				else
					-- 500 kHz
					if counter = 47 then
						counter <= 0;
						mc6850_clkBuffer <= not mc6850_clkBuffer;
					else
						counter <= counter + 1;
					end if;
				end if;
				mc6850_rxTxClk <= mc6850_clkBuffer;
				
				mc6850_CS2 <= '1';
				
				-- IRQ/NMI
				irq <= 'Z';
				nmi <= 'Z';
				if mc6850_irq = '0' then
					if mconfig(0) = '1' then
						irq <= '0';
					end if;
					if mconfig(1) = '1' then
						nmi <= '0';
					end if;
				end if;

				-- data bus
				dt <= (others => 'Z');

				-- RAM/flash
				dir <= '0';
				ramCE <= '1';
				oe <= '1';
				flashCE <= '1';
				
				-- filter IO glitches: max. measured glitch is 20 ns, filter for 62.5 ns
				io1_latched <= io1_latched(1 downto 0) & io1;
				io2_latched <= io2_latched(1 downto 0) & io2;
				
				s02_latched <= s02;
				rw_latched <= rw;
				romL_latched <= romL;
				
				-- register access
				if io2_latched = "000" then
					if a(7 downto 0) = x"3d" then
						if rw_latched = '0' then
							-- write mconfig register
							mconfig <= dt;
						end if;
					elsif a(7 downto 0) = x"3e" then
						if rw_latched = '0' then
							-- write control register
							control <= dt(4 downto 0);
						--else
							-- read control register
						--	dir <= '1';
						--	dt <= control;
						end if;
					elsif a(7 downto 0) = x"3f" then
						if rw_latched = '0' then
							-- write address extension
							if control(2) = '1' then
								-- RAM
								at(16 downto 8) <= control(4) & dt;
							else
								-- flash
								at(20 downto 13) <= dt;
							end if;
						--else
							-- read address extension
						--	dir <= '1';
						--	dt <= addressExtension;
						end if;
					end if;
				end if;

				-- RAM access
				if io1_latched = "000" then
					if control(2) = '1' then
						if rw_latched = '0' then
							-- write to RAM
							ramCE <= '0';
						else
							-- read from RAM
							ramCE <= '0';
							oe <= '0';
							dir <= '1';
						end if;
					else
						-- MIDI access
						if rw_latched = '0' then
							case mconfig(7 downto 6) is
								when "00" =>
									if a(7 downto 4) = "0000" then
										mc6850_CS2 <= '0';
									end if;
								when "01" =>
									if a(7 downto 1) = "0000000" then
										mc6850_CS2 <= '0';
									end if;
								when "10" =>
									if a(7 downto 1) = "0000010" then
										mc6850_CS2 <= '0';
									end if;
								when "11" =>
									if a(7 downto 1) = "0000100" then
										mc6850_CS2 <= '0';
									end if;
								when others => null;
							end case;
						else
							case mconfig(5 downto 4) is
								when "00" =>
									if a(7 downto 4) = "0000" then
										mc6850_CS2 <= '0';
									end if;
								when "01" =>
									if a(7 downto 1) = "0000001" then
										mc6850_CS2 <= '0';
									end if;
								when "10" =>
									if a(7 downto 1) = "0000011" then
										mc6850_CS2 <= '0';
									end if;
								when "11" =>
									if a(7 downto 1) = "0000100" then
										mc6850_CS2 <= '0';
									end if;
								when others => null;
							end case;
						end if;
					end if;
				end if;
				
				-- flash access
				we <= '1';
				if romL_latched = '0' and s02_latched = '1' then
					at(12 downto 8) <= a(12 downto 8);
					we <= rw;
					if rw_latched = '0' then
						-- write to flash
						flashCE <= '0';
					else
						-- read from flash
						flashCE <= '0';
						oe <= '0';
						dir <= '1';
					end if;
				end if;
				
				-- game and exrom
				if control(1) = '0' then
					exRom <= '0';
				else
					exRom <= 'Z';
				end if;
				if control(0) = '0' then
					game <= '0';
				else
					game <= 'Z';
				end if;
				
				-- kernal hack: enable ultimax mode for kernal read
--				if a(15 downto 13) = "111" and s02 = '1' and ba = '1' and rw = '1' then
--					game <= '0';
--					exRom <= 'Z';
--				end if;

--				if romH = '0' and rw_latched = '1' then
--					-- read from flash
--					at(12 downto 8) <= a(12 downto 8);
--					at(16) <= '1';
--					we <= '1';
--					flashCE <= '0';
--					oe <= '0';
--					dir <= '1';
--				end if;
				
			end if;
		end if;

	end process;
	
	led1 <= not mc6850_rxData;
	led2 <= not mc6850_txData;
	at(7 downto 0) <= a(7 downto 0);

end architecture rtl;
