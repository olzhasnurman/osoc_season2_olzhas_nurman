/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------------------
// This is a counter module that counts the number of transferred data bursts through AXI4-Lite interface.
// --------------------------------------------------------------------------------------------------------

module counter 
#(
    parameter LIMIT          = 4'b1111,
              SIZE           = 16 
) 
(   
    // Countrol logic
    input  logic i_clk,
    input  logic i_arst,
    input  logic i_run,
    input  logic i_restartn,

    // Output interface.
    output logic o_done
);

    logic [ $clog2( SIZE ) - 1:0 ] s_count;

    always_ff @( posedge i_clk, posedge i_arst ) begin
        if      ( i_arst      ) s_count <= '0;
        else if ( ~i_restartn ) s_count <= '0;
        else if ( i_run       ) s_count <= s_count + 4'b1; 
    end

    always_ff @( posedge i_clk, posedge i_arst ) begin
        if      ( i_arst                      ) o_done <= 1'b0;
        else if ( (s_count == LIMIT ) & i_run ) o_done <= 1'b1;
        else                                  o_done <= 1'b0;
    end
    
endmodule