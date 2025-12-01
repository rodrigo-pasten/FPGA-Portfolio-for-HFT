`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2025 17:48:59
// Design Name: 
// Module Name: tb_axis_parser
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


module tb_axis_parser;

    // 1. Signal Declarations
    logic aclk;
    logic aresetn;
    logic [63:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tready;
    logic match_detected;

    //2. Instantiate the UUT (Unit Under Test)
    axis_parser uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .match_detected(match_detected)
    );

    // 3. Clock Generation (100 MHz = 10 ns period)
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // Toggle every 5 ns
    end

    // 4. Test Stimulus
    initial begin
        // Setup the Waveform clarity
        $dumpfile("dump.vcd");
        $dumpvars;

        // Initialize Inputs
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 64'h0;

        // Apply Reset
        #20;
        aresetn = 1;
        #10;

        // Test Case 1: Send Random Noise (No Match)
        @(posedge aclk); // Wait for clock edge
        s_axis_tvalid = 1;
        s_axis_tdata = 64'h1234567890ABCDEF; // Random data

        // Test Case 2: Send the Target Header (Match Expected)
        @(posedge aclk);
        s_axis_tvalid = 1;
        s_axis_tdata = 64'h4846544348494C45; // "HFTCHILE"
        // We expect 'match_detected' to go high INMEDATELY here

        // Test Case 3: Send More Random Noise (No Match)
        @(posedge aclk);
        s_axis_tvalid = 1;
        s_axis_tdata = 64'hDEADBEEFCAFEBABE; // Random data

        // Test Case 4: Valid goes low (Idle)
        @(posedge aclk);
        s_axis_tvalid = 0;
        s_axis_tdata = 64'h0;

        // End Simulation
        #50;
        $finish;
    end
endmodule
