/*
 
SID tester
 
compile command line (with CC65, see http://www.cc65.org )
 
cl65 -O -t c64 sid-tester.c -o sid-tester.prg
 
testing in WinVICE:
 
"\Program Files\WinVICE-2.4-x64\x64.exe" sid.prg
 
*/
 
#include <stdio.h>
#include <conio.h>

#include "menu.h"

uint8_t* g_sidBase2 = (uint8_t*) 0xd400;
uint8_t g_baseX, g_baseY;
uint8_t g_waveforms = 15;
 
uint16_t g_freq[8] = {
	0x22cd,
	0x3424,
	0x459a
};
 
void setVolume(uint8_t volume)
{
	g_sidBase2[24] = volume | (1 << 4);
}
 
void initSid()
{
	uint8_t i = 0;
	for (i = 0; i < 24; i++) g_sidBase2[i] = 0;
	setVolume(15);
}
 
void setFrequency(uint8_t voice, uint16_t freqIndex)
{
	uint16_t freq = g_freq[freqIndex];
	g_sidBase2[7 * voice] = freq & 0xff;
	g_sidBase2[7 * voice + 1] = freq >> 8;
}
 
void setAdsr(uint8_t voice, uint8_t attack, uint8_t decay, uint8_t sustain, uint8_t release)
{
	g_sidBase2[7 * voice + 5] = (attack << 4) | decay;
	g_sidBase2[7 * voice + 6] = (sustain << 4) | release;
}
 
void shortDelay()
{
	long i;
	for (i = 0; i < 2; i++);
}
 
void delay()
{
	long i;
	for (i = 0; i < 200; i++);
}
 
void playOneTone(uint8_t voice, uint8_t freqIndex, uint8_t waveform)
{
	g_sidBase2[7 * voice + 3] = 7;
	setFrequency(voice, freqIndex);
	setAdsr(voice, 2, 1, 15, 1);
	g_sidBase2[7 * voice + 4] = waveform | 1;
	delay();
	g_sidBase2[7 * voice + 4] = waveform;
}

void playChord(uint8_t voice, uint8_t waveform)
{
	playOneTone(voice, 0, waveform);
	playOneTone(voice, 1, waveform);
	playOneTone(voice, 2, waveform);
}

void voiceTest(uint8_t voice)
{
	cprintf("testing voice %i...\n", voice + 1);
	if (g_waveforms & 1) playChord(voice, 1 << 4);
	if (g_waveforms & 2) playChord(voice, 1 << 5);
	if (g_waveforms & 4) playChord(voice, 1 << 6);
	if (g_waveforms & 8) playChord(voice, 1 << 7);
}

int toHex(char c)
{
	if (c >= '0' && c <= '9') {
		return c - '0';
	}
	if (c >= 'a' && c <= 'f') {
		return c - 'a' + 10;
	}
	return -1;
}

uint16_t readHex()
{
	uint16_t result = 0;
	uint8_t i = 0;
	cursor(1);
	cclearxy(g_baseX, g_baseY, 4);
	gotoxy(g_baseX, g_baseY);
	for (i = 0; i < 4; i++) {
		while (1) {
			char c = cgetc();
			int digit = toHex(c);
			if (digit >= 0) {
				result <<= 4;
				result += digit;
				cputc(c);
				break;
			}
		}
	}
	cursor(0);
	return result;
}

void filterTest(char* info, uint8_t filter)
{
	uint8_t cutoff = 0;
	uint8_t voice = 0;
	uint8_t i = 0;
	uint8_t waveform = 1 << 5;
	cprintf("%s pass filter test...\n", info);
	g_sidBase2[23] = 7;
	g_sidBase2[24] = filter | 15;
	for (voice = 0; voice < 3; voice++) {
		setAdsr(voice, 2, 1, 15, 1);
		g_sidBase2[7 * voice + 4] = waveform | 1;
		setFrequency(voice, voice);
	}
	for (i = 0; i < 3; i++) {
		for (cutoff = 1; cutoff < 250; cutoff++) {
			g_sidBase2[22] = cutoff;
			shortDelay();
		}
		for (cutoff = 249; cutoff > 2; cutoff--) {
			g_sidBase2[22] = cutoff;
			shortDelay();
		}
	}
	for (voice = 0; voice < 3; voice++) {
		g_sidBase2[7 * voice + 4] = waveform;
	}
}

void sidTest()
{
	showTitle("SID test");
	while (1) {
		initSid();
		gotoxy(0, 2);
		textcolor(CAPTION_COLOR);
		textcolor(TEXT_COLOR);
		cputs("A: SID base address: ");
		g_baseX = wherex();
		g_baseY = wherey();
		cprintf("%04X\n", g_sidBase2);
		cputs("\r\n");
		textcolor(CAPTION_COLOR);
		cputs("Voice Test\r\n");
		textcolor(TEXT_COLOR);
		cputs("1: voice 1\r\n");
		cputs("2: voice 2\r\n");
		cputs("3: voice 3\r\n");
		cputs("\r\n");
		textcolor(CAPTION_COLOR);
		cputs("Voice Test options\r\n");
		textcolor(TEXT_COLOR);
		cprintf("T: triangle %s\r\n", (g_waveforms & 1) ? "on " : "off");
		cprintf("S: sawtooth %s\r\n", (g_waveforms & 2) ? "on " : "off");
		cprintf("P: pulse %s\r\n", (g_waveforms & 4) ? "on " : "off");
		cprintf("N: noise %s\r\n", (g_waveforms & 8) ? "on " : "off");
		cputs("\r\n");
		textcolor(CAPTION_COLOR);
		cputs("Filter Test\r\n");
		textcolor(TEXT_COLOR);
		cputs("L: low pass\r\n");
		cputs("B: band pass\r\n");
		cputs("H: high pass\r\n");
		cputs("\r\n");
		cputs("\x1f: back\r\n");
		cputs("\r\n");
		cclearxy(wherex(), wherey(), 38);
		gotoxy(0, wherey());
		switch (cgetc()) {
			case '1':
				voiceTest(0);
				break;
			case '2':
				voiceTest(1);
				break;
			case '3':
				voiceTest(2);
				break;
			case 'l':
				filterTest("low", 1 << 4);
				break;
			case 'b':
				filterTest("band", 1 << 5);
				break;
			case 'h':
				filterTest("high", 1 << 6);
				break;
			case 't':
				g_waveforms ^= 1;
				break;
			case 's':
				g_waveforms ^= 2;
				break;
			case 'p':
				g_waveforms ^= 4;
				break;
			case 'n':
				g_waveforms ^= 8;
				break;
			case 'a':
				g_sidBase2 = (uint8_t*) readHex();
				initSid();
				break;
			case LEFT_ARROW_KEY:
				return;
		}
		delay();
	}
}
