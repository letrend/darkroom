<?xml version="1.0" encoding="UTF-8"?>
<project name="darkroom" board="Mojo V3" language="Lucid">
  <files>
    <src top="true">mojo_top.luc</src>
    <src>lighthouse_sensor.luc</src>
    <ucf lib="true">mojo.ucf</ucf>
    <ucf>esp.ucf</ucf>
    <component>counter.luc</component>
    <component>cclk_detector.luc</component>
    <component>uart_rx.luc</component>
    <component>spi_slave.luc</component>
    <component>avr_interface.luc</component>
    <component>uart_tx.luc</component>
    <component>reset_conditioner.luc</component>
    <component>edge_detector.luc</component>
    <core name="clock10MHz">
      <src>clock10MHz.v</src>
    </core>
  </files>
</project>
