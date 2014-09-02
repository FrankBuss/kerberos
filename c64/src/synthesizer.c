#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "util.h"
#include "midi.h"
#include "regs.h"

#define BACKGROUND_COLOR 0
#define TEXT_COLOR 14
#define CAPTION_COLOR 1

uint8_t waveform = 0;

// http://codebase64.org/doku.php?id=base:pal_frequency_table
const uint16_t freqTablePal[] = {
	// C       C#      D       D#      E       F       F#      G       G#      A       A#      B
	0x0117, 0x0127, 0x0139, 0x014b, 0x015f, 0x0174, 0x018a, 0x01a1, 0x01ba, 0x01d4, 0x01f0, 0x020e,  // 1
	0x022d, 0x024e, 0x0271, 0x0296, 0x02be, 0x02e8, 0x0314, 0x0343, 0x0374, 0x03a9, 0x03e1, 0x041c,  // 2
	0x045a, 0x049c, 0x04e2, 0x052d, 0x057c, 0x05cf, 0x0628, 0x0685, 0x06e8, 0x0752, 0x07c1, 0x0837,  // 3
	0x08b4, 0x0939, 0x09c5, 0x0a5a, 0x0af7, 0x0b9e, 0x0c4f, 0x0d0a, 0x0dd1, 0x0ea3, 0x0f82, 0x106e,  // 4
	0x1168, 0x1271, 0x138a, 0x14b3, 0x15ee, 0x173c, 0x189e, 0x1a15, 0x1ba2, 0x1d46, 0x1f04, 0x20dc,  // 5
	0x22d0, 0x24e2, 0x2714, 0x2967, 0x2bdd, 0x2e79, 0x313c, 0x3429, 0x3744, 0x3a8d, 0x3e08, 0x41b8,  // 6
	0x45a1, 0x49c5, 0x4e28, 0x52cd, 0x57ba, 0x5cf1, 0x6278, 0x6853, 0x6e87, 0x751a, 0x7c10, 0x8371,  // 7
	0x8b42, 0x9389, 0x9c4f, 0xa59b, 0xaf74, 0xb9e2, 0xc4f0, 0xd0a6, 0xdd0e, 0xea33, 0xf820, 0xffff,  // 8
};

uint8_t midiWaitAndReceiveByte()
{
	while (!midiByteReceived());
	return midiReadByte();
}

void noteOn(uint8_t channel, uint8_t note, uint8_t velocity)
{
	gotox(0);
	cclear(39);
	gotox(0);
	cprintf("note on, channel: %i note: %02x, vel: %02x", channel, note, velocity);
	
	// only 8 octaves, 96 notes, defined
	if (note > 96) return;
		
	// set frequency	
	SID.v1.freq = freqTablePal[note];
	
	// ADSR
	SID.v1.ad = 0x11;
	SID.v1.sr = 0xd6;
		
	// start noise (0x81), square (0x41), sawtooth (0x21) or triangle (0x11), based on channel
	waveform = (0x10 << (channel & 3)) | 1;
	SID.v1.ctrl = waveform;
}

void noteOff()
{
	gotox(0);
	cclear(39);
	gotox(0);
	cputs("note off");
	SID.v1.ctrl = waveform & 0xfe;
}

int main(void)
{
	clrscr();
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(0, 0);
	textcolor(1);

	// test for Kerberos MIDI interface
	if (!midiIrqNmiTest()) {
		cputs("MIDI IRQ not working\r\n");
		return -1;
	}
	
	// init Namesoft MIDI emulation
	midiInit();

	// show instructions
	cputs("simple synthesizer demo\r\n");
	cputs("use MIDI channel 1-4 for waveform\r\n");
	cputs("\r\n");
	
	// reset SID
	memset(&SID, 0, sizeof(SID));
	
	// full amplitude
	SID.amp = 15;
	
	// pulse width
	SID.v1.pw = 0x100;

	// receive loop
	while (1) {
		// wait for first MIDI message byte
		uint8_t message;
		uint8_t channel;
		uint8_t note;
		uint8_t velocity;
		while (1) {
			message = midiWaitAndReceiveByte();
			if (message & 0x80) break;
		}
		channel = message & 0xf;
		
		// get note and velocity
		note = midiWaitAndReceiveByte();
		velocity = midiWaitAndReceiveByte();
		
		// evaluate message
		switch (message & 0xf0) {
			case 0x80:
				noteOff();
				break;
			case 0x90:
				if (velocity == 0) {
					noteOff();
				} else {
					noteOn(channel, note, velocity);
				}
				break;
		}
	}
	
	return 0;
}
