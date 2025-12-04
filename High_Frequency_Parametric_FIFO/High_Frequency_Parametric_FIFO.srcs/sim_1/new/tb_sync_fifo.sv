`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2025 15:07:12
// Design Name: 
// Module Name: tb_sync_fifo
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


module tb_sync_fifo();

    parameter DATA_WIDTH = 32;
    parameter FIFO_DEPTH = 16;

    logic clk, rst_n, wr_en, rd_en, full, empty, rd_valid;
    logic [DATA_WIDTH - 1 : 0] wr_data, rd_data;

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH)) uut (.*);

    initial begin
        clk = 0; forever #1.25 clk = ~clk; 
    end

    integer test_errors = 0;

    initial begin
        rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 0;
        #15; rst_n = 1; #10;

        $display("========================================");
        $display("Starting FINAL FIFO Testbench");
        $display("========================================");

        $display("\n[TEST 1] Sanity Check");
        test_sanity_check();
        
        rst_n=0; #10; rst_n=1; #10; 

        $display("\n[TEST 2] Dynamic Full Flag Test");
        test_full_flag();

        rst_n=0; #10; rst_n=1; #10; 

        $display("\n[TEST 3] Throughput Test");
        test_throughput();

        rst_n=0; #10; rst_n=1; #10; 

        $display("\n[TEST 4] Zero Latency (Bypass) Test");
        test_zero_latency();

        $display("\n========================================");
        if (test_errors == 0) $display("ALL TESTS PASSED!");
        else $display("TEST FAILURES: %d errors detected", test_errors);
        $display("========================================\n");
        $finish;
    end

    task test_sanity_check();
        integer i, cnt=0;
        integer timeout;
        logic [DATA_WIDTH-1:0] exp;
        
        for (i=0; i<10; i++) begin
            @(negedge clk);
            if (!full) begin wr_en=1; wr_data=(i+1)*32'h11111111; cnt++; end
        end
        @(negedge clk); wr_en=0;

        for (i=0; i<cnt; i++) begin
            timeout = 0;
            while(!rd_valid && timeout < 100) begin
                @(negedge clk);
                timeout++;
            end
            if (timeout >= 100) begin $display("  ERROR: Timeout Idx %d", i); test_errors++; break; end
            
            exp = (i+1)*32'h11111111;
            if (rd_data !== exp) begin
                $display("  ERROR: Idx %d. Exp %h, Got %h", i, exp, rd_data);
                test_errors++;
            end
            rd_en=1; @(negedge clk); rd_en=0;
        end
        #10;
        if (!empty) begin $display("  ERROR: Not empty!"); test_errors++; end
        else $display("Passed");
    endtask

    task test_full_flag();
        integer i, count_filled, count_read;
        integer timeout;
        count_filled = 0;
        count_read = 0;
        
        $display("  Filling FIFO...");
        // Robust Fill Loop: Check full at negedge before writing
        while (count_filled < FIFO_DEPTH + 10) begin
            @(negedge clk);
            if (full) begin
                // FIFO is full, stop writing
                wr_en = 0;
                break; 
            end
            wr_en = 1; 
            wr_data = 32'hDEADBEEF + count_filled;
            count_filled++;
        end
        @(negedge clk); wr_en = 0;
        
        $display("  FIFO Full after %d writes (Expected >= %d)", count_filled, FIFO_DEPTH);
        
        if (!full) begin $display("  ERROR: Full flag never asserted!"); test_errors++; end
        if (count_filled < FIFO_DEPTH) begin $display("  ERROR: Capacity too small!"); test_errors++; end
        
        // Drain Dynamically (Don't trust count_filled blindly)
        timeout = 0;
        while (!empty && timeout < 500) begin
             // Wait for data valid if empty logic lags slightly
             while(!rd_valid && !empty && timeout < 500) begin 
                @(negedge clk); timeout++; 
             end
             
             if (empty) break; // Double check

             rd_en = 1; 
             count_read++;
             @(negedge clk); 
             rd_en = 0;
        end
        
        $display("  Read %d items", count_read);
        
        if (count_read != count_filled) begin
             $display("  ERROR: Mismatch! Wrote %d, Read %d (Data lost?)", count_filled, count_read);
             test_errors++;
        end else begin
             $display("Passed");
        end
    endtask

    task test_throughput();
        integer i, wc=0, rc=0;
        integer timeout;
        
        for (i=0; i<8; i++) begin
            @(negedge clk); wr_en=1; wr_data=i;
        end
        @(negedge clk); wr_en=0; #5;

        for (i=0; i<200; i++) begin
            @(negedge clk);
            if (!full) begin wr_en=1; wr_data=wc+100; wc++; end else wr_en=0;
            if (!empty) begin rd_en=1; rc++; end else rd_en=0;
        end
        @(negedge clk); wr_en=0; rd_en=0;
        
        timeout = 0;
        while(!empty && timeout < 500) begin
            @(negedge clk); 
            if(!empty) begin rd_en=1; rc++; end
            timeout++;
        end
        if (timeout >= 500) begin $display("  ERROR: Throughput Drain Stuck"); test_errors++; end
        @(negedge clk); rd_en=0;
        
        $display("  Wrote %d, Read %d", wc+8, rc);
        if ((wc+8) != rc) begin $display("  ERROR: Mismatch"); test_errors++; end
        else $display("Passed");
    endtask

    task test_zero_latency();
        @(negedge clk); wr_en=1; wr_data=32'hDEADC0DE;
        #1; 
        if (rd_data !== 32'hDEADC0DE) begin
            $display("  ERROR: Combinatorial Bypass failed. Got %h", rd_data); test_errors++;
        end 
        @(negedge clk); wr_en=0; 
        #1;
        if (rd_data !== 32'hDEADC0DE) begin
            $display("  ERROR: Latch persistence failed. Got %h", rd_data); test_errors++;
        end else $display("Bypass Correct");
        
        @(negedge clk); rd_en=1; 
        @(negedge clk); rd_en=0;
        $display("Passed");
    endtask
endmodule
