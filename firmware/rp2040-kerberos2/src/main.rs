//! Blinks the LED on a Pico board
//!
//! This will blink an LED attached to GP25, which is the pin the Pico uses for the on-board LED.
#![no_std]
#![no_main]

use defmt::*;
use defmt_rtt as _;
use embedded_hal::digital::v2::OutputPin;
use hal::pac;
use panic_probe as _;
use rp2040_hal as hal;
use rp2040_hal::clocks::init_clocks_and_plls;
use rp2040_hal::Clock;
use rp2040_hal::{gpio::Pins, watchdog::Watchdog, Sio};

#[cfg(feature = "rt")]
extern crate cortex_m_rt;
#[cfg(feature = "rt")]
pub use hal::entry;

/// The linker will place this boot block at the start of our program image. We
/// need this to help the ROM bootloader get our code up and running.
#[cfg(feature = "boot2")]
#[link_section = ".boot2"]
#[no_mangle]
#[used]
pub static BOOT2_FIRMWARE: [u8; 256] = rp2040_boot2::BOOT_LOADER_W25Q080;

#[hal::entry]
fn main() -> ! {
    info!("Program start");

    let mut pac = pac::Peripherals::take().unwrap();
    let mut watchdog = Watchdog::new(pac.WATCHDOG);
    const XOSC_CRYSTAL_FREQ: u32 = 12_000_000;
    let clocks = init_clocks_and_plls(
        XOSC_CRYSTAL_FREQ,
        pac.XOSC,
        pac.CLOCKS,
        pac.PLL_SYS,
        pac.PLL_USB,
        &mut pac.RESETS,
        &mut watchdog,
    )
    .ok()
    .unwrap();

    let sio = Sio::new(pac.SIO);
    let pins = Pins::new(
        pac.IO_BANK0,
        pac.PADS_BANK0,
        sio.gpio_bank0,
        &mut pac.RESETS,
    );
    // Set a pin to drive output
    let mut led_pin = pins.gpio25.into_push_pull_output();
    /*
        // Drive output to 3.3V
        output_pin.set_high().unwrap();
        // Drive output to 0V
        output_pin.set_low().unwrap();
        // Set a pin to input
        let input_pin = pins.gpio24.into_floating_input();
        // pinstate will be true if the pin is above 2V
        let pinstate = input_pin.is_high().unwrap();
        // pinstate_low will be true if the pin is below 1.15V
        let pinstate_low = input_pin.is_low().unwrap();
        // you'll want to pull-up or pull-down a switch if it's not done externally
        let button_pin = pins.gpio23.into_pull_down_input();
        let button2_pin = pins.gpio22.into_pull_up_input();
    */

    let core = pac::CorePeripherals::take().unwrap();
    let mut delay = cortex_m::delay::Delay::new(core.SYST, clocks.system_clock.freq().to_Hz());
    loop {
        led_pin.set_high().unwrap();
        delay.delay_ms(100);
        led_pin.set_low().unwrap();
        delay.delay_ms(100);
    }
}

// End of file
