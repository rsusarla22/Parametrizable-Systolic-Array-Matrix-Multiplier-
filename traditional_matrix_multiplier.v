`timescale 1ns / 1ps

module traditional_matrix_multiplier #(
    parameter M = 6,                    // Rows of A
    parameter K = 6,                    // Columns of A = Rows of B  
    parameter N = 6,                    // Columns of B
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 2*DATA_WIDTH + $clog2(K)
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [M*K*DATA_WIDTH-1:0] A_flat,
    input wire [K*N*DATA_WIDTH-1:0] B_flat,
    output reg [M*N*ACC_WIDTH-1:0] C_flat,
    output reg done
);

    // Internal 2D array representations
    reg [DATA_WIDTH-1:0] A_matrix [0:M-1][0:K-1];
    reg [DATA_WIDTH-1:0] B_matrix [0:K-1][0:N-1];
    reg [ACC_WIDTH-1:0] C_matrix [0:M-1][0:N-1];
    
    // Control variables
    reg [$clog2(M):0] i;
    reg [$clog2(N):0] j;
    reg [$clog2(K):0] k;
    reg [2:0] state;
    
    // State encoding
    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam COMPUTE = 3'b010;
    localparam OUTPUT = 3'b011;
    localparam DONE = 3'b100;
    
    integer row, col;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
            C_flat <= 0;
            
            // Initialize matrices
            for (row = 0; row < M; row = row + 1) begin
                for (col = 0; col < K; col = col + 1) begin
                    A_matrix[row][col] <= 0;
                end
            end
            for (row = 0; row < K; row = row + 1) begin
                for (col = 0; col < N; col = col + 1) begin
                    B_matrix[row][col] <= 0;
                end
            end
            for (row = 0; row < M; row = row + 1) begin
                for (col = 0; col < N; col = col + 1) begin
                    C_matrix[row][col] <= 0;
                end
            end
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD;
                        done <= 0;
                    end
                end
                
                LOAD: begin
                    // Load A matrix
                    for (row = 0; row < M; row = row + 1) begin
                        for (col = 0; col < K; col = col + 1) begin
                            A_matrix[row][col] <= A_flat[((row*K + col + 1)*DATA_WIDTH-1) -: DATA_WIDTH];
                        end
                    end
                    // Load B matrix
                    for (row = 0; row < K; row = row + 1) begin
                        for (col = 0; col < N; col = col + 1) begin
                            B_matrix[row][col] <= B_flat[((row*N + col + 1)*DATA_WIDTH-1) -: DATA_WIDTH];
                        end
                    end
                    // Initialize result matrix
                    for (row = 0; row < M; row = row + 1) begin
                        for (col = 0; col < N; col = col + 1) begin
                            C_matrix[row][col] <= 0;
                        end
                    end
                    
                    i <= 0;
                    j <= 0;
                    k <= 0;
                    state <= COMPUTE;
                end
                
                COMPUTE: begin
                    // Perform C[i][j] += A[i][k] * B[k][j]
                    C_matrix[i][j] <= C_matrix[i][j] + A_matrix[i][k] * B_matrix[k][j];
                    
                    // Update counters
                    if (k < K-1) begin
                        k <= k + 1;
                    end
                    else begin
                        k <= 0;
                        if (j < N-1) begin
                            j <= j + 1;
                        end
                        else begin
                            j <= 0;
                            if (i < M-1) begin
                                i <= i + 1;
                            end
                            else begin
                                state <= OUTPUT;
                            end
                        end
                    end
                end
                
                OUTPUT: begin
                    // Flatten result matrix to output
                    for (row = 0; row < M; row = row + 1) begin
                        for (col = 0; col < N; col = col + 1) begin
                            C_flat[((row*N + col + 1)*ACC_WIDTH-1) -: ACC_WIDTH] <= C_matrix[row][col];
                        end
                    end
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule
