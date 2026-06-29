`include "../rtl/dual_port_ram.v"

module mem_proc_unit #(parameter N = 32) (clk, rst, mem_addr_A, mem_addr_B, twiddle_addr, agu_send, fft_done, load_en, load_data_r, load_data_i, load_addr, fft_start, read_addr, read_data_i, read_data_r, bank_sel);
    
    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    input clk, rst;
    input [ADDR_WIDTH - 1 : 0] mem_addr_A, mem_addr_B;
    input [TWIDDLE_WIDTH - 1 : 0] twiddle_addr;
    input agu_send;
    input fft_done;
    input fft_start;

    input bank_sel;
    localparam BANK_A_SEL = 0;
    localparam BANK_B_SEL = 1;

    input load_en;
    input [18:0] load_data_r, load_data_i;
    input [ADDR_WIDTH - 1 : 0] load_addr;

    input [ADDR_WIDTH - 1 : 0] read_addr;
    output reg [18:0] read_data_i, read_data_r;

    //BANK A 
    wire [ADDR_WIDTH - 1 : 0] bankA_addr_p0, bankA_addr_p1;
    wire bankA_we_p0, bankA_we_p1;
    wire signed [18:0] bankA_wdata_p0, bankA_wdata_p1;      //Q1.18 real data
    wire signed [18:0] bankA_wdata_p0_i, bankA_wdata_p1_i;  //Q1.18 imag data
    wire signed [18:0] bankA_rdata_p0, bankA_rdata_p1;      //Q1.18 real data
    wire signed [18:0] bankA_rdata_p0_i, bankA_rdata_p1_i;  //Q1.18 imag data

    assign bankA_addr_p0 = (load_en == 1) ? load_addr : ((bank_sel == BANK_A_SEL) ? mem_addr_A : mem_addr_A4);
    assign bankA_addr_p1 = (bank_sel == BANK_A_SEL) ? mem_addr_B : mem_addr_B4;
    assign bankA_we_p0 = (load_en == 1) ? 1'b1 : ((bank_sel == BANK_A_SEL) ? 1'b0 : send4);
    assign bankA_we_p1 = (bank_sel == BANK_A_SEL) ? 1'b0 : send4;
    assign bankA_wdata_p0   = (load_en == 1) ? load_data_r : M_r_trunc;   
    assign bankA_wdata_p1   = N_r_trunc;
    assign bankA_wdata_p0_i = (load_en == 1) ? load_data_i : M_i_trunc;
    assign bankA_wdata_p1_i = N_i_trunc;

    //BANK B 
    wire [ADDR_WIDTH - 1 : 0] bankB_addr_p0, bankB_addr_p1;
    wire bankB_we_p0, bankB_we_p1;
    wire signed [18:0] bankB_wdata_p0, bankB_wdata_p1;      //Q1.18 real data
    wire signed [18:0] bankB_wdata_p0_i, bankB_wdata_p1_i;  //Q1.18 imag data
    wire signed [18:0] bankB_rdata_p0, bankB_rdata_p1;      //Q1.18 real data
    wire signed [18:0] bankB_rdata_p0_i, bankB_rdata_p1_i;  //Q1.18 imag data

    assign bankB_addr_p0 = (bank_sel == BANK_B_SEL) ? mem_addr_A : mem_addr_A4;
    assign bankB_addr_p1 = (bank_sel == BANK_B_SEL) ? mem_addr_B : mem_addr_B4;
    assign bankB_we_p0 = (bank_sel == BANK_B_SEL) ? 1'b0 : send4;
    assign bankB_we_p1 = (bank_sel == BANK_B_SEL) ? 1'b0 : send4;
    assign bankB_wdata_p0   = M_r_trunc;   
    assign bankB_wdata_p1   = N_r_trunc;
    assign bankB_wdata_p0_i = M_i_trunc;
    assign bankB_wdata_p1_i = N_i_trunc;

    dual_port_ram #(.DEPTH(N), .WIDTH(19), .INIT_FILE("../rtl/real_mem.hex")) BANK_A_REAL(
        .clk(clk),
        .we_p0(bankA_we_p0),
        .we_p1(bankA_we_p1),
        .addr_p0(bankA_addr_p0),
        .addr_p1(bankA_addr_p1),
        .wdata_p0(bankA_wdata_p0),
        .wdata_p1(bankA_wdata_p1),
        .rdata_p0(bankA_rdata_p0),
        .rdata_p1(bankA_rdata_p1)
    );

    dual_port_ram #(.DEPTH(N), .WIDTH(19), .INIT_FILE("../rtl/imag_mem.hex")) BANK_A_IMAG(
        .clk(clk),
        .we_p0(bankA_we_p0),
        .we_p1(bankA_we_p1),
        .addr_p0(bankA_addr_p0),
        .addr_p1(bankA_addr_p1),
        .wdata_p0(bankA_wdata_p0_i),
        .wdata_p1(bankA_wdata_p1_i),
        .rdata_p0(bankA_rdata_p0_i),
        .rdata_p1(bankA_rdata_p1_i)
    );

    dual_port_ram #(.DEPTH(N), .WIDTH(19)) BANK_B_REAL(
        .clk(clk),
        .we_p0(bankB_we_p0),
        .we_p1(bankB_we_p1),
        .addr_p0(bankB_addr_p0),
        .addr_p1(bankB_addr_p1),
        .wdata_p0(bankB_wdata_p0),
        .wdata_p1(bankB_wdata_p1),
        .rdata_p0(bankB_rdata_p0),
        .rdata_p1(bankB_rdata_p1)
    );

    dual_port_ram #(.DEPTH(N), .WIDTH(19)) BANK_B_IMAG(
        .clk(clk),
        .we_p0(bankB_we_p0),
        .we_p1(bankB_we_p1),
        .addr_p0(bankB_addr_p0),
        .addr_p1(bankB_addr_p1),
        .wdata_p0(bankB_wdata_p0_i),
        .wdata_p1(bankB_wdata_p1_i),
        .rdata_p0(bankB_rdata_p0_i),
        .rdata_p1(bankB_rdata_p1_i)
    );

    always @(posedge clk) begin
        if(rst) begin
            read_data_i <= 0;
            read_data_r <= 0;
        end
        else begin
            read_data_r <= 0;
            read_data_i <= 0;
        end
    end

    //Q1.18 twiddle memory
    reg signed [18:0] real_twiddle_mem [0 : (N/2) - 1];
    reg signed [18:0] imag_twiddle_mem [0 : (N/2) - 1];

    initial begin
        //$readmemh("real_mem.hex", real_mem);
        //$readmemh("imag_mem.hex", imag_mem);
        $readmemh("../rtl/real_twiddle_mem.hex", real_twiddle_mem);
        $readmemh("../rtl/imag_twiddle_mem.hex", imag_twiddle_mem);
    end

    reg signed [18:0] A_r, A_i;
    reg signed [18:0] B_r, B_i;
    reg signed [18:0] W_r, W_i;

    reg [ADDR_WIDTH - 1 : 0] mem_addr_A1, mem_addr_B1;
    reg send1, send2, send3, send4;

    always @(*) begin
        A_r = (bank_sel == BANK_A_SEL) ? bankA_rdata_p0 : bankB_rdata_p0;
        A_i = (bank_sel == BANK_A_SEL) ? bankA_rdata_p0_i : bankB_rdata_p0_i;
        B_r = (bank_sel == BANK_A_SEL) ? bankA_rdata_p1 : bankB_rdata_p1;
        B_i = (bank_sel == BANK_A_SEL) ? bankA_rdata_p1_i : bankB_rdata_p1_i;
    end

    always @(posedge clk) begin
        if(rst) begin
            W_r <= 0;
            W_i <= 0;

            mem_addr_A1 <= 0;
            mem_addr_B1 <= 0;

            send1 <= 0;
        end
        else begin
            W_r <= real_twiddle_mem[twiddle_addr];
            W_i <= imag_twiddle_mem[twiddle_addr];

            mem_addr_A1 <= mem_addr_A;
            mem_addr_B1 <= mem_addr_B;
            send1 <= agu_send;
        end
    end

    //Q9.29 values
    reg signed [37:0] p1, p2, p3, p4;

    reg signed [18:0] A_r_1, A_i_1;
    reg [ADDR_WIDTH - 1 : 0] mem_addr_A2, mem_addr_B2;

    always @(posedge clk) begin
        if(rst) begin
            p1 <= 0;
            p2 <= 0;
            p3 <= 0;
            p4 <= 0;
            A_r_1 <= 0;
            A_i_1 <= 0;

            mem_addr_A2 <= 0;
            mem_addr_B2 <= 0;
            send2 <= 0;
        end
        else begin
            p1 <= B_r * W_r;
            p2 <= B_i * W_i;
            p3 <= B_r * W_i;
            p4 <= B_i * W_r;
            A_r_1 <= A_r;
            A_i_1 <= A_i;

            mem_addr_A2 <= mem_addr_A1;
            mem_addr_B2 <= mem_addr_B1;
            send2 <= send1;
        end
    end

    //Q9.29 values
    reg signed [37:0] temp_r, temp_i;
    reg signed [37:0] A_r_2, A_i_2;

    reg [ADDR_WIDTH - 1 : 0] mem_addr_A3, mem_addr_B3;

    always @(posedge clk) begin
        if(rst) begin
            temp_r <= 0;
            temp_i <= 0;
            A_r_2 <= 0;
            A_i_2 <= 0;

            mem_addr_A3 <= 0;
            mem_addr_B3 <= 0;
            send3 <= 0;
        end
        else begin
            temp_r <= p1 - p2;
            temp_i <= p3 + p4;
            A_r_2  <= {{19{A_r_1[18]}}, A_r_1} <<< 18; // Q8.11 -> Q9.29
            A_i_2  <= {{19{A_i_1[18]}}, A_i_1} <<< 18; // Q8.11 -> Q9.29

            mem_addr_A3 <= mem_addr_A2;
            mem_addr_B3 <= mem_addr_B2;
            send3 <= send2;
        end
    end

    //Q10.29
    reg signed [38:0] out_A_r, out_A_i;
    reg signed [38:0] out_B_r, out_B_i;

    reg [ADDR_WIDTH - 1 : 0] mem_addr_A4, mem_addr_B4;

    always @(posedge clk) begin
        if(rst) begin
            out_A_r <= 0;
            out_A_i <= 0;
            out_B_r <= 0;
            out_B_i <= 0;

            mem_addr_A4 <= 0;
            mem_addr_B4 <= 0;
            send4 <= 0;
        end
        else begin
            out_A_r <= {A_r_2[37], A_r_2} + {temp_r[37], temp_r};
            out_A_i <= {A_i_2[37], A_i_2} + {temp_i[37], temp_i};
            out_B_r <= {A_r_2[37], A_r_2} - {temp_r[37], temp_r};
            out_B_i <= {A_i_2[37], A_i_2} - {temp_i[37], temp_i};

            mem_addr_A4 <= mem_addr_A3;
            mem_addr_B4 <= mem_addr_B3;
            send4 <= send3;
        end
    end

    always @(posedge clk) begin
        if(fft_done) begin
            display_fft_output();
        end
    end

    always @(posedge clk) begin
        if(fft_start) begin
            display_mem();
        end
    end

    //10.29
    wire signed [38:0] M_r, M_i;
    wire signed [38:0] N_r, N_i;

    assign M_r = out_A_r;
    assign M_i = out_A_i;
    assign N_r = out_B_r;
    assign N_i = out_B_i;

    //Q8.11
    wire signed [18:0] M_r_trunc, M_i_trunc;
    wire signed [18:0] N_r_trunc, N_i_trunc;

    assign M_r_trunc = {M_r[38], M_r[35:18]};
    assign M_i_trunc = {M_i[38], M_i[35:18]};
    assign N_r_trunc = {N_r[38], N_r[35:18]};
    assign N_i_trunc = {N_i[38], N_i[35:18]};

    /*always @(posedge clk) begin
        if(load_en) begin
            real_mem[load_addr] <= load_data_r;
            imag_mem[load_addr] <= load_data_i;
        end
        else if(send4) begin
            real_mem[mem_addr_A4] <= M_r_trunc;
            imag_mem[mem_addr_A4] <= M_i_trunc;
            real_mem[mem_addr_B4] <= N_r_trunc;
            imag_mem[mem_addr_B4] <= N_i_trunc;
        end
    end*/

    reg signed [18:0] disp_signal_real;
    reg signed [18:0] disp_signal_imag;
    localparam IDLE = 0;
    localparam DISP = 1;
    reg disp_state;

    reg [$clog2(N) - 1 : 0] point_cnt;

    /*always @(posedge clk) begin
        if(rst) begin
            disp_signal_real <= 0;
            disp_signal_imag <= 0;
            disp_state <= IDLE;
            point_cnt <= 0;
        end
        else begin
            case(disp_state)
                IDLE : begin
                    if(fft_done) begin
                        disp_state <= DISP;
                    end
                    point_cnt <= 0;
                    disp_signal_real <= 0;
                    disp_signal_imag <= 0;
                end
                DISP : begin
                    if(point_cnt == N - 1) begin
                        disp_state <= IDLE;
                    end
                    point_cnt <= point_cnt + 1;
                    disp_signal_real <= real_mem[point_cnt];
                    disp_signal_imag <= imag_mem[point_cnt];
                end
            endcase
        end
    end*/

    /*genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin : dbg
            wire signed [18:0] real_dbg = real_mem[i];
            wire signed [18:0] imag_dbg = imag_mem[i];
        end
    endgenerate*/

    task display_fft_output;
        integer i;
        real real_val, imag_val;
        real scale;
        begin
            scale = 2.0 ** 11;
            $display("FFT OUTPUT : ");
            for(i = 0; i < N; i = i + 1) begin
                if(bank_sel == BANK_A_SEL) begin
                    real_val = $itor($signed(BANK_A_REAL.mem[i])) / scale;
                    imag_val = $itor($signed(BANK_A_IMAG.mem[i])) / scale;
                end
                else begin
                    real_val = $itor($signed(BANK_B_REAL.mem[i])) / scale;
                    imag_val = $itor($signed(BANK_B_IMAG.mem[i])) / scale;
                end
                $display("X[%0d] = %10.4f + j%10.4f", i, real_val, imag_val);
            end
            $display("End of Output\n");
        end
    endtask

    task display_mem;
        integer i;
        begin
            $display("MEM CONTENTS (bank_sel = %0d)", bank_sel);
            if(bank_sel == BANK_A_SEL) begin
                $display("Reading BANK A:");
                $display("REAL : ");
                for(i = 0; i < N; i = i + 1) begin
                    $display(BANK_A_REAL.mem[i]);
                end
                $display("IMAG : ");
                for(i = 0; i < N; i = i + 1) begin
                    $display(BANK_A_IMAG.mem[i]);
                end
            end
            else begin
                $display("Reading BANK B:");
                $display("REAL : ");
                for(i = 0; i < N; i = i + 1) begin
                    $display(BANK_B_REAL.mem[i]);
                end
                $display("IMAG : ");
                for(i = 0; i < N; i = i + 1) begin
                    $display(BANK_B_IMAG.mem[i]);
                end
            end
            $display("End of MEM CONTENTS\n");
        end
    endtask

endmodule