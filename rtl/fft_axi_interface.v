`include "../rtl/top_fft.v"

module fft_axi_interface #(parameter N = 32, AW = 32, DW = 32, BW = 2) (clk, rst, s_axi_awvalid, s_axi_awaddr, s_axi_awready, s_axi_wvalid, s_axi_wdata, s_axi_wready, s_axi_arvalid, s_axi_arready, s_axi_araddr, s_axi_bready, s_axi_bvalid, s_axi_bresp, s_axi_rdata, s_axi_rvalid, s_axi_rready, s_axi_rresp);

    input clk, rst;

    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    reg fft_start, load_en;
    reg [ADDR_WIDTH - 1 : 0] load_addr;
    reg [18:0] load_data_r, load_data_i;

    wire sent, fft_busy, fft_done;

    reg [ADDR_WIDTH - 1 : 0] read_addr;
    wire [18:0] read_data_i, read_data_r;
    reg sel;

    top_fft #(.N(N)) FFT_MODULE(
        .clk(clk),
        .rst(rst),
        .fft_start(fft_start),
        .load_en(load_en),
        .load_addr(load_addr),
        .load_data_i(load_data_i),
        .load_data_r(load_data_r),
        .fft_busy(fft_busy),
        .sent(sent),
        .fft_done(fft_done),
        .read_addr(read_addr),
        .read_data_r(read_data_r),
        .read_data_i(read_data_i)
    );

    input s_axi_awvalid;
    input [AW - 1 : 0] s_axi_awaddr;
    output s_axi_awready;

    input s_axi_wvalid;
    input [DW - 1 : 0] s_axi_wdata;
    output s_axi_wready;

    input s_axi_arvalid;
    input [AW - 1 : 0] s_axi_araddr;
    output s_axi_arready;

    assign s_axi_awready = ~fft_busy;
    assign s_axi_wready = ~fft_busy;
    assign s_axi_arready = 1'b1;

    wire valid_write_request;
    assign valid_write_request = (s_axi_wvalid && s_axi_awvalid && s_axi_wready && s_axi_awready);

    wire valid_read_request;
    assign valid_read_request = (s_axi_arvalid && s_axi_arready);

    input s_axi_rready;
    output reg [DW - 1 : 0] s_axi_rdata;
    output reg s_axi_rvalid;
    output [BW - 1 : 0] s_axi_rresp;

    always @(posedge clk) begin
        if(rst) begin
            s_axi_rvalid <= 0;
        end
        else if(s_axi_rready && s_axi_rvalid) begin
            s_axi_rvalid <= 0;
        end
        else if(valid_read_request) begin
            s_axi_rvalid <= 1;
        end
    end

    input s_axi_bready;
    output [BW - 1 : 0] s_axi_bresp;
    output reg s_axi_bvalid;

    always @(posedge clk) begin
        if(rst) begin
            s_axi_bvalid <= 0;
        end
        else if(s_axi_bready && s_axi_bvalid) begin
            s_axi_bvalid <= 0;
        end
        else if(valid_write_request) begin
            s_axi_bvalid <= 1;
        end
    end

    assign s_axi_bresp = {BW{1'b0}};
    assign s_axi_rresp = {BW{1'b0}};

    always @(posedge clk) begin
        if(rst) begin
            fft_start <= 0;
        end
        else if(load_en || fft_start || fft_busy) begin
            fft_start <= 0;
        end
        else if(valid_write_request) begin
            if(s_axi_awaddr == 32'h00) begin
                fft_start <= s_axi_wdata[0];
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            load_en <= 0;
        end
        else if(fft_busy || fft_start) begin
            load_en <= 0;
        end
        else if(valid_write_request) begin
            if(s_axi_awaddr == 32'h04) begin
                load_en <= s_axi_wdata[0];
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            load_addr <= 0;
            load_data_i <= 0;
            load_data_r <= 0;
        end
        else begin
            if(valid_write_request) begin
                case(s_axi_awaddr)
                    32'h08 : load_addr <= s_axi_wdata[ADDR_WIDTH - 1 : 0];
                    32'h0C : load_data_r <= s_axi_wdata[18:0];
                    32'h10 : load_data_i <= s_axi_wdata[18:0];
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            read_addr <= 0;
            sel <= 0;
        end
        else begin
            if(valid_write_request && (s_axi_awaddr == 32'h14)) begin
                read_addr <= s_axi_wdata[ADDR_WIDTH - 1 : 0];
                sel <= s_axi_wdata[ADDR_WIDTH];
            end
        end
    end

    always @(posedge clk) begin
        if(valid_read_request) begin
            case(sel)
                0 : s_axi_rdata <= {13'b0, read_data_r};
                1 : s_axi_rdata <= {13'b0, read_data_i};
            endcase
        end
    end
endmodule