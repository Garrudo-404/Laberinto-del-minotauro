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

extern volatile EstadoJuego estado_actual;


volatile uint8_t temp_turno;//volatile ya que esta variable la toca la interrupcion
uint8_t jugador_actual;
static Jugador jugadores[NUM_JUGADORES];


void StartGameTask(void *argument)
{
  /* USER CODE BEGIN 5 */
	HAL_TIM_Base_Start_IT(&htim2);//arrancamos el temporizador una vez empieza el juego

	estado_actual = ESTADO_INICIO;
	EventoJuego evento_recibido;

	//variable para pintar el led solo una vez por estado
	uint8_t primera_vez = 1;

  /* Infinite loop */
  for(;;)
  {
	  //implementacion con maquina de estados
	  switch (estado_actual)
	  {

	  //ESTADO INICIO
	     case ESTADO_INICIO:
	    	 if(primera_vez)
	    	 {
	    		 LCD1602_clear();
	    		 LCD1602_print("  El MINOTAURO");
	    		 LCD1602_2ndLine();
	    		 LCD1602_print("Pulsa btn inicio");//en este contexto de estado de inicio usamos la interrupcion de golpe para comenzar

	    		 //inicializamos las variables de los jugadores
	    		 jugador_actual=0;
	    		 temp_turno = 45;
	    		 for(uint8_t i=0;i<NUM_JUGADORES;i++){
	    			   jugadores[i].id=i+1;
	    			   sprintf(jugadores[i].nombre, "J%d", i + 1);
	    			   jugadores[i].golpes= 0;
	    			  }

	    		 TurnoLEDS(jugadores[jugador_actual]);
	    	     primera_vez =0;
	    	 }

	    	 //Esperamos el "Evento_Golpe" para iniciar juego
	   	  if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, 0) == osOK)
	   	  {
	   		  if(evento_recibido == Event_GOLPE)
	   		  {
	   			  estado_actual = ESTADO_JUGANDO;
	   			  primera_vez = 1;//para que pinte la pantalla de juego
	   		  }
	   	  }
	   	  break;

	   	  //ESTADO JUGANDO
	     case ESTADO_JUGANDO:
	    	 if(primera_vez)
	    	 {
	    	 	LCD1602_clear();
	    	 	LCD1602_print("A JUGAR! ");
	    	 	LCD1602_2ndLine();
	    	 	LCD1602_print(jugadores[jugador_actual].nombre);//mostramos el nombre del jugador
	    	 	primera_vez=0;
	         }

	    	  //leemos cola a ver si hay algun mensaje nuevo
	    		  if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, 0) == osOK)
	    		  {
	    			  switch (evento_recibido)
	    			  {
	    			    case Event_GOLPE://el evento golpe en este contexto significa golpe
	    			    	jugadores[jugador_actual].golpes++;
	    			    	HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_14);

	    			    	if(jugadores[jugador_actual].golpes == 10)
	    			    	{


	    			    		estado_actual = ESTADO_FIN;
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

	    		  //Gestion de turnos solo si seguimos jugando
	    		  if(estado_actual == ESTADO_JUGANDO && temp_turno==0)
	    		 	  {
	    		 		  jugador_actual++;
	    		 		  if(jugador_actual>(NUM_JUGADORES-1)){jugador_actual=0;}

	    		 		  //actualizamos LED
	    		 		  TurnoLEDS(jugadores[jugador_actual]);

	    		 		  //reiniciamos el reloj
	    		 		  temp_turno=45;

	    		 		  //actualizamos LCD con nuevo jugador
	    		 		 LCD1602_clear();
	    		         LCD1602_print("Turno: ");
 			    		 LCD1602_print(jugadores[jugador_actual].nombre);
	    		 	  }

	    		     osDelay(100);
	    		     break;

	     case ESTADO_FIN:
	    	 if(primera_vez)
	    	 {
	    		 //Luces victoria
	    		 HAL_GPIO_WritePin(GPIOD, GPIO_PIN_12|GPIO_PIN_13|GPIO_PIN_14|GPIO_PIN_15, GPIO_PIN_SET);

	    		 //Mensaje fin de partida
	    		 LCD1602_clear();
	    		 LCD1602_print("!!! GAME OVER !!!");
	    	     LCD1602_2ndLine();
	    		 LCD1602_print("Ganador: ");
	    		 LCD1602_print(jugadores[jugador_actual].nombre);

	    		 primera_vez = 0;

	    	 }

	    	 //Esperamos el "Evento_Golpe" para reiniciar
	    	 if(osMessageQueueGet(ColaEventoHandle, &evento_recibido, NULL, 0) == osOK)
	    	 {
	    	   		  if(evento_recibido == Event_GOLPE)
	    	   		  {
	    	   			  estado_actual = ESTADO_INICIO;//vuelta a empezar
	    	   			  primera_vez = 1;
	    	   		  }
	    	 }
	    	 break;

	     default:
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


