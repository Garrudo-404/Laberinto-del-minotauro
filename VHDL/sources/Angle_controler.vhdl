----------------------------------------------------------------------------------
-- Angle_controler: Suaviza las transiciones de ángulo
-- Recibe una consigna y ajusta suavemente el ángulo interno hacia ella
-- Incrementa/decrementa en 2 cada 50Hz (cada período PWM = 20ms)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Angle_controler is
    Generic (
        sys_clk_hz  : integer := 100_000_000; -- Reloj del sistema (100MHz)
        pwm_freq_hz : integer := 50           -- Frecuencia PWM (50Hz)
    );
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        setpoint_in : in  STD_LOGIC_VECTOR(7 downto 0); -- Consigna desde Control_Unit (0-255)
        sw          : in  STD_LOGIC; -- Switch para activar modo "terremoto" (1=activado, 0=desactivado)
        angle_out   : out STD_LOGIC_VECTOR(7 downto 0)  -- Ángulo actual hacia PWM_Generator (0-255)
    );
end Angle_controler;

architecture Behavioral of Angle_controler is

    -- Constantes
    constant cycles_per_pwm_period : integer := sys_clk_hz / pwm_freq_hz; -- 2,000,000 ciclos (20ms)
    constant cycles_per_tremor_period : integer := sys_clk_hz; -- 10,000,000 ciclos (0.1s = 100ms)
    
    -- Señales internas
    signal current_angle : integer range 0 to 255 := 0; -- Ángulo interno actual
    signal counter_50hz  : integer range 0 to cycles_per_pwm_period := 0; -- Contador para 50Hz
    signal setpoint_int  : integer range 0 to 255; -- Consigna como entero
    signal earthquake_toggle : STD_LOGIC := '0'; -- Toggle para alternar +10/-10 en modo terremoto
    signal earthquake_clk_counter : integer range 0 to cycles_per_tremor_period := 0; -- Contador de ciclos de reloj para 0.1s
    signal angle_with_tremor : integer range 0 to 255; -- Ángulo con temblor aplicado

begin

    -- Conversión de la consigna a entero
    setpoint_int <= to_integer(unsigned(setpoint_in));

    -- Proceso principal: actualización del ángulo cada 50Hz
    process(clk, reset)
    begin
        if reset = '0' then
            current_angle <= 0; -- Ángulo inicial
            counter_50hz <= 0;
            earthquake_clk_counter <= 0;
            earthquake_toggle <= '0';
        elsif rising_edge(clk) then
            
            
            -- Contador para detectar cada período de 50Hz
            if counter_50hz < cycles_per_pwm_period - 1 then
                counter_50hz <= counter_50hz + 1;
            else
                counter_50hz <= 0;
                
                -- Contador de terremoto: cuenta ciclos de reloj de 100MHz para 0.1 segundos
                if sw = '1' then
                    if earthquake_clk_counter < 5 - 1 then
                        earthquake_clk_counter <= earthquake_clk_counter + 1;
                    else
                        earthquake_clk_counter <= 0;
                        earthquake_toggle <= not earthquake_toggle; -- Cambiamos cada 0.1s (10,000,000 ciclos)
                    end if;
                else
                    earthquake_toggle <= '0';
                    earthquake_clk_counter <= 0;
                end if;

                -- Cada 50Hz, ajustamos el ángulo hacia la consigna (incremento/decremento de 3)
                if current_angle < setpoint_int then
                    -- Incrementamos si estamos por debajo de la consigna
                    if (current_angle + 3) <= setpoint_int then
                        current_angle <= current_angle + 3; -- Incremento de 2
                    else
                        current_angle <= setpoint_int; -- Llegamos exactamente a la consigna
                    end if;
                elsif current_angle > setpoint_int then
                    -- Decrementamos si estamos por encima de la consigna
                    if (current_angle - 3) >= setpoint_int then
                        current_angle <= current_angle - 3; -- Decremento de 2
                    else
                        current_angle <= setpoint_int; -- Llegamos exactamente a la consigna
                    end if;
                -- Si current_angle = setpoint_int, no hacemos nada (ya estamos en la consigna)
                end if;
            end if;
        end if;
    end process;

    -- Modo terremoto: aplicar temblor a la salida (+30 o -30 alternando cada 0.1s usando reloj de 100MHz)
    -- El ángulo interno sigue funcionando normalmente, solo la salida "tiembla"
    process(current_angle, earthquake_toggle, sw)
        variable tremor_offset : integer;
        variable temp_angle : integer;
    begin
        if sw = '1' then
            -- Modo terremoto activo: alternar entre +30 y -30 (amplitud mayor para ser más perceptible)
            if earthquake_toggle = '1' then
                tremor_offset := 5;
            else
                tremor_offset := -5;
            end if;
            
            -- Aplicar el temblor con saturación (0-255)
            temp_angle := current_angle + tremor_offset;
            if temp_angle > 255 then
                angle_with_tremor <= 255;
            elsif temp_angle < 0 then
                angle_with_tremor <= 0;
            else
                angle_with_tremor <= temp_angle;
            end if;
        else
            -- Modo normal: salida = ángulo interno
            angle_with_tremor <= current_angle;
        end if;
    end process;
    
    -- Salida: ángulo con temblor (si está activo) o ángulo normal
    angle_out <= std_logic_vector(to_unsigned(angle_with_tremor, 8));

end Behavioral;
