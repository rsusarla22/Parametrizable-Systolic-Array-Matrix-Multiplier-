module PISO #(
    parameter N = 64,           // K*DATA_WIDTH bits
    parameter DATA_WIDTH = 16,
    parameter DELAY_CYCLES = 0  // Row-specific delay
)(
    input clk,
    input rst,
    input start,
    input [N-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid
);
    
    reg [N-1:0] queue;
    reg [$clog2(N/DATA_WIDTH):0] shift_count;
    reg [$clog2(DELAY_CYCLES+1):0] delay_count;
    reg active;
    
    always @(posedge clk) begin
        if (rst) begin
            queue <= 0;
            shift_count <= 0;
            delay_count <= 0;
            data_out <= 0;
            valid <= 0;
            active <= 0;
        end
        else if (start && !active) begin
            queue <= data_in;
            delay_count <= 0;
            shift_count <= 0;
            active <= 1;
            valid <= 0;
        end
        else if (active) begin
            if (delay_count < DELAY_CYCLES) begin
                delay_count <= delay_count + 1;
                valid <= 0;
            end
            else if (shift_count < N/DATA_WIDTH) begin
                data_out <= queue[DATA_WIDTH-1:0];
                queue <= queue >> DATA_WIDTH;
                shift_count <= shift_count + 1;
                valid <= 1;
            end
            else begin
                valid <= 0;
            end
        end
    end
endmodule
