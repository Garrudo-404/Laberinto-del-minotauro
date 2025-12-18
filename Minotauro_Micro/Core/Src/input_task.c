/*
 * input_task.c
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */
#include "main.h"
#include "cmsis_os.h"
#include "Eventos_Juego.h"

//flags definidas
#define FLAG_GOLPE  0x00000001U
#define FLAG_IR     0x00000002U

/* Variables globales del joystick para Live Expressions */
volatile uint16_t joyX = 0;
volatile uint16_t joyY = 0;
extern ADC_HandleTypeDef hadc1;

//extern osSemaphoreId_t SemBinGolpeHandle;
extern osMessageQueueId_t ColaEventoHandle;
//extern osSemaphoreId_t SemBinIRHandle;//Semáforo para el sensor IR
extern osEventFlagsId_t InputEventsHandle; // Importamos el handle

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin){

	static uint32_t last_ir_time = 0; // Variable estática para recordar el tiempo desde la ultima interrupcion
	    uint32_t current_time = HAL_GetTick();

	if(GPIO_Pin == GPIO_PIN_0)
	{

		//liberamos al semaforo con la interrupcion
		//osSemaphoreRelease(SemBinGolpeHandle);


		/*PRUEBA CON FLAGS*/
		// Enviamos la señal (Flag) directamente
		        osEventFlagsSet(InputEventsHandle, FLAG_GOLPE);
	}
	if (GPIO_Pin == IR1_SENSOR_Pin)
	    {
		/*LCD1602_clear();
		LCD1602_print("Sensor IR");*/
		//HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_13);
	    //osSemaphoreRelease(SemBinIRHandle);

		/*PRUEBA CON FLAGS*/
		/* ANTIRREBOTE POR HARDWARE/SOFTWARE EN LA ISR:
		           Si han pasado menos de 500ms desde el último disparo, IGNORAMOS la interrupción.
		           Esto evita inundar la cola y cumple con no hacer polling en la tarea.
		        */
		        if ((current_time - last_ir_time) > 500)
		        {
		            // Solo si ha pasado el tiempo de seguridad, avisamos a la tarea
		            osEventFlagsSet(InputEventsHandle, FLAG_IR);
		            last_ir_time = current_time;

		            // Debug LED (Opcional)
		            HAL_GPIO_TogglePin(GPIOD, GPIO_PIN_13);
		        }
	    }
}

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
// ASUMIMOS:
// 1. Existe 'SemBinIRHandle' (creado en main.c)
// 2. La ISR de GPIOC_PIN_1 libera 'SemBinIRHandle'.

void Start_Input_Task(void *argument)
{

	uint32_t flags_recibidos;

	HAL_NVIC_EnableIRQ(EXTI0_IRQn);
	HAL_NVIC_EnableIRQ(EXTI1_IRQn);

    EventoJuego mensaje_evento;
    // Timeout pequeño para evitar bloqueo infinito y ceder CPU a otras tareas
    const uint32_t check_timeout = 10;

    for(;;)
    {
    	/*PRUEBA CON FLAGS*/
    	// La tarea se BLOQUEA (Dorme) aquí indefinidamente hasta que
    	// ocurra ALGUNO (osFlagsWaitAny) de los eventos.
    	        flags_recibidos = osEventFlagsWait(InputEventsHandle,
    	                                           FLAG_GOLPE | FLAG_IR,
    	                                           osFlagsWaitAny,
    	                                           osWaitForever);
        // ----------------------------------------------------
        // 1. MANEJO DE EVENTO GOLPE (GPIOA, PIN_0)
        // ----------------------------------------------------
        if (flags_recibidos & FLAG_GOLPE)
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
        if (flags_recibidos & FLAG_IR)
        {
            //el antirebote ya lo habiamos metido en la gestion de la interrupcion


                mensaje_evento = Event_IR_DETECTED;
                osMessageQueuePut(ColaEventoHandle, &mensaje_evento, 0, 0);
                osDelay(100);

        }
        Leer_Joystick_Polling();

    }
}

