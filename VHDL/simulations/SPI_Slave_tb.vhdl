----------------------------------------------------------------------------------
-- Testbench para SPI_Slave_Rx
-- Verifica la recepción de 2 palabras de 16 bits cada 20 ms
-- Basado en SPI.vhd para la generación de señales SPI
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Slave_tb is
end SPI_Slave_tb;

architecture Behavioral of SPI_Slave_tb is

    -- Constantes
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz = 10 ns período
    constant SPI_BIT_TIME : time := 1 us;  -- Tiempo por bit SPI (1 MHz)
    constant UPDATE_PERIOD : time := 20 ms;  -- Período de actualización (20ms = 50Hz)
    
    -- Señales del testbench
    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '0';
    signal sclk_pin : STD_LOGIC := '0';
    signal ss_pin   : STD_LOGIC := '1';  -- Inicialmente inactivo (alto)
    signal mosi_pin : STD_LOGIC := '0';
    signal rx_data  : STD_LOGIC_VECTOR(7 downto 0);
    signal rx_ready : STD_LOGIC;
    
    -- Componente a testear
    component SPI_Slave_Rx is
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            sclk_pin : in  STD_LOGIC;
            ss_pin   : in  STD_LOGIC;
            mosi_pin : in  STD_LOGIC;
            rx_data  : out STD_LOGIC_VECTOR(7 downto 0);
            rx_ready : out STD_LOGIC
        );
    end component;

begin

    -- Instanciación del módulo bajo prueba
    uut: SPI_Slave_Rx
        port map (
            clk      => clk,
            reset    => reset,
            sclk_pin => sclk_pin,
            ss_pin   => ss_pin,
            mosi_pin => mosi_pin,
            rx_data  => rx_data,
            rx_ready => rx_ready
        );

    -- Proceso de generación de reloj del sistema (100 MHz)
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Proceso de reset
    reset_process: process
    begin
        reset <= '0';
        wait for 100 ns;
        reset <= '1';
        wait;
    end process;

    -- Proceso de simulación SPI
    -- Envía 2 palabras de 16 bits cada 20 ms
    spi_simulation: process
        -- Valores de prueba (16 bits)
        variable data_word_1 : STD_LOGIC_VECTOR(15 downto 0);
        variable data_word_2 : STD_LOGIC_VECTOR(15 downto 0);
        variable toggle : boolean := false;
        
        -- Procedimiento para enviar 16 bits por SPI
        procedure send_spi_16bits(data : in STD_LOGIC_VECTOR(15 downto 0)) is
        begin
            -- Activar chip select (bajo)
            ss_pin <= '0';
            wait for SPI_BIT_TIME;
            
            -- Enviar los 16 bits MSB primero
            for i in 15 downto 0 loop
                mosi_pin <= data(i);
                wait for SPI_BIT_TIME/4;
                sclk_pin <= '1';
                wait for SPI_BIT_TIME/2;
                sclk_pin <= '0';
                wait for SPI_BIT_TIME/4;
            end loop;
            
            -- Desactivar chip select (alto)
            ss_pin <= '1';
            wait for SPI_BIT_TIME;
        end procedure;
        
    begin
        -- Esperar a que termine el reset
        wait for 200 ns;
        
        -- Bucle infinito: enviar 2 palabras de 16 bits cada 20 ms
        loop
            -- Alternar valores para ver diferentes datos
            if toggle then
                -- Primera secuencia: valores bajos
                data_word_1 := std_logic_vector(to_unsigned(16#1234#, 16)); -- 0x1234
                data_word_2 := std_logic_vector(to_unsigned(16#5678#, 16)); -- 0x5678
                toggle := false;
            else
                -- Segunda secuencia: valores altos
                data_word_1 := std_logic_vector(to_unsigned(16#ABCD#, 16)); -- 0xABCD
                data_word_2 := std_logic_vector(to_unsigned(16#EF00#, 16)); -- 0xEF00
                toggle := true;
            end if;
            
            -- Enviar primera palabra de 16 bits
            send_spi_16bits(data_word_1);
            
            -- Pequeña pausa entre palabras
            wait for SPI_BIT_TIME * 2;
            
            -- Enviar segunda palabra de 16 bits
            send_spi_16bits(data_word_2);
            
            -- Calcular tiempo restante hasta completar 20 ms
            -- Cada palabra de 16 bits: 16 bits * SPI_BIT_TIME + setup/teardown
            -- Aproximadamente: 2 palabras * (16 * 1us + 2us) = ~36us
            -- Esperamos el resto del período de 20 ms
            wait for UPDATE_PERIOD - 40 us;
        end loop;
    end process;

end Behavioral;
