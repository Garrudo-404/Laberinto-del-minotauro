----------------------------------------------------------------------------------
-- Testbench para Control_Unit
-- Verifica la secuencia de transición de estados y cómo cambian los ángulos
-- al recibir datos a través de rx_data_in con rx_dv_in
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Control_Unit_tb is
end Control_Unit_tb;

architecture Behavioral of Control_Unit_tb is

    -- Constantes
    constant CLK_PERIOD : time := 10 ns; -- 100MHz = 10ns período
    constant PWM_PERIOD : time := 20 ms; -- Período PWM de 50Hz = 20ms
    
    -- Señales del testbench
    signal clk         : STD_LOGIC := '0';
    signal reset       : STD_LOGIC := '0';
    signal rx_data_in  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal rx_dv_in    : STD_LOGIC := '0';
    signal angle_out_1 : STD_LOGIC_VECTOR(7 downto 0);
    signal angle_out_2 : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Componente a testear
    component Control_Unit is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            rx_data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            rx_dv_in    : in  STD_LOGIC;
            angle_out_1 : out STD_LOGIC_VECTOR(7 downto 0);
            angle_out_2 : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

begin

    -- Instanciación del módulo bajo prueba
    uut: Control_Unit
        port map (
            clk         => clk,
            reset       => reset,
            rx_data_in  => rx_data_in,
            rx_dv_in    => rx_dv_in,
            angle_out_1 => angle_out_1,
            angle_out_2 => angle_out_2
        );

    -- Proceso de generación de reloj
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Proceso de estimulación
    stim_process: process
    begin
        -- Reset inicial
        reset <= '0';
        rx_data_in <= (others => '0');
        rx_dv_in <= '0';
        wait for 100 ns;
        
        -- Liberar reset (valores iniciales: angle_out_1 = 180, angle_out_2 = 0)
        reset <= '1';
        wait for 100 ns;
        
        -- Secuencia 1: Enviar dato para Motor 1 (cada 50Hz = 20ms)
        -- Estado inicial: WAIT_MOTOR_1
        rx_data_in <= std_logic_vector(to_unsigned(50, 8)); -- Ángulo 50 para motor 1
        wait for 20 ns;
        rx_dv_in <= '1'; -- Pulso de data valid
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        -- Ahora debería estar en WAIT_MOTOR_2 y angle_out_1 = 50
        
        -- Secuencia 2: Enviar dato para Motor 2
        rx_data_in <= std_logic_vector(to_unsigned(100, 8)); -- Ángulo 100 para motor 2
        wait for 20 ns;
        rx_dv_in <= '1'; -- Pulso de data valid
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        -- Ahora debería estar en WAIT_MOTOR_1 y angle_out_2 = 100
        
        -- Secuencia 3: Enviar otro dato para Motor 1
        rx_data_in <= std_logic_vector(to_unsigned(150, 8)); -- Ángulo 150 para motor 1
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        -- Ahora debería estar en WAIT_MOTOR_2 y angle_out_1 = 150
        
        -- Secuencia 4: Enviar otro dato para Motor 2
        rx_data_in <= std_logic_vector(to_unsigned(200, 8)); -- Ángulo 200 para motor 2
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        -- Ahora debería estar en WAIT_MOTOR_1 y angle_out_2 = 200
        
        -- Secuencia 5: Enviar dato para Motor 1 (valor máximo)
        rx_data_in <= std_logic_vector(to_unsigned(255, 8)); -- Ángulo 255 para motor 1
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        
        -- Secuencia 6: Enviar dato para Motor 2 (valor mínimo)
        rx_data_in <= std_logic_vector(to_unsigned(0, 8)); -- Ángulo 0 para motor 2
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        
        -- Secuencia 7: Variar más los valores
        rx_data_in <= std_logic_vector(to_unsigned(75, 8)); -- Ángulo 75 para motor 1
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        
        rx_data_in <= std_logic_vector(to_unsigned(180, 8)); -- Ángulo 180 para motor 2
        wait for 20 ns;
        rx_dv_in <= '1';
        wait for CLK_PERIOD;
        rx_dv_in <= '0';
        wait for PWM_PERIOD - CLK_PERIOD - 20 ns; -- Esperar hasta el próximo período de 50Hz
        
        -- Esperar un poco más para observar
        wait for PWM_PERIOD;
        
        -- Finalizar simulación
        wait;
    end process;

end Behavioral;

