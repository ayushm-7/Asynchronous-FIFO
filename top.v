`timescale 1ns / 1ps
module top #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8,
    parameter PTR_WIDTH  = $clog2(DEPTH)
)(
    input  wire                  wclk,
    input  wire                  rclk,
    input  wire                  wrst_n,
    input  wire                  rrst_n,

    input  wire                  w_en,
    input  wire                  r_en,

    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out,

    output wire                  full,
    output wire                  empty
);

    // ------------------------------------------------
    // Binary pointers
    // ------------------------------------------------
    wire [PTR_WIDTH:0] b_wptr;
    wire [PTR_WIDTH:0] b_rptr;

    // ------------------------------------------------
    // Gray-code pointers
    // ------------------------------------------------
    wire [PTR_WIDTH:0] g_wptr;
    wire [PTR_WIDTH:0] g_rptr;

    // ------------------------------------------------
    // Synchronized Gray-code pointers
    // ------------------------------------------------
    wire [PTR_WIDTH:0] g_wptr_sync;
    wire [PTR_WIDTH:0] g_rptr_sync;


    // ------------------------------------------------
    // Write pointer -> Read clock domain
    // ------------------------------------------------
    synchronizer #(
        .PTR_WIDTH(PTR_WIDTH)
    ) sync_wptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .d_in  (g_wptr),
        .d_out (g_wptr_sync)
    );


    // ------------------------------------------------
    // Read pointer -> Write clock domain
    // ------------------------------------------------
    synchronizer #(
        .PTR_WIDTH(PTR_WIDTH)
    ) sync_rptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .d_in  (g_rptr),
        .d_out (g_rptr_sync)
    );


    // ------------------------------------------------
    // Write pointer handler
    // ------------------------------------------------
    write_pointer_handler #(
        .PTR_WIDTH(PTR_WIDTH)
    ) wptr_handler (
        .wclk        (wclk),
        .wrst_n      (wrst_n),
        .w_en        (w_en),
        .full        (full),
        .g_rptr_sync (g_rptr_sync),

        .b_wptr      (b_wptr),
        .g_wptr      (g_wptr),
        .wfull       (full)
    );


    // ------------------------------------------------
    // Read pointer handler
    // ------------------------------------------------
    read_pointer_handler #(
        .PTR_WIDTH(PTR_WIDTH)
    ) rptr_handler (
        .rclk        (rclk),
        .rrst_n      (rrst_n),
        .r_en        (r_en),
        .empty       (empty),
        .g_wptr_sync (g_wptr_sync),

        .b_rptr      (b_rptr),
        .g_rptr      (g_rptr),
        .rempty      (empty)
    );


    // ------------------------------------------------
    // FIFO memory
    // ------------------------------------------------
    fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .PTR_WIDTH (PTR_WIDTH)
    ) memory (
        .wclk     (wclk),
        .w_en     (w_en),
        .wfull    (full),

        .waddr    (b_wptr[PTR_WIDTH-1:0]),
        .raddr    (b_rptr[PTR_WIDTH-1:0]),

        .data_in  (data_in),
        .data_out (data_out)
    );

endmodule
