// ============================================================================
// Level 1: N-bit logarithmic barrel shifter, ROTATE RIGHT only
// Architecture: Weste & Harris, CMOS VLSI Design 4e, Fig. 11.68(a)
//
// Your job: fill in the TODO section (the generate loops).
// Test with:  cd test/levels && make LEVEL=1 N=4
// ============================================================================

module n_ror_barrel #(parameter N = 4)
(
    input  wire [N-1:0]         data_in,   // word to be rotated
    input  wire [$clog2(N)-1:0] k,         // rotate amount (0 .. N-1)
    output wire [N-1:0]         data_out
);

    localparam STAGES = $clog2(N);   // number of mux rows = log2(N)

    // STAGES+1 buses, each N bits wide, packed side by side in ONE vector:
    //   bus 0       = stage[N-1:0]            = input to the first row
    //   bus j       = stage[j*N +: N]         (bits j*N .. j*N+N-1)
    //   bus STAGES  = stage[STAGES*N +: N]    = output of the last row
    // So bit b of bus j is  stage[j*N + b].
    // (We use one packed vector instead of a wire array because the
    //  synthesis tool (Yosys) does not accept assigns to wire arrays.)
    wire [(STAGES+1)*N-1:0] stage;

    assign stage[N-1:0] = data_in;               // first bus is the input
    assign data_out     = stage[STAGES*N +: N];  // last bus is the output

    // ------------------------------------------------------------------------
    // TODO: build the grid of 2:1 muxes with two nested generate loops.
    //
    // Hint 1 - Structure:
    //   Outer loop over rows    (j = 0 .. STAGES-1)
    //   Inner loop over bits    (b = 0 .. N-1)
    //   Each inner iteration = ONE 2:1 mux = ONE assign statement.
    //
    // Hint 2 - Generate syntax:
    //   genvar j, b;
    //   generate
    //       for (j = 0; j < ???; j = j + 1) begin : row
    //           for (b = 0; b < ???; b = b + 1) begin : mux
    //               assign ... ;
    //           end
    //       end
    //   endgenerate
    //   (Generate loops need a label after "begin", like ": row".)
    //
    // Hint 3 - A 2:1 mux in Verilog is the ternary operator:
    //   assign out = select ? in_when_1 : in_when_0;
    //
    // Hint 4 - For the mux of row j, bit b:
    //   output    -> bit b of the NEXT bus,   stage[(j+1)*N + b]
    //   select    -> which bit of k controls row j?
    //   in_when_0 -> pass through: the same bit b of THIS row's bus,
    //                stage[j*N + b]
    //   in_when_1 -> the bit that a rotate brings into position b
    //                (index it as stage[j*N + <which bit?>])
    //
    // Hint 5 - How far does row j rotate?
    //   Row j rotates right by 2^j  (row 0 -> 1, row 1 -> 2, row 2 -> 4 ...).
    //   In Verilog write 2^j as (1 << j): shifting the number 1 left by j
    //   places doubles it j times.  1<<0 = 1, 1<<1 = 2, 1<<2 = 4.
    //   (Do NOT write 2^j: in Verilog ^ means XOR!)
    //
    // Hint 6 - Which input bit lands at position b?
    //   In a rotate RIGHT, data moves toward bit 0, so output bit b takes
    //   the input bit that is (rotate amount) positions HIGHER.
    //   When that index runs past N-1 it must wrap around to 0, and the
    //   wrap must happen INSIDE the bus (before adding j*N).
    //   Which operator gives the remainder after dividing by N?
    //   Try N = 4, rotate by 2 on paper: which input lands at bit 3? at bit 0?
    // ------------------------------------------------------------------------

    genvar j, b;
    generate
        for (j = 0; j < STAGES; j = j + 1) begin : row
            for (b = 0; b < N; b = b + 1) begin : mux
                assign stage[(j+1)*N + b] = k[j] ? stage[j*N + ((b + (1 << j)) % N)]
                                                 : stage[j*N + b];
            end
        end
    endgenerate


endmodule
