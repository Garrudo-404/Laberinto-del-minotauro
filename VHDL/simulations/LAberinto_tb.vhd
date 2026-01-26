library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Servo_System is
    -- Testbench sin puertos
end tb_Servo_System;

architecture Behavioral of tb_Servo_System is

    -- 1. Componente TOP
    component Top
        Port (
            clk_100MHz : in  STD_LOGIC;
            btn_reset  : in  STD_LOGIC;
            spi_sclk   : in  STD_LOGIC;
            spi_ss     : in  STD_LOGIC;
            spi_mosi   : in  STD_LOGIC;
            servo_1    : out STD_LOGIC;
            servo_2    : out STD_LOGIC
        );
    end component;

    -- 2. Señales
    signal tb_clk      : STD_LOGIC := '0';
    signal tb_reset    : STD_LOGIC := '0';
    signal tb_sclk     : STD_LOGIC := '0';
    signal tb_ss       : STD_LOGIC := '1';
    signal tb_mosi     : STD_LOGIC := '0';
    signal tb_servo_1  : STD_LOGIC;
    signal tb_servo_2  : STD_LOGIC;

    -- Constantes
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz
    constant SPI_PERIOD : time := 1 us;  -- 1 MHz SPI
    
    -- TIEMPO ENTRE COMANDOS (0.5 Segundos)
    constant STEP_DELAY : time := 500 ms; 

begin

    -- 3. Instancia UUT
    uut: Top
    port map (
        clk_100MHz => tb_clk,
        btn_reset  => tb_reset,
        spi_sclk   => tb_sclk,
        spi_ss     => tb_ss,
        spi_mosi   => tb_mosi,
        servo_1    => tb_servo_1,
        servo_2    => tb_servo_2
    );

    -- 4. Reloj
    clk_process : process
    begin
        tb_clk <= '0';
        wait for CLK_PERIOD/2;
        tb_clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Proceso de Estímulos
    stim_proc: process
        
        -- Procedimiento de envío SPI
        procedure send_spi_pair(
            constant val_m1 : in integer;
            constant val_m2 : in integer
        ) is
            variable data_byte_1 : std_logic_vector(7 downto 0);
            variable data_byte_2 : std_logic_vector(7 downto 0);
        begin
            data_byte_1 := std_logic_vector(to_unsigned(val_m1, 8));
            data_byte_2 := std_logic_vector(to_unsigned(val_m2, 8));
            
            wait for 10 us; -- Pequeña pausa antes de bajar SS
            tb_ss <= '0';   -- Inicio transacción
            wait for SPI_PERIOD;

            -- Byte 1
            for i in 7 downto 0 loop
                tb_mosi <= data_byte_1(i);
                wait for SPI_PERIOD/2;
                tb_sclk <= '1';
                wait for SPI_PERIOD/2;
                tb_sclk <= '0';
            end loop;
            
            wait for SPI_PERIOD; -- Pausa entre bytes

            -- Byte 2
            for i in 7 downto 0 loop
                tb_mosi <= data_byte_2(i);
                wait for SPI_PERIOD/2;
                tb_sclk <= '1';
                wait for SPI_PERIOD/2;
                tb_sclk <= '0';
            end loop;

            wait for SPI_PERIOD;
            tb_ss <= '1';   -- Fin transacción
            
            report ">> SPI ENVIADO: M1=" & integer'image(val_m1) & " M2=" & integer'image(val_m2);
        end procedure;

    begin        
        -- Reset inicial
        report "Iniciando Simulacion de 5 Segundos...";
        tb_reset <= '1';
        wait for 100 ns;
        tb_reset <= '0';
        wait for 100 ns;

        -- SECUENCIA DE 5 SEGUNDOS (10 pasos de 0.5s)

        -- T = 0.0s: Centrar motores
        send_spi_pair(128, 128); 
        wait for STEP_DELAY; 

        -- T = 0.5s: Mover a extremos (0 y 180)
        send_spi_pair(0, 255);
        wait for STEP_DELAY;

        -- T = 1.0s: Invertir extremos (180 y 0)
        send_spi_pair(255, 0);
        wait for STEP_DELAY;

        -- T = 1.5s: Cuarto de vuelta (45 y 135 grados aprox)
        send_spi_pair(64, 192);
        wait for STEP_DELAY;

        -- T = 2.0s: Invertir cuartos
        send_spi_pair(192, 64);
        wait for STEP_DELAY;

        -- T = 2.5s: Valores pequeños
        send_spi_pair(10, 20);
        wait for STEP_DELAY;

        -- T = 3.0s: Valores grandes
        send_spi_pair(240, 230);
        wait for STEP_DELAY;

        -- T = 3.5s: Motor 1 quieto, Motor 2 barre
        send_spi_pair(128, 50);
        wait for STEP_DELAY;

        -- T = 4.0s: Motor 1 quieto, Motor 2 barre otro lado
        send_spi_pair(128, 200);
        wait for STEP_DELAY;

        -- T = 4.5s: Volver al centro para finalizar
        send_spi_pair(128, 128);
        wait for STEP_DELAY;

        -- T = 5.0s: FINAL
        report "Simulacion de 5 segundos completada.";
        assert false report "Fin del Testbench" severity failure;
        wait;
    end process;

end Behavioral;