`timescale 1ns/1ps

module ahb_slave(

    input         HCLK,
    input         HRESETn,

    input         HSELx,
    input         HREADY_IN,
    input         HWRITE,

    input  [1:0]  HTRANS,
    input  [2:0]  HSIZE,
    input  [2:0]  HBURST,

    input  [31:0] HADDR,
    input  [31:0] HWDATA,

    output reg        HREADY_OUT,
    output reg [1:0]  HRESP,
    output reg [31:0] HRDATA

);

//====================================================
// Memory Declaration (256 x 32-bit)
//====================================================

reg [31:0] memory [0:255];

//====================================================
// Wait-State Counter
//====================================================

reg [1:0] wait_count;

//====================================================
// AHB Slave
//====================================================

always @(posedge HCLK or negedge HRESETn)
begin

    if(!HRESETn)
    begin

        HREADY_OUT <= 1'b1;
        HRESP      <= 2'b00;       // OKAY
        HRDATA     <= 32'd0;

        wait_count <= 2'd0;

    end

    else
    begin

        //--------------------------------------------------
        // Default Outputs
        //--------------------------------------------------

        HREADY_OUT <= 1'b1;
        HRESP      <= 2'b00;

        //--------------------------------------------------
        // Valid Transfer?
        //--------------------------------------------------

        if(HSELx && HREADY_IN && HTRANS[1])
        begin

            //--------------------------------------------------
            // Invalid Address
            //--------------------------------------------------

            if(HADDR > 32'h000000FF)
            begin

                HRESP <= 2'b01;        // ERROR

            end

            //--------------------------------------------------
            // Valid Address
            //--------------------------------------------------

            else
            begin

                //--------------------------------------------------
                // Generate Wait States for Address 0x20
                //--------------------------------------------------

                if(HADDR == 32'h20)
                begin

                    if(wait_count < 2)
                    begin

                        HREADY_OUT <= 1'b0;
                        wait_count <= wait_count + 1;

                    end

                    else
                    begin

                        HREADY_OUT <= 1'b1;
                        wait_count <= 0;

                        if(HWRITE)
                            memory[HADDR] <= HWDATA;
                        else
                            HRDATA <= memory[HADDR];

                    end

                end

                //--------------------------------------------------
                // Normal Read / Write
                //--------------------------------------------------

                else
                begin

                    wait_count <= 0;

                    if(HWRITE)
                        memory[HADDR] <= HWDATA;
                    else
                        HRDATA <= memory[HADDR];

                end

            end

        end

    end

end

endmodule
