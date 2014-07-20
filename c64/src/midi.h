#ifndef MIDI_H
#define MIDI_H

uint8_t __fastcall__ midiWaitAndReadByte(void);
uint8_t __fastcall__ midiIrqNmiTest(void);
void __fastcall__ midiInit(void);
uint8_t __fastcall__ midiByteReceived(void);
uint8_t __fastcall__ midiWaitAndReadByte(void);
uint8_t __fastcall__ midiReadByte(void);
void __fastcall__ midiSendByte(uint8_t);

#endif
