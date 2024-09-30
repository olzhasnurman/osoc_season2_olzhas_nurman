/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// --------------------------------------------------------------------------------------
// This is a instruction memory simulatrion file. Later to be replaced with cache.
// --------------------------------------------------------------------------------------

`define PATH_TO_MEM "./test/tests/instr/riscv-tests/rv64ui-p-xori.txt" // Later to be defined properly.

module i_mem
// Parameters.
#(
    parameter DATA_WIDTH = 32,
              ADDR_WIDTH = 10,
              MEM_DEPTH  = 1024
)
// Port decleration. 
(   
    //Input interface. 
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr,
    
    // Output interface.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    // Memory block.
    logic [ DATA_WIDTH - 1:0 ] mem_block [ MEM_DEPTH - 1:0 ];

    // Write logic.
    always_ff @( posedge i_clk, posedge i_arst ) begin 
        if ( i_arst ) begin
            $readmemh ( `PATH_TO_MEM, mem_block );
        end
    end

    // Read logic.
    assign o_read_data = mem_block [ i_addr ];

    
endmodule