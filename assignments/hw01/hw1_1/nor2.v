/*
    CS 147 Spring 26
    Homework #1, problem 1

    2-input NOR gate.
*/
module nor2 (out,in1,in2);
    output out;
    input in1,in2;
    assign out = ~(in1 | in2);
endmodule
