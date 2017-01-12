library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mojo_top is
	port (
		clk			: in  std_logic;		-- 50Mhz clock
		rst_n		: in  std_logic;		-- "reset" button input (negative logic)
		cclk		: in  std_logic;		-- configuration clock (?) from AVR (to detect when AVR ready)
		led			: out std_logic_vector(7 downto 0);	 -- 8 LEDs on Mojo board
		spi_sck		: in  std_logic;		-- SPI clock to from AVR
		spi_ss		: in  std_logic;		-- SPI slave select from AVR
		spi_mosi	: in  std_logic;		-- SPI serial data master out, slave in (AVR -> FPGA)
		spi_miso	: out std_logic;		-- SPI serial data master in, slave out (AVR <- FPGA)
		spi_channel : out std_logic_vector(3 downto 0);  -- analog read channel (input to AVR service task)
		avr_tx		: in  std_logic;		-- serial data transmited from AVR/USB (FPGA recieve)
		avr_rx		: out std_logic;		-- serial data for AVR/USB to receive (FPGA transmit)
		avr_rx_busy : in  std_logic;			-- AVR/USB buffer full (don't send data when true)
		sensor		: in std_logic;		-- sensor input
		esp_tx		: out std_logic;		-- uart outout
		esp_rx		: in std_logic;			-- uart input
		esp_newData : out std_logic;			-- signal new data for esp interrupt
		miso 		: out  std_logic;			
		sck		: in std_logic;
		ss_n		: in std_logic;		
		mosi		: in std_logic;		
		trdy_out : out std_logic
	);
end mojo_top;

architecture RTL of mojo_top is

signal rst	: std_logic;		-- reset signal (rst_n inverted for postive logic)

-- signals for avr_interface
signal channel			: std_logic_vector(3 downto 0);
signal sample			: std_logic_vector(9 downto 0);
signal sample_channel	: std_logic_vector(3 downto 0);
signal new_sample		: std_logic;
signal tx_data			: std_logic_vector(7 downto 0);
signal rx_data			: std_logic_vector(7 downto 0);
signal new_tx_data		: std_logic;
signal new_rx_data		: std_logic;
signal tx_busy			: std_logic;

-- signals for UART echo test
signal uart_data		: std_logic_vector(7 downto 0);	-- data buffer for UART (holds last recieved/sent byte)
signal data_to_send		: std_logic;					-- indicates data to send in uart_data

-- signals for sample test
signal temp_timer		: std_logic_vector(31 downto 0);
signal clk10MHz		: std_logic;
signal clk50MHz		: std_logic;
signal clk_FB			: std_logic;
signal tx_uart_block		: std_logic;
signal tx_uart_busy		: std_logic;
signal tx_uart_newData	: std_logic;
signal tx_uart_data		: std_logic_vector(7 downto 0);
signal rx_uart_newData	: std_logic;
signal rx_uart_data		: std_logic_vector(7 downto 0);
signal rx_uart_busy		: std_logic;

signal sweep_detected 	: std_logic;
signal sweep_value		: std_logic_vector(31 downto 0);
signal uart_counter		: integer range 0 to 5;
signal sweep_count		: std_logic_vector(31 downto 0);
signal temp: std_logic_vector(7 downto 0);

signal fifo_WriteEn	: STD_LOGIC;
signal fifo_DataIn	: STD_LOGIC_VECTOR (31 downto 0);
signal fifo_ReadEn	: STD_LOGIC;
signal fifo_DataOut	: STD_LOGIC_VECTOR (31 downto 0);
signal fifo_Count 	: natural range 0 to 255;
signal fifo_Empty	: STD_LOGIC;
signal fifo_Full	: STD_LOGIC;

signal miso_en	: STD_LOGIC;
signal done	: STD_LOGIC;

begin

rst	<= NOT rst_n;						-- generate non-inverted reset signal from rst_n button

-- NOTE: If you are not using the avr_interface component, then you should uncomment the
--       following lines to keep the AVR output lines in a high-impeadence state.  When
--       using the avr_interface, this will be done automatically and these lines should
--       be commented out (or else "multiple signals connected to output" errors).
--spi_miso <= 'Z';						-- keep AVR output lines high-Z
--avr_rx <= 'Z';						-- keep AVR output lines high-Z
--spi_channel <= "ZZZZ";				-- keep AVR output lines high-Z

clock10MHz: entity work.clk10MHz
port map(
		clk 	=> clk,
		rst	=> rst,
		clk10MHz_out 	=> clk10MHz,
		clk50MHz_out 	=> clk50MHz
	);

-- instantiate the avr_interface (to handle USB UART and analog sampling, etc.)
avr_interface : entity work.avr_interface
	port map (
		clk			=> clk50MHz,				-- 50Mhz clock
		rst			=> rst,				-- reset signal
		-- AVR MCU pin connections (that will be managed)
		cclk		=> cclk,
		spi_miso	=> spi_miso,
		spi_mosi	=> spi_mosi,
		spi_sck		=> spi_sck,
		spi_ss		=> spi_ss,
		spi_channel	=> spi_channel,
		tx			=> avr_rx,
		tx_block	=> avr_rx_busy,
		rx			=> avr_tx,
		-- analog sample interface
		channel		=> channel,			-- set this to channel to sample (0, 1, 4, 5, 6, 7, 8, or 9)
		new_sample	=> new_sample,		-- indicates when new sample available
		sample_channel => sample_channel,	-- channel number of sample (only when new_sample = '1')
		sample		=> sample,			-- 10 bit sample value (only when new_sample = '1')
		-- USB UART tx interface
		new_tx_data	=> new_tx_data,		-- set to set data in tx_data (only when tx_busy = '0')
		tx_data		=> tx_data,			-- data to send
		tx_busy		=> tx_busy,			-- indicates AVR is not ready to send data
		-- USB UART rx interface
		new_rx_data	=> new_rx_data,		-- set when new data is received
		rx_data		=> rx_data			-- received data (only when new_tx_data = '1')
	);

counter: entity work.counter
	port map(
		clock 	=> clk10MHz,
		output 	=> temp_timer
	);

sweep_counter: entity work.counter
	port map(
		clock 	=> sweep_detected,
		output 	=> sweep_count
	);
	
lighthouse: entity work.lighthouse
	port map(
		clk 			=> clk50MHz,
		clk10MHz 	=> clk10MHz,
		sensor	 	=> sensor,
		timer			=> temp_timer,
		sweep_detected => sweep_detected,
		sensor_value => sweep_value
	);
	
uart: entity work.RS232
	port map(
		CLK		=> clk50MHz,
		RXD		=> esp_rx,
		RX_DATA 	=> rx_uart_data,
		RX_BUSY	=> rx_uart_busy,
		TXD 		=> esp_tx,
      TX_Data  => tx_uart_data,
      TX_Start => tx_uart_newData,
      TX_Busy 	=> tx_uart_busy
	);
	
fifo: entity work.STD_FIFO
	port map(
		CLK		=> clk50MHz,
		RST		=> rst,
		WriteEn	=> fifo_WriteEn,
		DataIn	=> sweep_value,
		ReadEn	=> fifo_ReadEn,
		DataOut	=> fifo_DataOut,
		Empty		=> fifo_Empty,
		Full	   => fifo_Full
	);
	
spi_slave: entity work.spi_slave
	port map(
		clk 	=> clk50MHz,
		rst	=> rst,
		ss		=> ss_n,
		mosi	=> mosi,
		miso	=> miso,
		miso_en => miso_en,
		done	=> done,
		sck	=> sck, 
		din	=> temp
  );
	
darkroom: process(clk50MHz, rst)
constant ss: character := 's'; 
begin
	if rising_edge(clk50MHz) then
	
		fifo_ReadEn <= '0';
		if (ss_n = '0') and (uart_counter < 4) and (done = '1') then -- if uart not busy and not all data was sent
			case uart_counter is
			  when 0      =>  temp <= fifo_DataOut(7 downto 0);--std_logic_vector(to_unsigned(65,8));--;
			  when 1      =>  temp <= fifo_DataOut(15 downto 8);--std_logic_vector(to_unsigned(66,8));--sweep_value(15 downto 8);
			  when 2		  =>  temp <= fifo_DataOut(23 downto 16);--std_logic_vector(to_unsigned(67,8));--sweep_value(23 downto 16);
			  when 3		  =>  temp <= fifo_DataOut(31 downto 24);--std_logic_vector(to_unsigned(68,8));--sweep_value(31 downto 24);
			  when others 	  => 	temp <= "11111111";
			end case;
			uart_counter <= uart_counter + 1;	
		elsif (fifo_Empty = '0') and (ss_n = '1') then  -- if all data was sent and there is new data available
			uart_counter <= 0; 
			trdy_out <= '1';
			fifo_ReadEn <= '1';
		elsif (uart_counter >= 4) then
			trdy_out <= '0';
		end if;
		
		fifo_WriteEn <= '0';
		if (sweep_detected = '1') and (uart_counter >= 4) then
			fifo_WriteEn <= sweep_detected;
		end if;
		
--		tx_uart_newData <= '0';
--		fifo_ReadEn <= '0';
--		if(tx_uart_busy = '0') and (uart_counter < 4) then -- if uart not busy and not all data was sent
--			case uart_counter is
--			  when 0      =>  tx_uart_data <= temp(7 downto 0);--std_logic_vector(to_unsigned(65,8));--;
--			  when 1      =>  tx_uart_data <= temp(15 downto 8);--std_logic_vector(to_unsigned(66,8));--sweep_value(15 downto 8);
--			  when 2		  =>  tx_uart_data <= temp(23 downto 16);--std_logic_vector(to_unsigned(67,8));--sweep_value(23 downto 16);
--			  when 3		  =>  tx_uart_data <= temp(31 downto 24);--std_logic_vector(to_unsigned(68,8));--sweep_value(31 downto 24);
--			  when others 	  => 	tx_uart_data <= "11111111";
--			end case;
--			tx_uart_newData <= '1';
--			uart_counter <= uart_counter + 1;	
--		elsif (tx_uart_busy = '0') and (uart_counter >= 4) and (fifo_Full = '1') then  -- if all data was sent and there is new data available
--			uart_counter <= 0; 
--			esp_newData <= '0';
--			fifo_ReadEn <= '1';
--		elsif (uart_counter >= 4) then
--			esp_newData <= '1'; -- active low
--		end if;
--		
--		fifo_WriteEn <= '0';
--		if (sweep_detected = '1') and (uart_counter >= 4) then
--			temp <= fifo_DataOut;
--			fifo_WriteEn <= sweep_detected;
--		end if;
		
		led <= sweep_count(7 downto 0);
	end if;
end process darkroom;
	
end RTL;
