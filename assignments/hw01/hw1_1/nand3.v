/*
    CS 147 Spring 26
    Homework #1, problem 1

    3-input NAND gate.
*/
module nand3 (out,in1,in2,in3);
    output out;
    input in1,in2,in3;
    assign out = ~(in1 & in2 & in3);
endmodule
