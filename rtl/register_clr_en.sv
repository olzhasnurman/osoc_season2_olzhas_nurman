/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------
// This is a nonarchitectural register with clear and enable signals.
// -------------------------------------------------------------------

module register_clr_en
// Parameters.
#(
    parameter DATA_WIDTH = 64
)
// Port decleration. 
(   
    //Input interface. 
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic                      i_clr,
    input  logic                      i_enable,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Write logic.
    always_ff @( posedge i_clk, posedge i_arst ) begin 
        if      ( i_arst   ) o_read_data <= '0;
        else if ( i_clr    ) o_read_data <= '0;
        else if ( i_enable ) o_read_data <= i_write_data;
    end
    
endmodule