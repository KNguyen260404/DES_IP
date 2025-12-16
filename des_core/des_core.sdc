set clk_name clk
set clk_port_name clk
set clk_period 6.67
set clk_io_pct 0.2

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

set input_delay_value [expr $clk_period * $clk_io_pct]
set output_delay_value [expr $clk_period * $clk_io_pct]

# Set input/output delays (exclude clock port manually)
set all_inputs_except_clk [get_ports {rst_n des_encipher_en des_decipher_en des_data[*] des_key_in[*]}]
set_input_delay $input_delay_value -clock $clk_name $all_inputs_except_clk
set_output_delay $output_delay_value -clock $clk_name [get_ports {desc_result[*] desc_ready}]

# Set driving cell and load
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $all_inputs_except_clk
set_load 0.05 [get_ports {desc_result[*] desc_ready}]

set_max_fanout 10 [current_design]
