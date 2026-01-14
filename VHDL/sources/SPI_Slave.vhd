library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Slave_Rx is
    Port (
        clk      : in  STD_LOGIC; -- Reloj del sistema (100 MHz)
        reset    : in  STD_LOGIC;
        
        -- Pines f�sicos SPI
        sclk_pin : in  STD_LOGIC;
        ss_pin   : in  STD_LOGIC; -- Active Low (0 es activado)
        mosi_pin : in  STD_LOGIC;
        
        -- Interfaz interna
        rx_data  : out STD_LOGIC_VECTOR(7 downto 0); -- Solo los 8 LSB (bits 7-0) de los 16 bits recibidos
        rx_ready : out STD_LOGIC -- Pulso de 1 ciclo cuando el dato es v�lido
    );
end SPI_Slave_Rx;

architecture Behavioral of SPI_Slave_Rx is

    -- 1. Se�ales para Sincronizaci�n (Doble Flip-Flop)
    -- Se usan vectores de 2 bits: bit(0) es actual, bit(1) es previo
    signal sclk_sync : std_logic_vector(1 downto 0);
    signal ss_sync   : std_logic_vector(1 downto 0);
    signal mosi_sync : std_logic_vector(1 downto 0);

    -- 2. Se�ales de registro interno
    signal shift_reg : std_logic_vector(15 downto 0); -- Aqu� vamos guardando los bits
    signal bit_cnt   : integer range 0 to 15 := 0;    -- Cuenta bits recibidos
    
    -- Detectores de flanco
    signal sclk_rising : std_logic;

begin

    -- =========================================================================
    -- PROCESO 1: Sincronizaci�n de se�ales externas
    -- =========================================================================
    -- Esto protege a la FPGA de se�ales as�ncronas y ruidosas
    process(clk, reset)
    begin
        if reset = '0' then
            sclk_sync <= "00";
            ss_sync   <= "11"; -- Asumimos inactivo (High) al inicio
            mosi_sync <= "00";
        elsif rising_edge(clk) then
            -- Desplazamos los valores: pin -> sync(0) -> sync(1)
            sclk_sync <= sclk_sync(0) & sclk_pin;
            ss_sync   <= ss_sync(0)   & ss_pin;
            mosi_sync <= mosi_sync(0) & mosi_pin;
        end if;
    end process;

    -- Detecci�n de flanco de subida en SCLK
    -- Ocurre cuando el estado "viejo" (1) es '0' y el "nuevo" (0) es '1'
    sclk_rising <= '1' when (sclk_sync(1) = '0' and sclk_sync(0) = '1') else '0';

    -- =========================================================================
    -- PROCESO 2: L�gica de Recepci�n SPI
    -- =========================================================================
    process(clk, reset)
    begin
        if reset = '0' then
            shift_reg <= (others => '0');
            bit_cnt   <= 0;
            rx_data   <= (others => '0');
            rx_ready  <= '0';
            
        elsif rising_edge(clk) then
            -- Valor por defecto para el pulso de 'listo'
            rx_ready <= '0'; 

            -- Verificamos si el Chip Select (SS) est� activo (Nivel Bajo)
            -- Usamos ss_sync(1) que es la se�al limpia y estable
            if ss_sync(1) = '0' then
                
                -- Si detectamos flanco de subida en el reloj SPI...
                if sclk_rising = '1' then
                    -- 1. Desplazamos el bit recibido (MOSI) al registro
                    -- Entra por la derecha (LSB) o izquierda dependiendo del protocolo.
                    -- SPI est�ndar suele enviar MSB primero.
                    shift_reg <= shift_reg(14 downto 0) & mosi_sync(1);
                    
                    -- 2. Contamos los bits
                    if bit_cnt = 15 then
                        -- �Tenemos un byte completo!
                        rx_data  <= shift_reg(7 downto 0); -- Solo los 8 bits menos significativos
                        rx_ready <= '1'; -- Disparamos la bandera de "Dato Listo"
                        bit_cnt  <= 0;   -- Reiniciamos contador para el siguiente dato
                    else
                        bit_cnt <= bit_cnt + 1;
                    end if;
                end if;
                
            else
                -- Si SS sube (se desactiva), reseteamos el contador para evitar desincronizaci�n
                bit_cnt <= 0;
            end if;
        end if;
    end process;

end Behavioral;
