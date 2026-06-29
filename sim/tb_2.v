`timescale 1ns/1ns
`include "../rtl/top_fft.v"

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
    reg load_en;
    reg [ADDR_WIDTH - 1 : 0] load_addr;
    reg [15:0] load_data_i, load_data_r;

    wire fft_done;
    wire sent;

    top_fft #(.N(N)) DUT(
        .clk(clk),
        .rst(rst),
        .fft_done(fft_done),
        .fft_start(fft_start),
        .sent(sent),
        .load_en(load_en),
        .load_addr(load_addr),
        .load_data_i(load_data_i),
        .load_data_r(load_data_r)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_1);

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

    task load_square_wave;
        begin
            reg [4:0] i;
            integer j;
            for(j = 0; j < N; j = j + 1) begin
                i = j;
                if(j < N/4) begin
                    load_sample(bit_rev(i), 16'h0800, 16'h0000);
                end
                else begin
                    load_sample(bit_rev(i), 16'h0000, 16'h0000);
                end
            end
        end
    endtask

    task load_triangular_wave;
        begin
            integer j;
            reg [4:0] i;
            reg [15:0] sample;

            for(j = 0; j < N; j = j + 1) begin
                i = j;
                if(j < N/2) begin
                    // Ramp up: j=0 -> 0x0000, j=15 -> 0x0800
                    // val = round(j / 15.0 * 2048) — precomputed for N=32
                    case(j)
                        0:  sample = 16'h0000;
                        1:  sample = 16'h008A;  //  138
                        2:  sample = 16'h0115;  //  277
                        3:  sample = 16'h01A0;  //  416
                        4:  sample = 16'h022B;  //  555
                        5:  sample = 16'h02B5;  //  693
                        6:  sample = 16'h0340;  //  832
                        7:  sample = 16'h03CB;  //  971
                        8:  sample = 16'h0456;  // 1110
                        9:  sample = 16'h04E1;  // 1249
                        10: sample = 16'h056B;  // 1387
                        11: sample = 16'h05F6;  // 1526
                        12: sample = 16'h0681;  // 1665
                        13: sample = 16'h070C;  // 1804
                        14: sample = 16'h0796;  // 1942
                        15: sample = 16'h0800;  // 2048
                        default: sample = 16'h0000;
                    endcase
                end
                else begin
                    // Ramp down: j=16 -> 0x0800, j=31 -> 0x0000
                    // mirrors the ramp-up: index into down-ramp = j - 16, same values reversed
                    case(j - 16)
                        0:  sample = 16'h0800;  // 2048
                        1:  sample = 16'h0796;  // 1942
                        2:  sample = 16'h070C;  // 1804
                        3:  sample = 16'h0681;  // 1665
                        4:  sample = 16'h05F6;  // 1526
                        5:  sample = 16'h056B;  // 1387
                        6:  sample = 16'h04E1;  // 1249
                        7:  sample = 16'h0456;  // 1110
                        8:  sample = 16'h03CB;  //  971
                        9:  sample = 16'h0340;  //  832
                        10: sample = 16'h02B5;  //  693
                        11: sample = 16'h022B;  //  555
                        12: sample = 16'h01A0;  //  416
                        13: sample = 16'h0115;  //  277
                        14: sample = 16'h008A;  //  138
                        15: sample = 16'h0000;  //   0
                        default: sample = 16'h0000;
                    endcase
                end

                load_sample(bit_rev(i), sample, 16'h0000);
            end
        end
    endtask

    task load_sample;
        input [ADDR_WIDTH - 1 : 0] addr;
        input [15:0] data_r, data_i;
        
        begin
            @(posedge clk);
            load_en = 1;
            load_data_i = data_i;
            load_data_r = data_r;
            load_addr = addr;
            @(posedge clk);
            load_en = 0;
        end
    endtask

    function [4:0] bit_rev;
        input [4:0] in;
        integer i;
        begin
            for(i = 0; i < 5; i = i + 1) begin
                bit_rev[i] = in[4 - i];
            end
        end
    endfunction
endmodule