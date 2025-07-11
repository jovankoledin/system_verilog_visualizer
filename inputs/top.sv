module top(input logic clk, rst, input logic [3:0] op_sel, input logic [31:0] data_in, output logic [31:0] result);

    logic [3:0] ctrl_op;
    logic [31:0] reg_out1, reg_out2, alu_out;

    controller ctrl (
        .clk(clk),
        .rst(rst),
        .op_sel(op_sel),
        .ctrl_op(ctrl_op)
    );

    datapath dp (
        .clk(clk),
        .rst(rst),
        .ctrl_op(ctrl_op),
        .data_in(data_in),
        .reg_out1(reg_out1),
        .reg_out2(reg_out2),
        .alu_result(alu_out)
    );

    assign result = alu_out;

endmodule

module controller(input logic clk, rst, input logic [3:0] op_sel, output logic [3:0] ctrl_op);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) ctrl_op <= 0;
        else ctrl_op <= op_sel;
    end
endmodule

module datapath(
    input logic clk, rst,
    input logic [3:0] ctrl_op,
    input logic [31:0] data_in,
    output logic [31:0] reg_out1,
    output logic [31:0] reg_out2,
    output logic [31:0] alu_result
);

    logic [4:0] rd_addr1 = 5'd0;
    logic [4:0] rd_addr2 = 5'd1;
    logic [31:0] alu_in1, alu_in2;

    register_file rf (
        .clk(clk),
        .rst(rst),
        .we(1'b1),
        .wr_addr(rd_addr1),
        .wr_data(data_in),
        .rd_addr1(rd_addr1),
        .rd_addr2(rd_addr2),
        .rd_data1(reg_out1),
        .rd_data2(reg_out2)
    );

    assign alu_in1 = reg_out1;
    assign alu_in2 = reg_out2;

    alu u_alu (
        .op(ctrl_op),
        .a(alu_in1),
        .b(alu_in2),
        .result(alu_result)
    );
endmodule

module register_file(
    input logic clk, rst,
    input logic we,
    input logic [4:0] wr_addr,
    input logic [31:0] wr_data,
    input logic [4:0] rd_addr1,
    input logic [4:0] rd_addr2,
    output logic [31:0] rd_data1,
    output logic [31:0] rd_data2
);
    logic [31:0] regs[0:31];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) regs[i] <= 0;
        end else if (we) begin
            regs[wr_addr] <= wr_data;
        end
    end

    assign rd_data1 = regs[rd_addr1];
    assign rd_data2 = regs[rd_addr2];
endmodule

module alu(input logic [3:0] op, input logic [31:0] a, b, output logic [31:0] result);
    logic [31:0] sum, product;

    adder u_adder (.a(a), .b(b), .sum(sum));
    multiplier u_mult (.a(a), .b(b), .product(product));

    always_comb begin
        case (op)
            4'd0: result = sum;
            4'd1: result = product;
            default: result = 32'd0;
        endcase
    end
endmodule

module adder(input logic [31:0] a, b, output logic [31:0] sum);
    assign sum = a + b;
endmodule

module multiplier(input logic [31:0] a, b, output logic [31:0] product);
    assign product = a * b;
endmodule
