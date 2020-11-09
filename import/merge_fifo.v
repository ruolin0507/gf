//基于FIFO的合并
module merge_fifo
#(
  parameter DW = 8,   //输入三元组的宽度
  parameter SW = 4,   //通道号的宽度
  parameter SHW = 32,
  parameter THW = 2,  //THW = O_TAM_WIDTH ，需要合并 2^THW 个数据帧
  parameter THHW = 32,
  parameter FIFO_DEPTH_WIDTH = 8
)
(
  input  clk,
  input  reset,
  
  output i_ready,
  input  i_valid,
  input  i_last,
  input  [DW-1:0] i_data,
  input  [SHW-1:0] i_sh,
  input  [THHW-1:0] i_thh,
  output reg [THW:0] ptr,
  
  input  o_ready,
  output reg o_valid,
  output o_last,
  output reg [DW-1:0] o_data,     //排序后的三元组
  output reg [THW-1:0] o_th,      //o_data 的时间高位
  output reg [SHW-1:0] o_sh,
  output reg [THHW-1:0] o_thh
);

wire [2**THW-1:0] wrreq_w;
wire [DW*(2**THW)-1:0] data_w;
wire [2**THW-1:0] full_w;
reg  [2**THW-1:0] wt_r;
reg  [2**THW-1:0] wt_r_2;

wire rst;
assign rst = reset || (o_last && o_ready);

// ptr 表示当前正在写入的FIFO编号 (0<= ptr <= 2**THW-1) 
// ptr 从0开始，依次递增，每输入一个数据帧 ptr 加一
// ptr = 2**THW 时表示输入结束
assign i_ready = (ptr < 2**THW) && (full_w[ptr] == 0);
assign wrreq_w = (ptr < 2**THW) ? (i_valid << ptr) : 0;

genvar i;
generate for (i=0; i<2**THW; i=i+1) begin: data_i

  assign data_w[(i+1)*DW-1:i*DW] = i_data;

end
endgenerate
// wt_r = 0 表示当前数据帧已经全部写入FIFO
integer k;
always@(posedge clk)
  if(rst)
    begin
      ptr <= 0;
      for (k=0; k<2**THW; k=k+1)
        wt_r[k] <= 1;
    end
  else
    if(i_last && i_ready)
      begin
        wt_r[ptr] <= 0;
        ptr <= ptr + 1;
      end

always@(posedge clk)
  if(rst)
    for (k=0; k<2**THW; k=k+1)
      wt_r_2[k] <= 1;
  else
    wt_r_2 <= wt_r;

wire valid_o;
wire wt_o;
wire [THW-1:0] th_o;
wire [DW-1:0] data_o;
//~valid_o为fifo中无数据帧，~wt_o为数据帧全部到来 wt_o在该次合并的数据帧输出之后会重新恢复为1
assign o_last = ~valid_o && ~wt_o;

cpr_fifo #(.SW(SW),.THW(THW),.DW(DW),.FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)) cpr_fifo_0
(
  .clk(clk),.rst(rst),
  .wrreq(wrreq_w),.data(data_w),.wt(wt_r_2),.full(full_w),
  .valid_o(valid_o),.wt_o(wt_o),.s_o(),.th_o(th_o),.data_o(data_o),.ready_o(o_ready)
);

always@(posedge clk)
  if(rst)
    begin
      o_valid <= 0;
      o_data <= 0;
      o_th <= 0;
    end
  else
    if(o_ready)
      begin
        o_valid <= valid_o;
        o_data <= data_o;
        o_th <= th_o;
      end

always@(posedge clk)
  if(rst)
    begin
      o_sh <= 0;
      o_thh <= 0;
    end
  else
    if(i_valid && i_ready)
      begin
        o_sh <= i_sh;
        o_thh <= i_thh;
      end

endmodule