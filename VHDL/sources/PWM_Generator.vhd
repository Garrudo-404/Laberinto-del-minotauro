library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_Generator is
    Generic (
        sys_clk_hz  : integer := 100_000_000; -- Reloj de la Nexys A7 (100MHz)
        pwm_freq_hz : integer := 50           -- Frecuencia del Servo (50Hz)
    );
    Port (
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        angle_in  : in  STD_LOGIC_VECTOR(7 downto 0); -- Byte de entrada (0 a 255)
        pwm_signal: out STD_LOGIC
    );
end PWM_Generator;

architecture Behavioral of PWM_Generator is
    
    -- Constantes calculadas automáticamente
    constant cycles_per_period : integer := sys_clk_hz / pwm_freq_hz; -- 2,000,000
    
    -- Definición de límites del pulso (En ciclos de reloj)
    -- 1ms = 100,000 ciclos (para 0 grados)
    -- 2ms = 200,000 ciclos (para 180 grados)
    constant min_pulse_cycles  : integer := sys_clk_hz / 1000;      -- 1ms
    constant max_pulse_cycles  : integer := sys_clk_hz / 500;       -- 2ms
    
    -- Calculamos cuánto dura cada "paso" de los 256 posibles valores
    -- Rango total = 100,000 ciclos. Dividido entre 256 pasos = ~390 ciclos/paso
    constant cycles_per_step   : integer := (max_pulse_cycles - min_pulse_cycles) / 256;

    -- Contadores y señales
    signal counter     : integer range 0 to cycles_per_period := 0;
    signal high_time   : integer range 0 to cycles_per_period := 0;
    
begin

    -- Proceso 1: Calcular el ancho del pulso según la entrada
    -- high_time = 1ms + (valor_entrada * 390 ciclos)
    high_time <= min_pulse_cycles + (to_integer(unsigned(angle_in)) * cycles_per_step);

    -- Proceso 2: Generación de la señal PWM
    process(clk, reset)
    begin
        if reset = '1' then
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

end Behavioral;