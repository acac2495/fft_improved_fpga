module bit_reverse #(parameter N = 32) (
    input  [$clog2(N)-1:0] addr_in,
    output [$clog2(N)-1:0] addr_out
);
    localparam WIDTH = $clog2(N);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : reverse_bits
            assign addr_out[i] = addr_in[WIDTH-1-i];
        end
    endgenerate

endmodule