/* Copyright (c) 2024 Maveric NU. All rights reserved. */

// ----------------------------------------------------------------------
// This module is a 4-way set-associative data cache module.
// ----------------------------------------------------------------------


module dcache 
#(
    parameter SET_COUNT  = 4,
              WORD_WIDTH = 32,
              SET_WIDTH  = 512,
              N          = 4, // N-way set-associative.
              ADDR_WIDTH = 64,
              DATA_WIDTH = 64
)
(
    // Input interface.
    input  logic                      i_clk,
    input  logic                      i_arst,
    input  logic                      i_write_en,
    input  logic                      i_block_we,
    input  logic                      i_mem_access,
    input  logic [              1:0 ] i_store_type, // 00 - SB, 01 - SH, 10 - SW, 11 - SD.
    input  logic [ ADDR_WIDTH - 1:0 ] i_addr, 
    input  logic [ SET_WIDTH  - 1:0 ] i_data_block,
    input  logic [ DATA_WIDTH - 1:0 ] i_write_data,

    // Output interface.
    output logic                      o_hit,
    output logic                      o_dirty,
    output logic [ ADDR_WIDTH - 1:0 ] o_addr_wb,    // write-back address in case of dirty block.
    output logic [ SET_WIDTH  - 1:0 ] o_data_block, // write-back data.
    output logic [ DATA_WIDTH - 1:0 ] o_read_data
);

    //----------------------------------------------------
    // Local parameters for cache size reconfigurability.
    //----------------------------------------------------
    localparam WORD_COUNT = SET_WIDTH/WORD_WIDTH; // 16 words.

    localparam SET_INDEX_WIDTH   = $clog2 ( SET_COUNT    ); // 2 bit.
    localparam WORD_OFFSET_WIDTH = $clog2 ( WORD_COUNT   ); // 4 bit.
    localparam BYTE_OFFSET_WIDTH = $clog2 ( WORD_WIDTH/8 ); // 2 bit.

    localparam TAG_MSB         = ADDR_WIDTH - 1;                                          // 63.
    localparam TAG_LSB         = SET_INDEX_WIDTH + WORD_OFFSET_WIDTH + BYTE_OFFSET_WIDTH; // 8.
    localparam TAG_WIDTH       = TAG_MSB - TAG_LSB + 1;                                   // 56.
    localparam INDEX_MSB       = TAG_LSB - 1;                                             // 7.
    localparam INDEX_LSB       = INDEX_MSB - SET_INDEX_WIDTH + 1;                         // 6.
    localparam WORD_OFFSET_MSB = INDEX_LSB - 1;                                           // 5.
    localparam WORD_OFFSET_LSB = BYTE_OFFSET_WIDTH;                                       // 2.
    localparam BYTE_OFFSET_MSB = BYTE_OFFSET_WIDTH - 1;                                   // 1.


    //---------------------------------------------------------
    // Internal nets.
    //---------------------------------------------------------
    logic [ TAG_WIDTH         - 1:0 ] s_tag_in;
    logic [ SET_INDEX_WIDTH   - 1:0 ] s_index_in;
    logic [ WORD_OFFSET_WIDTH - 1:0 ] s_word_offset_in;
    logic [ BYTE_OFFSET_WIDTH - 1:0 ] s_byte_offset_in;

    logic [ TAG_WIDTH    - 1:0 ] s_tag;
    logic                        s_valid;
    logic                        s_dirty;

    logic [ N            - 1:0 ] s_hit_find;
    logic                        s_hit;
    logic [ $clog2 ( N ) - 1:0 ] s_way;
    logic [ $clog2 ( N ) - 1:0 ] s_plru;

    logic s_write_en;


    //---------------------------------------------------------
    // Memory blocks.
    //---------------------------------------------------------
    logic [ TAG_WIDTH - 1:0 ] tag_mem   [ SET_COUNT - 1:0 ][ N - 1:0 ]; // Tag memory.
    logic [ N         - 1:0 ] valid_mem [ SET_COUNT - 1:0 ];            // Valid memory.
    logic [ N         - 1:0 ] dirty_mem [ SET_COUNT - 1:0 ];            // Dirty memory.
    logic [ N         - 2:0 ] plru_mem  [ SET_COUNT - 1:0 ];            // Tree Pseudo-LRU memory.
    logic [ SET_WIDTH - 1:0 ] d_mem     [ SET_COUNT - 1:0 ][ N - 1:0 ]; // Instruction memory.



    //---------------------------------------------
    // Continious assignments.
    //---------------------------------------------
    assign s_tag_in         = i_addr [ TAG_MSB         : TAG_LSB         ];
    assign s_index_in       = i_addr [ INDEX_MSB       : INDEX_LSB       ];
    assign s_word_offset_in = i_addr [ WORD_OFFSET_MSB : WORD_OFFSET_LSB ];
    assign s_byte_offset_in = i_addr [ BYTE_OFFSET_MSB : 0               ];

    assign s_tag   = tag_mem   [ s_index_in ][ s_way  ];
    assign s_valid = valid_mem [ s_index_in ][ s_way  ];
    assign s_dirty = dirty_mem [ s_index_in ][ s_plru ];

    assign s_write_en = i_write_en & s_hit;


    //---------------------------------------------------
    // Check.
    //---------------------------------------------------

    // Check for hit and find the way/line that matches.
    always_comb begin
        s_hit_find [ 0 ] = valid_mem [ s_index_in ][ 0 ] & ( tag_mem [ s_index_in ][ 0 ] == s_tag_in );
        s_hit_find [ 1 ] = valid_mem [ s_index_in ][ 1 ] & ( tag_mem [ s_index_in ][ 1 ] == s_tag_in );
        s_hit_find [ 2 ] = valid_mem [ s_index_in ][ 2 ] & ( tag_mem [ s_index_in ][ 2 ] == s_tag_in );
        s_hit_find [ 3 ] = valid_mem [ s_index_in ][ 3 ] & ( tag_mem [ s_index_in ][ 3 ] == s_tag_in );

        casez ( s_hit_find )
            4'bzzz1: s_way = 2'b00;
            4'bzz10: s_way = 2'b01;
            4'bz100: s_way = 2'b10;
            4'b1000: s_way = 2'b11;
            default: s_way = s_plru;
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
        else if ( i_block_we ) valid_mem [ s_index_in ][ s_plru ] <= 1'b1;
    end

    // Dirty memory.
    always_ff @( posedge i_clk, posedge i_arst ) begin
        if ( i_arst ) begin
            for ( int i = 0; i < SET_COUNT; i++ ) begin
                dirty_mem [ i ] <= '0;
            end 
        end
        else if ( i_block_we ) dirty_mem [ s_index_in ][ s_plru ] <= 1'b0;
        else if ( s_write_en ) dirty_mem [ s_index_in ][ s_way  ] <= 1'b1;
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
        else if ( s_hit & i_mem_access ) begin
            plru_mem [ s_index_in ][ 0               ] <= ~ s_way [ 1 ];
            plru_mem [ s_index_in ][ 1 + s_way [ 1 ] ] <= ~ s_way [ 0 ];
        end
    end


    // Data memory.
    always_ff @( posedge i_clk, posedge i_arst ) begin
        // Here it first checks WE which is 1 and ignores block_we.
        if ( i_block_we ) begin
            d_mem   [ s_index_in ][ s_plru ] <= i_data_block;
            tag_mem [ s_index_in ][ s_plru ] <= s_tag_in; 
        end
        else if ( s_write_en ) begin
            case ( i_store_type )
                // SD Instruction.
                2'b11: begin
                    case ( s_word_offset_in [ 3:1 ] )
                        3'b000:  d_mem [ s_index_in ][ s_way ][ 63 :0   ] <= i_write_data; 
                        3'b001:  d_mem [ s_index_in ][ s_way ][ 127:64  ] <= i_write_data; 
                        3'b010:  d_mem [ s_index_in ][ s_way ][ 191:128 ] <= i_write_data; 
                        3'b011:  d_mem [ s_index_in ][ s_way ][ 255:192 ] <= i_write_data; 
                        3'b100:  d_mem [ s_index_in ][ s_way ][ 319:256 ] <= i_write_data; 
                        3'b101:  d_mem [ s_index_in ][ s_way ][ 383:320 ] <= i_write_data; 
                        3'b110:  d_mem [ s_index_in ][ s_way ][ 447:384 ] <= i_write_data; 
                        3'b111:  d_mem [ s_index_in ][ s_way ][ 511:448 ] <= i_write_data;
                        default: d_mem [ s_index_in ][ s_way ][ 63:0    ] <= '0;
                    endcase                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
                end

                // SW Instruction.
                2'b10: begin
                    case ( s_word_offset_in )
                        4'b0000: d_mem [ s_index_in ][ s_way ][ 31 :0   ] <= i_write_data [ 31:0 ]; 
                        4'b0001: d_mem [ s_index_in ][ s_way ][ 63 :32  ] <= i_write_data [ 31:0 ]; 
                        4'b0010: d_mem [ s_index_in ][ s_way ][ 95 :64  ] <= i_write_data [ 31:0 ]; 
                        4'b0011: d_mem [ s_index_in ][ s_way ][ 127:96  ] <= i_write_data [ 31:0 ]; 
                        4'b0100: d_mem [ s_index_in ][ s_way ][ 159:128 ] <= i_write_data [ 31:0 ]; 
                        4'b0101: d_mem [ s_index_in ][ s_way ][ 191:160 ] <= i_write_data [ 31:0 ]; 
                        4'b0110: d_mem [ s_index_in ][ s_way ][ 223:192 ] <= i_write_data [ 31:0 ]; 
                        4'b0111: d_mem [ s_index_in ][ s_way ][ 255:224 ] <= i_write_data [ 31:0 ]; 
                        4'b1000: d_mem [ s_index_in ][ s_way ][ 287:256 ] <= i_write_data [ 31:0 ]; 
                        4'b1001: d_mem [ s_index_in ][ s_way ][ 319:288 ] <= i_write_data [ 31:0 ]; 
                        4'b1010: d_mem [ s_index_in ][ s_way ][ 351:320 ] <= i_write_data [ 31:0 ]; 
                        4'b1011: d_mem [ s_index_in ][ s_way ][ 383:352 ] <= i_write_data [ 31:0 ]; 
                        4'b1100: d_mem [ s_index_in ][ s_way ][ 415:384 ] <= i_write_data [ 31:0 ]; 
                        4'b1101: d_mem [ s_index_in ][ s_way ][ 447:416 ] <= i_write_data [ 31:0 ];
                        4'b1110: d_mem [ s_index_in ][ s_way ][ 479:448 ] <= i_write_data [ 31:0 ];
                        4'b1111: d_mem [ s_index_in ][ s_way ][ 511:480 ] <= i_write_data [ 31:0 ];
                        default: d_mem [ s_index_in ][ s_way ][ 31:0    ] <= '0;
                    endcase    
                end 

                // SH Instruction.
                2'b01: begin
                    case ( { s_word_offset_in, s_byte_offset_in [ 1 ] } )
                        5'b00000: d_mem [ s_index_in ][ s_way ][ 15 :0   ] <= i_write_data [ 15:0 ]; 
                        5'b00001: d_mem [ s_index_in ][ s_way ][ 31 :16  ] <= i_write_data [ 15:0 ]; 
                        5'b00010: d_mem [ s_index_in ][ s_way ][ 47 :32  ] <= i_write_data [ 15:0 ]; 
                        5'b00011: d_mem [ s_index_in ][ s_way ][ 63 :48  ] <= i_write_data [ 15:0 ]; 
                        5'b00100: d_mem [ s_index_in ][ s_way ][ 79 :64  ] <= i_write_data [ 15:0 ]; 
                        5'b00101: d_mem [ s_index_in ][ s_way ][ 95 :80  ] <= i_write_data [ 15:0 ]; 
                        5'b00110: d_mem [ s_index_in ][ s_way ][ 111:96  ] <= i_write_data [ 15:0 ]; 
                        5'b00111: d_mem [ s_index_in ][ s_way ][ 127:112 ] <= i_write_data [ 15:0 ]; 
                        5'b01000: d_mem [ s_index_in ][ s_way ][ 143:128 ] <= i_write_data [ 15:0 ]; 
                        5'b01001: d_mem [ s_index_in ][ s_way ][ 159:144 ] <= i_write_data [ 15:0 ]; 
                        5'b01010: d_mem [ s_index_in ][ s_way ][ 175:160 ] <= i_write_data [ 15:0 ]; 
                        5'b01011: d_mem [ s_index_in ][ s_way ][ 191:176 ] <= i_write_data [ 15:0 ]; 
                        5'b01100: d_mem [ s_index_in ][ s_way ][ 207:192 ] <= i_write_data [ 15:0 ]; 
                        5'b01101: d_mem [ s_index_in ][ s_way ][ 223:208 ] <= i_write_data [ 15:0 ]; 
                        5'b01110: d_mem [ s_index_in ][ s_way ][ 239:224 ] <= i_write_data [ 15:0 ];
                        5'b01111: d_mem [ s_index_in ][ s_way ][ 255:240 ] <= i_write_data [ 15:0 ]; 
                        5'b10000: d_mem [ s_index_in ][ s_way ][ 271:256 ] <= i_write_data [ 15:0 ]; 
                        5'b10001: d_mem [ s_index_in ][ s_way ][ 287:272 ] <= i_write_data [ 15:0 ]; 
                        5'b10010: d_mem [ s_index_in ][ s_way ][ 303:288 ] <= i_write_data [ 15:0 ]; 
                        5'b10011: d_mem [ s_index_in ][ s_way ][ 319:304 ] <= i_write_data [ 15:0 ]; 
                        5'b10100: d_mem [ s_index_in ][ s_way ][ 335:320 ] <= i_write_data [ 15:0 ]; 
                        5'b10101: d_mem [ s_index_in ][ s_way ][ 351:336 ] <= i_write_data [ 15:0 ]; 
                        5'b10110: d_mem [ s_index_in ][ s_way ][ 367:352 ] <= i_write_data [ 15:0 ]; 
                        5'b10111: d_mem [ s_index_in ][ s_way ][ 383:368 ] <= i_write_data [ 15:0 ]; 
                        5'b11000: d_mem [ s_index_in ][ s_way ][ 399:384 ] <= i_write_data [ 15:0 ]; 
                        5'b11001: d_mem [ s_index_in ][ s_way ][ 415:400 ] <= i_write_data [ 15:0 ]; 
                        5'b11010: d_mem [ s_index_in ][ s_way ][ 431:416 ] <= i_write_data [ 15:0 ];
                        5'b11011: d_mem [ s_index_in ][ s_way ][ 447:432 ] <= i_write_data [ 15:0 ];
                        5'b11100: d_mem [ s_index_in ][ s_way ][ 463:448 ] <= i_write_data [ 15:0 ];
                        5'b11101: d_mem [ s_index_in ][ s_way ][ 479:464 ] <= i_write_data [ 15:0 ];
                        5'b11110: d_mem [ s_index_in ][ s_way ][ 495:480 ] <= i_write_data [ 15:0 ];
                        5'b11111: d_mem [ s_index_in ][ s_way ][ 511:496 ] <= i_write_data [ 15:0 ];
                        default:  d_mem [ s_index_in ][ s_way ][ 31:0    ] <= '0;
                    endcase
                end

                // SB Instruction.
                2'b00: begin
                    case ( { s_word_offset_in, s_byte_offset_in } )
                        6'b000000: d_mem [ s_index_in ][ s_way ][ 7  :0   ] <= i_write_data [ 7:0 ]; 
                        6'b000001: d_mem [ s_index_in ][ s_way ][ 15 :8   ] <= i_write_data [ 7:0 ]; 
                        6'b000010: d_mem [ s_index_in ][ s_way ][ 23 :16  ] <= i_write_data [ 7:0 ]; 
                        6'b000011: d_mem [ s_index_in ][ s_way ][ 31 :24  ] <= i_write_data [ 7:0 ];

                        6'b000100: d_mem [ s_index_in ][ s_way ][ 39 :32  ] <= i_write_data [ 7:0 ]; 
                        6'b000101: d_mem [ s_index_in ][ s_way ][ 47 :40  ] <= i_write_data [ 7:0 ]; 
                        6'b000110: d_mem [ s_index_in ][ s_way ][ 55 :48  ] <= i_write_data [ 7:0 ]; 
                        6'b000111: d_mem [ s_index_in ][ s_way ][ 63 :56  ] <= i_write_data [ 7:0 ]; 

                        6'b001000: d_mem [ s_index_in ][ s_way ][ 71 :64  ] <= i_write_data [ 7:0 ]; 
                        6'b001001: d_mem [ s_index_in ][ s_way ][ 79 :72  ] <= i_write_data [ 7:0 ]; 
                        6'b001010: d_mem [ s_index_in ][ s_way ][ 87 :80  ] <= i_write_data [ 7:0 ]; 
                        6'b001011: d_mem [ s_index_in ][ s_way ][ 95 :88  ] <= i_write_data [ 7:0 ]; 

                        6'b001100: d_mem [ s_index_in ][ s_way ][ 103:96  ] <= i_write_data [ 7:0 ]; 
                        6'b001101: d_mem [ s_index_in ][ s_way ][ 111:104 ] <= i_write_data [ 7:0 ]; 
                        6'b001110: d_mem [ s_index_in ][ s_way ][ 119:112 ] <= i_write_data [ 7:0 ]; 
                        6'b001111: d_mem [ s_index_in ][ s_way ][ 127:120 ] <= i_write_data [ 7:0 ]; 

                        6'b010000: d_mem [ s_index_in ][ s_way ][ 135:128 ] <= i_write_data [ 7:0 ]; 
                        6'b010001: d_mem [ s_index_in ][ s_way ][ 143:136 ] <= i_write_data [ 7:0 ]; 
                        6'b010010: d_mem [ s_index_in ][ s_way ][ 151:144 ] <= i_write_data [ 7:0 ]; 
                        6'b010011: d_mem [ s_index_in ][ s_way ][ 159:152 ] <= i_write_data [ 7:0 ];

                        6'b010100: d_mem [ s_index_in ][ s_way ][ 167:160 ] <= i_write_data [ 7:0 ]; 
                        6'b010101: d_mem [ s_index_in ][ s_way ][ 175:168 ] <= i_write_data [ 7:0 ]; 
                        6'b010110: d_mem [ s_index_in ][ s_way ][ 183:176 ] <= i_write_data [ 7:0 ]; 
                        6'b010111: d_mem [ s_index_in ][ s_way ][ 191:184 ] <= i_write_data [ 7:0 ];

                        6'b011000: d_mem [ s_index_in ][ s_way ][ 199:192 ] <= i_write_data [ 7:0 ]; 
                        6'b011001: d_mem [ s_index_in ][ s_way ][ 207:200 ] <= i_write_data [ 7:0 ]; 
                        6'b011010: d_mem [ s_index_in ][ s_way ][ 215:208 ] <= i_write_data [ 7:0 ]; 
                        6'b011011: d_mem [ s_index_in ][ s_way ][ 223:216 ] <= i_write_data [ 7:0 ];

                        6'b011100: d_mem [ s_index_in ][ s_way ][ 231:224 ] <= i_write_data [ 7:0 ];
                        6'b011101: d_mem [ s_index_in ][ s_way ][ 239:232 ] <= i_write_data [ 7:0 ]; 
                        6'b011110: d_mem [ s_index_in ][ s_way ][ 247:240 ] <= i_write_data [ 7:0 ]; 
                        6'b011111: d_mem [ s_index_in ][ s_way ][ 255:248 ] <= i_write_data [ 7:0 ];

                        6'b100000: d_mem [ s_index_in ][ s_way ][ 263:256 ] <= i_write_data [ 7:0 ]; 
                        6'b100001: d_mem [ s_index_in ][ s_way ][ 271:264 ] <= i_write_data [ 7:0 ]; 
                        6'b100010: d_mem [ s_index_in ][ s_way ][ 279:272 ] <= i_write_data [ 7:0 ]; 
                        6'b100011: d_mem [ s_index_in ][ s_way ][ 287:280 ] <= i_write_data [ 7:0 ];

                        6'b100100: d_mem [ s_index_in ][ s_way ][ 295:288 ] <= i_write_data [ 7:0 ];  
                        6'b100101: d_mem [ s_index_in ][ s_way ][ 303:296 ] <= i_write_data [ 7:0 ]; 
                        6'b100110: d_mem [ s_index_in ][ s_way ][ 311:304 ] <= i_write_data [ 7:0 ]; 
                        6'b100111: d_mem [ s_index_in ][ s_way ][ 319:312 ] <= i_write_data [ 7:0 ]; 

                        6'b101000: d_mem [ s_index_in ][ s_way ][ 327:320 ] <= i_write_data [ 7:0 ]; 
                        6'b101001: d_mem [ s_index_in ][ s_way ][ 335:328 ] <= i_write_data [ 7:0 ]; 
                        6'b101010: d_mem [ s_index_in ][ s_way ][ 343:336 ] <= i_write_data [ 7:0 ]; 
                        6'b101011: d_mem [ s_index_in ][ s_way ][ 351:344 ] <= i_write_data [ 7:0 ]; 

                        6'b101100: d_mem [ s_index_in ][ s_way ][ 359:352 ] <= i_write_data [ 7:0 ]; 
                        6'b101101: d_mem [ s_index_in ][ s_way ][ 367:360 ] <= i_write_data [ 7:0 ]; 
                        6'b101110: d_mem [ s_index_in ][ s_way ][ 375:368 ] <= i_write_data [ 7:0 ]; 
                        6'b101111: d_mem [ s_index_in ][ s_way ][ 383:376 ] <= i_write_data [ 7:0 ];

                        6'b110000: d_mem [ s_index_in ][ s_way ][ 391:384 ] <= i_write_data [ 7:0 ];
                        6'b110001: d_mem [ s_index_in ][ s_way ][ 399:392 ] <= i_write_data [ 7:0 ];
                        6'b110010: d_mem [ s_index_in ][ s_way ][ 407:400 ] <= i_write_data [ 7:0 ]; 
                        6'b110011: d_mem [ s_index_in ][ s_way ][ 415:408 ] <= i_write_data [ 7:0 ];

                        6'b110100: d_mem [ s_index_in ][ s_way ][ 423:416 ] <= i_write_data [ 7:0 ]; 
                        6'b110101: d_mem [ s_index_in ][ s_way ][ 431:424 ] <= i_write_data [ 7:0 ];
                        6'b110110: d_mem [ s_index_in ][ s_way ][ 439:432 ] <= i_write_data [ 7:0 ]; 
                        6'b110111: d_mem [ s_index_in ][ s_way ][ 447:440 ] <= i_write_data [ 7:0 ];

                        6'b111000: d_mem [ s_index_in ][ s_way ][ 455:448 ] <= i_write_data [ 7:0 ]; 
                        6'b111001: d_mem [ s_index_in ][ s_way ][ 463:456 ] <= i_write_data [ 7:0 ]; 
                        6'b111010: d_mem [ s_index_in ][ s_way ][ 471:464 ] <= i_write_data [ 7:0 ]; 
                        6'b111011: d_mem [ s_index_in ][ s_way ][ 479:472 ] <= i_write_data [ 7:0 ]; 

                        6'b111100: d_mem [ s_index_in ][ s_way ][ 487:480 ] <= i_write_data [ 7:0 ]; 
                        6'b111101: d_mem [ s_index_in ][ s_way ][ 495:488 ] <= i_write_data [ 7:0 ]; 
                        6'b111110: d_mem [ s_index_in ][ s_way ][ 503:496 ] <= i_write_data [ 7:0 ]; 
                        6'b111111: d_mem [ s_index_in ][ s_way ][ 511:504 ] <= i_write_data [ 7:0 ]; 
                    endcase
                end
            endcase   
        end
    end


    //-------------------------------------------
    // Memory read logic.
    //-------------------------------------------
    always_comb begin
        case ( s_word_offset_in [ 3:1 ] )
            3'b000 : o_read_data = d_mem [ s_index_in ][ s_way ][ 63 :0   ]; 
            3'b001 : o_read_data = d_mem [ s_index_in ][ s_way ][ 127:64  ]; 
            3'b010 : o_read_data = d_mem [ s_index_in ][ s_way ][ 191:128 ]; 
            3'b011 : o_read_data = d_mem [ s_index_in ][ s_way ][ 255:192 ]; 
            3'b100 : o_read_data = d_mem [ s_index_in ][ s_way ][ 319:256 ]; 
            3'b101 : o_read_data = d_mem [ s_index_in ][ s_way ][ 383:320 ]; 
            3'b110 : o_read_data = d_mem [ s_index_in ][ s_way ][ 447:384 ]; 
            3'b111 : o_read_data = d_mem [ s_index_in ][ s_way ][ 511:448 ];
            default: o_read_data = '0;
        endcase
    end


    //--------------------------------------
    // Output continious assignments.
    //--------------------------------------
    assign o_hit        = s_hit;
    assign o_dirty      = s_dirty; 
    assign o_addr_wb    = { tag_mem [ s_index_in ][ s_plru ], s_index_in, 6'b0 };
    assign o_data_block = d_mem [ s_index_in ][ s_plru ];

endmodule