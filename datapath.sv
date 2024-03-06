module datapath(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, 
                        loads, writenum, write, datapath_in, Z_out, C, mdata, sximm8, sximm5, PC); 
    //REGFILE
    reg [15:0] data_in; 
    input [2:0] writenum, readnum;
    input write, clk;
    wire [15:0] data_out;

    //ALU
    reg [15:0] Ain, Bin;
    input [1:0] ALUop;
    wire [15:0] out;
    wire [2:0] Z;

    //SHIFTER
    reg [15:0] in;
    input [1:0] shift;
    wire [15:0] sout;

    //OTHERS
    input asel, bsel, loada, loadb, loadc, loads;
    input [3:0] vsel;
    input [15:0] datapath_in;
    output reg [15:0] C; //change datapath_out to C
    output reg [2:0] Z_out;

    //LAB 6 ADDITIONS
    input [15:0] mdata, sximm8, sximm5;
    input [8:0] PC;

    //calls the regfile module
    regfile REGFILE(
        .data_in(data_in),
        .writenum(writenum),
        .write(write),
        .readnum(readnum),
        .clk(clk),
        .data_out(data_out)
    );

    //calls the ALU module
    ALU ALU(
        .Ain(Ain),
        .Bin(Bin),
        .ALUop(ALUop),
        .out(out),
        .Z(Z)
    );

    //calls the shifter module
    shifter SHIFTER(
        .in(in),
        .shift(shift),
        .sout(sout)
    );

    // multiplexer to determine what value you want to register (set to data_in)
    // lab 5: assign data_in = vsel ? datapath_in : datapath_out;

    always @(*) begin
	    case(vsel)
        	4'b0001: data_in = mdata;
        	4'b0010: data_in = sximm8;
        	4'b0100: data_in = {8'b0,PC};
        	4'b1000: data_in = C;
        	default: data_in = 16'bxxxxxxxxxxxxxxxx;
    	endcase
    end

    //declaring the outputs of each flipflop
    reg [15:0] Aout, Bout, Cout;

    //flipflop A which takes whatever value stored in data_out and holds it until clk is pressed
    //the that value is copied to Aout
    flipflop A_clk(
        .clk(clk),
        .D(data_out),
        .load(loada),
        .Q(Aout)
    );
    
    //allows for more complex instructions when Ain is set to 0
    assign Ain = asel ? 16'b0 : Aout;
    
    //flipflop B which takes whatever value stored in data_out when loadb is 1
    //and holds it until clk is pressed
    //the that value is copied to Bout
    flipflop B_clk(
        .clk(clk),
        .D(data_out),
        .load(loadb),
        .Q(Bout)
    );

    //sets in to the value of Bout to match the diagram on the lab sheet
    assign in = Bout;

    // if bsel is 1 (TRUE) Bin is set to the concatenation of 11 bits of 0 
    // and the first 5 bits of datapath_in
    // if bsel is 0 (FALSE) Bin is set to sout
    assign Bin = bsel ? sximm5 : sout;

    //flipflop C which takes whatever value stored in out after the ALU operation,
    //and loads it into loadc until clk is pressed, then the value of loadc gets
    //inputted into Cout
    flipflop C_clk(
        .clk(clk),
        .D(out),
        .load(loadc),
        .Q(Cout)
    );

    //sets datapath_out to the value held in Cout to match the diagram
    assign C = Cout;

    //checks to what the status is
    status Z_status(
        .clk(clk),
        .D(Z),
        .load(loads),
        .Q(Z_out)
    );
endmodule

//flipflop module to recieve a 16 bit value
module flipflop(clk,D,load,Q);
  input clk;
  input [15:0] D;
  input load;
  output reg [15:0] Q;

  always @(posedge clk) begin
    if(load)
      Q <= D;
  end
endmodule

module status(clk,D,load,Q);
  input clk;
  input [2:0] D;
  input load;
  output reg [2:0] Q;

  always @(posedge clk) begin
    if(load)
      Q <= D;
  end
endmodule