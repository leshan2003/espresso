`timescale 1ns / 1ps
// Two-stage, unsigned 5x5 nonmaximum suppression for the espresso revision.
// Row-major packed values: pixel 0 occupies the least-significant slice.
// A center-row tie selects its first maximum; other rows may tie the center.
// No output buffer: the consumer must remain ready for windows in flight.
module nms5 #(
    parameter DATA_WIDTH = 46
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH*25-1:0] in_window_value,
    input wire in_window_valid,
    input wire [15:0] in_window_addr,
    input wire ready_for_new_feature,
    input wire [DATA_WIDTH-1:0] threshold,
    output reg out_isfeature,
    output reg [15:0] out_feature_addr,
    output reg out_feature_valid,
    output wire window_req
);
    assign window_req = ready_for_new_feature;

    wire [DATA_WIDTH-1:0] row_max [0:4];
    wire [4:0] row_middle, row_valid;
    reg [15:0] window_addr_d;
    reg [DATA_WIDTH-1:0] threshold_d;

    genvar row;
    generate
        for (row = 0; row < 5; row = row + 1) begin : row_maxima
            max5 #(.DATA_WIDTH(DATA_WIDTH)) maximum (
                .clk(clk),
                .rst_n(rst_n),
                .in_window_value(in_window_value[DATA_WIDTH*5*row +: DATA_WIDTH*5]),
                .in_window_valid(in_window_valid),
                .out_max_value(row_max[row]),
                .ifmiddle(row_middle[row]),
                .out_max_valid(row_valid[row])
            );
        end
    endgenerate

    // Metadata follows the same first-stage register as the row maxima.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            window_addr_d <= 0;
            threshold_d <= 0;
        end else if (in_window_valid) begin
            window_addr_d <= in_window_addr;
            threshold_d <= threshold;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_isfeature <= 0;
            out_feature_addr <= 0;
            out_feature_valid <= 0;
        end else if (&row_valid) begin
            out_feature_addr <= window_addr_d;
            out_feature_valid <= 1;
            out_isfeature <= row_middle[2] && row_max[2] >= threshold_d &&
                row_max[2] >= row_max[0] && row_max[2] >= row_max[1] &&
                row_max[2] >= row_max[3] && row_max[2] >= row_max[4];
        end else begin
            out_isfeature <= 0;
            out_feature_addr <= 0;
            out_feature_valid <= 0;
        end
    end
endmodule
