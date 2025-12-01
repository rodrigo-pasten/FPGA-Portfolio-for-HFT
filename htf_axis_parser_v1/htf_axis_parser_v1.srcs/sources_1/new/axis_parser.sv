`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2025 17:36:38
// Design Name: 
// Module Name: axis_parser
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axis_parser(
    // Clock and Reset
    input logic aclk,
    input logic aresetn, // Active low reset

    // AXI-Stream Slave Interface (the incoming data)
    // 64-bit data = 8 bytes.
    input logic [63:0] s_axis_tdata,
    input logic s_axis_tvalid, // Master says "data is valid"
    output logic s_axis_tready, // We say "ready to accept data"
    
    // The HFT Output
    output logic match_detected // Goeas high INSTANTLY when a match is found
    );

    // -------------------------------
    // 1. Define the Target
    // -------------------------------
    // We are looking for the ASCII string "HFTCHILE" (8 bytes)
    // Hex: 0x48 (H) 0x46 (F) 0x54 (T) 0x43 (C) 0x48 (H) 0x49 (I) 0x4C (L) 0x45 (E)
    // Note: Network data is usually big endian
    localparam logic [63:0] TARGET_HEADER = 64'h4846544348494C45;

    // -------------------------------
    // 2. The Flow Control
    // -------------------------------
    // For this specific exercise, we are an "Always Ready" consumer.
    // In a real system, you might drop ready if your FIFO is full
    assign s_axis_tready = 1'b1;

    // -------------------------------
    // 3. The Zero-Latency Logic (Combinational)
    // -------------------------------
    // HFT Requirement: "Assert a valid signal on the SAME cycle"
    // We do NOT use 'always_ff @(posedge aclk)' here, that would add 1 cycle delay.
    // We use 'assign' for pure boolen logic.
    assign match_detected = (s_axis_tvalid && (s_axis_tdata == TARGET_HEADER));

endmodule
