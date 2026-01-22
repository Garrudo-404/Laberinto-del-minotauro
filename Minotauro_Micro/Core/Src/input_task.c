/*
 * input_task.c
 *
 *  Created on: Dec 10, 2025
 *      Author: danie
 */
#include "main.h"
#include "cmsis_os.h"
#include "Eventos_Juego.h"
#include "Core_Juego.h"



//flags definidas
#define FLAG_GOLPE  0x00000001U
#define FLAG_IR     0x00000002U


volatile uint16_t lectura_actual = 0;
extern ADC_HandleTypeDef hadc2;
extern TIM_HandleTypeDef htim3;//Temporizador que activa tarea golpe

extern osMessageQueueId_t ColaEventoHandle;
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



void Leer_piezo_minotauro(void)
{
	HAL_ADC_Start(&hadc2);
    // Variables persistentes
    static uint32_t tiempo_encendido = 0;
    static uint16_t lectura_anterior = 0;

    // Inicialización del temporizador de seguridad
    if (tiempo_encendido == 0) {
        tiempo_encendido = HAL_GetTick();
        return; // Salimos para esperar al menos un ciclo
    }

    // 1. POLLING SEGURO (Sin Start/Stop)
    // Solo esperamos a que el ADC (que ya está corriendo) tenga un dato nuevo
    if (HAL_ADC_PollForConversion(&hadc2, 1) == HAL_OK)
    {
        lectura_actual = HAL_ADC_GetValue(&hadc2);

        // 2. FILTRO DE SEGURIDAD (Tiempo + Derivada)
        // Solo evaluamos si han pasado los 2 segundos de estabilización
        if ((HAL_GetTick() - tiempo_encendido) > 400)
        {
            // Calculamos la diferencia brusca para ignorar la inclinación
            int32_t derivada = (int32_t)lectura_actual - (int32_t)lectura_anterior;

            // Si el salto es mayor a 500 (ajustable), es un impacto real
            if (derivada > 400) {
                //golpe_detectado = 1;
                //REINICIAR el contador del Timer a 0
                 __HAL_TIM_SET_COUNTER(&htim3, 0);
                // Iniciar el Timer para que nos avise en 100ms
                 HAL_TIM_Base_Start_IT(&htim3);
            }
        }

        // Guardamos la lectura para la siguiente comparación de derivada
        lectura_anterior = lectura_actual;
    }
    HAL_ADC_Stop(&hadc2);
}


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
    	        flags_recibidos = osEventFlagsWait(InputEventsHandle,FLAG_GOLPE | FLAG_IR,osFlagsWaitAny,20);
    	        // En CMSIS-RTOS v2, los errores tienen el bit más alto en 1, asi que comprueba que
    	        //no esté enviando la señal de error por medio de una máscara
     if (!(flags_recibidos & 0x80000000))
    	{
        // ----------------------------------------------------
        // 1. MANEJO DE EVENTO GOLPE (GPIOA, PIN_0)
        // ----------------------------------------------------
        if (flags_recibidos & FLAG_GOLPE)
        {
            // Retardo para el anti-rebote (después de despertar)
            osDelay(50);

            // Confirmamos que la señal sigue activa (Golpe)
           // if(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET){
                mensaje_evento = Event_GOLPE;
                osMessageQueuePut(ColaEventoHandle, &mensaje_evento, 0, 0);

                // Lógica LCD si fuera necesaria para el golpe

                // Esperamos a que se libere el pulsador
                while(HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0) == GPIO_PIN_SET){
                    osDelay(10);
               // }
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
    	}
     else
         {
             // AQUÍ LLEGAMOS SI PASARON LOS 20ms (TIMEOUT)
             // No hacemos nada, simplemente seguimos abajo hacia el joystick
         }
        //Leer_Joystick_Polling();
        Leer_piezo_minotauro();
    }
}

