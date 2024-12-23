/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -------------------------------------------------------------------------------
// This is a data memory in RISC-V architecture. Later to be replaced with cache.
// -------------------------------------------------------------------------------

`define PATH_TO_DMEM "/home/maveric/osoc_season2_olzhas_nurman/test/tests/dmem.txt" // Later to be defined properly.


module d_mem
// Parameters.
#(
    parameter DATA_WIDTH = 64,
              ADDR_WIDTH = 11,
              MEM_DEPTH  = 256
)
// Port decleration. 
(   
    // Common clock, enable signal.
    input  logic                      i_clk,
    input  logic                      i_write_en,
    input  logic                      i_arst,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Memory block.
    logic [ DATA_WIDTH - 1:0 ] mem_block [ MEM_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge i_clk, posedge i_arst ) begin 
        if ( i_arst ) $readmemh ( `PATH_TO_DMEM, mem_block );
        else if ( i_write_en ) mem_block [ i_addr [ 10:3 ] ] <= i_write_data;
    end

    // Read logic.
    assign o_read_data = mem_block [ i_addr [ 10:3 ] ];

    
endmodule
