//! Blinks the LED on a Pico board
//!
//! This will blink an LED attached to GP25, which is the pin the Pico uses for the on-board LED.
#![no_std]
#![no_main]

use bsp::{
    entry,
    hal::{self},
};
use defmt::*;
use defmt_rtt as _;
use embedded_hal::digital::v2::{InputPin, OutputPin, PinState};
use panic_probe as _;

// USB Device support
use usb_device::{class_prelude::*, prelude::*};

// USB Communications Class Device support
use usbd_serial::SerialPort;

// Used to demonstrate writing formatted strings
//use core::fmt::Write;
//use heapless::String;

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

    let mut delay = cortex_m::delay::Delay::new(core.SYST, clocks.system_clock.freq().to_Hz());

    let pins = bsp::Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );

    let mut led_pin = pins.gpio15.into_push_pull_output();

    let mut jtag_sel_pin = pins.gpio0.into_push_pull_output_in_state(PinState::High);
    let mut jtag_tck_pin = pins.gpio1.into_push_pull_output();
    let mut jtag_tms_pin = pins.gpio2.into_push_pull_output();
    let jtag_tdo_pin = pins.gpio3.into_floating_input();
    let mut jtag_tdi_pin = pins.gpio4.into_push_pull_output();
    let jtag_done_pin = pins.gpio5.into_pull_up_input();
    let mut jtag_reconfig_pin = pins.gpio6.into_push_pull_output();
    let mut jtag_spare1_pin = pins.gpio7.into_push_pull_output();

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

    //let timer = hal::Timer::new(pac.TIMER, &mut pac.RESETS);
    //let mut said_hello = false;
    loop {
        // A welcome message at the beginning
        /*
        if !said_hello && timer.get_counter().ticks() >= 2_000_000 {
            said_hello = true;
            let _ = serial.write(b"Hello, World!\r\n");

            let time = timer.get_counter().ticks();
            let mut text: String<64> = String::new();
            writeln!(&mut text, "Current timer ticks: {}", time).unwrap();

            // This only works reliably because the number of bytes written to
            // the serial port is smaller than the buffers available to the USB
            // peripheral. In general, the return value should be handled, so that
            // bytes not transferred yet don't get lost.
            let _ = serial.write(text.as_bytes());
        }
        */

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
                    // read byte, output it, read inputs and return it
                    buf.iter_mut().take(count).for_each(|b| {
                        // output byte
                        jtag_sel_pin
                            .set_state(if *b & 0x01 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        jtag_tck_pin
                            .set_state(if *b & 0x02 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        jtag_tms_pin
                            .set_state(if *b & 0x04 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        led_pin
                            .set_state(if *b & 0x08 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        jtag_tdi_pin
                            .set_state(if *b & 0x10 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        jtag_reconfig_pin
                            .set_state(if *b & 0x40 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        jtag_spare1_pin
                            .set_state(if *b & 0x80 > 0 {
                                PinState::High
                            } else {
                                PinState::Low
                            })
                            .unwrap();
                        delay.delay_us(1);

                        // read pins
                        *b = 0;
                        if jtag_tdo_pin.is_high().unwrap() {
                            *b |= 0x08
                        }
                        if jtag_done_pin.is_high().unwrap() {
                            *b |= 0x20
                        }
                        delay.delay_us(1);
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

// End of file
