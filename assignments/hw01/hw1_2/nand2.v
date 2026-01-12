/*
    CS/ECE 552 Spring '22
    Homework #1, Problem 2

    2 input NAND
*/
module nand2 (out,in1,in2);
    output out;
    input in1,in2;
    assign out = ~(in1 & in2);
endmodule
