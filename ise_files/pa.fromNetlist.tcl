
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Mojo-Base-VHDL -dir "/home/letrend/workspace/darkroom/ise_files/planAhead_run_4" -part xc6slx9tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/letrend/workspace/darkroom/ise_files/mojo_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/letrend/workspace/darkroom/ise_files} }
set_property target_constrs_file "/home/letrend/workspace/darkroom/src/mojo.ucf" [current_fileset -constrset]
add_files [list {/home/letrend/workspace/darkroom/src/mojo.ucf}] -fileset [get_property constrset [current_run]]
link_design
