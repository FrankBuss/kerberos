/*
 * timer.h
 *
 *  Created on: 21.01.2011
 *      Author: skoe
 */

#ifndef TIMER_H_
#define TIMER_H_

#include <stdint.h>

void timerInitTOD(void);
void timerStart(void);
void timerStop(void);
void timerCont(void);
uint16_t timerGet(void);


#endif /* TIMER_H_ */
