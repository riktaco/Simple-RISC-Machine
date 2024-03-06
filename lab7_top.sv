`define MNONE 2'b00
`define MWRITE 2'b01
`define MREAD 2'b10

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    //CPU
    reg [8:0] next_pc;
    reg reset_pc, addr_sel;
    reg [15:0] read_data;
    reg[1:0] mem_cmd;
    reg [8:0] mem_addr;
    reg [15:0] write_data,lols; // is datapath_out
    reg N, V, Z, load_pc;
    reg load_ir;

    //others
    reg enable;
    reg ksel;
    reg wsel;
    reg msel;
    reg [15:0] dout;
    reg write;

    RAM MEM (
        .clk(~KEY[0]), 
        .read_address(mem_addr[7:0]), 
        .write_address(mem_addr[7:0]), 
        .write(write), 
        .din(write_data), 
        .dout(dout)
    );

    cpu CPU(
        .clk(~KEY[0]),
        .reset(~KEY[1]),
        .load_ir(load_ir),
        .datapath_out(write_data),
        .N(N),
        .V(V),
        .Z(Z),
        .load_pc(load_pc),
        .mem_addr(mem_addr), 
        .mem_cmd(mem_cmd), 
        .read_data(read_data)
    );

    //bottom input to tristate inverter and gate
    always @(*) begin
        if(mem_addr[8] == 1'b0)
            msel = 1'b1;
        else
            msel = 1'b0;
    end

    //top input to tristate inverter and gate
    always @(*) begin
        if(mem_cmd == `MREAD)
            ksel = 1'b1;
        else
            ksel = 1'b0;
    end

    //top input to write and gate
    always @(*) begin
        if(mem_cmd == `MWRITE)
            wsel = 1'b1;
        else
            wsel = 1'b0;
    end
    
    //input to tristate inverter
    always @(*) begin
        enable = msel & ksel;
    end

    //tristate inverter
    assign read_data = enable ? dout : lols;

    always @(*) begin
        write = msel & wsel;
    end


    assign HEX5[0] = ~Z;
    assign HEX5[6] = ~N;
    assign HEX5[3] = ~V;

    input_iface IN(~KEY[0], SW, lols, LEDR[7:0]);

    // fill in sseg to display 4-bits in hexidecimal 0,1,2...9,A,B,C,D,E,F
    sseg H0(write_data[3:0],   HEX0);
    sseg H1(write_data[7:4],   HEX1);
    sseg H2(write_data[11:8],  HEX2);
    sseg H3(write_data[15:12], HEX3);
    assign HEX4 = 7'b1111111;
    assign {HEX5[2:1],HEX5[5:4]} = 4'b1111; // disabled
    assign LEDR[8] = 1'b0;

endmodule

// To ensure Quartus uses the embedded MLAB memory blocks inside the Cyclone
// V on your DE1-SoC we follow the coding style from in Altera's Quartus II
// Handbook (QII5V1 2015.05.04) in Chapter 12, “Recommended HDL Coding Style”
//
// 1. "Example 12-11: Verilog Single Clock Simple Dual-Port Synchronous RAM 
//     with Old Data Read-During-Write Behavior" 
// 2. "Example 12-29: Verilog HDL RAM Initialized with the readmemb Command"

module RAM(clk,read_address,write_address,write,din,dout);
  parameter data_width = 16; 
  parameter addr_width = 8;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
      dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
  end 
endmodule


module input_iface(clk, SW, ir, LEDR);
  input clk;
  input [9:0] SW;
  output [15:0] ir;
  output [7:0] LEDR;
  wire sel_sw = SW[9];  
  wire [15:0] ir_next = sel_sw ? {SW[7:0],ir[7:0]} : {ir[15:8],SW[7:0]};
  vDFF #(16) REG(clk,ir_next,ir);
  assign LEDR = sel_sw ? ir[7:0] : ir[15:8];  
endmodule         

module vDFF(clk,D,Q);
  parameter n=1;
  input clk;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  always @(posedge clk)
    Q <= D;
endmodule

module sseg(in,segs);
  input [3:0] in;
  output reg [6:0] segs;

  always @(*) begin
    case (in)
      4'b0000: segs = 7'b1000000; //0
      4'b0001: segs = 7'b1111001; //1
      4'b0010: segs = 7'b0100100; //2
      4'b0011: segs = 7'b0110000; //3
      4'b0100: segs = 7'b0011001; //4
      4'b0101: segs = 7'b0010010; //5
      4'b0110: segs = 7'b0000010; //6
      4'b0111: segs = 7'b1111000; //7
      4'b1000: segs = 7'b0000000; //8
      4'b1001: segs = 7'b0010000; //9
      4'b1010: segs = 7'b0001000; //A
      4'b1011: segs = 7'b0000011; //b
      4'b1100: segs = 7'b1000110; //C
      4'b1101: segs = 7'b0100001; //d
      4'b1110: segs = 7'b0000110; //E
      4'b1111: segs = 7'b0001110; //F
      default: segs = 7'b1000000; // default is 0
    endcase
  end

endmodule