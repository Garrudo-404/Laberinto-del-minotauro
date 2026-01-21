/*
 * Eventos_Juego.h
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */

#ifndef INC_EVENTOS_JUEGO_H_
#define INC_EVENTOS_JUEGO_H_

typedef enum {
	Event_NONE=0,
	Event_GOLPE,
	Event_IR_DETECTED,
	Event_FIN_TEMP
} EventoJuego;

typedef enum {
	Estado_INICIO,
	Estado_JUGANDO,
	Estado_FIN
}EstadoJuego;

#endif /* INC_EVENTOS_JUEGO_H_ */
