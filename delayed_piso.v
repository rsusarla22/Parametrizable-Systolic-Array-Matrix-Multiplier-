`timescale 1ns / 1ps

//   NUM_ELEMENTS :  K   → number of matrix words to shift
//   DATA_WIDTH   :  bit-width of each word
//   DELAY_CYCLES :  row/column offset (0…K-1)

module delayed_piso #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_ELEMENTS = 6,
    parameter DELAY_CYCLES = 0
)(
    input  wire                       clk  ,
    input  wire                       rst  ,
    input  wire                       start,
    input  wire [NUM_ELEMENTS*DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0]      data_out,
    output reg                        valid
);

    //  Internal state

    localparam TOTAL_SHIFTS = 2*NUM_ELEMENTS;          // K data + K zeros
    reg [NUM_ELEMENTS*DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(TOTAL_SHIFTS+1)-1:0]  shift_cnt;
    reg [$clog2(DELAY_CYCLES+1) :0]   delay_cnt;
    reg                               active;


    //  Sequential logic

    always @(posedge clk) begin
        if (rst) begin                                         // async reset
            shift_reg  <= {NUM_ELEMENTS*DATA_WIDTH{1'b0}};
            shift_cnt  <= 0;
            delay_cnt  <= 0;
            valid      <= 1'b0;
            data_out   <= {DATA_WIDTH{1'b0}};
            active     <= 1'b0;
        end else if (start) begin                              // load new line/col
            shift_reg  <= data_in;                             // preload matrix row/col
            shift_cnt  <= 0;
            delay_cnt  <= 0;
            valid      <= 1'b0;
            data_out   <= {DATA_WIDTH{1'b0}};
            active     <= 1'b1;
        end else if (active) begin

            if (delay_cnt < DELAY_CYCLES) begin
                delay_cnt <= delay_cnt + 1;
                valid     <= 1'b0;                             // hold invalid

            end else if (shift_cnt < NUM_ELEMENTS) begin
                data_out <= shift_reg[DATA_WIDTH-1:0];
                shift_reg<= shift_reg >> DATA_WIDTH;
                shift_cnt<= shift_cnt + 1;
                valid    <= 1'b1;

            end else if (shift_cnt < TOTAL_SHIFTS) begin
                data_out <= {DATA_WIDTH{1'b0}};                // send zeros
                shift_cnt<= shift_cnt + 1;
                valid    <= 1'b1;

            end else begin
                valid  <= 1'b0;
                active <= 1'b0;
            end
        end
    end
endmodule
