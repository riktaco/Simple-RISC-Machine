module cpu_tb;
  reg clk, reset, s, load_ir;
  reg [15:0] read_data;
  wire [15:0] datapath_out;
  wire N,V,Z,w;
  wire [1:0] mem_cmd;
  wire [8:0] mem_addr;
  reg err;

  cpu DUT(clk,reset,load_ir,datapath_out,N,V,Z,load_pc, mem_addr, mem_cmd, read_data);

  initial begin
    forever begin
      clk = 1; #5;
      clk = 0; #5;
    end
  end

  initial begin
    //reset
    err = 0;
    reset = 1; load_ir = 0; read_data = 16'b0;
    #10;
    reset = 0;

    //MOV R0, #7
    read_data = 16'b1101000000000111;
    #15; //skip initial
    wait(cpu_tb.DUT.present_state == 4'b0001);
    if (cpu_tb.DUT.DP.REGFILE.R0 !== 16'h7) begin
      err = 1;
      $display("FAILED: MOV R0, #7");
      //$stop;
    end 


    //MOV R1, #2
    read_data = 16'b1101000100000010;
    wait(cpu_tb.DUT.present_state == 4'b0001);
    #5;
    if (cpu_tb.DUT.DP.REGFILE.R1 !== 16'h2) begin
      err = 1;
      $display("FAILED: MOV R1, #2");
      //$stop;
    end

    //ADD R2, R1, R0, LSL#1 (with shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010000101001000;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R2 !== 16'h10) begin
      err = 1;
      $display("FAILED: ADD R2, R1, R0, LSL#1");
    end

    //ADD R2, R1, R0 (no shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010000101000000;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R2 !== 16'h9) begin
      err = 1;
      $display("FAILED: ADD R2, R1, R0");
    end

    //MOV R3, #6
    read_data = 16'b1101001100000110;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R3 !== 16'h6) begin
      err = 1;
      $display("FAILED: MOV R3, #6");
      //$stop;
    end

    //MOV R4, R3, LSR#1 (011) (right shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1100000010010011;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R4 !== 16'h3) begin
      err = 1;
      $display("FAILED: MOV R4, R3, LSR#1");
    end

    //CMP R3, R4, LSL#1 (110 - 110)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010101100001100;
    
    
    
    if (cpu_tb.DUT.DP.Z_out !== 3'b001) begin
      err = 1;
      $display("FAILED: CMP R3, R4, LSL#1");
    end

    //AND R5, R3, R4 (011 & 110)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011001110100100;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R5 !== 16'h2) begin
      err = 1;
      $display("FAILED: AND R5, R3, R4");
    end

    //MVN R6, R5 (~010)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011100011000101;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R6 !== 16'b1111111111111101) begin
      err = 1;
      $display("FAILED: MVN R6, R5");
    end

    //MOV R6, #-4
    read_data = 16'b1101011011111100;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R6 !== 16'b1111111111111100) begin
      err = 1;
      $display("FAILED: MOV R6, #-4");
      //$stop;
    end
    
    //ADD R7, R6, R5, LSR#1 (with negative number shift) (-4 + 1)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010011011111101;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R7 !== 16'b1111111111111101) begin
      err = 1;
      $display("FAILED: ADD R7, R6, R5, LSR#1");
    end

    //MOV R0, R1, LSL#1 (100) (left shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1100000000001001;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R0 !== 16'h4) begin
      err = 1;
      $display("FAILED: MOV R0, R1, LSL#1");
    end

    //MOV R1, R0 (100) (no shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1100000000100000;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R1 !== 16'h4) begin
      err = 1;
      $display("FAILED: MOV R1, R0");
    end

    //CMP R3, R4, LSL#1 (zero flag)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010101100001100;
    
    
    
    if (cpu_tb.DUT.DP.Z_out !== 3'b001) begin
      err = 1;
      $display("FAILED: CMP R3, R4, LSL#1");
    end

    //CMP R5, R0 (negative flag) (2-4)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010110100000000;
    
    
    
    if (cpu_tb.DUT.DP.Z_out !== 3'b010) begin
      err = 1;
      $display("FAILED: CMP R5, R0 (negative flag)");
    end

    //AND R2, R0, R1, LSL#1 (100 & 1000) (left shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011000001001001;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R2 !== 16'h0) begin
      err = 1;
      $display("FAILED: AND R2, R0, R1, LSL#1");
    end

    //AND R5, R4, R3, LSR#1 (011 & 011) (right shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011010010110011;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R5 !== 16'h3) begin
      err = 1;
      $display("FAILED: AND R5, R4, R3, LSR#1");
    end

    //MVN R2, R3, LSL#1  (left shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011100001001011;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R2 !== 16'b1111111111110011) begin
      err = 1;
      $display("FAILED: MVN R2, R3, LSL#1");
    end

    //MVN R4, R3, LSR#1  (right shift)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1011100010010011;
    
    
    
    if (cpu_tb.DUT.DP.REGFILE.R4 !== 16'b1111111111111100) begin
      err = 1;
      $display("FAILED: MVN R4, R3, LSR#1");
    end

    //MOV R0, #-1
    read_data = 16'b1101000011111111;
    
    
    

    //MOV R0, #-1
    read_data = 16'b1101000011111111;
    
    
    
    

    //MOV R1, #127
    read_data = 16'b1101000101111111;
    
    
    

    //CMP R1, R0 (overflow flag)
    @(posedge DUT.cpu.PC or negedge DUT.cpu.PC); // wait for falling edge of clock before changing inputs
    read_data = 16'b1010100100000000;
    
    
    
    if (cpu_tb.DUT.DP.Z_out !== 3'b100) begin
      err = 1;
      $display("FAILED: CMP R1, R7, LSL#1 (overflow flag)");
    end

    if (~err) begin
      $display("INTERFACE OK");
      //$stop;
    end
    $stop;
  end
endmodule