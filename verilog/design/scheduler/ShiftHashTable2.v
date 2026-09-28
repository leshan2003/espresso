`timescale 1ns / 1ps
// Sparse row storage and neighborhood-window reads.

module ShiftHashTable2 #(
    parameter DATA_WIDTH = 4,
    parameter MEM_DEPTH = 16,
    parameter HALF_WINDOW_SIZE = 1,
    parameter WINDOW_SIZE = 2,
    parameter HALF_ADDR_WIDTH = 4
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
assign out_window_value = {out_window_value_reg[0][0], out_window_value_reg[0][1], out_window_value_reg[1][0], out_window_value_reg[1][1]};

reg [DATA_WIDTH-1:0] datamem [0:MEM_DEPTH-1][0:WINDOW_SIZE-1];
reg [2*HALF_ADDR_WIDTH-1:0] out_window_addr_0;
reg [2*HALF_ADDR_WIDTH-1:0] in_event_addr_0;
reg [DATA_WIDTH-1:0] in_event_value_0;
reg in_event_valid_0;
integer k,j;

wire [HALF_ADDR_WIDTH-1:0] in_addr_row = in_event_addr_0[2*HALF_ADDR_WIDTH-1:HALF_ADDR_WIDTH];
wire [HALF_ADDR_WIDTH-1:0] in_addr_col = in_event_addr_0[HALF_ADDR_WIDTH-1:0];
wire [HALF_ADDR_WIDTH-1:0] out_addr_row = out_window_addr[2*HALF_ADDR_WIDTH-1:HALF_ADDR_WIDTH];
wire [HALF_ADDR_WIDTH-1:0] out_addr_col = out_window_addr[HALF_ADDR_WIDTH-1:0];
reg [HALF_ADDR_WIDTH-1:0] current_addr_row;
wire [HALF_ADDR_WIDTH-1:0] in_row_diff = in_addr_row - current_addr_row;
wire signed [HALF_ADDR_WIDTH-1:0] out_row_diff = out_addr_row - current_addr_row;

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
                1: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col][1];
                    out_window_value_reg[0][1] <= datamem[out_addr_col+1][1];
                    out_window_value_reg[1][0] <= 0;
                    out_window_value_reg[1][1] <= 0;
                end
                0: begin
                    out_window_value_reg[0][0] <= datamem[out_addr_col][0];
                    out_window_value_reg[0][1] <= datamem[out_addr_col+1][0];
                    out_window_value_reg[1][0] <= datamem[out_addr_col][1];
                    out_window_value_reg[1][1] <= datamem[out_addr_col+1][1];
                end
                -1: begin
                    out_window_value_reg[0][0] <= 0;
                    out_window_value_reg[0][1] <= 0;
                    out_window_value_reg[1][0] <= datamem[out_addr_col][0];
                    out_window_value_reg[1][1] <= datamem[out_addr_col+1][0];
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
