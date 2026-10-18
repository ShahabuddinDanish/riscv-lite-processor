# analyze source files
analyze -format sverilog -library WORK ../src/sram_wrapper.sv

# preserve rtl names in netlist
set power_preserve_rtl_hier_name true

# elaborate top entity
elaborate sram_32_1024_wrapper -lib work
uniquify
link

# applying constraints
set WCP 0.74
create_clock -name "MY_CLK" -period $WCP CLK
set_dont_touch_network MY_CLK

# simulate clock jitter
set_clock_uncertainty 0.07 [get_clocks MY_CLK]

# verify the clock
report_clock > ./reports/clock_fmax.rpt

# max output delay
set_input_delay 0.5 -max -clock MY_CLK [remove_from_collection [all_inputs] CLK]
set_output_delay 0.5 -max -clock MY_CLK [all_outputs]

# output load 
set OUTPUT_LOAD [load_of NangateOpenCellLibrary/BUF_X4/A]
set_load $OUTPUT_LOAD [all_outputs]
check_design

# compile
compile

# timing, area and power report
report_timing > ./reports/timing_fmax.rpt
report_area > ./reports/area_fmax.rpt
#report_power > ./reports/power_fmax.rpt

# export netlist
ungroup -all -flatten
change_names -hierarchy -rules verilog
#write_sdf ../netlist/riscv_ssram.sdf
write -f verilog -hierarchy -output ../netlist/ssram_wrapper.v
#write_sdc ../netlist/riscv_ssram.sdc
exit
