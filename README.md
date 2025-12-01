# FPGA & HFT Engineering Portfolio
**Author:** Rodrigo Pastén | **Focus:** Ultra-Low Latency Architecture & SystemVerilog

## Overview
This repository documents my progression through a rigorous High-Frequency Trading (HFT) engineering roadmap. It contains modular, verified hardware designs focused on nanosecond-scale latency, memory hierarchy, and cut-through processing.

## Technical Roadmap & Modules

| ID | Project Name | Key Concept | Latency | Status |
| :--- | :--- | :--- | :--- | :--- |
| **01** | [**AXI-Stream Pattern Matcher**] | Cut-Through Parsing, Combinatorial Logic | **0 Cycles** | ✅ Complete |
| **02** | Async FIFO (Planned) | CDC, Gray Coding, Formal Verification | TBD | 🚧 Pending |
| **03** | 10G Ethernet MAC (Planned) | Network Protocol, CRC Pipelining | TBD | 📅 Planned |
| **04** | Tick-to-Trade Engine (Planned) | Full Loopback, Order Generation | TBD | 📅 Planned |

## Tools & Standards
* **Languages:** SystemVerilog, C++ (Verilator), Python.
* **Verification:** Self-checking testbenches, UVM (upcoming), Formal (SymbiYosys).
