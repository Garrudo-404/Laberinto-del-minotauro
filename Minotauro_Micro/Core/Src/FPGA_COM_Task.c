/*
 * FPGA_COM_Task.c
 *
 *  Created on: Dec 15, 2025
 *      Author: danie
 */
#include "main.h"

//extern SPI_HandleTypeDef hspi1;
//8 bits altos para eje x, 8 bits bajos para eje y
//uint16_t datos_joystick;

/* Variables globales del joystick para Live Expressions */
volatile uint16_t joyX = 0;
volatile uint16_t joyY = 0;
extern ADC_HandleTypeDef hadc1;

// Extern del handle de SPI (definido en main.c por CubeMX)
extern SPI_HandleTypeDef hspi1;
/* Variables para el empaquetado de datos */
uint16_t spi_buffer[2];

void Leer_Joystick_Polling(void)
{
    // 1. Leer Rank 1 (PA2)
    HAL_ADC_Start(&hadc1);
    if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
        joyX = HAL_ADC_GetValue(&hadc1);
    }

    // 2. Leer Rank 2 (PA3)
    if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK) {
        joyY = HAL_ADC_GetValue(&hadc1);
    }

    HAL_ADC_Stop(&hadc1);
}

uint8_t mapear_joystick(uint16_t valor_crudo) {

    // 1. Definir el centro detectado y la zona muerta
    const uint16_t CENTRO_ADC = 2030;
    const uint16_t ZONA_MUERTA = 15;

    // 2. Si el joystick está en reposo (dentro de la zona muerta)
    // Devolvemos 128 (centro exacto de un byte)
    if (valor_crudo > (CENTRO_ADC - ZONA_MUERTA) && valor_crudo < (CENTRO_ADC + ZONA_MUERTA)) {
        return 128;
    }

    // 3. Mapeo lineal para el resto del rango
    // Simplemente desplazamos 4 bits (dividir por 16)
    int32_t resultado = (int32_t)(valor_crudo >> 4);

    // 4. Saturación de seguridad
    if (resultado > 255) return 255;
    if (resultado < 0)   return 0;

    return (uint8_t)resultado;
}

void StartFPGA_COM_Task(void *argument)
{
    // 1. Definimos el periodo de ejecución (20ms = 50Hz)
    const uint32_t ticks_periodo = osKernelGetTickFreq() / 50; // Equivale a 20ms
    uint32_t tickstart = osKernelGetTickCount();

    for(;;)
    {
        // Lectura ejes x,y joystick
        Leer_Joystick_Polling();

        // Suponemos centro medido en 2030
        spi_buffer[0] = mapear_joystick(joyX);
        spi_buffer[1] = mapear_joystick(joyY);

        // Bajamos CS: La FPGA pone su contador a 0 y se prepara
        HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_RESET);

        // Ahora envio 2 bytes de 8 bits (0-255) ya centrados
        HAL_SPI_Transmit(&hspi1, spi_buffer, 2, 10);

        // Subimos CS: La FPGA toma los 16 bits recibidos y actualiza el PWM de golpe
        HAL_GPIO_WritePin(GPIOA, GPIO_PIN_4, GPIO_PIN_SET);


        //LIBERAMOS CPU
        // osDelayUntil bloquea ESTA tarea y permite que el LCD y el Juego se ejecuten.
        // Se despertará exactamente 20ms después del inicio del ciclo anterior.
        osDelayUntil(tickstart + ticks_periodo);
        tickstart = osKernelGetTickCount();
    }
}
