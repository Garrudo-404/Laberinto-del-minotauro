library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Top is
    Port (
        clk_100MHz : in  STD_LOGIC; -- Reloj del sistema
        btn_reset : in  STD_LOGIC; -- Botón físico (asumimos activo alto)
        
        -- Pines físicos SPI
        spi_sclk  : in  STD_LOGIC;
        spi_ss    : in  STD_LOGIC;
        spi_mosi  : in  STD_LOGIC;
        
        -- Pines físicos a Servos
        servo_1   : out STD_LOGIC;
        servo_2   : out STD_LOGIC
    );
end Top;

architecture Structural of Top is

    -------------------------------------------------------------------------
    -- 1. Declaración de Componentes
    -------------------------------------------------------------------------
    
    component SPI_Slave_Rx
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

    component Control_Unit
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            rx_data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            rx_dv_in    : in  STD_LOGIC;
            angle_out_1 : out STD_LOGIC_VECTOR(7 downto 0);
            angle_out_2 : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component PWM_Generator
        Generic (
            sys_clk_hz  : integer := 100_000_000; -- Valor por defecto
            pwm_freq_hz : integer := 50
        );
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            angle_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            pwm_signal: out STD_LOGIC
        );
    end component;

    -------------------------------------------------------------------------
    -- 2. Declaración de Señales (Cables internos)
    -------------------------------------------------------------------------
    
    -- Cables entre SPI y Control Unit
    signal w_spi_data  : STD_LOGIC_VECTOR(7 downto 0);
    signal w_spi_valid : STD_LOGIC;
    
    -- Cables entre Control Unit y PWMs
    signal w_angle_1   : STD_LOGIC_VECTOR(7 downto 0);
    signal w_angle_2   : STD_LOGIC_VECTOR(7 downto 0);

begin

    -------------------------------------------------------------------------
    -- 3. Instanciación (Conexionado)
    -------------------------------------------------------------------------

    -- Instancia A: Receptor SPI
    U_SPI_RX : SPI_Slave_Rx
    port map (
        clk      => clk_100MHz,
        reset    => btn_reset,
        sclk_pin => spi_sclk,
        ss_pin   => spi_ss,
        mosi_pin => spi_mosi,
        rx_data  => w_spi_data,  -- Salida del SPI...
        rx_ready => w_spi_valid  -- ...entrada al cable
    );

    -- Instancia B: Unidad de Control (FSM)
    U_CONTROL : Control_Unit
    port map (
        clk         => clk_100MHz,
        reset       => btn_reset,
        rx_data_in  => w_spi_data,  -- ...entrada desde el cable SPI
        rx_dv_in    => w_spi_valid,
        angle_out_1 => w_angle_1,   -- Salida hacia PWM 1
        angle_out_2 => w_angle_2    -- Salida hacia PWM 2
    );

    -- Instancia C: Generador PWM Motor 1
   U_PWM_M1 : PWM_Generator
    generic map (
        sys_clk_hz => 100_000_000, -- Confirmamos 100MHz
        pwm_freq_hz => 50
    )
    port map (
    clk        => clk_100MHz, -- Ojo: Asegúrate de que el puerto se llame clk_100MHz si usas el reloj nativo
    reset      => btn_reset,
    angle_in   => w_angle_1,
    pwm_signal => servo_1
);

    -- Instancia D: Generador PWM Motor 2
    U_PWM_M2 : PWM_Generator
    port map (
        clk        => clk_100MHz,
        reset      => btn_reset,
        angle_in   => w_angle_2,    -- Toma el dato del cable 2
        pwm_signal => servo_2       -- Salida al pin físico
    );

end Structural;