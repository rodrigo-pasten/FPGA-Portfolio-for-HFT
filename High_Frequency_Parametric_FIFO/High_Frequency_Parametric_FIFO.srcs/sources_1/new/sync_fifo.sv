`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2025 00:39:10
// Design Name: 
// Module Name: sync_fifo
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


module sync_fifo
    #(
        parameter DATA_WIDTH = 32, // Width of the data bus
        parameter FIFO_DEPTH = 1024   // Depth of the FIFO (number of entries)
    )
    (
        input logic clk,                            // Clock input
        input logic rst_n,                          // Active low reset                            
        input logic wr_en,                          // Write enable
        input logic [DATA_WIDTH - 1 : 0] wr_data,   // Data input
        input logic rd_en,                          // Read enable

        output logic [DATA_WIDTH - 1 : 0] rd_data,  // Data output
        output logic full,                          // FIFO full indicator
        output logic empty,                         // FIFO empty indicator
        output logic rd_valid                       // Read data valid indicator
    );

    localparam FIFO_DEPTH_LOG = $clog2(FIFO_DEPTH);

    // -------------------------------------------------------------------------
    // 1. BRAM Storage & Pointers
    // -------------------------------------------------------------------------
    (* ram_style = "block" *) 
    logic [DATA_WIDTH - 1 : 0] fifo_mem [0 : FIFO_DEPTH - 1];
    
    logic [FIFO_DEPTH_LOG : 0] wr_ptr; 
    logic [FIFO_DEPTH_LOG : 0] rd_ptr; 
    
    // Explicit Counter for Robust Full Detection
    logic [FIFO_DEPTH_LOG : 0] bram_count;
    logic bram_full;
    logic bram_empty;

    // -------------------------------------------------------------------------
    // 2. Pipeline Registers
    // -------------------------------------------------------------------------
    logic [DATA_WIDTH - 1 : 0] m_data;  // Middle Stage
    logic m_valid;
    
    logic [DATA_WIDTH - 1 : 0] out_data; // Output Stage
    logic out_valid;
    
    // Control Signals
    logic internal_rd_en;
    logic m_move;
    
    // Fast Path Detection
    logic fast_path;
    assign fast_path = (out_valid == 0) && (m_valid == 0) && (bram_empty);

    // -------------------------------------------------------------------------
    // 3. Write Logic (With Fast Path)
    // -------------------------------------------------------------------------
    assign bram_count = wr_ptr - rd_ptr;
    assign bram_full  = (bram_count >= FIFO_DEPTH);
    assign full       = bram_full; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_ptr <= 0;
        else if (wr_en && !full) begin
            if (!fast_path) begin
                fifo_mem[wr_ptr[FIFO_DEPTH_LOG-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. BRAM Read Controller
    // -------------------------------------------------------------------------
    assign bram_empty = (wr_ptr == rd_ptr);
    
    // Refill Middle if BRAM has data AND (Middle is empty OR Middle is moving to Out)
    assign internal_rd_en = !bram_empty && (!m_valid || m_move);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rd_ptr <= 0;
        else if (internal_rd_en) rd_ptr <= rd_ptr + 1;
    end

    // Middle Stage Latch (Prioritized)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_valid <= 0;
            m_data <= 0;
        end else begin
            if (internal_rd_en) begin
                m_valid <= 1; // Refill priority: Stays valid if refilling
            end else if (m_move) begin
                m_valid <= 0; // Drain: Becomes invalid if moved and NOT refilled
            end
        end
    end

    always_ff @(posedge clk) begin
        if (internal_rd_en) m_data <= fifo_mem[rd_ptr[FIFO_DEPTH_LOG-1:0]];
    end

    // -------------------------------------------------------------------------
    // 5. Output Stage Controller
    // -------------------------------------------------------------------------
    assign m_move = m_valid && (!out_valid || rd_en);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            out_data <= 0;
        end else begin
            // 1. Fast Path Write (Inject directly to Output)
            if (wr_en && fast_path) begin
                out_valid <= 1;
                out_data <= wr_data;
            end 
            // 2. Normal Pipeline Move
            else if (m_move) begin
                out_valid <= 1;
                out_data <= m_data;
            end 
            // 3. Consumer Read (Invalidate if not refilled by 1 or 2)
            else if (rd_en) begin
                out_valid <= 0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 6. Final Outputs (Combinatorial Overlay)
    // -------------------------------------------------------------------------
    // Bypass for Cycle 0: Show wr_data immediately if Fast Path is active
    assign rd_data  = (wr_en && fast_path) ? wr_data : out_data;
    assign rd_valid = out_valid || (wr_en && fast_path);
    assign empty    = !rd_valid;
endmodule
