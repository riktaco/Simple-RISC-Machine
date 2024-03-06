module ALU(Ain,Bin,ALUop,out,Z);
    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output reg [15:0] out;
    output reg [2:0] Z;

    //combinational block to control what operation you want to use
    always @* begin
        case(ALUop)
            2'b00: out = Ain + Bin; //adds a and b together
            2'b01: out = Ain - Bin; //subtracts and b from a
            2'b10: out = Ain & Bin; //
            2'b11: out = ~Bin; //
        endcase

        //Z = 3'bVNZ
        //if out is 0, Z = 1
        //if out is -ve, N = 1 
        //if out overflows, V = 1

        casex(out)
           16'b0000000000000000: Z = 3'b001;
           16'b1xxxxxxxxxxxxxxx: Z = 3'b010;
           default: Z = 3'b000;
        endcase
    end 
endmodule 
 
