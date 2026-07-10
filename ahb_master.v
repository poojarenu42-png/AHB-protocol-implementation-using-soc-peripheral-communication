`timescale 1ns/1ps

module ahb_master(

    input         HCLK,
    input         HRESETn,

    // Slave Interface
    input         HREADY_OUT,
    input  [1:0]  HRESP,
    input  [31:0] HRDATA,

    // Master Outputs
    output reg        HSELx,
    output reg        HREADY_IN,
    output reg        HWRITE,
    output reg [1:0]  HTRANS,
    output reg [2:0]  HSIZE,
    output reg [2:0]  HBURST,
    output reg [31:0] HADDR,
    output reg [31:0] HWDATA

);

//======================================================
// State Encoding
//======================================================

localparam IDLE          = 3'd0;
localparam WRITE         = 3'd1;
localparam READ          = 3'd2;
localparam WAIT_STATE    = 3'd3;
localparam ERROR_ADDR    = 3'd4;
localparam ERROR_HTRANS  = 3'd5;
localparam ERROR_HSIZE   = 3'd6;

//======================================================
// State Registers
//======================================================

reg [2:0] state;
reg [2:0] next_state;

//======================================================
// State Register
//======================================================

always @(posedge HCLK or negedge HRESETn)
begin
    if(!HRESETn)
        state <= IDLE;
    else
        state <= next_state;
end

//======================================================
// Next State Logic
//======================================================

always @(*)
begin

    case(state)

        IDLE :
            next_state = WRITE;

        WRITE :
            next_state = READ;

        READ :
            next_state = WAIT_STATE;

        WAIT_STATE :
        begin
            if(HREADY_OUT)
                next_state = ERROR_ADDR;
            else
                next_state = WAIT_STATE;
        end

        ERROR_ADDR :
            next_state = ERROR_HTRANS;

        ERROR_HTRANS :
            next_state = ERROR_HSIZE;

        ERROR_HSIZE :
            next_state = ERROR_HSIZE;

        default :
            next_state = IDLE;

    endcase

end

//======================================================
// Output Logic
//======================================================

always @(posedge HCLK or negedge HRESETn)
begin

    if(!HRESETn)
    begin

        HSELx      <= 1'b1;
        HREADY_IN  <= 1'b1;

        HWRITE     <= 1'b0;

        HTRANS     <= 2'b00;      // IDLE
        HSIZE      <= 3'b010;     // 32-bit
        HBURST     <= 3'b000;     // SINGLE

        HADDR      <= 32'h00000000;
        HWDATA     <= 32'h00000000;

    end

    else
    begin

        case(state)

        //------------------------------------------------
        // IDLE
        //------------------------------------------------

        IDLE :
        begin

            HWRITE <= 0;
            HTRANS <= 2'b00;

        end

        //------------------------------------------------
        // WRITE
        //------------------------------------------------

        WRITE :
        begin

            HSELx   <= 1;
            HWRITE  <= 1;
            HTRANS  <= 2'b10;          // NONSEQ
            HSIZE   <= 3'b010;
            HBURST  <= 3'b000;

            HADDR   <= 32'h00000002;
            HWDATA  <= 32'h000000AA;

        end

        //------------------------------------------------
        // READ
        //------------------------------------------------

        READ :
        begin

            HWRITE <= 0;
            HTRANS <= 2'b10;

            HADDR  <= 32'h00000002;

        end

        //------------------------------------------------
        // WAIT STATE
        //------------------------------------------------

        WAIT_STATE :
        begin

            HWRITE <= 1;
            HTRANS <= 2'b10;

            HADDR  <= 32'h00000020;
            HWDATA <= 32'h0000BBBB;

        end

        //------------------------------------------------
        // INVALID ADDRESS
        //------------------------------------------------

        ERROR_ADDR :
        begin

            HWRITE <= 1;
            HTRANS <= 2'b10;

            HADDR  <= 32'h000001FF;
            HWDATA <= 32'h0000DEAD;

        end

        //------------------------------------------------
        // INVALID HTRANS
        //------------------------------------------------

        ERROR_HTRANS :
        begin

            HWRITE <= 1;

            HTRANS <= 2'b01;      // BUSY

            HADDR  <= 32'h00000005;

        end

        //------------------------------------------------
        // INVALID HSIZE
        //------------------------------------------------

        ERROR_HSIZE :
        begin

            HWRITE <= 1;

            HTRANS <= 2'b10;

            HSIZE  <= 3'b111;

            HADDR  <= 32'h00000008;

        end

        endcase

    end

end

endmodule
