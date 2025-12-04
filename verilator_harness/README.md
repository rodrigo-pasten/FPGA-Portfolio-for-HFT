# Project 02: C++ Verification Harness (Verilator)

## Objective
Migrate from manual waveform inspection to automated, high-throughput verification using Verilator and C++. [cite_start]This satisfies Phase 2 of the roadmap[cite: 78].

## Implementation
* **DUT:** The `axis_parser` from Project 01.
* **Harness:** A C++ wrapper (`sim_main.cpp`) that acts as the AXI Master.
* **Volume:** Injected 1,000,000 pseudo-random 64-bit packets.

## Results
* **Throughput:** Processed 1M cycles in < 100ms.
* **Verification:** Confirmed 0 false positives and 100% capture rate of the target header `0x4846545F4348494C`.

## Commands
```bash
# To build and run
verilator -Wall --cc --exe --build -j 4 -I./rtl rtl/axis_parser.sv sim/sim_main.cpp --top-module axis_parser
./obj_dir/Vaxis_parser