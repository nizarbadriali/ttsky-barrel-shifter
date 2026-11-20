// ============================================================================
// Level 3: N-bit barrel shifter with ROTATE, LOGICAL and ARITHMETIC SHIFTS
// Architecture: Weste & Harris, CMOS VLSI Design 4e, Fig. 11.68(c)
//
//   shift left arithmetic | operation
//     0    0      x       | rotate right
//     0    1      x       | rotate left
//     1    0      0       | logical shift right     (fill with 0)
//     1    0      1       | arithmetic shift right  (fill with sign bit)
//     1    1      x       | shift left              (fill with 0)
//
// Start from your working Level 2 code, then add the masking unit.
// Test with:  cd test/levels && make LEVEL=3 N=4
// ============================================================================

module n_shifter #(parameter N = 4)
(
    input  wire [N-1:0]         data_in,
    input  wire [$clog2(N)-1:0] k,
    input  wire                 left,       // 0 = right, 1 = left
    input  wire                 shift,      // 0 = rotate, 1 = shift
    input  wire                 arithmetic, // 1 = arithmetic right shift
    output wire [N-1:0]         data_out
);

    localparam STAGES = $clog2(N);

    // Same packed bus layout as Levels 1-2: bit b of bus j is stage[j*N + b].
    wire [(STAGES+1)*N-1:0] stage;

    // ---------------- Rotate core ----------------
    // TODO (A): copy k_eff, pre, and your generate loops from Level 2.
    wire [STAGES-1:0] k_eff = k ^ {STAGES{left}};
    wire [N-1:0]      pre   = left ? {data_in[0], data_in[N-1:1]} : data_in;

    assign stage[N-1:0] = pre;

    genvar j, b;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : row
            for (b = 0; b < N; b = b + 1) begin : mux
                assign stage[(j+1)*N + b] = k_eff[j] ? stage[j*N + ((b + (1 << j)) % N)]
                                                     : stage[j*N + b];
            end
        end
    endgenerate

    wire [N-1:0] x = stage[STAGES*N +: N];   // rotation result ("X" in Fig 11.68c)

    // ---------------- Masking unit ----------------
    // A shift is a rotate where the bits that WRAPPED AROUND are replaced
    // by a "kill value". The mask marks which bits wrapped.
    //
    // Example, N = 8, right shift by 2:
    //   rotate result  x    = b1 b0 b7 b6 b5 b4 b3 b2
    //   mask                =  1  1  0  0  0  0  0  0   <- top k bits
    //   output              =  K  K b7 b6 b5 b4 b3 b2   (K = kill value)
    //
    // A mask with k ones filled from one end is a THERMOMETER CODE.

    wire [N-1:0] therm;   // thermometer code: ones in the k LOWEST bits
    wire [N-1:0] mask;    // 1 = replace this bit with the kill value

    // TODO (B): generate loop over bits b = 0 .. N-1 that sets
    //   therm[b] : 1 when bit b is one of the k lowest bits.
    //              Hint: it's a single comparison between b and k.
    //   mask[b]  : 0 for rotates (shift = 0).
    //              Left shift: wrapped bits are the k LOWEST bits -> therm[b]
    //              Right shift: wrapped bits are the k HIGHEST bits
    //                           -> therm, but bit-reversed. Which therm bit
    //                              corresponds to output bit b when reversed?
    generate
        for (b = 0; b < N; b = b + 1) begin : maskgen
            assign therm[b] = (b < k);
            assign mask[b]  = shift & (left ? therm[b] : therm[N-1-b]);
        end
    endgenerate


    // TODO (C): kill value.
    //   1 only for an arithmetic RIGHT shift of a negative number,
    //   otherwise 0. Which bit of data_in is the sign bit?
    wire kill = arithmetic & ~left & data_in[N-1];


    // TODO (D): output. Each bit is one 2:1 mux:
    //   mask[b] = 1 -> kill value,   mask[b] = 0 -> x[b]
    // Hint: you can do all N bits at once with bitwise operators,
    //       or with one more generate loop. {N{kill}} makes N copies of kill.
    assign data_out = (mask & {N{kill}}) | (~mask & x);



endmodule
