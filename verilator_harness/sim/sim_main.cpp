#include <verilated.h>
#include "Vaxis_parser.h"
#include <iostream>
#include <vector>
#include <random>
#include <chrono> // added for timing


vluint64_t main_time = 0;

int main(int argc, char** argv) {

    // 1. Setup Verilator Context
    Verilated::commandArgs(argc, argv);
    auto exec_start = std::chrono::high_resolution_clock::now();

    Vaxis_parser* top = new Vaxis_parser; // Instantiate the DUT

    // 2. Setup Random Number Generation (Simulating Market Data)
    std::mt19937 rng(42); // Fixed seed for reproducibility
    std::uniform_int_distribution<uint64_t> dist64;

    //3. Simulation Parameters
    const uint64_t MAX_CYCLES = 1000000;
    const uint64_t TARGET = 0x4846544348494C45; // "HFTCHILE"
    int match_count = 0;

    // 4. Reset Sequence
    top->aclk = 0;
    top->aresetn = 0; // Assert Reset (Active Low)
    top->eval(); //Evaluate logic
    top->aclk = 1;
    top->eval();
    top->aclk = 0;
    top->aresetn = 1; // Release Reset
    top->eval();


    // 5. The "Run" Loop (The Tick-to-Trade Simulation)
    std::cout << "[INFO] Starting Simulation of " << MAX_CYCLES << " cycles..." << std::endl;
    for (int i = 0; i < MAX_CYCLES; ++i) {
        // --- A. Rising Edge (Drive Inputs) ---
        top->aclk = 1;

        // Randomly decide if data is valid (90% load)
        top->s_axis_tvalid = 1;

        // Inject Data: Occasioanlly insert the TARGET, otherwise noise
        if (i % 1000 == 0) {
            top->s_axis_tdata = TARGET;
        } else {
            top->s_axis_tdata = dist64(rng);
        }

        // Evaluate combinational logic (The FPGA "Hardware" updates)
        top->eval();

        // --- B. Check Outputs (Scoreboard) ---
        // Verifing the "Zero-Latency" requirement
        if (top->match_detected) {
            // Check if it's a False Positive
            if (top->s_axis_tdata != TARGET) {
                std::cerr << "[ERROR] False Positive at cycle" << i << std::endl;
                return 1;
        }
        match_count++;
    }

    // --- C. Falling Edge ---
    top->aclk = 0;
    top->eval();
    main_time++;
    }

    // 6. Final Report
    std::cout << "[SUCCESS Simulation Complete.]" << std::endl;
    std::cout << "Cycle Processed: " << MAX_CYCLES << std::endl;
    std::cout << "Matches Found: " << match_count << std::endl;

    // 7. Cleanup
    delete top;

    // End overall execution timer and report
    auto exec_end = std::chrono::high_resolution_clock::now();
    auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(exec_end - exec_start).count();
    double elapsed_s = elapsed_ms / 1000.0;
    std::cout << "[INFO] Total execution time: " << elapsed_ms << " ms (" << elapsed_s << " s)" << std::endl;

    return 0;
}


