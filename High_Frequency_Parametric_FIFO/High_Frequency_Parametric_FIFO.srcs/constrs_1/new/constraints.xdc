# 1. Clock Definition (Keep this!)
create_clock -period 2.500 -name clk -waveform {0.000 1.250} [get_ports clk]

# 2. I/O Constraints - COMMENT THESE OUT!
# We are testing the core logic speed, not the I/O Pin speed.
# set_input_delay ...
# set_output_delay ...

# 3. Setting specific to Out-of-Context (Optional but good)
# This prevents Vivado from assuming the clock is perfect and helps with Hold timing later.
set_clock_uncertainty 0.035 [get_clocks clk]