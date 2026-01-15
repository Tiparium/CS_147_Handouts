/*
    CS 147 Spring 26
    Homework #1, problem 2

    2-input NAND gate.
*/
module nand2 (out,in1,in2);
    output out;
    input in1,in2;
    assign out = ~(in1 & in2);
endmodule
