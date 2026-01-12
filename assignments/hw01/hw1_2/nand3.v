/*
    CS/ECE 552 Spring '22
    Homework #1, Problem 2

    3 input NAND
*/
module nand3 (out,in1,in2,in3);
    output out;
    input in1,in2,in3;
    assign out = ~(in1 & in2 & in3);
endmodule
