module topp(input logic clk, input logic rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] result;
    Module1 m1(.clk(clk), .rst(rst), .in(in), .out(result));
    assign out = result;
endmodule

module Module1(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module2 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module2(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module3 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module3(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module4 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module4(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module5 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module5(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module6 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module6(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module7 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module7(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module8 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module8(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module9 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module9(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module10 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module10(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module11 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module11(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module12 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module12(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module13 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module13(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module14 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module14(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module15 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module15(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module16 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module16(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module17 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module17(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module18 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module18(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module19 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module19(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    logic [7:0] temp;
    Module20 m(.clk(clk), .rst(rst), .in(in + 1), .out(temp));
    assign out = temp;
endmodule

module Module20(input logic clk, rst, input logic [7:0] in, output logic [7:0] out);
    assign out = in + 1;
endmodule
