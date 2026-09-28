`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/09/24 14:00:10
// Design Name:
// Module Name: ShiftHashTable7
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


module ShiftHashTable7 #(
    parameter DATA_WIDTH = 4,
    parameter MEM_DEPTH = 32,
    parameter HALF_WINDOW_SIZE = 3,
    parameter WINDOW_SIZE = 2*HALF_WINDOW_SIZE+1,
    parameter HALF_ADDR_WIDTH = 5
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] in_event_value,
    input wire [2*HALF_ADDR_WIDTH-1:0] in_event_addr,
    input wire in_event_valid,
    input wire [2*HALF_ADDR_WIDTH-1:0] out_window_addr,
    input wire read_req,
    output reg write_done,
    output wire [DATA_WIDTH*WINDOW_SIZE*WINDOW_SIZE-1:0] out_window_value,
    output reg out_window_valid
    );

reg [DATA_WIDTH-1:0] out_window_value_reg [0:WINDOW_SIZE-1][0:WINDOW_SIZE-1];
assign out_window_value = {out_window_value_reg[0][0], out_window_value_reg[0][1], out_window_value_reg[0][2], out_window_value_reg[0][3], out_window_value_reg[0][4], out_window_value_reg[0][5], out_window_value_reg[0][6], out_window_value_reg[1][0], out_window_value_reg[1][1], out_window_value_reg[1][2], out_window_value_reg[1][3], out_window_value_reg[1][4], out_window_value_reg[1][5], out_window_value_reg[1][6], out_window_value_reg[2][0], out_window_value_reg[2][1], out_window_value_reg[2][2], out_window_value_reg[2][3], out_window_value_reg[2][4], out_window_value_reg[2][5], out_window_value_reg[2][6], out_window_value_reg[3][0], out_window_value_reg[3][1], out_window_value_reg[3][2], out_window_value_reg[3][3], out_window_value_reg[3][4], out_window_value_reg[3][5], out_window_value_reg[3][6], out_window_value_reg[4][0], out_window_value_reg[4][1], out_window_value_reg[4][2], out_window_value_reg[4][3], out_window_value_reg[4][4], out_window_value_reg[4][5], out_window_value_reg[4][6], out_window_value_reg[5][0], out_window_value_reg[5][1], out_window_value_reg[5][2], out_window_value_reg[5][3], out_window_value_reg[5][4], out_window_value_reg[5][5], out_window_value_reg[5][6], out_window_value_reg[6][0], out_window_value_reg[6][1], out_window_value_reg[6][2], out_window_value_reg[6][3], out_window_value_reg[6][4], out_window_value_reg[6][5], out_window_value_reg[6][6]};

reg [DATA_WIDTH-1:0] datamem [0:MEM_DEPTH-1][0:HALF_WINDOW_SIZE*2];
reg [2*HALF_ADDR_WIDTH-1:0] out_window_addr_0;
reg [2*HALF_ADDR_WIDTH-1:0] in_event_addr_0;
reg [DATA_WIDTH-1:0] in_event_value_0;
reg in_event_valid_0;
integer k,j;

wire [HALF_ADDR_WIDTH-1:0] in_addr_row = in_event_addr_0[2*HALF_ADDR_WIDTH-1:HALF_ADDR_WIDTH];
wire [HALF_ADDR_WIDTH-1:0] in_addr_col = in_event_addr_0[HALF_ADDR_WIDTH-1:0];
wire [HALF_ADDR_WIDTH-1:0] out_addr_row = out_window_addr[2*HALF_ADDR_WIDTH-1:HALF_ADDR_WIDTH];
wire [HALF_ADDR_WIDTH-1:0] out_addr_col = out_window_addr[HALF_ADDR_WIDTH-1:0];
wire [HALF_ADDR_WIDTH-1:0] in_row_diff = in_addr_row - current_addr_row;
wire signed [HALF_ADDR_WIDTH-1:0] out_row_diff = out_addr_row - current_addr_row;
reg [HALF_ADDR_WIDTH-1:0] current_addr_row;

initial begin
    write_done <= 0;
    out_window_valid <= 0;
    for (k=0; k<WINDOW_SIZE; k=k+1) begin
        for (j=0; j<WINDOW_SIZE; j=j+1) begin
            out_window_value_reg[k][j] <= 0;
        end
    end
    out_window_addr_0 <= 0;
    in_event_addr_0 <= 0;
    in_event_value_0 <= 0;
    in_event_valid_0 <= 0;
    current_addr_row <= 0;
    for (k=0; k<MEM_DEPTH; k=k+1) begin
        for (j=0; j<=HALF_WINDOW_SIZE*2; j=j+1) begin
            datamem[k][j] <= 0;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        write_done <= 0;
        out_window_valid <= 0;
        for (k=0; k<WINDOW_SIZE; k=k+1) begin
            for (j=0; j<WINDOW_SIZE; j=j+1) begin
                out_window_value_reg[k][j] <= 0;
            end
        end
        out_window_addr_0 <= 0;
        in_event_addr_0 <= 0;
        in_event_value_0 <= 0;
        in_event_valid_0 <= 0;
        current_addr_row <= 0;
        for (k=0; k<MEM_DEPTH; k=k+1) begin
            for (j=0; j<=HALF_WINDOW_SIZE*2; j=j+1) begin
                datamem[k][j] <= 0;
            end
        end
    end
    else begin
        if (in_event_valid) begin
            in_event_addr_0 <= in_event_addr;
            in_event_value_0 <= in_event_value;
            in_event_valid_0 <= 1;
        end
        if (in_event_valid_0) begin
            if ((in_row_diff)>=WINDOW_SIZE) begin
                for (k=0; k<MEM_DEPTH; k=k+1) begin
                    for (j=0; j<HALF_WINDOW_SIZE*2; j=j+1) begin
                        datamem[k][j] <= datamem[k][j+1];
                    end
                    datamem[k][HALF_WINDOW_SIZE*2] <= 0;
                end
                current_addr_row <= current_addr_row + 1;
                write_done <= 0;
            end
            else begin
                datamem[in_addr_col][in_row_diff] <= in_event_value_0;
                in_event_valid_0 <= 0;
                write_done <= 1;
            end
        end
        else begin
            write_done <= 0;
        end
        if (read_req) begin
            case(out_row_diff)
                9: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][6];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                8: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][5];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][5];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[1][3] <= datamem[out_addr_col-0][6];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                7: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][4];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[1][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][5];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[2][3] <= datamem[out_addr_col+0][6];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                6: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][3];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[1][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][5];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][6];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                5: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][2];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[1][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][5];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][6];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                4: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][1];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[1][3] <= datamem[out_addr_col+0][2];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][5];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][6];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][6];
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
                3: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[0][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[0][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[0][3] <= datamem[out_addr_col+0][0];
                    out_window_value_reg[0][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[0][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[0][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[1][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][2];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][6];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][6];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][6];
                    out_window_value_reg[6][3] <= datamem[out_addr_col+0][6];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][6];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][6];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][6];
                end
                2: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[1][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[1][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[1][3] <= datamem[out_addr_col+0][0];
                    out_window_value_reg[1][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[1][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[1][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][2];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][4];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][5];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][5];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][5];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][5];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][5];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][5];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][5];
                end
                1: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[2][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[2][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[2][3] <= datamem[out_addr_col-0][0];
                    out_window_value_reg[2][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[2][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[2][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][2];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][3];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][4];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][4];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][4];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][4];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][4];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][4];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][4];
                end
                0: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[3][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[3][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[3][3] <= datamem[out_addr_col-0][0];
                    out_window_value_reg[3][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[3][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[3][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][2];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][2];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][3];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][3];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][3];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][3];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][3];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][3];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][3];
                end
                -1: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[4][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[4][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[4][3] <= datamem[out_addr_col-0][0];
                    out_window_value_reg[4][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[4][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[4][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][1];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][2];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][2];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][2];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][2];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][2];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][2];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][2];
                end
                -2: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[5][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[5][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[5][3] <= datamem[out_addr_col-0][0];
                    out_window_value_reg[5][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[5][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[5][6] <= datamem[out_addr_col+3][0];
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][1];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][1];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][1];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][1];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][1];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][1];
                end
                -3: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= datamem[out_addr_col-3][0];
                    out_window_value_reg[6][1] <= datamem[out_addr_col-2][0];
                    out_window_value_reg[6][2] <= datamem[out_addr_col-1][0];
                    out_window_value_reg[6][3] <= datamem[out_addr_col-0][0];
                    out_window_value_reg[6][4] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[6][5] <= datamem[out_addr_col+2][0];
                    out_window_value_reg[6][6] <= datamem[out_addr_col+3][0];
                end
                default: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[0][2] <= 0;
                    out_window_value_reg[0][3] <= 0;
                    out_window_value_reg[0][4] <= 0;
                    out_window_value_reg[0][5] <= 0;
                    out_window_value_reg[0][6] <= 0;
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                    out_window_value_reg[1][2] <= 0;
                    out_window_value_reg[1][3] <= 0;
                    out_window_value_reg[1][4] <= 0;
                    out_window_value_reg[1][5] <= 0;
                    out_window_value_reg[1][6] <= 0;
                    out_window_value_reg[2][0] <= 0;
                    out_window_value_reg[2][1] <= 0;
                    out_window_value_reg[2][2] <= 0;
                    out_window_value_reg[2][3] <= 0;
                    out_window_value_reg[2][4] <= 0;
                    out_window_value_reg[2][5] <= 0;
                    out_window_value_reg[2][6] <= 0;
                    out_window_value_reg[3][0] <= 0;
                    out_window_value_reg[3][1] <= 0;
                    out_window_value_reg[3][2] <= 0;
                    out_window_value_reg[3][3] <= 0;
                    out_window_value_reg[3][4] <= 0;
                    out_window_value_reg[3][5] <= 0;
                    out_window_value_reg[3][6] <= 0;
                    out_window_value_reg[4][0] <= 0;
                    out_window_value_reg[4][1] <= 0;
                    out_window_value_reg[4][2] <= 0;
                    out_window_value_reg[4][3] <= 0;
                    out_window_value_reg[4][4] <= 0;
                    out_window_value_reg[4][5] <= 0;
                    out_window_value_reg[4][6] <= 0;
                    out_window_value_reg[5][0] <= 0;
                    out_window_value_reg[5][1] <= 0;
                    out_window_value_reg[5][2] <= 0;
                    out_window_value_reg[5][3] <= 0;
                    out_window_value_reg[5][4] <= 0;
                    out_window_value_reg[5][5] <= 0;
                    out_window_value_reg[5][6] <= 0;
                    out_window_value_reg[6][0] <= 0;
                    out_window_value_reg[6][1] <= 0;
                    out_window_value_reg[6][2] <= 0;
                    out_window_value_reg[6][3] <= 0;
                    out_window_value_reg[6][4] <= 0;
                    out_window_value_reg[6][5] <= 0;
                    out_window_value_reg[6][6] <= 0;
                end
            endcase
            out_window_addr_0 <= out_window_addr;
            out_window_valid <= 1;
        end
        else begin
            out_window_valid <= 0;
        end
    end
end
endmodule
