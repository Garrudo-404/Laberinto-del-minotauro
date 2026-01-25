----------------------------------------------------------------------------------
-- Testbench para PWM_Generator
-- Prueba el módulo PWM con diferentes ángulos:
-- - Cambia el ángulo cada 100 ms
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM_Generator_tb is
end PWM_Generator_tb;

architecture Behavioral of PWM_Generator_tb is

    -- Constantes
    constant CLK_PERIOD : time := 10 ns; -- 100MHz = 10ns período
    
    -- Señales del testbench
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '0';
    signal angle_in  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal pwm_signal: STD_LOGIC;
    signal debug_duty_cycle : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Componente a testear
    component PWM_Generator is
        Generic (
            sys_clk_hz  : integer := 100_000_000;
            pwm_freq_hz : integer := 50;
            A1          : integer := 100_000;
            A2          : integer := 200_000
        );
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            angle_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            pwm_signal: out STD_LOGIC;
            debug_duty_cycle : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

begin

    -- Instanciación del módulo bajo prueba
    uut: PWM_Generator
        generic map (
            sys_clk_hz  => 100_000_000,
            pwm_freq_hz => 50,
            A1          => 100_000,
            A2          => 200_000
        )
        port map (
            clk       => clk,
            reset     => reset,
            angle_in  => angle_in,
            pwm_signal => pwm_signal,
            debug_duty_cycle => debug_duty_cycle
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
        angle_in <= std_logic_vector(to_unsigned(0, 8)); -- Ángulo inicial: 0
        wait for 100 ns;
        
        -- Liberar reset
        reset <= '1';
        wait for 100 ns;
        
        -- Mantener primer ángulo (0) durante 100 ms
        angle_in <= std_logic_vector(to_unsigned(0, 8));
        wait for 100 ms;
        
        -- Cambiar a segundo ángulo (180, que es aproximadamente 128 en escala 0-255)
        angle_in <= std_logic_vector(to_unsigned(128, 8));
        wait for 100 ms;
        
        -- Cambiar a tercer ángulo para ver más variación (255 = máximo)
        angle_in <= std_logic_vector(to_unsigned(255, 8));
        wait for 100 ms;
        
        -- Finalizar simulación
        wait;
    end process;

end Behavioral;
