`timescale 1ns / 1ps
// Simulation-only event input from external hexadecimal fixtures.

module raw_event_dispatcher_dy#(
    parameter EventMEM_DEPTH = 1000,
    parameter DATA_WIDTH = 4,
    parameter eventvaluefile = "local/rtl-events/eventvalue.txt",
    parameter eventaddrrowfile = "local/rtl-events/eventaddrrow.txt",
    parameter eventaddrcolfile = "local/rtl-events/eventaddrcol.txt"
)(
    input wire clk,
    input wire rst_n,
    input wire out_event_req_0_1,
    input wire out_event_req_0_2,
    input wire out_event_req_0_3,
    input wire out_event_req_0_4,
    output reg in_event_valid_0_1,
    output reg in_event_valid_0_2,
    output reg in_event_valid_0_3,
    output reg in_event_valid_0_4,
    output wire [DATA_WIDTH-1:0] in_event_value_0_1,
    output wire [DATA_WIDTH-1:0] in_event_value_0_2,
    output wire [DATA_WIDTH-1:0] in_event_value_0_3,
    output wire [DATA_WIDTH-1:0] in_event_value_0_4,
    output wire [15:0] in_event_addr_0_1,
    output wire [15:0] in_event_addr_0_2,
    output wire [15:0] in_event_addr_0_3,
    output wire [15:0] in_event_addr_0_4,
    output reg rstn_btw_pictures
    );

reg [DATA_WIDTH-1:0] event_value_mem [0:EventMEM_DEPTH-1];
reg [7:0] event_addrrow_mem [0:EventMEM_DEPTH-1];
reg [7:0] event_addrcol_mem [0:EventMEM_DEPTH-1];
reg [7:0] last_x_min, last_x_max, last_y_min, last_y_max;
reg [7:0] this_x_min, this_x_max, this_y_min, this_y_max;
reg [15:0] event_cnt_1, event_cnt_2, event_cnt_3, event_cnt_4;
reg [31:0] long_wait_cnt;

assign in_event_value_0_1 = event_value_mem[event_cnt_1];
assign in_event_value_0_2 = event_value_mem[event_cnt_2];
assign in_event_value_0_3 = event_value_mem[event_cnt_3];
assign in_event_value_0_4 = event_value_mem[event_cnt_4];
assign in_event_addr_0_1 = {event_addrrow_mem[event_cnt_1], event_addrcol_mem[event_cnt_1]};
assign in_event_addr_0_2 = {event_addrrow_mem[event_cnt_2], event_addrcol_mem[event_cnt_2]};
assign in_event_addr_0_3 = {event_addrrow_mem[event_cnt_3], event_addrcol_mem[event_cnt_3]};
assign in_event_addr_0_4 = {event_addrrow_mem[event_cnt_4], event_addrcol_mem[event_cnt_4]};
// assign rstn_btw_pictures = ~event_value_mem[event_cnt_1] & ~event_value_mem[event_cnt_2] & ~event_value_mem[event_cnt_3] & ~event_value_mem[event_cnt_4];

initial begin
    $readmemh(eventvaluefile, event_value_mem);
    $readmemh(eventaddrrowfile, event_addrrow_mem);
    $readmemh(eventaddrcolfile, event_addrcol_mem);
    in_event_valid_0_1 <= 0;
    in_event_valid_0_2 <= 0;
    in_event_valid_0_3 <= 0;
    in_event_valid_0_4 <= 0;
    rstn_btw_pictures <= 1;
    last_x_min <= 0;
    last_x_max <= 8'hff;
    last_y_min <= 0;
    last_y_max <= 8'hff;
    this_x_min <= 8'hff;
    this_x_max <= 0;
    this_y_min <= 8'hff;
    this_y_max <= 0;
    event_cnt_1 <= 0;
    event_cnt_2 <= 0;
    event_cnt_3 <= 0;
    event_cnt_4 <= 0;
    long_wait_cnt <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        $readmemh(eventvaluefile, event_value_mem);
        $readmemh(eventaddrrowfile, event_addrrow_mem);
        $readmemh(eventaddrcolfile, event_addrcol_mem);
        in_event_valid_0_1 <= 0;
        in_event_valid_0_2 <= 0;
        in_event_valid_0_3 <= 0;
        in_event_valid_0_4 <= 0;
        rstn_btw_pictures <= 1;
        last_x_min <= 0;
        last_x_max <= 8'hff;
        last_y_min <= 0;
        last_y_max <= 8'hff;
        this_x_min <= 8'hff;
        this_x_max <= 0;
        this_y_min <= 8'hff;
        this_y_max <= 0;
        event_cnt_1 <= 0;
        event_cnt_2 <= 0;
        event_cnt_3 <= 0;
        event_cnt_4 <= 0;
        long_wait_cnt <= 0;
    end
    else begin
        if (event_value_mem[event_cnt_1] == 0 && event_value_mem[event_cnt_2] == 0 && event_value_mem[event_cnt_3] == 0 && event_value_mem[event_cnt_4] == 0) begin
            in_event_valid_0_1 <= 0;
            in_event_valid_0_2 <= 0;
            in_event_valid_0_3 <= 0;
            in_event_valid_0_4 <= 0;
            if (long_wait_cnt < 100000) begin
                long_wait_cnt <= long_wait_cnt + 1;
                event_cnt_1 <= event_cnt_1;
                event_cnt_2 <= event_cnt_2;
                event_cnt_3 <= event_cnt_3;
                event_cnt_4 <= event_cnt_4;
                rstn_btw_pictures <= 1;
            end
            else begin
                long_wait_cnt <= 0;
                event_cnt_1 <= event_cnt_1 + 1;
                event_cnt_2 <= event_cnt_2 + 1;
                event_cnt_3 <= event_cnt_3 + 1;
                event_cnt_4 <= event_cnt_4 + 1;
                rstn_btw_pictures <= 0;
                // last_x_max <= 8'hff;
                // last_x_min <= 0;
                // last_y_max <= 8'hff;
                // last_y_min <= 0;
                last_x_max <= this_x_max;
                last_x_min <= this_x_min;
                last_y_max <= this_y_max;
                last_y_min <= this_y_min;
                this_x_max <= 0;
                this_x_min <= 8'hff;
                this_y_max <= 0;
                this_y_min <= 8'hff;
            end
        end
        else begin
            rstn_btw_pictures <= 1;
            if (event_value_mem[event_cnt_1] == 0) begin
                event_cnt_1 <= event_cnt_1;
                in_event_valid_0_1 <= 0;
            end
            else begin
                if (event_addrrow_mem[event_cnt_1] < this_x_min) begin
                    this_x_min <= event_addrrow_mem[event_cnt_1];
                end
                if (event_addrrow_mem[event_cnt_1] > this_x_max) begin
                    this_x_max <= event_addrrow_mem[event_cnt_1];
                end
                if (event_addrcol_mem[event_cnt_1] < this_y_min) begin
                    this_y_min <= event_addrcol_mem[event_cnt_1];
                end
                if (event_addrcol_mem[event_cnt_1] > this_y_max) begin
                    this_y_max <= event_addrcol_mem[event_cnt_1];
                end
                if (out_event_req_0_1) begin
                    if ((event_addrrow_mem[event_cnt_1] < last_x_min) || (event_addrrow_mem[event_cnt_1] > last_x_max) || (event_addrcol_mem[event_cnt_1] < last_y_min) || (event_addrcol_mem[event_cnt_1] > last_y_max)) begin
                        in_event_valid_0_1 <= 1;
                        event_cnt_1 <= event_cnt_1 + 1;
                    end
                    else begin
                        in_event_valid_0_1 <= 0;
                        event_cnt_1 <= event_cnt_1 + 1;
                    end
                end
            end

            if (event_value_mem[event_cnt_2] == 0) begin
                event_cnt_2 <= event_cnt_2;
                in_event_valid_0_2 <= 0;
            end
            else begin
                if (event_addrrow_mem[event_cnt_2] < this_x_min) begin
                    this_x_min <= event_addrrow_mem[event_cnt_2];
                end
                if (event_addrrow_mem[event_cnt_2] > this_x_max) begin
                    this_x_max <= event_addrrow_mem[event_cnt_2];
                end
                if (event_addrcol_mem[event_cnt_2] < this_y_min) begin
                    this_y_min <= event_addrcol_mem[event_cnt_2];
                end
                if (event_addrcol_mem[event_cnt_2] > this_y_max) begin
                    this_y_max <= event_addrcol_mem[event_cnt_2];
                end
                if (out_event_req_0_2) begin
                    if ((event_addrrow_mem[event_cnt_2] >= last_x_min) && ((3*event_addrrow_mem[event_cnt_2]) < (last_x_max+2*last_x_min)) && (event_addrcol_mem[event_cnt_2] >= last_y_min) && (event_addrcol_mem[event_cnt_2] <= last_y_max)) begin
                        in_event_valid_0_2 <= 1;
                        event_cnt_2 <= event_cnt_2 + 1;
                    end
                    else begin
                        in_event_valid_0_2 <= 0;
                        event_cnt_2 <= event_cnt_2 + 1;
                    end
                end
            end

            if (event_value_mem[event_cnt_3] == 0) begin
                event_cnt_3 <= event_cnt_3;
                in_event_valid_0_3 <= 0;
            end
            else begin
                if (event_addrrow_mem[event_cnt_3] < this_x_min) begin
                    this_x_min <= event_addrrow_mem[event_cnt_3];
                end
                if (event_addrrow_mem[event_cnt_3] > this_x_max) begin
                    this_x_max <= event_addrrow_mem[event_cnt_3];
                end
                if (event_addrcol_mem[event_cnt_3] < this_y_min) begin
                    this_y_min <= event_addrcol_mem[event_cnt_3];
                end
                if (event_addrcol_mem[event_cnt_3] > this_y_max) begin
                    this_y_max <= event_addrcol_mem[event_cnt_3];
                end
                if (out_event_req_0_3) begin
                    if (((3*event_addrrow_mem[event_cnt_3]) >= (last_x_max+2*last_x_min)) && ((3*event_addrrow_mem[event_cnt_3]) < (2*last_x_max+last_x_min)) && (event_addrcol_mem[event_cnt_3] >= last_y_min) && (event_addrcol_mem[event_cnt_3] <= last_y_max)) begin
                        in_event_valid_0_3 <= 1;
                        event_cnt_3 <= event_cnt_3 + 1;
                    end
                    else begin
                        in_event_valid_0_3 <= 0;
                        event_cnt_3 <= event_cnt_3 + 1;
                    end
                end
            end

            if (event_value_mem[event_cnt_4] == 0) begin
                event_cnt_4 <= event_cnt_4;
                in_event_valid_0_4 <= 0;
            end
            else begin
                if (event_addrrow_mem[event_cnt_4] < this_x_min) begin
                    this_x_min <= event_addrrow_mem[event_cnt_4];
                end
                if (event_addrrow_mem[event_cnt_4] > this_x_max) begin
                    this_x_max <= event_addrrow_mem[event_cnt_4];
                end
                if (event_addrcol_mem[event_cnt_4] < this_y_min) begin
                    this_y_min <= event_addrcol_mem[event_cnt_4];
                end
                if (event_addrcol_mem[event_cnt_4] > this_y_max) begin
                    this_y_max <= event_addrcol_mem[event_cnt_4];
                end
                if (out_event_req_0_4) begin
                    if (((3*event_addrrow_mem[event_cnt_4]) >= (2*last_x_max+last_x_min)) && (event_addrrow_mem[event_cnt_4] <= last_x_max) && (event_addrcol_mem[event_cnt_4] >= last_y_min) && (event_addrcol_mem[event_cnt_4] <= last_y_max)) begin
                        in_event_valid_0_4 <= 1;
                        event_cnt_4 <= event_cnt_4 + 1;
                    end
                    else begin
                        in_event_valid_0_4 <= 0;
                        event_cnt_4 <= event_cnt_4 + 1;
                    end
                end
            end
        end
    end
end
endmodule
