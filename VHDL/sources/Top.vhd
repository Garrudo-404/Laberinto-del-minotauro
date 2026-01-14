library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top is
    Port (
        clk_100MHz : in  STD_LOGIC; -- Reloj del sistema
        btn_reset : in  STD_LOGIC; -- Bot�n f�sico (asumimos activo alto)
        
        -- Pines f�sicos SPI
        spi_sclk  : in  STD_LOGIC;
        spi_ss    : in  STD_LOGIC;
        spi_mosi  : in  STD_LOGIC;
        
        -- Pines f�sicos a Servos
        servo_1   : out STD_LOGIC;
        servo_2   : out STD_LOGIC;
        
        -- Switch para modo terremoto
        sw        : in  STD_LOGIC  -- Switch para activar modo terremoto (1=activado, 0=desactivado)
    );
end Top;

architecture Structural of Top is

    -------------------------------------------------------------------------
    -- 1. Declaraci�n de Componentes
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

    component Angle_controler
        Generic (
            sys_clk_hz  : integer := 100_000_000;
            pwm_freq_hz : integer := 50
        );
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            setpoint_in : in  STD_LOGIC_VECTOR(7 downto 0);
            sw          : in  STD_LOGIC;
            angle_out   : out STD_LOGIC_VECTOR(7 downto 0)
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
            pwm_signal: out STD_LOGIC;
            debug_duty_cycle : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -------------------------------------------------------------------------
    -- 2. Declaraci�n de Se�ales (Cables internos)
    -------------------------------------------------------------------------
    
    -- Cables entre SPI y Control Unit
    signal w_spi_data  : STD_LOGIC_VECTOR(7 downto 0);
    signal w_spi_valid : STD_LOGIC;
    
    -- Cables entre Control Unit y Angle_controler (consignas)
    signal w_angle_setpoint_1 : STD_LOGIC_VECTOR(7 downto 0);
    signal w_angle_setpoint_2 : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Cables entre Angle_controler y PWMs (ángulos suavizados)
    signal w_angle_smooth_1 : STD_LOGIC_VECTOR(7 downto 0);
    signal w_angle_smooth_2 : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Señales de debug para duty cycle
    signal w_duty_cycle_1 : STD_LOGIC_VECTOR(7 downto 0);
    signal w_duty_cycle_2 : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Señales intermedias para conversión de ángulos (0-255 -> 0-180) - solo para debug interno
    signal angle_1_scaled : STD_LOGIC_VECTOR(7 downto 0);
    signal angle_2_scaled : STD_LOGIC_VECTOR(7 downto 0);

begin

    -------------------------------------------------------------------------
    -- 3. Instanciaci�n (Conexionado)
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
        angle_out_1 => w_angle_setpoint_1,   -- Consigna hacia Angle_controler 1
        angle_out_2 => w_angle_setpoint_2    -- Consigna hacia Angle_controler 2
    );

    -- Instancia B1: Controlador de Ángulo Motor 1 (suaviza transiciones)
    U_ANGLE_CTRL_1 : Angle_controler
    generic map (
        sys_clk_hz => 100_000_000,
        pwm_freq_hz => 50
    )
    port map (
        clk         => clk_100MHz,
        reset       => btn_reset,
        setpoint_in => w_angle_setpoint_1,  -- Consigna desde Control_Unit
        sw          => sw,                   -- Switch para modo terremoto
        angle_out   => w_angle_smooth_1      -- Ángulo suavizado hacia PWM
    );

    -- Instancia B2: Controlador de Ángulo Motor 2 (suaviza transiciones)
    U_ANGLE_CTRL_2 : Angle_controler
    generic map (
        sys_clk_hz => 100_000_000,
        pwm_freq_hz => 50
    )
    port map (
        clk         => clk_100MHz,
        reset       => btn_reset,
        setpoint_in => w_angle_setpoint_2,  -- Consigna desde Control_Unit
        sw          => sw,                   -- Switch para modo terremoto
        angle_out   => w_angle_smooth_2      -- Ángulo suavizado hacia PWM
    );

    -- Instancia C: Generador PWM Motor 1
   U_PWM_M1 : PWM_Generator
    generic map (
        sys_clk_hz => 100_000_000, -- Confirmamos 100MHz
        pwm_freq_hz => 50
    )
    port map (
    clk        => clk_100MHz, -- Ojo: Aseg�rate de que el puerto se llame clk_100MHz si usas el reloj nativo
    reset      => btn_reset,
    angle_in   => w_angle_smooth_1,  -- Ángulo suavizado desde Angle_controler
    pwm_signal => servo_1,
    debug_duty_cycle => w_duty_cycle_1
);

    -- Instancia D: Generador PWM Motor 2
    U_PWM_M2 : PWM_Generator
    generic map (
        sys_clk_hz => 100_000_000, -- Confirmamos 100MHz
        pwm_freq_hz => 50
    )
    port map (
        clk        => clk_100MHz,
        reset      => btn_reset,
        angle_in   => w_angle_smooth_2,    -- Ángulo suavizado desde Angle_controler
        pwm_signal => servo_2,       -- Salida al pin f
        debug_duty_cycle => w_duty_cycle_2
    );
    
    -- Señales internas de debug (disponibles para ILA si se necesitan)
    -- Conversión de ángulos: de 0-255 a 0-180 grados
    -- ángulo_grados = (ángulo_entrada * 180) / 255
    angle_1_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(w_angle_smooth_1)) * 180) / 255, 8));
    angle_2_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(w_angle_smooth_2)) * 180) / 255, 8));
    
    -- Nota: Las señales w_duty_cycle_1, w_duty_cycle_2, angle_1_scaled y angle_2_scaled
    -- son señales internas que pueden ser observadas con ILA (Integrated Logic Analyzer)
    -- si se necesita depuración en hardware, pero no son necesarias para la funcionalidad

end Structural;
