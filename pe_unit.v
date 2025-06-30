`timescale 1ns / 1ps
module pe_unit #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 36
)(
    input  wire                     clk ,
    input  wire                     rst ,
    input  wire                     en  ,
    input  wire [DATA_WIDTH-1:0]    a_in,
    input  wire [DATA_WIDTH-1:0]    b_in,
    output reg  [DATA_WIDTH-1:0]    a_out,
    output reg  [DATA_WIDTH-1:0]    b_out,
    output reg  [ACC_WIDTH-1:0]     psum_out
);
    always @(posedge clk) begin
        if (rst) begin
            a_out    <= 0;
            b_out    <= 0;
            psum_out <= 0;
        end else if (en) begin
            psum_out <= psum_out + a_in * b_in;      // MAC
            a_out    <= a_in;                        // forward A east
            b_out    <= b_in;                        // forward B south
        end
    end
endmodule
