module dual_port_ram #(parameter DEPTH = 32, WIDTH = 19, INIT_FILE = "") (clk, addr_p0, addr_p1, rdata_p0, rdata_p1, wdata_p0, wdata_p1, we_p0, we_p1);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    input clk, we_p0, we_p1;
    input signed [WIDTH - 1 : 0] wdata_p0, wdata_p1;
    input [ADDR_WIDTH - 1 : 0] addr_p0, addr_p1;

    output reg signed [WIDTH - 1 : 0] rdata_p0, rdata_p1;

    reg signed [WIDTH - 1 : 0] mem [0 : DEPTH - 1];

    /*initial begin
        if(INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end*/

    always @(posedge clk) begin
        if(we_p0) begin
            mem[addr_p0] <= wdata_p0;
        end
        else begin
            rdata_p0 <= mem[addr_p0];
        end
        if(we_p1) begin
            mem[addr_p1] <= wdata_p1;
        end
        else begin
            rdata_p1 <= mem[addr_p1];
        end
    end

endmodule