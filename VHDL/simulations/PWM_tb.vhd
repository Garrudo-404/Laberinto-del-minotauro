library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_PWM_Generator is
    -- Entidad vacía para testbench
end tb_PWM_Generator;

architecture Behavioral of tb_PWM_Generator is

    -- 1. Declaramos el componente (debe coincidir con tu PWM_Generator.vhd)
    component PWM_Generator
        Generic (
            sys_clk_hz  : integer;
            pwm_freq_hz : integer
        );
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            angle_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            pwm_signal: out STD_LOGIC
        );
    end component;

    -- 2. Señales internas
    signal tb_clk       : STD_LOGIC := '0';
    signal tb_reset     : STD_LOGIC := '0';
    signal tb_angle_in  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal tb_pwm_out   : STD_LOGIC;

    -- Constantes para reloj de 100MHz
    constant CLK_PERIOD : time := 10 ns; 

begin

    -- 3. Instanciamos la Unidad bajo Prueba (UUT)
    uut: PWM_Generator
    generic map (
        sys_clk_hz  => 100_000_000, -- Simulamos tu Nexys A7
        pwm_freq_hz => 50           -- Frecuencia servo
    )
    port map (
        clk        => tb_clk,
        reset      => tb_reset,
        angle_in   => tb_angle_in,
        pwm_signal => tb_pwm_out
    );

    -- 4. Generador de Reloj
    clk_process : process
    begin
        tb_clk <= '0';
        wait for CLK_PERIOD/2;
        tb_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
   stim_proc: process
   begin		
      -- 1. Estado inicial de Reset
      tb_reset <= '1';
      tb_angle_in <= (others => '0'); -- Ángulo 0
      wait for 100 ns;	
      
      tb_reset <= '0';
      wait for 100 ns;

      -- ============================================================
      -- PRUEBA 1: Posición 0 grados (Valor 0) -> Esperamos 1ms ancho
      -- ============================================================
      -- Mantenemos este valor durante 10 ciclos PWM (aprox 200ms)
      -- para ver claramente la repetición del pulso.
      tb_angle_in <= "00000000"; -- x"00"
      wait for 200 ms; 
      
      -- ============================================================
      -- PRUEBA 2: Posición 90 grados (Valor 128) -> Esperamos ~1.5ms ancho
      -- ============================================================
      tb_angle_in <= "10000000"; -- x"80" (128 decimal)
      wait for 200 ms;

      -- ============================================================
      -- PRUEBA 3: Posición 180 grados (Valor 255) -> Esperamos 2ms ancho
      -- ============================================================
      tb_angle_in <= "11111111"; -- x"FF" (255 decimal)
      wait for 200 ms;

      -- ============================================================
      -- PRUEBA 4: Vuelta a 0 para ver la transición final
      -- ============================================================
      tb_angle_in <= "00000000";
      wait for 60 ms; -- Un par de ciclos más

      -- Fin de la simulación
      assert false report "Simulacion Finalizada Correctamente" severity failure;
      wait;
    end process;

end Behavioral;