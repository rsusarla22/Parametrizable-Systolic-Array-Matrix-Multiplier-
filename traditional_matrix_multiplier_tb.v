`timescale 1ns / 1ps

module traditional_matrix_multiplier_tb;

    parameter M = 6;
    parameter K = 6;
    parameter N = 6;
    parameter DATA_WIDTH = 16;
    parameter ACC_WIDTH = 2*DATA_WIDTH + $clog2(K);

    reg clk;
    reg rst;
    reg start;
    reg [M*K*DATA_WIDTH-1:0] A_flat;
    reg [K*N*DATA_WIDTH-1:0] B_flat;
    wire [M*N*ACC_WIDTH-1:0] C_flat;
    wire done;

    // Test matrices
    reg [DATA_WIDTH-1:0] A_matrix [0:M-1][0:K-1];
    reg [DATA_WIDTH-1:0] B_matrix [0:K-1][0:N-1];
    reg [ACC_WIDTH-1:0] C_matrix [0:M-1][0:N-1];

    // Instantiate traditional matrix multiplier
    traditional_matrix_multiplier #(
        .M(M), .K(K), .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk), .rst(rst), .start(start),
        .A_flat(A_flat), .B_flat(B_flat),
        .C_flat(C_flat), .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    integer i, j, k;

    initial begin

        // Initialize matrices
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < K; j = j + 1) begin
                A_matrix[i][j] = i + j + 1;  // Simple test pattern
            end
        end

        for (i = 0; i < K; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                B_matrix[i][j] = i + j + 1;  // Simple test pattern
            end
        end

        // Flatten matrices
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < K; j = j + 1) begin
                A_flat[(i*K+j+1)*DATA_WIDTH-1 -: DATA_WIDTH] = A_matrix[i][j];
            end
        end

        for (i = 0; i < K; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                B_flat[(i*N+j+1)*DATA_WIDTH-1 -: DATA_WIDTH] = B_matrix[i][j];
            end
        end

        // Reset and start computation
        rst = 1;
        start = 0;
        #20;
        rst = 0;
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for completion
        wait(done);
        #50;

        // Extract results
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                C_matrix[i][j] = C_flat[(i*N+j+1)*ACC_WIDTH-1 -: ACC_WIDTH];
            end
        end

        // Display results
        $display("Matrix A:");
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < K; j = j + 1) begin
                $write("%d ", A_matrix[i][j]);
            end
            $display("");
        end

        $display("Matrix B:");
        for (i = 0; i < K; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                $write("%d ", B_matrix[i][j]);
            end
            $display("");
        end

        $display("Result C:");
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                $write("%d ", C_matrix[i][j]);
            end
            $display("");
        end

        $finish;
    end

endmodule
