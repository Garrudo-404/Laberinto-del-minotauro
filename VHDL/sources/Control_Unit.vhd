library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control_Unit is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Interfaz con SPI
        rx_data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
        rx_dv_in    : in  STD_LOGIC; -- Data Valid (pulso)
        
        -- Salidas a los Módulos PWM
        angle_out_1 : out STD_LOGIC_VECTOR(7 downto 0);
        angle_out_2 : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Control_Unit;

architecture Behavioral of Control_Unit is
    -- Estados de la FSM
    type state_type is (WAIT_MOTOR_1, WAIT_MOTOR_2);
    signal state : state_type;

    -- Registros internos para mantener el valor
    signal reg_m1 : STD_LOGIC_VECTOR(7 downto 0);
    signal reg_m2 : STD_LOGIC_VECTOR(7 downto 0);
begin

    -- Proceso Lógico
    process(clk, reset)
    begin
        if reset = '1' then
            state <= WAIT_MOTOR_1;
            -- Valores iniciales (por ejemplo centro: 127)
            reg_m1 <= "10000000"; 
            reg_m2 <= "10000000";
        elsif rising_edge(clk) then
            case state is
                -- Estado 1: Esperando dato para Motor 1
                when WAIT_MOTOR_1 =>
                    if rx_dv_in = '1' then
                        reg_m1 <= rx_data_in; -- Guardamos dato
                        state  <= WAIT_MOTOR_2; -- Pasamos al siguiente
                    end if;

                -- Estado 2: Esperando dato para Motor 2
                when WAIT_MOTOR_2 =>
                    if rx_dv_in = '1' then
                        reg_m2 <= rx_data_in; -- Guardamos dato
                        state  <= WAIT_MOTOR_1; -- Vuelta a empezar
                    end if;
            end case;
        end if;
    end process;

    -- Conexión de registros a salidas
    angle_out_1 <= reg_m1;
    angle_out_2 <= reg_m2;

end Behavioral;