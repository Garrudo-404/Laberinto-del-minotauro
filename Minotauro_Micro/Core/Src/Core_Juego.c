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

volatile EstadoJuego estado_actual = Estado_INICIO;

void StartGameTask(void *argument)
{
	osDelay(100);
  /* USER CODE BEGIN 5 */
	HAL_TIM_Base_Start_IT(&htim2);//arrancamos el temporizador una vez empieza el juego

	EventoJuego evento_recibido=0;


	jugador_actual=0;
	temp_turno = 45;


	TurnoLEDS(jugadores[jugador_actual]);

	uint8_t primera_vez = 1;//bandera para reinicializar el juego

  /* Infinite loop */
  for(;;)
  {
	  switch(estado_actual){
	  case Estado_INICIO:
		  if(primera_vez)
		  {
		    LCD1602_clear();
		    LCD1602_print("  El MINOTAURO");
		    LCD1602_2ndLine();
		    LCD1602_print("    A jugar");
		    LCD1602_noBlink();

		    // Inicializamos datos
		    jugador_actual = 0;
		    temp_turno = 45;
		    for(uint8_t i = 0; i < NUM_JUGADORES; i++){
		    jugadores[i].id = i + 1;
		    sprintf(jugadores[i].nombre, "J%d", i + 1);
		    jugadores[i].golpes = 0;
		    }

		    TurnoLEDS(jugadores[jugador_actual]); // LED inicial

		    primera_vez = 0; // Ya hemos inicializado, bajamos la bandera
		    }

		    // Esperamos eventos para pasar de estado
		    if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, osWaitForever) == osOK)
		    {
		      if(evento_recibido == Event_GOLPE)
		      {
		        estado_actual = Estado_JUGANDO;
		        primera_vez = 1; // Importante: Activamos para pintar la pantalla del siguiente estado
		       }
		     }
		     break;


	  case Estado_JUGANDO:


		  if(primera_vez)
		  {
			  LCD1602_clear();
			  LCD1602_print("TURNO: ");
			  LCD1602_print(jugadores[jugador_actual].nombre);
			  LCD1602_2ndLine();
			  LCD1602_print("GOLPES: ");
			  LCD1602_print(jugadores[jugador_actual].golpes);



			  LCD1602_noBlink();
			  primera_vez=0;
		  }


		  //leemos cola a ver si hay algun mensaje nuevo
		 	  if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, 100) == osOK)
		 	  {
		 		  switch (evento_recibido)
		 		  {
		 		    case Event_GOLPE:
		 		    	jugadores[jugador_actual].golpes++;
		 		    	char buffer_lcd[16];
		 		    	sprintf(buffer_lcd, "GOLPES: %d", jugadores[jugador_actual].golpes);
		 		    	LCD1602_2ndLine();
		 		    	LCD1602_print(buffer_lcd);
		 		    	HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_14);

		 		    	if(jugadores[jugador_actual].golpes >= 10)
		 		    	{
		 		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12, GPIO_PIN_SET);
		 		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_13, GPIO_PIN_SET);
		 		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_14, GPIO_PIN_SET);
		 		    		HAL_GPIO_WritePin(GPIOD, GPIO_PIN_15, GPIO_PIN_SET);


		 		    		estado_actual = Estado_FIN;
		 		    		primera_vez = 1;

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

		 	  // Actualizar LCD para el nuevo jugador
		 	  LCD1602_clear();
		 	  LCD1602_print("TURNO: ");
		 	  LCD1602_print(jugadores[jugador_actual].nombre);
		 			  }
		 	break;

	  case Estado_FIN:

		  if(primera_vez)
		  {
		    // Luces de fiesta
		   HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_SET);

		   LCD1602_clear();
		   LCD1602_print("!!! GAME OVER !!!");
		   LCD1602_2ndLine();
		   LCD1602_print("VICTORIA: ");
		   LCD1602_print(jugadores[jugador_actual].nombre);
		   primera_vez = 0;
		    }
	 	  if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, osWaitForever) == osOK){
	 		  if(evento_recibido==Event_GOLPE){

	 			 HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_RESET);
		    	 estado_actual = Estado_INICIO;
		    	 primera_vez = 1;
	 		  }

	  }
 		  break;

	  default:
	      estado_actual = Estado_INICIO; // Recuperación de errores
	      primera_vez = 1;
	      break;


   }
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


