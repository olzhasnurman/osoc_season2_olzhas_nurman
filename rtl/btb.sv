/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ------------------------------------------------------------------------------------------
// This module implements a branch target buffer (BTB) based on N-way set-associative cache.
// ------------------------------------------------------------------------------------------

module btb 
#(
    parameter SET_COUNT  = 4,
              N          = 4, 
              ADDR_WIDTH = 64
)
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic                      i_branch_taken,
    input  logic [ ADDR_WIDTH - 1:0 ] i_target_addr,
    input  logic [ ADDR_WIDTH - 1:0 ] i_instr_addr,

    // Output interface.
    output logic                      o_hit,
    output logic [ ADDR_WIDTH - 1:0 ] o_target_addr
);
    //---------------------------------
    // Localparameters.
    //---------------------------------
    localparam BYTE_OFFSET_WIDTH = 2;                                             // 2 bit. 
    localparam INDEX_WIDTH       = $clog2 ( SET_COUNT );                           // 2 bit.
    localparam BIA_WIDTH         = ADDR_WIDTH - INDEX_WIDTH - BYTE_OFFSET_WIDTH; // 60 bit.

    localparam BIA_MSB   = ADDR_WIDTH - 1;              // 63.
    localparam BIA_LSB   = BIA_MSB - BIA_WIDTH + 1;     // 4.
    localparam INDEX_MSB = BIA_LSB - 1;                 // 3.
    localparam INDEX_LSB = INDEX_MSB - INDEX_WIDTH + 1; // 2.


    //---------------------------------
    // Internal nets.
    //---------------------------------
    logic [ BIA_WIDTH   - 1:0 ] s_bia_in; // Branch instruction address.
    logic [ INDEX_WIDTH - 1:0 ] s_index_in;

    logic [ BIA_WIDTH - 1:0 ] s_bia;
    logic                     s_valid;

    logic                        s_hit;
    logic [ N            - 1:0 ] s_hit_find;
    logic [ $clog2 ( N ) - 1:0 ] s_way;
    logic [ $clog2 ( N ) - 1:0 ] s_plru;


    //-----------------
    // Memory blocks.
    //-----------------
    logic [ BIA_WIDTH  - 1:0 ] bia_mem   [ SET_COUNT - 1:0 ][ N - 1:0 ]; // Branch Instruction Address = Tag memory.
    logic [ ADDR_WIDTH - 1:0 ] bta_mem   [ SET_COUNT - 1:0 ][ N - 1:0 ]; // Branch Target Addrss memory.
    logic [ N          - 1:0 ] valid_mem [ SET_COUNT - 1:0 ];            // Valid memory. 
    logic [ N          - 1:0 ] plru_mem  [ SET_COUNT - 1:0 ];            // Valid memory. 

    //-----------------------------------
    // Continious assignments.
    //-----------------------------------
    assign s_bia_in   = i_instr_addr [ BIA_MSB   : BIA_LSB   ];
    assign s_index_in = i_instr_addr [ INDEX_MSB : INDEX_LSB ];

    assign s_bia   = bia_mem   [ s_index_in ][ s_way ];
    assign s_valid = valid_mem [ s_index_in ][ s_way ];


    //-------------------------------------
    // Check for hit & plru.
    //-------------------------------------

    // Check for hit and find the way/line that matches.
    always_comb begin
        s_hit_find [ 0 ] = valid_mem [ s_index_in ][ 0 ] & ( bia_mem [ s_index_in ][ 0 ] == s_bia_in );
        s_hit_find [ 1 ] = valid_mem [ s_index_in ][ 1 ] & ( bia_mem [ s_index_in ][ 1 ] == s_bia_in );
        s_hit_find [ 2 ] = valid_mem [ s_index_in ][ 2 ] & ( bia_mem [ s_index_in ][ 2 ] == s_bia_in );
        s_hit_find [ 3 ] = valid_mem [ s_index_in ][ 3 ] & ( bia_mem [ s_index_in ][ 3 ] == s_bia_in );

        casez ( s_hit_find )
            4'bzzz1: s_way = 2'b00;
            4'bzz10: s_way = 2'b01;
            4'bz100: s_way = 2'b10;
            4'b1000: s_way = 2'b11;
            default: s_way = s_plru; // If there is no record of this branch instruction, new_value will be written into place of plru.
        endcase
    end

    assign s_hit = | s_hit_find;

    // Logic for finding the PLRU.
    assign s_plru = { plru_mem [ s_index_in ][ 0 ], ( plru_mem [ s_index_in ][ 0 ] ? plru_mem [ s_index_in ][ 2 ] : plru_mem [ s_index_in ][ 1 ] ) };


    //--------------------------------------------------
    // Memory write logic.
    //--------------------------------------------------

    // Valid memory.
    always_ff @( posedge i_clk, posedge i_arst ) begin
        if ( i_arst ) begin
            for ( int i = 0; i < SET_COUNT; i++ ) begin
                valid_mem [ i ] <= '0;
            end
        end
        else if ( i_branch_taken ) valid_mem [ s_index_in ][ s_way ] <= 1'b1;
    end

    // PLRU memory.
    //-----------------------------------------------------------------------
    // PLRU organization:
    // 0 - left, 1 - right leaf.
    // plru [ 0 ] - parent, plru [ 1 ] = left leaf, plru [ 2 ] - right leaf.
    //-----------------------------------------------------------------------
    always_ff @( posedge i_clk, posedge i_arst ) begin
        if ( i_arst ) begin
            for ( int i = 0; i < SET_COUNT; i++ ) begin
                plru_mem [ i ] <= '0;
            end       
        end
        else if ( i_branch_taken ) begin
            plru_mem [ s_index_in ][ 0               ] <= ~ s_way [ 1 ];
            plru_mem [ s_index_in ][ 1 + s_way [ 1 ] ] <= ~ s_way [ 0 ];
        end
    end


    // BIA & BTA memory.
    always_ff @( posedge i_clk, posedge i_arst ) begin
        if ( i_branch_taken ) begin
            bia_mem [ s_index_in ][ s_way ] <= s_bia_in;
            bta_mem [ s_index_in ][ s_way ] <= i_target_addr;
        end
    end

    
    //------------------------------
    // Output logic.
    //------------------------------
    assign o_hit         = s_hit;
    assign o_target_addr = bta_mem [ s_index_in ][ s_way ];

endmodule