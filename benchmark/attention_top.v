// the following is a general outline for the top level attention module

module attention_top #(
    // param D = 64
    // param N = 512
    // param tiles -> decide
)
(
    // maybe reset, start, pause, etc.
);
    // Q
    // K
    // V

    // matmul(in Q, in K, out S) -> mult Q and K^T, S is some M full rows
    // softmax(in S, out P) -> compute softmax for M rows and output as P
    // matmul(in P, in V, out O) -> mult rows P by V, accumulate in O

    // O should be done

endmodule;