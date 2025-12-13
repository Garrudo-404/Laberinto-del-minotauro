/*
 * input_task.c
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */
#include "main.h"
#include "cmsis_os.h"
#include "Eventos_Juego.h"

extern osSemaphoreId_t SemBinGolpeHandle;
extern osMessageQueueId_t ColaEventoHandle;

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin){
	if(GPIO_Pin==GPIO_PIN_0)
	{
		//liberamos al semaforo con la interrupcion
		osSemaphoreRelease(SemBinGolpeHandle);
	}
}

void Start_Input_Task(void *argument)
{
  /* USER CODE BEGIN Start_Input_Task */
	EventoJuego mensaje_evento;
  /* Infinite loop */
  for(;;)
  {
	  //lo bloqueo hasta que no haya un evento
	  osSemaphoreAcquire(SemBinGolpeHandle, osWaitForever);
	  //Hago que espere 50ms para que la señal se estabilice
    osDelay(50);

    //confirmo que tras 50ms la señal se ha estabilizado y sigue sientdo set
    if(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET)
    {
    	//activamos evento de golpe
    	mensaje_evento = Event_GOLPE;

    	//enviamos mensaje a la gametask con la cola
    	osMessageQueuePut(ColaEventoHandle, &mensaje_evento, 0, 0);

    	//esperamos a que pase la deteccion de golpe
    	while(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET){
    		osDelay(10);
    	}
    }
  }
}

