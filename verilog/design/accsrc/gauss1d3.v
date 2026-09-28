`timescale 1ns / 1ps
// Gaussian filter arithmetic.

module gauss1d3 #(
    parameter DATA_WIDTH = 14
)(
    input wire clk,
    input wire rst_n,
    input wire in_window_valid,
    input wire [DATA_WIDTH*3-1:0] in_window_value,
    output reg [2+DATA_WIDTH-1:0] out_event_value,
    output reg out_event_valid
    );
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        out_event_value <= 0;
        out_event_valid <= 0;
    end
    else begin
        if(in_window_valid == 1) begin
            out_event_value <= in_window_value[DATA_WIDTH*0+DATA_WIDTH-1:DATA_WIDTH*0] + 2*in_window_value[DATA_WIDTH*1+DATA_WIDTH-1:DATA_WIDTH*1] + 1*in_window_value[DATA_WIDTH*2+DATA_WIDTH-1:DATA_WIDTH*2];
            out_event_valid <= 1;
        end
        else begin
            out_event_value <= 0;
            out_event_valid <= 0;
        end
    end
end
endmodule
