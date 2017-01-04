/*
   This file was generated automatically by the Mojo IDE version B1.3.5.
   Do not edit this file directly. Instead edit the original Lucid source.
   This is a temporary file and any changes made to it will be destroyed.
*/

module mojo_top_0 (
    input clk,
    input rst_n,
    output reg [7:0] led,
    input cclk,
    output reg spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    output reg [3:0] spi_channel,
    input avr_tx,
    output reg avr_rx,
    input avr_rx_busy,
    input sensor,
    output reg esp_tx,
    input esp_rx,
    output reg data_available
  );
  
  
  
  reg rst;
  
  wire [1-1:0] M_reset_cond_out;
  reg [1-1:0] M_reset_cond_in;
  reset_conditioner_1 reset_cond (
    .clk(clk),
    .in(M_reset_cond_in),
    .out(M_reset_cond_out)
  );
  wire [1-1:0] M_avr_spi_miso;
  wire [4-1:0] M_avr_spi_channel;
  wire [1-1:0] M_avr_tx;
  wire [1-1:0] M_avr_new_sample;
  wire [10-1:0] M_avr_sample;
  wire [4-1:0] M_avr_sample_channel;
  wire [1-1:0] M_avr_tx_busy;
  wire [8-1:0] M_avr_rx_data;
  wire [1-1:0] M_avr_new_rx_data;
  reg [1-1:0] M_avr_cclk;
  reg [1-1:0] M_avr_spi_mosi;
  reg [1-1:0] M_avr_spi_sck;
  reg [1-1:0] M_avr_spi_ss;
  reg [1-1:0] M_avr_rx;
  reg [4-1:0] M_avr_channel;
  reg [8-1:0] M_avr_tx_data;
  reg [1-1:0] M_avr_new_tx_data;
  reg [1-1:0] M_avr_tx_block;
  avr_interface_2 avr (
    .clk(clk),
    .rst(rst),
    .cclk(M_avr_cclk),
    .spi_mosi(M_avr_spi_mosi),
    .spi_sck(M_avr_spi_sck),
    .spi_ss(M_avr_spi_ss),
    .rx(M_avr_rx),
    .channel(M_avr_channel),
    .tx_data(M_avr_tx_data),
    .new_tx_data(M_avr_new_tx_data),
    .tx_block(M_avr_tx_block),
    .spi_miso(M_avr_spi_miso),
    .spi_channel(M_avr_spi_channel),
    .tx(M_avr_tx),
    .new_sample(M_avr_new_sample),
    .sample(M_avr_sample),
    .sample_channel(M_avr_sample_channel),
    .tx_busy(M_avr_tx_busy),
    .rx_data(M_avr_rx_data),
    .new_rx_data(M_avr_new_rx_data)
  );
  reg [7:0] M_data_d, M_data_q = 1'h0;
  
  wire [1-1:0] M_clock_10MHz_clk_out;
  clock10MHz clock_10MHz (
    .clk_in(clk),
    .clk_out(M_clock_10MHz_clk_out)
  );
  
  wire [32-1:0] M_timer_value;
  counter_3 timer (
    .clk(M_clock_10MHz_clk_out),
    .rst(rst),
    .value(M_timer_value)
  );
  
  wire [1-1:0] M_sensor0_sweep_detected;
  wire [32-1:0] M_sensor0_value;
  lighthouse_sensor_4 sensor0 (
    .signal(sensor),
    .signal_inverted(~sensor),
    .rst(rst),
    .timer(M_timer_value),
    .sweep_detected(M_sensor0_sweep_detected),
    .value(M_sensor0_value)
  );
  
  wire [1-1:0] M_esp_transmit_tx;
  wire [1-1:0] M_esp_transmit_busy;
  reg [8-1:0] M_esp_transmit_data;
  reg [1-1:0] M_esp_transmit_new_data;
  uart_tx_5 esp_transmit (
    .clk(clk),
    .rst(rst),
    .block(rst),
    .data(M_esp_transmit_data),
    .new_data(M_esp_transmit_new_data),
    .tx(M_esp_transmit_tx),
    .busy(M_esp_transmit_busy)
  );
  
  wire [8-1:0] M_esp_receive_data;
  wire [1-1:0] M_esp_receive_new_data;
  reg [1-1:0] M_esp_receive_rx;
  uart_rx_6 esp_receive (
    .clk(clk),
    .rst(rst),
    .rx(M_esp_receive_rx),
    .data(M_esp_receive_data),
    .new_data(M_esp_receive_new_data)
  );
  
  reg [2:0] M_counter_d, M_counter_q = 1'h0;
  
  always @* begin
    M_counter_d = M_counter_q;
    
    M_reset_cond_in = ~rst_n;
    rst = M_reset_cond_out;
    M_avr_cclk = cclk;
    M_avr_spi_ss = spi_ss;
    M_avr_spi_mosi = spi_mosi;
    M_avr_spi_sck = spi_sck;
    M_avr_rx = avr_tx;
    M_avr_channel = 4'hf;
    M_avr_tx_block = avr_rx_busy;
    spi_miso = M_avr_spi_miso;
    spi_channel = M_avr_spi_channel;
    avr_rx = M_avr_tx;
    M_avr_new_tx_data = 1'h1;
    M_avr_new_tx_data = 1'h0;
    M_avr_tx_data = 1'h0;
    esp_tx = M_esp_transmit_tx;
    M_esp_receive_rx = esp_rx;
    M_esp_transmit_data = 1'h0;
    M_esp_transmit_new_data = 1'h0;
    data_available = 1'h0;
    if (M_timer_value[24+0-:1] && M_counter_q < 3'h4) begin
      data_available = 1'h1;
      if (!M_esp_transmit_busy) begin
        
        case (M_counter_q)
          1'h0: begin
            M_esp_transmit_data = 7'h41;
          end
          1'h1: begin
            M_esp_transmit_data = 7'h42;
          end
          2'h2: begin
            M_esp_transmit_data = 7'h43;
          end
          2'h3: begin
            M_esp_transmit_data = 7'h44;
          end
        endcase
        M_esp_transmit_new_data = 1'h1;
        M_counter_d = M_counter_q + 1'h1;
      end
    end else begin
      if (!M_timer_value[24+0-:1] && M_counter_q >= 3'h4) begin
        data_available = 1'h0;
        M_counter_d = 1'h0;
      end else begin
        data_available = 1'h1;
      end
    end
    led = M_timer_value[23+6-:7];
  end
  
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_data_q <= 1'h0;
    end else begin
      M_data_q <= M_data_d;
    end
  end
  
  
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_counter_q <= 1'h0;
    end else begin
      M_counter_q <= M_counter_d;
    end
  end
  
endmodule
