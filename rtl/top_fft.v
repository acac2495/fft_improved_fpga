`include "../rtl/agu.v"
`include "../rtl/mem_proc_unit.v"
`include "../rtl/bit_reverse.v"

module top_fft #(parameter N = 32) (clk, rst, fft_start, fft_done, sent, load_en, load_data_i, load_data_r, load_addr, fft_busy, read_addr, read_data_i, read_data_r);
    
    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    input clk, rst;
    input fft_start;

    input load_en;
    input [ADDR_WIDTH - 1 : 0] load_addr;
    input [18:0] load_data_r, load_data_i;

    output fft_done, fft_busy;

    input [ADDR_WIDTH - 1 : 0] read_addr;
    output [18:0] read_data_i, read_data_r;

    output sent;
    wire agu_send;

    wire [ADDR_WIDTH - 1 : 0] mem_addr_A, mem_addr_B;
    wire [TWIDDLE_WIDTH - 1 : 0] twiddle_addr;

    wire fft_done_agu;
    assign fft_done = fft_done_agu;

    wire bank_sel;

    agu #(.N(N)) AGU(
        .clk(clk),
        .rst(rst),
        .fft_start(fft_start),
        .fft_done(fft_done_agu),
        .sent(sent),
        .agu_send(agu_send),
        .mem_addr_A(mem_addr_A),
        .mem_addr_B(mem_addr_B),
        .twiddle_addr(twiddle_addr),
        .fft_busy(fft_busy),
        .bank_sel(bank_sel)
    );

    mem_proc_unit #(.N(N)) MEMU(
        .clk(clk),
        .rst(rst),
        .agu_send(agu_send),
        .mem_addr_A(mem_addr_A),
        .mem_addr_B(mem_addr_B),
        .twiddle_addr(twiddle_addr),
        .fft_done(fft_done_agu),
        .load_addr(load_addr),
        .load_data_i(load_data_i),
        .load_data_r(load_data_r),
        .load_en(load_en),
        .fft_start(fft_start),
        .read_addr(read_addr),
        .read_data_i(read_data_i),
        .read_data_r(read_data_r),
        .bank_sel(bank_sel)
    );
endmodule