module shifter(in,shift,sout);
    input [15:0] in;
    input [1:0] shift;
    output reg [15:0] sout;

    //controls what kind of shift you want to perform once something changes
    always @(*) begin
        case(shift)
            2'b00: sout = in;               // No shift
            2'b01: sout = in << 1;          // Shift left by 1 bit
            2'b10: sout = in >> 1;          // Shift right by 1 bit
            2'b11: sout = {in[15], in[15:1]}; // Shift right by 1 bit and make MSB a copy of B[15]
            default: sout = in;             // Default no shift
        endcase
    end
endmodule
