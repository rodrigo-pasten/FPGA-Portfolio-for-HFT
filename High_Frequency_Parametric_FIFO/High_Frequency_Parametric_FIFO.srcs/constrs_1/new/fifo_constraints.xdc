# 1. Clock Definition 
create_clock -period 2.500 -name clk -waveform {0.000 1.250} [get_ports clk]


# This prevents Vivado from assuming the clock is perfect and helps with Hold timing later.
set_clock_uncertainty 0.035 [get_clocks clk]