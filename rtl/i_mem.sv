/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------
// This is a instruction memory in RISC-V architecture. Later to be replaced with cache.
// --------------------------------------------------------------------------------------

module i_mem
// Parameters.
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 10,
              MEM_DEPTH  = 1024
)
// Port decleration. 
(   
    // Common clock, enable signal.
    input  logic                      i_clk,
    input  logic                      i_write_en,

    //Input interface. 
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Memory block.
    logic [ DATA_WIDTH - 1:0 ] mem_block [ MEM_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge i_clk ) begin 
        if ( i_write_en ) begin
            mem_block [ i_addr ] <= i_write_data;
        end
    end

    // Read logic.
    assign o_read_data = mem_block [ i_addr ];

    
endmodule