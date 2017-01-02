set projDir "/home/letrend/mojo/darkroom/work/planAhead"
set projName "darkroom"
set topName top
set device xc6slx9-2tqg144
if {[file exists "$projDir/$projName"]} { file delete -force "$projDir/$projName" }
create_project $projName "$projDir/$projName" -part $device
set_property design_mode RTL [get_filesets sources_1]
set verilogSources [list "/home/letrend/mojo/darkroom/work/verilog/mojo_top_0.v" "/home/letrend/mojo/darkroom/work/verilog/reset_conditioner_1.v" "/home/letrend/mojo/darkroom/work/verilog/avr_interface_2.v" "/home/letrend/mojo/darkroom/work/verilog/counter_3.v" "/home/letrend/mojo/darkroom/work/verilog/lighthouse_sensor_4.v" "/home/letrend/mojo/darkroom/work/verilog/cclk_detector_5.v" "/home/letrend/mojo/darkroom/work/verilog/spi_slave_6.v" "/home/letrend/mojo/darkroom/work/verilog/uart_rx_7.v" "/home/letrend/mojo/darkroom/work/verilog/uart_tx_8.v" "/home/letrend/mojo/darkroom/work/verilog/edge_detector_9.v" "/home/letrend/mojo/darkroom/work/verilog/edge_detector_10.v"]
import_files -fileset [get_filesets sources_1] -force -norecurse $verilogSources
set ucfSources [list  "/opt/mojo-ide-B1.3.5/library/components/mojo.ucf"]
import_files -fileset [get_filesets constrs_1] -force -norecurse $ucfSources
set coreSources [list "/home/letrend/mojo/darkroom/coreGen/clock10MHz.v"]
import_files -fileset [get_filesets sources_1] -force -norecurse $coreSources
set_property -name {steps.bitgen.args.More Options} -value {-g Binary:Yes -g Compress} -objects [get_runs impl_1]
set_property steps.map.args.mt on [get_runs impl_1]
set_property steps.map.args.pr b [get_runs impl_1]
set_property steps.par.args.mt on [get_runs impl_1]
update_compile_order -fileset sources_1
launch_runs -runs synth_1
wait_on_run synth_1
launch_runs -runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step Bitgen
wait_on_run impl_1
