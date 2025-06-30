`timescale 1ns / 1ps
module matrix_column_extractor #(
    parameter K = 6,             // rows
    parameter N = 6,             // cols
    parameter DATA_WIDTH = 16
)(
    input  wire [K*N*DATA_WIDTH-1:0] matrix_flat,   // B row-major
    output wire [N*K*DATA_WIDTH-1:0] columns_flat   // B column-major
);
    genvar c, r;
    generate
        for (c = 0; c < N; c = c + 1) begin : COL
            for (r = 0; r < K; r = r + 1) begin : ROW
                //-------------------------------------------------------------
                // Place element B[r][c] at (c*K + r) in column-major stream
                //-------------------------------------------------------------
                assign columns_flat[((c*K + r + 1)*DATA_WIDTH-1) -: DATA_WIDTH] =
                       matrix_flat[((r*N + c + 1)*DATA_WIDTH-1) -: DATA_WIDTH];
            end
        end
    endgenerate
endmodule
