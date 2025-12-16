/*
 * FPGA_COM_Task.c
 *
 *  Created on: Dec 15, 2025
 *      Author: danie
 */
#include "main.h"
#include "Core_Juego.h"

extern SPI_HandleTypeDef hspi1;
extern volatile EstadoJuego estado_actual;

//8 bits altos para eje x, 8 bits bajos para eje y
uint16_t datos_joystick;

void StartFPGA_COM_Task(void *argument)
{
  /* USER CODE BEGIN StartFPGA_COM_Task */
	const uint32_t servo_update_period = 20;//20ms para actualizar el estado del servo
	uint32_t tickstart;//para iniciar la cuenta
	const uint16_t POS_INICIO = 0x8080;//asumimos que esta es la pos centrada del tablero
  /* Infinite loop */
  for(;;)
  {
	  if (estado_actual == ESTADO_JUGANDO)
	  {
		  //aqui es donde meteriamos la logica de leer el joystick
		  tickstart = osKernelGetTickCount();

		  	  //simulamos dato para probar
		  	  datos_joystick = 0xAAAA;

		  	  //Transmision por el SPI con CS manual (activo a nivel bajp)
		  	  //ACTIVAMOS LA COMUNICACION
		  	  HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_RESET);
		  	  //TRANSMITIMOS EL DATO
		  	  //size 1 (un paquete de 16 bits), timeout de 10ms
		  	  HAL_SPI_Transmit(&hspi1, (uint8_t*)&datos_joystick, 1, 10);

		  	  //DESACTIVAMOS LA COMUNICACION
		  	  HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_SET);
		  	  //hago que se repita cuando pasen los 20ms de actualizacion
		        osDelayUntil(tickstart + servo_update_period);
	  }
	  else
	  {
		  //tanto en el estado de fin de juego como en el de inicio el tablero tiene que estar en su pos inicial
	  	  HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_RESET);
	  	  HAL_SPI_Transmit(&hspi1, (uint8_t*)&POS_INICIO, 1, 10);
	  	  HAL_GPIO_WritePin(SPI_CS_GPIO_Port, SPI_CS_Pin, GPIO_PIN_SET);

	  	  //esperamos 20ms
	  	  osDelay(20);

	  }


  }
  /* USER CODE END StartFPGA_COM_Task */
}

