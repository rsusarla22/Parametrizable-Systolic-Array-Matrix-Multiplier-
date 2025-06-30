`timescale 1ns / 1ps

module systolic_array #(
    parameter M = 6,
    parameter K = 6,
    parameter N = 6,
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 2*DATA_WIDTH + $clog2(K)
)(
    input  wire clk ,
    input  wire rst ,
    input  wire start,                         // single-cycle load pulse
    input  wire [M*K*DATA_WIDTH-1:0] A_flat,   // A row-major
    input  wire [K*N*DATA_WIDTH-1:0] B_flat,   // B row-major
    output wire [M*N*ACC_WIDTH-1:0]  C_flat,   // C row-major
    output reg  done
);

    // Generate column-major view of B

    wire [N*K*DATA_WIDTH-1:0] B_cols;
    matrix_column_extractor #(
        .K(K), .N(N), .DATA_WIDTH(DATA_WIDTH)
    ) xtr (
        .matrix_flat (B_flat ),
        .columns_flat(B_cols )
    );

    // Row & Column PISOs with progressive delays

    wire [DATA_WIDTH-1:0] A_ser [0:M-1];
    wire [DATA_WIDTH-1:0] B_ser [0:N-1];
    wire                  A_val [0:M-1];
    wire                  B_val [0:N-1];

    genvar ri, ci;
    generate
        // Row PISO inputs
        for (ri = 0; ri < M; ri = ri + 1) begin : ROW_PISO
            delayed_piso #(
                .DATA_WIDTH  (DATA_WIDTH ),
                .NUM_ELEMENTS(K          ),
                .DELAY_CYCLES(ri         )
            ) pA (
                .clk     (clk),
                .rst     (rst),
                .start   (start),
                .data_in (A_flat[((ri*K + K)*DATA_WIDTH-1) -: K*DATA_WIDTH]),
                .data_out(A_ser[ri]),
                .valid   (A_val[ri])
            );
        end
        //  Column PISO inputs
        for (ci = 0; ci < N; ci = ci + 1) begin : COL_PISO
            delayed_piso #(
                .DATA_WIDTH  (DATA_WIDTH ),
                .NUM_ELEMENTS(K          ),
                .DELAY_CYCLES(ci         )
            ) pB (
                .clk     (clk),
                .rst     (rst),
                .start   (start),
                .data_in (B_cols[((ci*K + K)*DATA_WIDTH-1) -: K*DATA_WIDTH]),
                .data_out(B_ser[ci]),
                .valid   (B_val[ci])
            );
        end
    endgenerate


    //  PE mesh 
    
    wire [DATA_WIDTH-1:0] a_in  [0:M-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_in  [0:M-1][0:N-1];
    wire [DATA_WIDTH-1:0] a_out [0:M-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_out [0:M-1][0:N-1];
    wire [ACC_WIDTH-1:0]  psum  [0:M-1][0:N-1];

    generate
        for (ri = 0; ri < M; ri = ri + 1) begin : PE_ROWS
            for (ci = 0; ci < N; ci = ci + 1) begin : PE_COLS

                //  West / North borders

                assign a_in[ri][ci] = (ci==0) ? A_ser[ri] : a_out[ri][ci-1];
                assign b_in[ri][ci] = (ri==0) ? B_ser[ci] : b_out[ri-1][ci];

                //  PE instance

                pe_unit #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH (ACC_WIDTH )
                ) PE (
                    .clk (clk),
                    .rst (rst),
                    .en  (A_val[ri] && B_val[ci]),
                    .a_in (a_in [ri][ci]),
                    .b_in (b_in [ri][ci]),
                    .a_out(a_out[ri][ci]),
                    .b_out(b_out[ri][ci]),
                    .psum_out(psum[ri][ci])
                );
            end
        end
    endgenerate


    //  Flatten outputs to C

    generate
        for (ri = 0; ri < M; ri = ri + 1) begin
            for (ci = 0; ci < N; ci = ci + 1) begin
                assign C_flat[((ri*N + ci + 1)*ACC_WIDTH-1) -: ACC_WIDTH] =
                       psum[ri][ci];
            end
        end
    endgenerate


    //  Global done pulse  - 2K + (M-1) + (N-1) cycles

    localparam LAT = 2*K + M + N - 2;
    reg [$clog2(LAT+2)-1:0] ctr;
    reg busy;
    always @(posedge clk) begin
        if (rst) begin
            ctr  <= 0;
            busy <= 1'b0;
            done <= 1'b0;
        end else if (start) begin
            ctr  <= 0;
            busy <= 1'b1;
            done <= 1'b0;
        end else if (busy) begin
            ctr  <= ctr + 1;
            if (ctr == LAT) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end else begin
            done <= 1'b0;
        end
    end
endmodule
