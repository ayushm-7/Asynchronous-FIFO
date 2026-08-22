`timescale 1ns / 1ps
module read_pointer_handler #(
    parameter PTR_WIDTH = 3
)(
    input  wire               rclk,
    input  wire               rrst_n,
    input  wire               r_en,
    input  wire               empty,

    input  wire [PTR_WIDTH:0] g_wptr_sync,

    output reg  [PTR_WIDTH:0] b_rptr,
    output reg  [PTR_WIDTH:0] g_rptr,
    output reg                rempty
);

    wire [PTR_WIDTH:0] b_rptr_next;
    wire [PTR_WIDTH:0] g_rptr_next;
    wire               rempty_next;

    // Next binary read pointer
    assign b_rptr_next = b_rptr + (r_en & ~empty);

    // Binary to Gray conversion
    assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;

    // Empty detection
    assign rempty_next = (g_wptr_sync == g_rptr_next);

    // Registers
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            b_rptr <= 0;
            g_rptr <= 0;
            rempty <= 1'b1;
        end
        else begin
            b_rptr <= b_rptr_next;
            g_rptr <= g_rptr_next;
            rempty <= rempty_next;
        end
    end

endmodule
