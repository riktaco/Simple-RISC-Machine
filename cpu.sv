//`define Wait 3'b000
`define RST 4'b0000
`define IF1 4'b0001
`define IF2 4'b0010
`define updatePC 4'b0011
`define decode 4'b0100
`define getA 4'b0101
`define getB 4'b0110
`define ALU 4'b1000
`define WriteReg 4'b1010
`define WriteImm 4'b1100
`define readRam 4'b1110
`define writeRam 4'b1111
`define dataAddress 4'b1011
`define HALT 4'b0111

`define MNONE 2'b00
`define MWRITE 2'b01
`define MREAD 2'b10

module cpu(clk,reset,load_ir,datapath_out,N,V,Z,load_pc, mem_addr, mem_cmd, read_data);
    input clk, reset; 
    output reg load_ir;
    //input [15:0] in; changed to read_data
    output reg [15:0] datapath_out; // changed from out
    output reg N, V, Z, load_pc; 

    reg [15:0] in_out;
    reg [2:0] Rn,Rd,Rm;
    reg [7:0] im8;
    reg [4:0] im5;

    reg [2:0] opcode;
    reg [1:0] op;

    reg [3:0] present_state;

    reg [2:0] nsel;

    //datapath
    reg [2:0] writenum, readnum;
    reg write;
    reg [15:0] data_out;
    reg [1:0] ALUop;
    reg [1:0] shift;
    reg asel, bsel, loada, loadb, loadc, loads;
    reg [3:0] vsel;
    reg [15:0] datapath_in;
    reg [2:0] Z_out;
    reg [15:0] mdata, sximm8, sximm5;
    reg [8:0] PC;

    //lab7 additions
    reg [8:0] next_pc;
    reg reset_pc, addr_sel;
    input [15:0] read_data;
    output reg [1:0] mem_cmd;
    output reg [8:0] mem_addr;

    reg load_addr;
    reg [8:0] dataAddress_out;

    datapath DP(
        .clk(clk), 
        .readnum(readnum), 
        .vsel(vsel), 
        .loada(loada), 
        .loadb(loadb), 
        .shift(shift), 
        .asel(asel), 
        .bsel(bsel), 
        .ALUop(ALUop), 
        .loadc(loadc), 
        .loads(loads), 
        .writenum(writenum), 
        .write(write), 
        .datapath_in(datapath_in), 
        .Z_out(Z_out), 
        .C(datapath_out), //C is value of out in datapath
        .mdata(mdata), 
        .sximm8(sximm8), 
        .sximm5(sximm5), 
        .PC(PC)
    );

    always @(*) begin
        N = Z_out[1];
        V = Z_out[2];
        Z = Z_out[0];
    end

    //instruction register

    cpuflipflop insr(
        .clk(clk),
        .D(read_data),
        .load(load_ir),
        .Q(in_out)
    );

    //instruction decoder

    //assign values to opcode,op,aluop
    always @(*) begin
        opcode = in_out[15:13];
        op = in_out[12:11];
        ALUop = in_out[12:11];
    end

    //assign values using opcode and op
    always @(*) begin
        case({opcode,op})
            5'b11010: 
                begin
                    Rn <= in_out[10:8]; im8 <= in_out[7:0]; Rm <= 3'bxxx; Rd <= 3'bxxx; shift <= 2'bxx; im5 <= 5'bxxxxx;
                end
            5'b11000: 
                begin
                    Rd <= in_out[7:5]; shift <= in_out[4:3]; Rm <= in_out[2:0]; Rn <= 3'bxxx; im8 <= 8'bxxxxxxxx; im5 <= 5'bxxxxx;
                end
            5'b10100: 
                begin
                    Rn <= in_out[10:8]; Rd <= in_out[7:5]; shift <= in_out[4:3]; Rm <= in_out[2:0]; im8 <= 8'bxxxxxxxx; im5 <= 5'bxxxxx;
                end
            5'b10101: 
                begin
                    Rn <= in_out[10:8]; shift <= in_out[4:3]; Rm <= in_out[2:0]; Rd <= 3'bxxx; im8 <= 8'bxxxxxxxx; im5 <= 5'bxxxxx;
                end
            5'b10110: 
                begin
                    Rn <= in_out[10:8]; Rd <= in_out[7:5]; shift <= in_out[4:3]; Rm <= in_out[2:0]; im8 <= 8'bxxxxxxxx; im5 <= 5'bxxxxx; 
                end
            5'b10111: 
                begin
                    Rd <= in_out[7:5]; shift <= in_out[4:3]; Rm <= in_out[2:0]; Rn <= 3'bxxx; im8 <= 8'bxxxxxxxx; im5 <= 5'bxxxxx;
                end
            5'b01100:
                begin
                    Rn <= in_out[10:8]; Rd <= in_out[7:5]; im5 <= in_out[4:0]; im8 <= 8'bxxxxxxxx; Rm <= 3'bxxx; shift <= 2'bxx;
                end
            5'b10000:
                begin
                    Rn <= in_out[10:8]; Rd <= in_out[7:5]; im5 <= in_out[4:0]; im8 <= 8'bxxxxxxxx; Rm <= 3'bxxx; shift <= 2'bxx;
                end
            5'b111xx:
                begin
                    Rn <= 0; Rd <= 0; im5 <= 0; im8 <= 0; Rm <= 0; shift <= 0;
                end
            default: 
                begin 
                    Rn <= 3'bxxx; Rm <= 3'bxxx; Rd <= 3'bxxx; im8 <= 8'bxxxxxxxx; shift <= 2'bxx; im5 <= 5'bxxxxx; 
                end
        endcase
    end

    //assign values to read and write num
    always @(*) begin
        case(nsel) 
            3'b001: 
                begin
                    readnum <= Rn; writenum <= Rn;
                end
            3'b010: 
                begin
                    readnum <= Rd; writenum <= Rd;
                end
            3'b100: 
                begin
                    readnum <= Rm; writenum <= Rm;
                end
            default: 
                begin
                    readnum <= 3'bxxx; writenum <= 3'bxxx;
                end
        endcase
    end

    //add bits to im5 and im8
    always @(*) begin
        sximm5 = {{11{im5[4]}}, im5};
        sximm8 = {{8{im8[7]}}, im8}; 
    end

    //make sximm8 datapath_in
    always @(*) begin
        datapath_in = sximm8;
    end
    
    //FSM
    always @(posedge clk) begin
        if(reset) begin
            present_state <= `RST;
        end else begin
            casex({opcode,op,present_state})
                {5'bxxxxx, `RST}: present_state <= `IF1;

                {5'bxxxxx, `IF1}: present_state <= `IF2;

                {5'bxxxxx, `IF2}: present_state <= `updatePC;

                {5'bxxxxx, `updatePC}: present_state <= `decode;

                {5'b101xx, `decode}: present_state <= `getA;
                {5'b01100, `decode}: present_state <= `getA;
                {5'b10000, `decode}: present_state <= `getA;
                {5'b11010, `decode}: present_state <= `WriteImm;

                {5'bxxxxx, `WriteImm}: present_state <= `IF1; 
                
                {5'bxxxxx, `getA}: present_state <= `getB; 
                {5'bxxxxx, `getB}: present_state <= `ALU;

                {5'b110xx, `ALU}: present_state <= `WriteReg;
                {5'b101xx, `ALU}: present_state <= `WriteReg;
                {5'b011xx, `ALU}: present_state <= `dataAddress;
                {5'b100xx, `ALU}: present_state <= `dataAddress;

                {5'b011xx, `dataAddress}: present_state <= `readRam;
                {5'b100xx, `dataAddress}: present_state <= `writeRam;

                {5'bxxxxx, `readRam}: present_state <= `WriteReg; 
                {5'bxxxxx, `writeRam}: present_state <= `IF1;
            
                {5'bxxxxx, `WriteReg}: present_state <= `IF1;

                //halt
                9'b111xxxxxx: present_state <= `HALT;
            endcase
        end
    end

    always @* begin
        begin
            //reset everything
            loada = 1'b0; loadb = 1'b0; asel = 1'b0; bsel = 1'b0; loadc = 1'b0; 
            loads = 1'b0; nsel = 3'b000; vsel = 4'b0000; write = 1'b0;
            addr_sel = 0; load_ir = 0; mem_cmd = `MNONE; reset_pc = 0;
        end
        case(present_state)
            `RST: 
		        begin
		            load_pc = 1; reset_pc = 1;
		        end
            `IF1:
                begin
                    addr_sel = 1; mem_cmd = `MREAD; reset_pc = 0; load_pc = 0;
                end
            `IF2:
                begin
                    addr_sel = 1; load_ir = 1; mem_cmd = `MREAD; load_pc = 0; reset_pc = 0;
                end
            `updatePC:
                begin
                    load_pc = 1; reset_pc = 0;
                end
            `decode:
                load_pc = 0;
            `getA: 
                begin
                    nsel = 3'b001; loada = 1; load_pc = 0; reset_pc = 0;
                end
            `getB: 
                begin
                    case(opcode)
                        3'b011: 
                            begin
                                nsel = 3'b010; loadb = 1; load_pc = 0;
                            end
                        3'b100: 
                            begin
                                nsel = 3'b010; loadb = 1; load_pc = 0;
                            end
                        default: 
                            begin
                                nsel = 3'b100; loadb = 1; load_pc = 0;
                            end
                    endcase
                end
            `ALU:   
                begin
                    casex({ALUop,opcode})
                        5'b00110: 
                            begin
                                asel = 1; bsel = 0; loadc = 1; loads = 0; load_pc = 0;
                            end
                        5'b00101: 
                            begin
                                asel = 0; bsel = 0; loadc = 1; loads = 0; load_pc = 0;
                            end
                        5'b01xxx: 
                            begin
                                asel = 0; bsel = 0; loadc = 1; loads = 1; load_pc = 0;
                            end
                        5'b10xxx: 
                            begin
                                asel = 0; bsel = 0; loadc = 1; loads = 0; load_pc = 0;
                            end
                        5'b11xxx: 
                            begin 
                                asel = 0; bsel = 0; loadc = 1; loads = 0; load_pc = 0;
                            end
                        5'b00011:
                            begin 
                                asel = 0; bsel = 1; loadc = 1; loads = 0; load_pc = 0;
                            end
                        5'b00100:
                            begin 
                                asel = 0; bsel = 1; loadc = 1; loads = 0; load_pc = 0;
                            end
                    endcase
                end
            `WriteReg: 
                begin
                    casex(ALUop)
                        2'b01: 
                            begin
                                nsel = 3'b010; vsel = 4'b1000; write = 0; load_pc = 0;
                            end
                        2'b00:
                            begin
                                nsel = 3'b010; vsel = 4'b0001; write = 1; load_pc = 0; mem_cmd = `MREAD;
                            end
                        default: 
                            begin
                                nsel = 3'b010; vsel = 4'b1000; write = 1; load_pc = 0;
                            end
                    endcase
                end
            `WriteImm: 
                begin
                    nsel = 3'b001; vsel = 4'b0010; write = 1; load_pc = 0;
                end
            `readRam:
                begin
                    mem_cmd = `MREAD; addr_sel = 0; 
                end
            `writeRam:
                begin
                    mem_cmd = `MWRITE; addr_sel = 0; 
                end
            `dataAddress:
                begin
                    case (opcode)
                        3'b100: 
                            begin
                                asel = 1; bsel = 0; loadc = 1; load_addr = 1;
                            end
                        3'b011:
                            begin
                                asel = 0; bsel = 0; loadc = 0; load_addr = 1;
                            end        
                        default:
                            begin
                                asel = 0; bsel = 0; loadc = 0; load_addr = 0;
                            end               
                    endcase    
                end
        endcase
    end

    //pc MUX
    always @(*) begin
        case (reset_pc)
            1'b1: next_pc = 9'b0;
            1'b0: next_pc = PC + 1'b1;
            default: next_pc = 9'bxxxxxxxxx;
        endcase
    end

        //program counter loader
    always @(posedge clk) begin
        if (load_pc)
            PC = next_pc;
    end
    
    //addr_sel MUX
    always @(*) begin
        case (addr_sel)
            1'b0: mem_addr = dataAddress_out;
            1'b1: mem_addr = PC;
            default: mem_addr = 9'bxxxxxxxxx;
        endcase
    end

    //data address loader
    always @(posedge clk) begin
        if (load_addr == 1'b1)
            dataAddress_out = datapath_out[8:0];
    end

    //set mdata to read_data constantly
    always @(*) begin
        mdata = read_data;
    end

endmodule

//load enabled flip flop
module cpuflipflop(clk,D,load,Q);
  input clk;
  input [15:0] D;
  input load;
  output reg [15:0] Q;

  always @(posedge clk) begin
    if(load)
      Q <= D;
  end
endmodule