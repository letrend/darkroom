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
	signal t_sweep_duration: std_logic_vector(31 downto 0);
	signal data: std_logic;
	signal rotor: std_logic;
	signal lighthouse: std_logic;
	signal start_valid_sync 	: std_logic_vector(31 downto 0);
	signal sensor_previous		: std_logic;
	constant zeros : std_logic_vector(t_0'range) := (others => '0');

	
begin   process(clk, sensor)
	variable duration: std_logic_vector(31 downto 0);
	variable stop_valid_sync : std_logic_vector(31 downto 0) := (others => '0');
	variable sync_gap_duration 	: std_logic_vector(31 downto 0):= (others => '0');
   begin
		if rising_edge(clk) then
			sensor_previous <= sensor;
			if (sensor_previous = '0') and (sensor = '1') then
				t_0 <= timer;
			elsif (sensor_previous = '1') and (sensor = '0') then
				duration := std_logic_vector(unsigned(timer)-unsigned(t_0));
				sweep_detected <= '0';
				if(duration < 500) then -- this is a sweep
					t_sweep_duration <= (t_0-t_sweep_start);
					sweep_detected <= '1';
				elsif (duration > (625 - 20)) and (duration < (938 + 20)) then -- this is a sync pulse, NOT skipping
					t_sweep_start <= t_0;
					
					if(start_valid_sync = 0) then
						start_valid_sync <= t_0;
					elsif(start_valid_sync /= 0 and stop_valid_sync = 0) then
						stop_valid_sync := t_0;
					end if;
				end if;
				
				if((start_valid_sync > 0) and (stop_valid_sync > 0)) then
					sync_gap_duration := std_logic_vector(unsigned(stop_valid_sync) - unsigned(start_valid_sync));
					start_valid_sync <= t_0;
					stop_valid_sync := (others => '0');
					if((sync_gap_duration - 83330 ) > 1000 ) then
						lighthouse <= '1';
					elsif ((sync_gap_duration - 83330 ) < -1000 ) then
						lighthouse <= '0';
					end if;
				end if;
				
				if((duration > 625 - 50) and (duration < 625 + 50)) or 
				  ((duration > 1040 - 50) and (duration < 1040 + 50)) then
					rotor <= '0';
					data  <= '0';
				elsif((duration > 729 - 50) and (duration < 729 + 50)) or 
				  ((duration > 1150 - 50) and (duration < 1150 + 50)) then
					rotor <= '1';
					data  <= '0';
				elsif((duration > 833 - 50) and (duration < 833 + 50)) or 
				  ((duration > 1250 - 50) and (duration < 1250 + 50)) then
					rotor <= '0';
					data  <= '1';
				elsif((duration > 938 - 50) and (duration < 938 + 50)) or 
				  ((duration > 1350 - 50) and (duration < 1350 + 50)) then
					rotor <= '1';
					data  <= '1';
				end if;
				
				if(t_sweep_duration < 81920) and (t_sweep_duration > 0 ) then 
					sensor_value(12) <= '1'; -- valid sweep
				else
					sensor_value(12) <= '0'; -- not valid
				end if;
				
				sensor_value(8 downto 0) <= sensorID;
				sensor_value(9) <= lighthouse;
				sensor_value(10) <= rotor;
				sensor_value(11) <= data;
				sensor_value(31 downto 13) <= t_sweep_duration(18 downto 0);--;t_sweep_duration(18 downto 0);--
			end if;
		end if;
   end process;
end Behavioral;