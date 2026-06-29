module agu #(parameter N = 32) (clk, rst, fft_start, sent, fft_done, mem_addr_A, mem_addr_B, twiddle_addr, agu_send, fft_busy, bank_sel);
    
    localparam N_BUTTERFLIES = N / 2;
    localparam N_LEVELS = $clog2(N);

    localparam FLUSH_CYCLES = 5;

    localparam ADDR_WIDTH = N_LEVELS;
    localparam TWIDDLE_WIDTH = N_LEVELS - 1;
    localparam N_BITS = N_LEVELS;

    input clk, rst;
    input fft_start;

    output reg fft_done;
    output reg sent;
    output reg agu_send;
    output reg fft_busy;

    output reg [ADDR_WIDTH - 1 : 0] mem_addr_A, mem_addr_B;
    output reg [TWIDDLE_WIDTH - 1 : 0] twiddle_addr;

    output reg bank_sel;
    localparam BANK_A_SEL = 0;
    localparam BANK_B_SEL = 1;

    reg [TWIDDLE_WIDTH - 1 : 0] twiddle_grp;

    reg [ADDR_WIDTH - 2 : 0] lvl_cnt;
    reg [ADDR_WIDTH - 2 : 0] bf_cnt;

    wire [ADDR_WIDTH - 1 : 0] bf_cnt_2;
    assign bf_cnt_2 = {bf_cnt, 1'b0};

    wire [ADDR_WIDTH - 1 : 0] up_ind, low_ind;
    assign up_ind = bf_cnt_2;
    assign low_ind = bf_cnt_2 + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};

    localparam IDLE = 0;
    localparam SEND = 1;
    localparam FLUSH = 2;

    reg [1:0] state;
    reg [$clog2(FLUSH_CYCLES) - 1 : 0] flush_cnt;
    reg flush_last;

    always @(posedge clk) begin
        if(rst) begin
            sent <= 0;
            lvl_cnt <= 0;
            bf_cnt <= 0;
            state <= IDLE;
            mem_addr_A <= 0;
            mem_addr_B <= 0;
            twiddle_addr <= 0;
            flush_cnt <= 0;
            fft_done <= 0;
            flush_last <= 0;
            agu_send <= 0;
            fft_busy <= 0;
            bank_sel <= BANK_A_SEL;
        end
        else begin
            case(state)
                IDLE : begin
                    if(fft_start) begin
                        bf_cnt <= 0;
                        lvl_cnt <= 0;
                        state <= SEND;
                        fft_busy <= 1;
                    end
                    sent <= 0;
                    fft_done <= 0;
                    flush_last <= 0;
                    flush_cnt <= 0;
                    agu_send <= 0;
                end
                SEND : begin
                    if(bf_cnt == (N_BUTTERFLIES - 1)) begin
                        if(lvl_cnt == (N_LEVELS - 1)) begin
                            flush_last <= 1;
                        end
                        else begin
                            bf_cnt <= 0;
                            lvl_cnt <= lvl_cnt + 1;
                            flush_last <= 0;
                        end
                        state <= FLUSH;
                        flush_cnt <= 0;
                        sent <= 1;
                    end
                    else begin
                        bf_cnt <= bf_cnt + 1;
                        sent <= 0;
                    end
                    mem_addr_A <= rotateN(up_ind, {1'b0, lvl_cnt});
                    mem_addr_B <= rotateN(low_ind, {1'b0, lvl_cnt});
                    twiddle_grp <= bf_cnt >> (TWIDDLE_WIDTH - lvl_cnt);
                    twiddle_addr <= bf_cnt & ~(({TWIDDLE_WIDTH{1'b1}}) >> lvl_cnt);
                    agu_send <= 1;
                end
                FLUSH : begin
                    sent <= 0;
                    if(flush_cnt == FLUSH_CYCLES - 1) begin
                        if(flush_last) begin
                            state <= IDLE;
                            fft_done <= 1;
                            fft_busy <= 0;
                        end
                        else begin
                            state <= SEND;
                            fft_done <= 0;
                        end
                        bank_sel <= ~bank_sel;
                    end
                    else begin
                        flush_cnt <= flush_cnt + 1;
                    end
                    agu_send <= 0;
                end
            endcase
        end
    end

    function [N_BITS - 1 : 0] rotateN;
        input [N_BITS - 1 : 0] in;
        input [N_BITS - 1 : 0] shift;
        begin
            rotateN = (in << shift) | (in >> (N_BITS - shift));
        end
    endfunction

endmodule
