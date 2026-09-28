`timescale 1ns / 1ps
// Self-checking arithmetic and metadata tests, shared by both pipeline revisions.
module nms5_tb;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg [199:0] window_value = 0;
    reg window_valid = 0;
    reg [15:0] window_addr = 0;
    reg [7:0] threshold = 0;
    wire feature, feature_valid, window_req;
    wire [15:0] feature_addr;
    nms5 #(.DATA_WIDTH(8)) dut (
        .clk(clk), .rst_n(rst_n), .in_window_value(window_value),
        .in_window_valid(window_valid), .in_window_addr(window_addr),
        .ready_for_new_feature(1'b1), .threshold(threshold),
        .out_isfeature(feature), .out_feature_addr(feature_addr),
        .out_feature_valid(feature_valid), .window_req(window_req)
    );

    reg [39:0] five_values = 0;
    reg five_valid = 0;
    wire [7:0] maximum;
    wire middle, maximum_valid;
    max5 #(.DATA_WIDTH(8)) maximum_dut (
        .clk(clk), .rst_n(rst_n), .in_window_value(five_values),
        .in_window_valid(five_valid), .out_max_value(maximum),
        .ifmiddle(middle), .out_max_valid(maximum_valid)
    );

    task tick;
        begin @(posedge clk); #1; end
    endtask

    task check_feature;
        input expected;
        input [15:0] address;
        begin
            if (feature_valid !== 1'b1 || feature !== expected || feature_addr !== address)
                $fatal(1, "NMS mismatch: feature=%b valid=%b address=%h expected=%b/%h",
                       feature, feature_valid, feature_addr, expected, address);
        end
    endtask

    integer sample, pixel, best_index;
    reg [7:0] best_value;
    initial begin
        tick;
        if (feature_valid !== 0 || maximum_valid !== 0) $fatal(1, "Reset failed");
        @(negedge clk); rst_n = 1;
        // Upper bits, middle maximum, first-index tie preference, then a bubble.
        five_values = {8'd4, 8'd3, 8'd200, 8'd2, 8'd1}; five_valid = 1;
        tick;
        if (maximum !== 8'd200 || middle !== 1 || maximum_valid !== 1) $fatal(1, "Full-width maximum failed");
        @(negedge clk); five_values = {8'd4, 8'd3, 8'd200, 8'd2, 8'd200};
        tick;
        if (maximum !== 8'd200 || middle !== 0) $fatal(1, "Tie priority failed");
        for (sample = 0; sample < 100; sample = sample + 1) begin
            @(negedge clk);
            best_value = 0; best_index = 0;
            for (pixel = 0; pixel < 5; pixel = pixel + 1) begin
                five_values[pixel*8 +: 8] = (sample*37 + pixel*61) % 256;
                if (five_values[pixel*8 +: 8] > best_value) begin
                    best_value = five_values[pixel*8 +: 8]; best_index = pixel;
                end
            end
            tick;
            if (maximum !== best_value || middle !== (best_index == 2)) $fatal(1, "Maximum sweep failed");
        end
        @(negedge clk); five_valid = 0;
        tick;
        if (maximum_valid !== 0 || maximum !== 0 || middle !== 0) $fatal(1, "Maximum bubble failed");

        // Consecutive windows with changing addresses and thresholds detect
        // both one-bit truncation and metadata slipping by one clock.
        @(negedge clk);
        window_value = 0; window_value[12*8 +: 8] = 200;
        window_valid = 1; window_addr = 16'h1234; threshold = 100;
        tick;
        if (feature_valid !== 0) $fatal(1, "Unexpected early output");
        @(negedge clk);
        window_addr = 16'h5678; threshold = 220;
        tick; check_feature(1, 16'h1234);
        @(negedge clk);
        window_addr = 16'h9abc; threshold = 0;
        window_value[0 +: 8] = 210;
        tick; check_feature(0, 16'h5678);
        @(negedge clk);
        window_addr = 16'h1111; window_value = 0;
        window_value[12*8 +: 8] = 200; window_value[10*8 +: 8] = 200;
        tick; check_feature(0, 16'h9abc);
        @(negedge clk);
        window_addr = 16'h2222; threshold = 200;
        window_value[10*8 +: 8] = 0;
        tick; check_feature(0, 16'h1111);
        @(negedge clk); window_valid = 0; window_addr = 16'hffff;
        tick; check_feature(1, 16'h2222);
        tick;
        if (feature_valid !== 0 || feature !== 0 || feature_addr !== 0) $fatal(1, "NMS bubble failed");
        if (window_req !== 1) $fatal(1, "Request signal failed");
        @(negedge clk); rst_n = 0;
        tick;
        if (feature_valid !== 0 || maximum_valid !== 0) $fatal(1, "Final reset failed");
        $display("PASS: max5 and nms5 arithmetic, threshold, ties, metadata, bubbles, reset");
        $finish;
    end
    initial begin
        #10000;
        $fatal(1, "Test timed out");
    end
endmodule
