----------------------------------------------------------------------------------
-- Testbench para Top - Simulación de SPI y Control de Servos
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI is
end SPI;

architecture Behavioral of SPI is

    -- Señales del DUT (Device Under Test)
    signal clk_100MHz : STD_LOGIC := '0';
    signal btn_reset  : STD_LOGIC := '0';
    signal spi_sclk   : STD_LOGIC := '0';
    signal spi_ss     : STD_LOGIC := '1';  -- Inicialmente inactivo (alto)
    signal spi_mosi   : STD_LOGIC := '0';
    signal servo_1    : STD_LOGIC;
    signal servo_2    : STD_LOGIC;
    signal sw         : STD_LOGIC := '0';  -- Switch para modo terremoto
    
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz = 10 ns período
    constant SPI_BIT_TIME : time := 1 us;  -- Tiempo por bit SPI (1 MHz)
    constant UPDATE_PERIOD : time := 20 ms;  -- Período de actualización (20ms = 50Hz)

begin

    -- =========================================================================
    -- Instanciación del DUT (Top)
    -- =========================================================================
    DUT : entity work.Top
        port map (
            clk_100MHz => clk_100MHz,
            btn_reset  => btn_reset,
            spi_sclk   => spi_sclk,
            spi_ss     => spi_ss,
            spi_mosi   => spi_mosi,
            servo_1    => servo_1,
            servo_2    => servo_2,
            sw         => sw
        );

    -- =========================================================================
    -- Generador de Reloj (100 MHz)
    -- =========================================================================
    clk_process : process
    begin
        clk_100MHz <= '0';
        wait for CLK_PERIOD/2;
        clk_100MHz <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- =========================================================================
    -- Proceso de Reset
    -- =========================================================================
    reset_process : process
    begin
        btn_reset <= '0';  -- Reset activo bajo
        wait for 100 ns;
        btn_reset <= '1';  -- Liberar reset
        wait;
    end process;

    -- =========================================================================
    -- Proceso de Simulación SPI
    -- Envía 2 palabras de 16 bits cada 20ms (50Hz) alternando entre (180,0) y (0,180)
    -- El SPI_Slave_Rx extrae los 8 LSB de cada palabra de 16 bits
    -- =========================================================================
    spi_simulation : process
        -- Valores en grados (0-180)
        variable angle_1_deg : integer := 180;  -- Valor inicial: ángulo 1 = 180 grados
        variable angle_2_deg : integer := 0;     -- Valor inicial: ángulo 2 = 0 grados
        -- Valores en 16 bits (0-65535, mapeados desde 0-180 grados)
        variable angle_1_val : integer;
        variable angle_2_val : integer;
        variable data_to_send : STD_LOGIC_VECTOR(15 downto 0);
        variable toggle : boolean := false;
        
        -- Procedimiento para enviar un bit por SPI (sin controlar SS)
        procedure send_spi_bit(bit_val : in STD_LOGIC) is
        begin
            spi_mosi <= bit_val;
            wait for SPI_BIT_TIME/4;
            spi_sclk <= '1';
            wait for SPI_BIT_TIME/2;
            spi_sclk <= '0';
            wait for SPI_BIT_TIME/4;
        end procedure;
        
    begin
        -- Inicializar mosi cuando SS está inactivo
        spi_mosi <= '0';
        
        -- Esperar a que termine el reset
        wait for 200 ns;
        
        -- Bucle infinito: enviar datos cada 20ms (50Hz)
        loop
            -- Convertir grados a valor de 16 bits: valor = (grados * 65535) / 180
            angle_1_val := (angle_1_deg * 65535) / 180;
            angle_2_val := (angle_2_deg * 65535) / 180;
            
            -- Activar chip select (bajo) - se mantiene activo durante las 2 palabras
            spi_ss <= '0';
            wait for SPI_BIT_TIME;
            
            -- Preparar las 2 palabras de 16 bits
            data_to_send := std_logic_vector(to_unsigned(angle_1_val, 16));
            
            -- Enviar primera palabra de 16 bits (32 bits en total: 16 + 16)
            -- Enviar los 16 bits MSB primero de la primera palabra
            for i in 15 downto 0 loop
                send_spi_bit(data_to_send(i));
            end loop;
            
            -- Preparar segunda palabra
            data_to_send := std_logic_vector(to_unsigned(angle_2_val, 16));
            
            -- Enviar segunda palabra de 16 bits (sin desactivar SS)
            -- Enviar los 16 bits MSB primero de la segunda palabra
            for i in 15 downto 0 loop
                send_spi_bit(data_to_send(i));
            end loop;
            
            -- Desactivar chip select (alto) - solo al final de las 2 palabras
            spi_ss <= '1';
            wait for SPI_BIT_TIME;
            
            -- Mantener mosi en '0' cuando SS está inactivo
            spi_mosi <= '0';
            
            -- Alternar valores para la próxima transmisión
            if toggle then
                angle_1_deg := 180;
                angle_2_deg := 0;
                toggle := false;
            else
                angle_1_deg := 0;
                angle_2_deg := 180;
                toggle := true;
            end if;
            
            -- Calcular tiempo restante hasta completar 20 ms
            -- Cada palabra de 16 bits: 16 bits * SPI_BIT_TIME + setup/teardown
            -- Aproximadamente: 2 palabras * (16 * 1us + 2us) = ~36us
            -- Esperamos el resto del período de 20 ms
            wait for UPDATE_PERIOD - 40 us;
        end loop;
    end process;

end Behavioral;
