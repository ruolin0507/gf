//根据读地址 raddr 和读长度 rlength 从RAM中连续读取数据
module read_memory
#(
  parameter DW = 16,
  parameter RAM_AW = 16
)
(
  input  clk,
  input  reset,
  
  input  ren,
  input  [RAM_AW-1:0] raddr,
  input  [RAM_AW-1:0] rlength,
  
  output dvalid,
  output dlast,
  output [DW-1:0] dout,
  
  output [RAM_AW-1:0] o_raddr,
  input  [DW-1:0] din
);

reg state;
reg [RAM_AW-1:0] addr;
reg [RAM_AW-1:0] length;
reg [RAM_AW-1:0] count;

assign dout = din;
assign o_raddr = addr + count;

always@(posedge clk)
  if(reset)
    state <= 0;
  else
    case(state)
      0:  if(ren) state <= 1;
      1:  if(dlast) state <= 0;
    endcase

always@(posedge clk)
  if(reset)
    begin
      addr <= 0;
      length <= 0;
    end
  else
    if(ren)
      begin
        addr <= raddr;
        length <= rlength;
      end

always@(posedge clk)
  if(reset)
    count <= 0;
  else
    case(state)
      0:  if(ren) count <= 0;
      1:  count <= count + 1;
    endcase

assign dvalid = count > 0 && count <= length;
assign dlast = (count == length) && dvalid;

endmodule