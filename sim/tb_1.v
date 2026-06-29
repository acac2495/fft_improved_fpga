`timescale 1ns/1ns
`include "../rtl/agu.v"

module tb_1;

    localparam N = 32;

    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    reg clk, rst;
    reg fft_start;

    wire fft_done;
    wire sent;

    wire [ADDR_WIDTH - 1 : 0] mem_addr_A, mem_addr_B;
    wire [TWIDDLE_WIDTH - 1 : 0] twiddle_addr;

    agu #(.N(N)) DUT(
        .clk(clk),
        .rst(rst),
        .fft_done(fft_done),
        .fft_start(fft_start),
        .sent(sent),
        .mem_addr_A(mem_addr_A),
        .mem_addr_B(mem_addr_B),
        .twiddle_addr(twiddle_addr)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_1);

        clk = 0;
        rst = 0;
        fft_start = 0;
        #3;
        rst = 1;
        #5;
        rst = 0;
        fft_start = 1;
        #10;
        fft_start = 0;
        #1000;
        $finish;
    end
endmodule