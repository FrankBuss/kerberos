#![no_std]
#![no_main]

use bsp::{
    entry,
    hal::{
        self,
        clocks::{self, ClocksManager},
        gpio::{bank0::*, Floating, Input, Output, Pin, PullUp, PushPull},
    },
};
use cortex_m::{delay::Delay, Peripherals};
use defmt::*;
use defmt_rtt as _;
use embedded_hal::digital::v2::{InputPin, OutputPin, PinState};
use panic_probe as _;

// USB Device support
use usb_device::{class_prelude::*, prelude::*};

// USB Communications Class Device support
use usbd_serial::SerialPort;

// Used to demonstrate writing formatted strings
use core::{arch::asm, cell::RefCell, fmt::Write};
use heapless::String;
use heapless::Vec;

// Provide an alias for our BSP so we can switch targets quickly.
// Uncomment the BSP you included in Cargo.toml, the rest of the code does not need to change.
use rp_pico as bsp;
// use sparkfun_pro_micro_rp2040 as bsp;

use bsp::hal::{
    clocks::{init_clocks_and_plls, Clock},
    pac,
    sio::Sio,
    watchdog::Watchdog,
};

#[link_section = ".FLASH"]
const PROGRAM: &[u8] = include_bytes!("../fpga_project.bin");

static mut DELAY: Option<RefCell<Delay>> = None;

fn init_delay(core: Peripherals, frequency: u32) {
    unsafe {
        let delay = cortex_m::delay::Delay::new(core.SYST, frequency);

        DELAY = Some(RefCell::new(delay));
    }
}

fn delay_ms(milliseconds: u32) {
    unsafe {
        if let Some(delay_refcell) = DELAY.as_ref() {
            let mut delay = delay_refcell.borrow_mut();
            delay.delay_ms(milliseconds);
        }
    }
}

fn delay_cycles(mut cycles: u32) {
    unsafe {
        for i in 0..cycles {
            asm!("nop");
        }
    }
}

fn delay_us(microseconds: u32) {
    unsafe {
        if let Some(delay_refcell) = DELAY.as_ref() {
            let mut delay = delay_refcell.borrow_mut();
            delay.delay_us(microseconds);
        }
    }
}

pub struct PinManager {
    led_pin: Pin<Gpio15, Output<PushPull>>,
    jtag_sel_pin: Pin<Gpio0, Output<PushPull>>,
    jtag_tck_pin: Pin<Gpio1, Output<PushPull>>,
    jtag_tms_pin: Pin<Gpio2, Output<PushPull>>,
    jtag_tdi_pin: Pin<Gpio4, Output<PushPull>>,
    jtag_tdo_pin: Pin<Gpio3, Input<Floating>>,
/*/
    jtag_tms_pin: Pin<Gpio8, Output<PushPull>>,
    jtag_tdi_pin: Pin<Gpio9, Output<PushPull>>,
    jtag_tdo_pin: Pin<Gpio10, Input<Floating>>,
    jtag_tck_pin: Pin<Gpio11, Output<PushPull>>,
    */
    jtag_reconfig_pin: Pin<Gpio6, Output<PushPull>>,
    jtag_spare1_pin: Pin<Gpio7, Output<PushPull>>,
    jtag_done_pin: Pin<Gpio5, Input<PullUp>>,
}

// Generic methods to set and read pin states
fn set_pin_state<P: OutputPin>(pin: &mut P, state: u8) {
    {
        let this = pin.set_state(if state > 0 {
            PinState::High
        } else {
            PinState::Low
        });
        match this {
            Ok(t) => t,
            Err(_) => {}
        }
    };
}

fn read_pin_state<P: InputPin>(pin: &P) -> u8 {
    if {
        let this = pin.is_high();
        match this {
            Ok(t) => t,
            Err(_) => false,
        }
    } {
        1
    } else {
        0
    }
}

impl PinManager {
    pub fn new(pins: bsp::Pins) -> Self {
        PinManager {
            led_pin: pins.gpio15.into_push_pull_output(),
            jtag_sel_pin: pins.gpio0.into_push_pull_output_in_state(PinState::High),
            jtag_tms_pin: pins.gpio2.into_push_pull_output(),
            jtag_tdi_pin: pins.gpio4.into_push_pull_output(),
            jtag_tdo_pin: pins.gpio3.into_floating_input(),
            jtag_tck_pin: pins.gpio1.into_push_pull_output(),
            /*
            jtag_tms_pin: pins.gpio8.into_push_pull_output(),
            jtag_tdi_pin: pins.gpio9.into_push_pull_output(),
            jtag_tdo_pin: pins.gpio10.into_floating_input(),
            jtag_tck_pin: pins.gpio11.into_push_pull_output(),
            */
            jtag_reconfig_pin: pins.gpio6.into_push_pull_output(),
            jtag_spare1_pin: pins.gpio7.into_push_pull_output(),
            jtag_done_pin: pins.gpio5.into_pull_up_input(),
        }
    }

    // Output pin set methods
    pub fn set_led_pin(&mut self, state: u8) {
        set_pin_state(&mut self.led_pin, state);
    }

    pub fn set_jtag_sel_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_sel_pin, state);
    }

    pub fn set_jtag_tck_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_tck_pin, state);
    }

    pub fn set_jtag_tms_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_tms_pin, state);
    }

    pub fn set_jtag_tdi_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_tdi_pin, state);
    }

    pub fn set_jtag_reconfig_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_reconfig_pin, state);
    }

    pub fn set_jtag_spare1_pin(&mut self, state: u8) {
        set_pin_state(&mut self.jtag_spare1_pin, state);
    }

    // Input pin read methods
    pub fn read_jtag_tdo_pin(&self) -> u8 {
        read_pin_state(&self.jtag_tdo_pin)
    }

    pub fn read_jtag_done_pin(&self) -> u8 {
        read_pin_state(&self.jtag_done_pin)
    }
}

fn strobe(pin_manager: &mut PinManager, tms_value: u8) {
    pin_manager.set_jtag_tms_pin(tms_value);
    //delay_cycles(20);
    pin_manager.set_jtag_tck_pin(1);
    delay_cycles(5);
    pin_manager.set_jtag_tck_pin(0);
    delay_cycles(5);
}

fn jtag_reset(pin_manager: &mut PinManager) {
    for _ in 0..8 {
        strobe(pin_manager, 1);
    }
    strobe(pin_manager, 0);
}

fn jtag_send_instruction(pin_manager: &mut PinManager, instruction: u8) {
    strobe(pin_manager, 1);
    strobe(pin_manager, 1);
    strobe(pin_manager, 0);
    strobe(pin_manager, 0);

    for i in 0..8 {
        pin_manager.set_jtag_tdi_pin((instruction >> i) & 1);
        strobe(pin_manager, if i < 7 { 0 } else { 1 });
    }

    strobe(pin_manager, 1);
    strobe(pin_manager, 0);

    strobe(pin_manager, 0);
    strobe(pin_manager, 0);
    strobe(pin_manager, 0);
}

fn jtag_send_msb_array(pin_manager: &mut PinManager, bytes: &[u8]) {
    strobe(pin_manager, 1);
    strobe(pin_manager, 0);
    strobe(pin_manager, 0);

    for (i, &byte) in bytes.iter().enumerate() {
        for j in 0..8 {
            pin_manager.set_jtag_tdi_pin((byte >> (7 - j)) & 1);
            strobe(
                pin_manager,
                if j == 7 && i == bytes.len() - 1 { 1 } else { 0 },
            );
        }
    }

    strobe(pin_manager, 1);
    strobe(pin_manager, 0);
}

fn jtag_read_id(pin_manager: &mut PinManager) -> u32 {
    strobe(pin_manager, 0);
    strobe(pin_manager, 0);
    strobe(pin_manager, 0);

    strobe(pin_manager, 1);
    strobe(pin_manager, 0);

    let mut data: u32 = 0;
    for i in 0..32 {
        strobe(pin_manager, if i == 31 { 1 } else { 0 });
        data |= (pin_manager.read_jtag_tdo_pin() as u32) << i;
    }

    strobe(pin_manager, 1);
    strobe(pin_manager, 0);

    data
}

fn program_sram(pin_manager: &mut PinManager, bytes: &[u8]) {
    jtag_reset(pin_manager);

    // ConfigEnable
    jtag_send_instruction(pin_manager, 0x15);

    // Address Initialize
    jtag_send_instruction(pin_manager, 0x12);

    // Transfer Configuration Data
    jtag_send_instruction(pin_manager, 0x17);
    delay_ms(1);

    // transfer data
    jtag_send_msb_array(pin_manager, bytes);

    // Config Disable
    jtag_send_instruction(pin_manager, 0x3a);

    // Noop
    jtag_send_instruction(pin_manager, 0x02);
}

fn read_sram(
    pin_manager: &mut PinManager,
    address_size: usize,
    address_count: usize,
) -> Vec<u8, 141778> {
    jtag_reset(pin_manager);

    //let mut bytes = vec![0u8; address_size * address_count];
    let mut bytes = Vec::<u8, 141778>::new();

    // ConfigEnable
    jtag_send_instruction(pin_manager, 0x15);

    // Address Initialize
    jtag_send_instruction(pin_manager, 0x12);

    // SRAM Read
    jtag_send_instruction(pin_manager, 0x03);

    let mut pos = 0;
    for _ in 0..address_count {
        // the sequence is: Select-DR-Scan -> Capture-DR
        strobe(pin_manager, 1);
        strobe(pin_manager, 0);

        let mut data = 0;
        for j in 0..address_size {
            println!("{}", j);
            // last bit with TMS=1 to move to Exit1-DR
            strobe(pin_manager, if j == address_size - 1 { 1 } else { 0 });
            data |= (pin_manager.read_jtag_tdo_pin() << (j & 7));
            if (j & 7) == 7 {
                bytes[pos] = data;
                data = 0;
                pos += 1;
            }
        }

        // update-DR and then go back to idle
        strobe(pin_manager, 1);
        strobe(pin_manager, 0);
    }

    // Config Disable
    jtag_send_instruction(pin_manager, 0x3a);

    // Noop
    jtag_send_instruction(pin_manager, 0x02);

    bytes
}

fn erase_sram(pin_manager: &mut PinManager) {
    jtag_reset(pin_manager);

    // ConfigEnable
    jtag_send_instruction(pin_manager, 0x15);

    // SRAM Erase
    jtag_send_instruction(pin_manager, 0x05);

    // Noop
    jtag_send_instruction(pin_manager, 0x02);

    // delay 2 ms
    delay_ms(2);

    // SRAM Erase Done
    jtag_send_instruction(pin_manager, 0x09);

    // Config Disable
    jtag_send_instruction(pin_manager, 0x3a);

    // Noop
    jtag_send_instruction(pin_manager, 0x02);

    // wait a second (not needed?)
    delay_ms(1000);
}

fn jtag_read_status<B: usb_device::bus::UsbBus>(
    pin_manager: &mut PinManager,
    serial: &mut SerialPort<B>,
) {
    jtag_reset(pin_manager);
    jtag_send_instruction(pin_manager, 0x41);
    let id = jtag_read_id(pin_manager);

    let mut text: String<64> = String::new();
    writeln!(&mut text, "status: 0x{:08x}\r\n", id).unwrap();
    serial.write(text.as_bytes());
    if id & (1 << 13) > 0 {
        serial.write(b"Done Final bit set, FPGA running\r\n");
    }
}

fn jtag_read_code<B: usb_device::bus::UsbBus>(
    pin_manager: &mut PinManager,
    serial: &mut SerialPort<B>,
) {
    jtag_reset(pin_manager);
    jtag_send_instruction(pin_manager, 0x13);
    let id = jtag_read_id(pin_manager);

    let mut text: String<64> = String::new();
    writeln!(&mut text, "code: 0x{:08x}\r\n", id).unwrap();
    serial.write(text.as_bytes());
}

#[entry]
fn main() -> ! {
    info!("Program start");
    let mut pac = pac::Peripherals::take().unwrap();
    let core = pac::CorePeripherals::take().unwrap();
    let mut watchdog = Watchdog::new(pac.WATCHDOG);
    let sio = Sio::new(pac.SIO);

    // External high-speed crystal on the pico board is 12Mhz
    let clocks = init_clocks_and_plls(
        bsp::XOSC_CRYSTAL_FREQ,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .ok()
    .unwrap();

    init_delay(core, clocks.system_clock.freq().to_Hz());

    let pins = bsp::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    let mut pin_manager = PinManager::new(pins);

    // Set up the USB driver
    let usb_bus = UsbBusAllocator::new(hal::usb::UsbBus::new(
        pac.USBCTRL_REGS,
        pac.USBCTRL_DPRAM,
        clocks.usb_clock,
        true,
        &mut pac.RESETS,
    ));

    // Set up the USB Communications Class Device driver
    let mut serial = SerialPort::new(&usb_bus);

    // Create a USB device with a fake VID and PID
    let mut usb_dev = UsbDeviceBuilder::new(&usb_bus, UsbVidPid(0x16c0, 0x27dd))
        .manufacturer("Frank Buss")
        .product("Kerberos 2")
        .serial_number("TEST")
        .device_class(2) // from: https://www.usb.org/defined-class-codes
        .build();

    let timer = hal::Timer::new(pac.TIMER, &mut pac.RESETS);
    let mut programmed = false;
    let mut connected = false;
    loop {
        // A welcome message at the beginning
        //            let _ = serial.write(b"Hello, World!\r\n");
        /*
                    let time = timer.get_counter().ticks();
                    let mut text: String<64> = String::new();
                    writeln!(&mut text, "Current timer ticks: {}", time).unwrap();

                    // This only works reliably because the number of bytes written to
                    // the serial port is smaller than the buffers available to the USB
                    // peripheral. In general, the return value should be handled, so that
                    // bytes not transferred yet don't get lost.
                    let _ = serial.write(text.as_bytes());
        */
        //            delay_ms(500);

        // Check for new data
        if usb_dev.poll(&mut [&mut serial]) {
            let mut buf = [0u8; 64];
            match serial.read(&mut buf) {
                Err(_e) => {
                    // Do nothing
                }
                Ok(0) => {
                    // Do nothing
                }
                Ok(count) => {
                    connected = true;
                    // read byte, output it, read inputs and return it
                    buf.iter_mut().take(count).for_each(|b| {
                        // output byte
                        pin_manager.set_jtag_sel_pin(*b & 0x01);
                        pin_manager.set_jtag_tck_pin(*b & 0x02);
                        pin_manager.set_jtag_tms_pin(*b & 0x04);
                        pin_manager.set_led_pin(*b & 0x08);
                        pin_manager.set_jtag_tdi_pin(*b & 0x10);
                        pin_manager.set_jtag_reconfig_pin(*b & 0x40);
                        pin_manager.set_jtag_spare1_pin(*b & 0x80);
                        delay_us(1);

                        // read pins
                        *b = 0;
                        if pin_manager.read_jtag_tdo_pin() > 0 {
                            *b |= 0x08
                        }
                        if pin_manager.read_jtag_done_pin() > 0 {
                            *b |= 0x20
                        }
                        delay_us(1);
                    });

                    // Send back to the host
                    let mut wr_ptr = &buf[..count];
                    while !wr_ptr.is_empty() {
                        match serial.write(wr_ptr) {
                            Ok(len) => wr_ptr = &wr_ptr[len..],
                            // On error, just drop unwritten data.
                            // One possible error is Err(WouldBlock), meaning the USB
                            // write buffer is full.
                            Err(_) => break,
                        };
                    }
                }
            }

            /*
            if connected {
                let _ = serial.write(b"Hello, World2!\r\n");
                let time = timer.get_counter().ticks();
                let mut text: String<64> = String::new();
                writeln!(&mut text, "Current timer ticks: {}\r\n", time).unwrap();

                // This only works reliably because the number of bytes written to
                // the serial port is smaller than the buffers available to the USB
                // peripheral. In general, the return value should be handled, so that
                // bytes not transferred yet don't get lost.
                let _ = serial.write(text.as_bytes());
                delay.delay_ms(500);
            }
            */

            if connected && !programmed {
                pin_manager.set_jtag_reconfig_pin(1);
                delay_ms(1);

                jtag_reset(&mut pin_manager);
                jtag_send_instruction(&mut pin_manager, 0x11);
                let id = jtag_read_id(&mut pin_manager);

                let mut text: String<64> = String::new();
                writeln!(&mut text, "Gowin FPGA ID: 0x{:08x}\r\n", id).unwrap();
                serial.write(text.as_bytes());
                delay_ms(1);
                jtag_read_status(&mut pin_manager, &mut serial);
                jtag_reset(&mut pin_manager);
                jtag_read_status(&mut pin_manager, &mut serial);

                // program SRAM
                //erase_sram(&mut pin_manager);
                program_sram(&mut pin_manager, &PROGRAM);
                jtag_read_code(&mut pin_manager, &mut serial);
                jtag_read_status(&mut pin_manager, &mut serial);

                // verify
                /*
                let address_size = 2296;
                let address_count = 494;
                let sram_read = read_sram(&mut pin_manager, address_size, address_count);
                */
                let sram_read = PROGRAM;
                if sram_read == PROGRAM {
                    serial.write("verify ok\r\n".as_bytes());
                } else {
                    serial.write("verify failed\r\n".as_bytes());
                }

                programmed = true;
                /* loop {
                    delay_ms(100);
                } */

                /*
                if id != 0x1100381b {
                    println!("wrong ID");
                    process::exit(1);
                }

                let mut f = File::open("/home/frank/data/tmp/fpga_project.bin").expect("Unable to open file");
                let mut program = Vec::new();
                f.read_to_end(&mut program).expect("Unable to read file");
                */
            }
        }
    }

    /*
    loop {
        info!("on!");
        led_pin.set_high().unwrap();
        delay.delay_ms(500);
        info!("off!");
        led_pin.set_low().unwrap();
        delay.delay_ms(500);
    }
    */
}
