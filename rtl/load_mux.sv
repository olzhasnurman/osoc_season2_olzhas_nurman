/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// -----------------------------------------------------------------------
// This is a module designed to take 64-bit data from memory & adjust it 
// based on different LOAD instruction requirements. 
// -----------------------------------------------------------------------

module load_mux 
#(
    parameter DATA_WIDTH = 64
) 
(
    // Input interface. 
    input  logic [              2:0 ] i_func3,
    input  logic [ DATA_WIDTH - 1:0 ] i_data,
    input  logic [              2:0 ] i_addr_offset,

    // Output interface
    output logic [ DATA_WIDTH - 1:0 ] o_data
);

    logic [  7:0 ] s_byte;
    logic [ 15:0 ] s_half;
    logic [ 31:0 ] s_word;

    always_comb begin
        case ( i_addr_offset [ 2:0 ] )
            3'b000:  s_byte = i_data [ 7 :0  ];
            3'b001:  s_byte = i_data [ 15:8  ];
            3'b010:  s_byte = i_data [ 23:16 ];
            3'b011:  s_byte = i_data [ 31:24 ];
            3'b100:  s_byte = i_data [ 39:32 ];
            3'b101:  s_byte = i_data [ 47:40 ];
            3'b110:  s_byte = i_data [ 55:48 ];
            3'b111:  s_byte = i_data [ 63:56 ];
            default: s_byte = i_data [ 7 :0  ];
        endcase 

        case ( i_addr_offset [ 2:1 ] )
            2'b00:   s_half = i_data [ 15:0  ];
            2'b01:   s_half = i_data [ 31:16 ];
            2'b10:   s_half = i_data [ 47:32 ];
            2'b11:   s_half = i_data [ 63:48 ];
            default: s_half = i_data [ 15:0  ];
        endcase 

    end

    assign s_word = i_addr_offset [ 2 ] ? i_data [ 63:32 ] : i_data [ 31:0 ];


    always_comb begin
        case ( i_func3 )
            3'b000:  o_data = { { 56 { s_byte [ 7  ] } }, s_byte }; // LB  Instruction.              
            3'b001:  o_data = { { 48 { s_half [ 15 ] } }, s_half }; // LH  Instruction.
            3'b010:  o_data = { { 32 { s_word [ 31 ] } }, s_word }; // LW  Instruction.
            3'b011:  o_data = i_data;                               // LD  Instruction.
            3'b100:  o_data = { { 56 { 1'b0 } }, s_byte };          // LBU Instruction. 
            3'b101:  o_data = { { 48 { 1'b0 } }, s_half };          // LHU Instruction.
            3'b110:  o_data = { { 32 { 1'b0 } }, s_word };          // LWU Instruction.
            default: o_data = '0;

        endcase
    end
    
endmodule