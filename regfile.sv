module regfile(data_in,writenum,write,readnum,clk,data_out);
    input [15:0] data_in; //value we want to set the register to
    input [2:0] writenum, readnum; //register to write/read to
    input write, clk; //write: save value of data_in to the register
    output reg [15:0] data_out;

    reg [7:0] writenum_oh;
    reg [7:0] readnum_oh;
    reg [15:0] R0, R1, R2, R3, R4, R5, R6, R7;

    always @(posedge clk) begin
        //multiplexer to assign a register a value
        if(write)
            case(writenum_oh)
                8'b00000001: R0 = data_in;
                8'b00000010: R1 = data_in;
                8'b00000100: R2 = data_in;
                8'b00001000: R3 = data_in;
                8'b00010000: R4 = data_in;
                8'b00100000: R5 = data_in;
                8'b01000000: R6 = data_in;
                8'b10000000: R7 = data_in;
            endcase
    end

    always @* begin
        //3:8 decoder
        case(writenum)
            3'b000: writenum_oh = 8'b00000001;
            3'b001: writenum_oh = 8'b00000010;
            3'b010: writenum_oh = 8'b00000100;
            3'b011: writenum_oh = 8'b00001000;
            3'b100: writenum_oh = 8'b00010000;
            3'b101: writenum_oh = 8'b00100000;
            3'b110: writenum_oh = 8'b01000000;
            3'b111: writenum_oh = 8'b10000000;
            default: writenum_oh = 8'bxxxxxxxx;
        endcase
    end

    always @* begin
        //3:8 decoder
        case(readnum)
            3'b000: readnum_oh = 8'b00000001;
            3'b001: readnum_oh = 8'b00000010;
            3'b010: readnum_oh = 8'b00000100;
            3'b011: readnum_oh = 8'b00001000;
            3'b100: readnum_oh = 8'b00010000;
            3'b101: readnum_oh = 8'b00100000;
            3'b110: readnum_oh = 8'b01000000;
            3'b111: readnum_oh = 8'b10000000;
            default: readnum_oh = 8'bxxxxxxxx;
        endcase
    end

    always @* begin
        //multiplexer to choose what register to read data from
        case (readnum_oh)
            8'b00000001: data_out = R0;
            8'b00000010: data_out = R1;
            8'b00000100: data_out = R2;
            8'b00001000: data_out = R3;
            8'b00010000: data_out = R4;
            8'b00100000: data_out = R5;
            8'b01000000: data_out = R6;
            8'b10000000: data_out = R7;
            default: data_out = 16'bxxxxxxxxxxxxxxxx;
        endcase
    end
endmodule
