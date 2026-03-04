/*
    CS 147 Spring 26
    Homework #1, problem 2

    3-input NOR gate.
*/
module nor3 (out,in1,in2,in3);
    output out;
    input  in1,in2,in3;
    assign out = ~(in1 | in2 | in3);
endmodule
