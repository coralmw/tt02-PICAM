`default_nettype none
`timescale 1ns/1ps

module coralmw_mkPICAMTop (
    input [7:0] io_in,
    input [7:0] io_out
   );

    // instantiate the DUT
    coralmw_mkPICAMInternal internal(
        .clock  (io_in[7]),
        .reset  (io_in[6]),
        .in_in_ (io_in[5:0]),
        .out    (io_out)
        );

endmodule
