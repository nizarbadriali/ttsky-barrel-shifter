// ============================================================================
// Level 2: N-bit barrel shifter, ROTATE RIGHT and ROTATE LEFT
// Architecture: Weste & Harris, CMOS VLSI Design 4e, Fig. 11.68(b)
//
// Start from your working Level 1 loops. You only ADD two things:
//   (A) XOR gates that invert k when rotating left
//   (B) a "preshift" row that rotates right by 1 when rotating left
// Test with:  cd test/levels && make LEVEL=2 N=4
// ============================================================================

module n_ror_l #(parameter N = 4)
(
    input  wire [N-1:0]         data_in,   // word to be rotated
    input  wire [$clog2(N)-1:0] k,         // rotate amount (0 .. N-1)
    input  wire                 left,      // 0 = rotate right, 1 = rotate left
    output wire [N-1:0]         data_out
);

    localparam STAGES = $clog2(N);

    // Same packed bus layout as Level 1: bit b of bus j is stage[j*N + b].
    wire [(STAGES+1)*N-1:0] stage;

    // ------------------------------------------------------------------------
    // The idea:
    //   Rotate LEFT by k  ==  rotate RIGHT by (N - k).
    //   In two's complement, N - k = ~k + 1  (mod N).
    //   "+1"  -> a fixed rotate right by 1 (the preshift row)
    //   "~k"  -> just invert the bits of k (XOR gates), no adder needed!
    //   Check: N = 8, left by 3 -> ~3 = 4, +1 = 5. Right by 5 == left by 3.
    // ------------------------------------------------------------------------

    // TODO (A): k_eff = k when left = 0, ~k when left = 1.
    // Hint: x ^ 1 = ~x and x ^ 0 = x, so XOR each bit of k with left.
    //       {STAGES{left}} copies the 1-bit "left" STAGES times
    //       so it is the same width as k.
    wire [STAGES-1:0] k_eff = k ^ {STAGES{left}};


    // TODO (B): preshift row. pre = data_in rotated right by 1 when left = 1,
    //           otherwise data_in unchanged.
    // Hint: rotate right by 1 on 4 bits: {A3 A2 A1 A0} -> {A0 A3 A2 A1}.
    //       Use concatenation { , } and a part-select like data_in[N-1:1].
    wire [N-1:0] pre = left ? {data_in[0], data_in[N-1:1]} : data_in;


    assign stage[N-1:0] = pre;                   // the rotate rows now start from the preshift
    assign data_out     = stage[STAGES*N +: N];

    // TODO (C): copy your Level 1 generate loops here.
    // Hint: only ONE thing changes. Which signal should select the muxes now?
    genvar j, b;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : row
            for (b = 0; b < N; b = b + 1) begin : mux
                assign stage[(j+1)*N + b] = k_eff[j] ? stage[j*N + ((b + (1 << j)) % N)]
                                                     : stage[j*N + b];
            end
        end
    endgenerate


endmodule
