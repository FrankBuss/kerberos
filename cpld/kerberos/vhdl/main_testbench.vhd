library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity main_testbench is
end;

architecture rtl of main_testbench is

-- register bits
constant MIDI_CONFIG_IRQ : std_logic_vector(7 downto 0) := x"01";
constant MIDI_CONFIG_NMI : std_logic_vector(7 downto 0) := x"02";
constant MIDI_CONFIG_CLOCK : std_logic_vector(7 downto 0) := x"04";
constant MIDI_CONFIG_THRU : std_logic_vector(7 downto 0) := x"08";
constant MIDI_CONFIG_ENABLE : std_logic_vector(7 downto 0) := x"10";
constant CART_CONTROL_GAME : std_logic_vector(7 downto 0) := x"01";
constant CART_CONTROL_EXROM : std_logic_vector(7 downto 0) := x"02";
constant CART_CONTROL_LED1 : std_logic_vector(7 downto 0) := x"04";
constant CART_CONTROL_LED2 : std_logic_vector(7 downto 0) := x"08";
constant CART_CONTROL_RESET : std_logic_vector(7 downto 0) := x"10";
constant CART_CONFIG_RAM : std_logic_vector(7 downto 0) := x"01";
constant CART_CONFIG_KERNAL_HACK : std_logic_vector(7 downto 0) := x"02";
constant CART_CONFIG_HIGHRAM_HACK : std_logic_vector(7 downto 0) := x"04";
constant CART_CONFIG_EASYFLASH : std_logic_vector(7 downto 0) := x"08";
constant CART_CONFIG_RAM_AS_ROM : std_logic_vector(7 downto 0) := x"10";
constant CART_CONFIG_BASIC_HACK : std_logic_vector(7 downto 0) := x"20";
constant ADDRESS_EXTENSION2_RAM : std_logic_vector(7 downto 0) := x"01";
constant ADDRESS_EXTENSION2_FLASH : std_logic_vector(7 downto 0) := x"02";

-- register addresses
constant MIDI_ADDRESS : std_logic_vector(15 downto 0) := x"de3a";
constant MIDI_CONFIG : std_logic_vector(15 downto 0) := x"de3b";
constant CART_CONTROL : std_logic_vector(15 downto 0) := x"de3c";
constant CART_CONFIG : std_logic_vector(15 downto 0) := x"de3d";
constant ADDRESS_EXTENSION : std_logic_vector(15 downto 0) := x"de3e";
constant ADDRESS_EXTENSION2 : std_logic_vector(15 downto 0) := x"de3f";

signal led1: std_logic;
signal led2: std_logic;
signal clk24:std_logic := '0';
signal at: std_logic_vector(20 downto 0) := (others => '0');
signal flashCE: std_logic := '1';
signal ramCE: std_logic := '1';
signal we: std_logic := '1';
signal oe: std_logic := '1';
signal dt: std_logic_vector(7 downto 0) := (others => 'Z');
signal dir: std_logic := '1';
signal midiThru: std_logic := '0';
signal mc6850_rxData: std_logic := '1';
signal mc6850_CS2: std_logic := '1';
signal mc6850_rxTxClk: std_logic := '1';
signal mc6850_txData: std_logic := '1';
signal mc6850_rs: std_logic := '1';
signal mc6850_irq: std_logic := '1';
signal ba: std_logic := '1';
signal s02: std_logic := '0';
signal io1: std_logic := '1';
signal io2: std_logic := '1';
signal a: std_logic_vector(15 downto 0) := (others => '0');
signal romL: std_logic := '1';
signal romH: std_logic := '1';
signal exRom: std_logic := '1';
signal game: std_logic := '1';
signal reset: std_logic := '1';
signal rw: std_logic := '1';
signal nmi: std_logic := '1';
signal irq: std_logic := '1';

begin
	main_instance: entity main
	port map (
        led1 => led1,
        led2 => led2,
        clk24 => clk24,
        at => at,
        flashCE => flashCE,
        ramCE => ramCE,
        we => we,
        oe => oe,
        dt => dt,
        dir => dir,
        midiThru => midiThru,
        mc6850_rxData => mc6850_rxData,
        mc6850_CS2 => mc6850_CS2,
        mc6850_rxTxClk => mc6850_rxTxClk,
        mc6850_txData => mc6850_txData,
        mc6850_rs => mc6850_rs,
        mc6850_irq => mc6850_irq,
        ba => ba,
        s02 => s02,
        io1 => io1,
        io2 => io2,
        a => a,
        romL => romL,
        romH => romH,
        exRom => exRom,
        game => game,
        reset => reset,
        rw => rw,
        nmi => nmi,
        irq => irq
	);

	clock24_process: process
	begin
		while true loop
			wait for 20 ns; clk24 <= not clk24;
		end loop;
	end process;
	
	clock1_process: process
	begin
		while true loop
			wait for 500 ns; s02 <= not s02;
		end loop;
	end process;
	
	stimulus: process
	procedure io1Write(address: std_logic_vector(15 downto 0); data: std_logic_vector(7 downto 0)) is
	begin
        -- wait for CPU cycle start and write to address
        wait until s02 = '1';
        rw <= '0';
        a <= address;
        dt <= data;
        io1 <= '0';
        
        -- wait for CPU cycle end and change to read again
        wait until s02 = '0';
        rw <= '1';
        dt <= (others => 'Z');
        io1 <= '1';
	end;
	procedure romhRead(address: std_logic_vector(15 downto 0)) is
	begin
        -- wait for CPU cycle start and read from address
        wait until s02 = '1';
        rw <= '1';
        a <= address;
        dt <= (others => 'Z');
        romh <= '0';
        
        -- wait for CPU cycle end
        wait until s02 = '0';
        dt <= (others => 'Z');
        romh <= '1';
	end;
	procedure memWrite(address: std_logic_vector(15 downto 0); data: std_logic_vector(7 downto 0)) is
	begin
        -- wait for CPU cycle start and write to address
        wait until s02 = '1';
        rw <= '0';
        a <= address;
        dt <= data;
        
        -- wait for CPU cycle end and change to read again
        wait until s02 = '0';
        rw <= '1';
        dt <= (others => 'Z');
	end;
	procedure memRead(address: std_logic_vector(15 downto 0)) is
	begin
        -- wait for CPU cycle start and read from address
        wait until s02 = '1';
        rw <= '1';
        a <= address;
        dt <= (others => 'Z');
        
        -- wait for CPU cycle end
        wait until s02 = '0';
        dt <= (others => 'Z');
	end;
	begin
		-- reset
		wait for 60 ns; reset  <= '0';
		wait for 60 ns; reset  <= '1';
        
        io1Write(CART_CONFIG, CART_CONFIG_RAM or CART_CONFIG_RAM_AS_ROM or CART_CONFIG_KERNAL_HACK);
        io1Write(CART_CONTROL, CART_CONTROL_GAME or CART_CONTROL_EXROM);
        romhRead(x"e000");
		
		wait for 10 us;

		-- show simulation end
		assert false report "no failure, simulation successful" severity failure;
		
	end process;

end;
