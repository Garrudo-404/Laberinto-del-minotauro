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
extern osSemaphoreId_t SemBinIRHandle;//Semáforo para el sensor IR

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin){
	if(GPIO_Pin == GPIO_PIN_0)
	{
		//liberamos al semaforo con la interrupcion
		osSemaphoreRelease(SemBinGolpeHandle);
	}
	if (GPIO_Pin == IR1_SENSOR_Pin)
	    {
	            osSemaphoreRelease(SemBinIRHandle);
	    }
}

// ASUMIMOS:
// 1. Existe 'SemBinIRHandle' (creado en main.c)
// 2. La ISR de GPIOC_PIN_1 libera 'SemBinIRHandle'.

void Start_Input_Task(void *argument)
{
    EventoJuego mensaje_evento;
    // Timeout pequeño para evitar bloqueo infinito y ceder CPU a otras tareas
    const uint32_t check_timeout = 10;

    for(;;)
    {
        // ----------------------------------------------------
        // 1. MANEJO DE EVENTO GOLPE (GPIOA, PIN_0)
        // ----------------------------------------------------
        if (osSemaphoreAcquire(SemBinGolpeHandle, check_timeout) == osOK)
        {
            // Retardo para el anti-rebote (después de despertar)
            osDelay(50);

            // Confirmamos que la señal sigue activa (Golpe)
            if(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET)
            {
                mensaje_evento = Event_GOLPE;
                osMessageQueuePut(ColaEventoHandle, &mensaje_evento, 0, 0);

                // Lógica LCD si fuera necesaria para el golpe

                // Esperamos a que se libere el pulsador
                while(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET){
                    osDelay(10);
                }
            }
        }

        // ----------------------------------------------------
        // 2. MANEJO DE EVENTO IR (GPIOC, PIN_1)
        // ----------------------------------------------------
        if (osSemaphoreAcquire(SemBinIRHandle, 20) == osOK)
        {
            osDelay(5); // antirrebote

            if (HAL_GPIO_ReadPin(GPIOC, IR1_SENSOR_Pin) == GPIO_PIN_RESET)
            {
                mensaje_evento = Event_IR_DETECTED;
                osMessageQueuePut(ColaEventoHandle, &mensaje_evento, 0, 0);
            }
        }


    }
}

