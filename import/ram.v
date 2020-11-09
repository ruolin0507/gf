module ram(
        //input:
        clk,
        wen,
        din,
        waddr,
        raddr,
        //output:
        dout
        );
 
        parameter   DWIDTH = 8; //数据宽度，请根据实际情况修改
        parameter   AWIDTH = 10; //地址宽度，请根据实际情况修改
 
        input clk;
        input wen;
        input [DWIDTH-1:0] din;
        input [AWIDTH-1:0] waddr;
        input   [AWIDTH-1:0] raddr;
        output [DWIDTH-1:0] dout; 
 
        reg [DWIDTH-1:0] RAM [2**AWIDTH-1:0];
        reg [AWIDTH-1:0] raddr_reg;
 
        always @ (posedge clk)
        begin
            if(wen) 
                begin
                RAM[waddr] <= din;
            end
        end
 
        always @ (posedge clk)
        begin
            raddr_reg <= raddr;
        end
 
        assign dout = RAM[raddr_reg];
    endmodule