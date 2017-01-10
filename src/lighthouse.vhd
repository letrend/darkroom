library ieee;
use ieee.std_logic_1164.all;        
use ieee.numeric_std.all;
USE IEEE.std_logic_signed.all;

entity lighthouse is
	Generic (
		constant sensorID  : std_logic_vector(8 downto 0) := "000000000"
	);
   port( 
		clk: in std_logic;
		sensor: in std_logic;
		timer: in std_logic_vector(31 downto 0);
		sweep_detected: out std_logic;
		sensor_value: out std_logic_vector(31 downto 0));
end lighthouse;
 
architecture Behavioral of lighthouse is
   signal t_0: 		std_logic_vector(31 downto 0);
	signal t_sweep_start: std_logic_vector(31 downto 0);
	signal data: std_logic;
	signal rotor: std_logic;
	signal lighthouse: std_logic;
	signal start_valid_sync 	: std_logic_vector(31 downto 0);
	signal sensor_previous		: std_logic;
	signal temp_sensor_value	: std_logic_vector(31 downto 0);
	signal temp_sweep_detected : std_logic;
	constant zeros : std_logic_vector(t_0'range) := (others => '0');

	
begin process(clk)
	variable duration: std_logic_vector(31 downto 0);
	variable t_sweep_duration: std_logic_vector(31 downto 0);
	variable stop_valid_sync : std_logic_vector(31 downto 0) := (others => '0');
	variable sync_gap_duration 	: std_logic_vector(31 downto 0):= (others => '0');
   begin
		if rising_edge(clk) then
			sensor_previous <= sensor;
			temp_sweep_detected <= '0';
			if (sensor_previous = '0') and (sensor = '1') then -- rising edge
				t_0 <= timer;
			elsif (sensor_previous = '1') and (sensor = '0') then -- falling edge
				duration := std_logic_vector(unsigned(timer)-unsigned(t_0));
				if(duration < 300) then -- this is a sweep
					t_sweep_duration := (t_0-t_sweep_start);
					temp_sensor_value(31 downto 13) <= t_sweep_duration(18 downto 0);--;t_sweep_duration(18 downto 0);--
					temp_sweep_detected <= '1';
				elsif (duration > (625 - 20)) and (duration < (938 + 20)) then -- this is a sync pulse, NOT skipping
					t_sweep_start <= t_0;
					
					sync_gap_duration := std_logic_vector(unsigned(t_0) - unsigned(start_valid_sync));
					start_valid_sync <= t_0;
					if((sync_gap_duration - 83330 ) > 3000 ) then
						temp_sensor_value(9) <= '1';
						-- sensor_value(9) <= '1';
					elsif ((sync_gap_duration - 83330 ) < -3000 ) then
						temp_sensor_value(9) <= '0';
						--sensor_value(9) <= '0';
					end if;
					
					if(abs(duration - 630) < 50) then
						temp_sensor_value(10) <= '0';
						--sensor_value(10) <= '0'; -- rotor
					elsif(abs(duration - 730) < 50) then
						temp_sensor_value(10) <= '1';
						--sensor_value(10) <= '1'; -- rotor
					elsif(abs(duration - 830) < 50) then
						temp_sensor_value(10) <= '0';
						--sensor_value(10) <= '0'; -- rotor
					elsif(abs(duration - 940) < 50) then
						temp_sensor_value(10) <= '1';
						--sensor_value(10) <= '1'; -- rotor
					end if;
				end if;
				
				if(t_sweep_duration < 81920) and (t_sweep_duration > 0 ) then 
					temp_sensor_value(12) <= '1';
					--sensor_value(12) <= '1'; -- valid sweep
				else
					temp_sensor_value(12) <= '0';
					--sensor_value(12) <= '0'; -- not valid
				end if;
				
				temp_sensor_value(8 downto 0) <= sensorID;
				--sensor_value(8 downto 0) <= sensorID;
			end if;
		end if;
   end process;
	
	process(clk)
		begin 
			if rising_edge(clk) then
				if(temp_sweep_detected = '1') then
					sensor_value <= temp_sensor_value;
					sweep_detected <= '1';
				else
					sweep_detected <= '0';
				end if;
			end if;
	end process;
end Behavioral;