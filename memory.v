`timescale 1ns / 1ps
module fifo_memory #(
    parameter DATA_WIDTH = 8,
    parameter PTR_WIDTH  = 3
)(
    input  wire                    wclk,
    input  wire                    w_en,
    input  wire                    wfull,
    input  wire [PTR_WIDTH-1:0]    waddr,

    input  wire [PTR_WIDTH-1:0]    raddr,
    output wire [DATA_WIDTH-1:0]   data_out,

    input  wire [DATA_WIDTH-1:0]   data_in
);

    // FIFO memory
    reg [DATA_WIDTH-1:0] fifo [0:(1 << PTR_WIDTH)-1];

    // Write operation
    always @(posedge wclk) begin
        if (w_en && !wfull)
            fifo[waddr] <= data_in;
    end

    // Asynchronous read
    assign data_out = fifo[raddr];

endmodule
