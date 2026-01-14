library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_Generator is
    Generic (
        sys_clk_hz  : integer := 100_000_000; -- Reloj de la Nexys A7 (100MHz)
        pwm_freq_hz : integer := 50;          -- Frecuencia del Servo (50Hz)
        A1          : integer := 100_000;     -- Límite inferior del escalado (ciclos de reloj, por defecto 1ms)
        A2          : integer := 200_000      -- Límite superior del escalado (ciclos de reloj, por defecto 2ms)
    );
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        angle_in  : in  STD_LOGIC_VECTOR(7 downto 0); -- Ángulo de entrada (0 a 255, mapeado a rango A1-A2)
        pwm_signal: out STD_LOGIC;
        debug_duty_cycle : out STD_LOGIC_VECTOR(7 downto 0) -- Duty cycle en porcentaje (0-100)
    );
end PWM_Generator;

architecture Behavioral of PWM_Generator is
    
    -- Constantes calculadas autom�ticamente
    constant cycles_per_period : integer := sys_clk_hz / pwm_freq_hz; -- 2,000,000
    
    -- Definici�n de l�mites del pulso (En ciclos de reloj)
    -- 1ms = 100,000 ciclos (para 0 grados)
    -- 2ms = 200,000 ciclos (para 180 grados)
    constant min_pulse_cycles  : integer := sys_clk_hz / 1000;      -- 1ms
    constant max_pulse_cycles  : integer := sys_clk_hz / 500;       -- 2ms
    
    -- Calculamos cu�nto dura cada "paso" de los 256 posibles valores
    -- Rango total = 100,000 ciclos. Dividido entre 256 pasos = ~390 ciclos/paso
    constant cycles_per_step   : integer := (max_pulse_cycles - min_pulse_cycles) / 256;
    constant range_size : integer := A2 - A1;

    -- Contadores y se�ales
    signal counter     : integer range 0 to cycles_per_period := 0;
    signal high_time   : integer range 0 to cycles_per_period := 0;
    signal duty_cycle_percent : integer range 0 to 100 := 0; -- Duty cycle en porcentaje (0-100)
    signal angle_scaled : integer range 0 to cycles_per_period := 0; -- Angulo escalado a rango A1-A2
    
begin

    -- Proceso 1: Calcular el ancho del pulso seg�n la entrada
    -- high_time = 1ms + (valor_entrada * 390 ciclos)
    -- =========================================================================
    -- ESCALADO: De 0-255 (2^8) a rango A1-A2
    -- =========================================================================
    -- Escalamos el angulo de entrada al nuevo rango definido por A1 y A2
    -- Cuando angle_in = 0 -> angle_scaled = A1
    -- Cuando angle_in = 255 -> angle_scaled = A2
    angle_scaled <= A1 + ((to_integer(unsigned(angle_in)) * range_size) / 255);
    
    -- Proceso 1: Calcular el ancho del pulso usando el valor escalado
    -- Usamos el valor escalado directamente como tiempo en alto
    high_time <= angle_scaled;
    
    -- Cálculo del duty cycle en porcentaje (0-100)
    -- duty_cycle = (high_time / cycles_per_period) * 100
    duty_cycle_percent <= (high_time * 100) / cycles_per_period;

    -- Proceso 2: Generaci�n de la se�al PWM
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= 0;
            pwm_signal <= '0';
        elsif rising_edge(clk) then
            -- Contador principal (0 a 1,999,999)
            if counter < cycles_per_period - 1 then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;

            -- Comparador para generar la salida
            if counter < high_time then
                pwm_signal <= '1';
            else
                pwm_signal <= '0';
            end if;
        end if;
    end process;
    
    -- Salida del duty cycle
    debug_duty_cycle <= std_logic_vector(to_unsigned(duty_cycle_percent, 8));

end Behavioral;
