/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------------------
// This is a nonarchitectural register file with stall and flush signals for fetch stage pipelining.
// --------------------------------------------------------------------------------------------------

module preg_fetch
// Parameters.
#(
    parameter DATA_WIDTH  = 64,
              INSTR_WIDTH = 32
)
// Port decleration. 
(   
    //Input interface. 
    input  logic                       i_clk,
    input  logic                       i_arst,
    input  logic                       i_flushD,
    input  logic                       i_stallD,
    input  logic [ INSTR_WIDTH - 1:0 ] i_instr,
    input  logic [ DATA_WIDTH  - 1:0 ] i_pc,
    input  logic [ DATA_WIDTH  - 1:0 ] i_pc_plus4,
    
    // Output interface.
    output logic [ INSTR_WIDTH - 1:0 ] o_instr,
    output logic [ DATA_WIDTH  - 1:0 ] o_pc,
    output logic [ DATA_WIDTH  - 1:0 ] o_pc_plus4
);

    // Write logic.
    always_ff @( posedge i_clk, posedge i_arst ) begin 
        if ( i_arst ) begin
            o_instr    <= '0;
            o_pc       <= '0;
            o_pc_plus4 <= '0;
        end
        else if ( i_flushD ) begin
            o_instr    <= '0;
            o_pc       <= '0;
            o_pc_plus4 <= '0;
        end
        else if ( ~ i_stallD ) begin
            o_instr    <= i_instr;
            o_pc       <= i_pc;
            o_pc_plus4 <= i_pc_plus4;
        end
    end
    
endmodule