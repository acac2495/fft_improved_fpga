`timescale 1ns/1ns
`include "../rtl/fft_axi_interface.v"

module axi_tb;

    localparam N = 128;
    localparam AW = 32;
    localparam DW = 32;
    localparam BW = 2;

    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    reg clk, rst;

    reg awvalid;
    reg [AW - 1 : 0] awaddr;
    wire awready;

    reg wvalid;
    reg [DW - 1 : 0] wdata;
    wire wready;

    reg arvalid;
    reg [AW - 1 : 0] araddr;
    wire arready;

    reg rready;
    wire [DW - 1 : 0] rdata;
    wire  rvalid;
    wire [BW - 1 : 0] rresp;

    reg bready;
    wire [BW - 1 : 0] bresp;
    wire bvalid;

    fft_axi_interface #(.N(N), .AW(AW), .DW(DW), .BW(2)) DUT(
        .clk(clk), .rst(rst),
        .s_axi_awvalid(awvalid), .s_axi_awaddr(awaddr),
        .s_axi_awready(awready),
        .s_axi_wvalid(wvalid),   .s_axi_wdata(wdata),
        .s_axi_wready(wready),
        .s_axi_arvalid(arvalid), .s_axi_araddr(araddr),
        .s_axi_arready(arready),
        .s_axi_bready(bready),   .s_axi_bvalid(bvalid),
        .s_axi_bresp(bresp),
        .s_axi_rdata(rdata),     .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),   .s_axi_rresp(rresp)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, axi_tb);

        clk = 0;
        rst = 0;
        awvalid = 0;
        wvalid = 0;
        arvalid = 0;
        rready = 1;
        bready = 1;
        awaddr = 0;
        wdata = 0;
        araddr = 0;

        #3;
        rst = 1;
        #5;
        rst = 0;

        load_data();

        @(posedge clk);
        awvalid = 1;
        wvalid = 1;
        awaddr = 0;
        wdata = 32'd1;
        @(posedge clk);
        awvalid = 0;
        wvalid = 0;

        #13000;
        $finish;
    end

    task load_data;
        integer i;
        reg [ADDR_WIDTH - 1 : 0] idx;
        begin
            @(posedge clk);
            awvalid = 1;
            wvalid = 1;
            awaddr = 32'd4;
            wdata = 32'd1;

            for(i = 0; i < N; i = i + 1) begin
                idx = i;
                @(posedge clk);
                #1;
                awaddr = 32'd8;
                wdata = bit_rev(idx);
                @(posedge clk);
                #1;
                awaddr = 32'd12;
                if(idx < N/2) begin
                    wdata = 19'h00800;
                end
                else begin
                    wdata = 0;
                end
                @(posedge clk);
                #1;
                awaddr = 32'd16;
                wdata = 0;
            end

            @(posedge clk);
            #1;
            awaddr = 32'd4;
            wdata = 0;
            @(posedge clk);
            #1;
            awvalid = 0;
            wvalid = 0;
        end
    endtask

    function [ADDR_WIDTH - 1 : 0] bit_rev;
        input [ADDR_WIDTH - 1 : 0] in;
        integer i;
        begin
            for(i = 0; i < N_BITS; i = i + 1) begin
                bit_rev[i] = in[N_BITS - 1 - i];
            end
        end
    endfunction
endmodule