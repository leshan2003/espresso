`timescale 1ns / 1ps
// Experimental multiwrite FIFO; not a validated general-purpose FIFO.

module testfifo(
    input clk,
    input rst_n,
    input [15:0] din,
    input wr_en,
    input rd_en,
    output reg [15:0] dout
    );

reg [15:0] mem1 [0:127];
// reg [15:0] mem2 [0:31];
// reg [15:0] mem3 [0:31];
reg [7:0] wptr;
reg [7:0] rptr;
// reg [15:0] currentvalue;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wptr <= 0;
        rptr <= 0;
    end
    else begin
        if(wr_en) begin
            mem1[wptr] <= din - 4; mem1[wptr+1] <= din - 3; mem1[wptr+2] <= din - 2; mem1[wptr+3] <= din - 1; mem1[wptr+4] <= din;
            wptr <= wptr + 4;
            // if ((din - currentvalue) == 1) begin
            //     mem1[wptr] <= din; mem2[wptr] <= din - 32; mem3[wptr] <= din - 64;
            //     currentvalue <= din;
            //     wptr <= wptr + 1;
            // end
            // else if ((din - currentvalue) == 2) begin
            //     mem1[wptr] <= din - 1; mem2[wptr] <= din - 32 - 1; mem3[wptr] <= din - 64 - 1;
            //     mem1[wptr + 1] <= din; mem2[wptr + 1] <= din - 32; mem3[wptr + 1] <= din - 64;
            //     currentvalue <= din;
            //     wptr <= wptr + 2;
            // end
            // else if ((din - currentvalue) == 3) begin
            //     mem1[wptr] <= din - 2; mem2[wptr] <= din - 32 - 2; mem3[wptr] <= din - 64 - 2;
            //     mem1[wptr + 1] <= din - 1; mem2[wptr + 1] <= din - 32 - 1; mem3[wptr + 1] <= din - 64 - 1;
            //     mem1[wptr + 2] <= din; mem2[wptr + 2] <= din - 32; mem3[wptr + 2] <= din - 64;
            //     currentvalue <= din;
            //     wptr <= wptr + 3;
            // end
            // else if ((din - currentvalue) == 4) begin
            //     mem1[wptr] <= din - 3; mem2[wptr] <= din - 32 - 3; mem3[wptr] <= din - 64 - 3;
            //     mem1[wptr + 1] <= din - 2; mem2[wptr + 1] <= din - 32 - 2; mem3[wptr + 1] <= din - 64 - 2;
            //     mem1[wptr + 2] <= din - 1; mem2[wptr + 2] <= din - 32 - 1; mem3[wptr + 2] <= din - 64 - 1;
            //     mem1[wptr + 3] <= din; mem2[wptr + 3] <= din - 32; mem3[wptr + 3] <= din - 64;
            //     currentvalue <= din;
            //     wptr <= wptr + 4;
            // end
            // else if ((din - currentvalue) > 4) begin
            //     mem1[wptr] <= din - 4; mem2[wptr] <= din - 32 - 4; mem3[wptr] <= din - 64 - 4;
            //     mem1[wptr + 1] <= din - 3; mem2[wptr + 1] <= din - 32 - 3; mem3[wptr + 1] <= din - 64 - 3;
            //     mem1[wptr + 2] <= din - 2; mem2[wptr + 2] <= din - 32 - 2; mem3[wptr + 2] <= din - 64 - 2;
            //     mem1[wptr + 3] <= din - 1; mem2[wptr + 3] <= din - 32 - 1; mem3[wptr + 3] <= din - 64 - 1;
            //     mem1[wptr + 4] <= din; mem2[wptr + 4] <= din - 32; mem3[wptr + 4] <= din - 64;
            //     currentvalue <= din;
            //     wptr <= wptr + 5;
            // end
        end
        if(rd_en) begin
            rptr <= rptr + 1;
            // if (mem1[rptr] < mem2[rptr] && mem1[rptr] < mem3[rptr]) begin
            //     dout <= mem1[rptr];
            // end
            // else if (mem2[rptr] < mem3[rptr]) begin
            //     dout <= mem2[rptr];
            // end
            // else begin
            //     dout <= mem3[rptr];
            // end
            dout <= mem1[rptr];
        end
    end
end
endmodule
