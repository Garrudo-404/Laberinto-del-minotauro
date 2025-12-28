/*
 * Core_Juego.c
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */

#include "Core_Juego.h"
#include "cmsis_os.h"
#include "Eventos_Juego.h"
#include <stdio.h>

#define NUM_JUGADORES 4


extern TIM_HandleTypeDef htim2;//Me la traigo al codigo
//extern osSemaphoreId_t SemBinGolpeHandle;
extern osMessageQueueId_t ColaEventoHandle;

volatile uint8_t temp_turno;//volatile ya que esta variable la toca la interrupcion
uint8_t jugador_actual;
static Jugador jugadores[NUM_JUGADORES];


void StartGameTask(void *argument)
{
  /* USER CODE BEGIN 5 */
	HAL_TIM_Base_Start_IT(&htim2);//arrancamos el temporizador una vez empieza el juego

	jugador_actual=0;
	temp_turno = 45;

	EventoJuego evento_recibido=0;

	for(uint8_t i=0;i<NUM_JUGADORES;i++){
		jugadores[i].id=i+1;
		sprintf(jugadores[i].nombre, "J%d", i + 1);
		jugadores[i].golpes= 0;
	}
	TurnoLEDS(jugadores[jugador_actual]);

  /* Infinite loop */
  for(;;)
  {
	  //leemos cola a ver si hay algun mensaje nuevo
	  if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, 0) == osOK)
	  {
		  switch (evento_recibido)
		  {
		    case Event_GOLPE:
		    	jugadores[jugador_actual].golpes++;
		    	HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_14);

		    	if(jugadores[jugador_actual].golpes == 10)
		    	{
		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12, GPIO_PIN_SET);
		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_13, GPIO_PIN_SET);
		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_14, GPIO_PIN_SET);
		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_15, GPIO_PIN_SET);

		    		//Mensaje fin de partida
		    		LCD1602_clear();
		    		LCD1602_print("!!! GAME OVER !!!");
		    		LCD1602_2ndLine();
		    		LCD1602_print("Jugador ");
		    		LCD1602_print(jugadores[jugador_actual].nombre);

		    	}
		    	break;
		    case Event_IR_DETECTED:
		    	 // Visualización en LCD

		    	                LCD1602_clear();
		    	                LCD1602_1stLine();
		    	                LCD1602_print("JUGADOR CAIDO!!");
		    	                LCD1602_2ndLine();
		    	                LCD1602_print("Vuelva al inicio");
		    	                break;

		  }
	  }
	  //chequeamos el tiempo
	  if(temp_turno==0)
	  {
		  jugador_actual++;
		  if(jugador_actual>(NUM_JUGADORES-1)){jugador_actual=0;}

		  //actualizamos LED
		  TurnoLEDS(jugadores[jugador_actual]);

		  //reiniciamos el reloj
		  temp_turno=45;
	  }

    osDelay(100);
  }
}

  void TurnoLEDS(Jugador jugador){
  	HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_RESET);//limpiamos los leds

  	switch (jugador.id){
  	case 1:
  		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12, GPIO_PIN_SET);
  		break;
  	case 2:
  		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_13, GPIO_PIN_SET);
  		break;
  	case 3:
  		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_14, GPIO_PIN_SET);
  		break;
  	case 4:
  		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_15, GPIO_PIN_SET);
  		break;



  	}
  }

  void Temp_Tick_Turno(void){
	  if (temp_turno>0)
	  {
		  temp_turno--;
	  }
  }


