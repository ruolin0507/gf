// FWFT FIFO
module fifo
#(
  parameter WIDTH = 8,
  parameter DEPTH_WIDTH = 3
)
(
     input  clk,
     input  rst,
     
     output full,
     input  wr_en,
     input  [WIDTH-1:0] din,
 
     output empty,
     input  rd_en,
     output reg [WIDTH-1:0] dout,
     output [DEPTH_WIDTH:0] count     //FIFO中有效数据的个数
);  

reg [WIDTH-1:0] ram [2**DEPTH_WIDTH-1:0];
reg [DEPTH_WIDTH:0] rp,wp;

wire fifo_empty;
wire fifo_rd_en;

assign count = wp - rp;

assign full = (wp[DEPTH_WIDTH] != rp[DEPTH_WIDTH] && wp[DEPTH_WIDTH-1:0] == rp[DEPTH_WIDTH-1:0]) ? 1 : 0;
assign fifo_empty = (wp == rp) ? 1 : 0;

always@(posedge clk)
  if(rst)
    wp <= 0;
  else
    if(wr_en && ~full)
      begin
        wp <= wp + 1;
        ram[wp[DEPTH_WIDTH-1:0]] <= din;
      end

always@(posedge clk)
  if(rst)
    begin
      rp <= 0;
      dout <= 0;
    end
  else
    if(fifo_rd_en && ~fifo_empty)
      begin
        rp <= rp + 1;
        dout <= ram[rp[DEPTH_WIDTH-1:0]];
      end

reg dout_valid;

assign fifo_rd_en = !fifo_empty && (!dout_valid || rd_en);
assign empty = !dout_valid;

always @(posedge clk)
  if (rst)
    dout_valid <= 0;
  else
    begin
      if (fifo_rd_en)
        dout_valid <= 1;
      else if (rd_en)
        dout_valid <= 0;
    end 

endmodule