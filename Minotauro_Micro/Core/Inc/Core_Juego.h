/*
 * Core_Juego.h
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */

#ifndef INC_CORE_JUEGO_H_
#define INC_CORE_JUEGO_H_

#include "main.h"


typedef struct{
	char nombre[15];
	uint8_t id;
	uint8_t golpes;
}Jugador;

void TurnoLEDS(Jugador jugador);
void StartGameTask(void *argument);
void Temp_Tick_Turno(void);



#endif /* INC_CORE_JUEGO_H_ */
