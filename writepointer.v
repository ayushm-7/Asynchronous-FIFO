`timescale 1ns / 1ps
module write_pointer_handler #(
    parameter PTR_WIDTH = 3
)(
    input  wire               wclk,
    input  wire               wrst_n,
    input  wire               w_en,
    input  wire               full,

    input  wire [PTR_WIDTH:0] g_rptr_sync,

    output reg  [PTR_WIDTH:0] b_wptr,
    output reg  [PTR_WIDTH:0] g_wptr,
    output reg                wfull
);

    wire [PTR_WIDTH:0] b_wptr_next;
    wire [PTR_WIDTH:0] g_wptr_next;
    wire               wfull_next;

    // Next binary write pointer
    assign b_wptr_next = b_wptr + (w_en & ~full);

    // Binary to Gray conversion
    assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;

    // Full detection
    assign wfull_next =
        (g_wptr_next ==
        {
            ~g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1],
             g_rptr_sync[PTR_WIDTH-2:0]
        });

    // Registers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            b_wptr <= 0;
            g_wptr <= 0;
            wfull  <= 1'b0;
        end
        else begin
            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;
            wfull  <= wfull_next;
        end
    end

endmodule
