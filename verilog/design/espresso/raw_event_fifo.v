`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/03/03 16:32:54
// Design Name:
// Module Name: raw_event_fifo
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module raw_event_fifo#(
    parameter DATA_WIDTH = 4,
    parameter FIFO_DEPTH = 65536
)(
    input wire clk,
    input wire rst_n,
    input wire in_event_valid,
    input wire [DATA_WIDTH-1:0] in_event_value,
    input wire [15:0] in_event_addr,
    input wire event_req,
    output wire fifo_not_full,
    output reg out_event_valid,
    output reg [DATA_WIDTH-1:0] out_event_value,
    output reg [15:0] out_event_addr
    );
reg [DATA_WIDTH-1:0] event_value_fifo [0:FIFO_DEPTH-1];
reg [15:0] event_addr_fifo [0:FIFO_DEPTH-1];
reg [15:0] read_ptr, write_ptr;
reg waitcnt;

wire fifo_empty = (read_ptr == write_ptr);
wire fifo_full = (write_ptr + 1 == read_ptr);
assign fifo_not_full = ~fifo_full;
integer k;
initial begin
    read_ptr <= 0;
    write_ptr <= 0;
    out_event_valid <= 0;
    out_event_value <= 0;
    out_event_addr <= 0;
    waitcnt <= 0;
    for (k = 0; k < FIFO_DEPTH; k = k + 1) begin
        event_value_fifo[k] <= 0;
        event_addr_fifo[k] <= 0;
    end
end

always@ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        read_ptr <= 0;
        write_ptr <= 0;
        out_event_valid <= 0;
        out_event_value <= 0;
        out_event_addr <= 0;
        waitcnt <= 0;
        for (k = 0; k < FIFO_DEPTH; k = k + 1) begin
            event_value_fifo[k] <= 0;
            event_addr_fifo[k] <= 0;
        end
    end
    else begin
        if (event_req && ~fifo_empty && ~waitcnt) begin
            out_event_valid <= 1;
            out_event_value <= event_value_fifo[read_ptr];
            out_event_addr <= event_addr_fifo[read_ptr];
            read_ptr <= read_ptr + 1;
            waitcnt <= 1;
        end
        else if(waitcnt) begin
            out_event_valid <= 0;
            out_event_value <= 0;
            out_event_addr <= 0;
            waitcnt <= 0;
        end
        if (in_event_valid && ~fifo_full) begin
            event_value_fifo[write_ptr] <= in_event_value;
            event_addr_fifo[write_ptr] <= in_event_addr;
            write_ptr <= write_ptr + 1;
        end
    end
end

endmodule
