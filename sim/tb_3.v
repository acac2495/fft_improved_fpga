`timescale 1ns/1ns
`include "../rtl/top_fft.v"

module tb_3;

    localparam N = 128;

    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    reg clk, rst;
    reg fft_start;
    reg load_en;
    reg [ADDR_WIDTH - 1 : 0] load_addr;
    reg [18:0] load_data_i, load_data_r;

    wire fft_done;
    wire sent;
    wire fft_busy;

    top_fft #(.N(N)) DUT(
        .clk(clk),
        .rst(rst),
        .fft_done(fft_done),
        .fft_start(fft_start),
        .sent(sent),
        .load_en(load_en),
        .load_addr(load_addr),
        .load_data_i(load_data_i),
        .load_data_r(load_data_r),
        .fft_busy(fft_busy)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_3);

        load_en = 0;
        load_addr = 0;
        load_data_i = 0;
        load_data_r = 0;
        clk = 0;
        rst = 0;
        fft_start = 0;
        #3;
        rst = 1;
        #5;
        rst = 0;
        #40;
        fft_start = 1;
        #10;
        fft_start = 0;
        #13000;
        $finish;
    end

endmodule