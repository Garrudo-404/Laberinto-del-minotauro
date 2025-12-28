/*
 * FPGA_COM_Task.c
 *
 *  Created on: Dec 15, 2025
 *      Author: danie
 */
#include "main.h"

extern SPI_HandleTypeDef hspi1;
//8 bits altos para eje x, 8 bits bajos para eje y
uint16_t datos_joystick;
void StartFPGA_COM_Task(void *argument)
{
  /* USER CODE BEGIN StartFPGA_COM_Task */
	const uint32_t servo_update_period = 20;//20ms para actualizar el estado del servo
	uint32_t tickstart;//para iniciar la cuenta
  /* Infinite loop */
  for(;;)
  {
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
  /* USER CODE END StartFPGA_COM_Task */
}

