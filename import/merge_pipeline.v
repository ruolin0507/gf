//流水线合并
module merge_pipeline
#(
  parameter DW = 32,  //输入三元组的宽度
  parameter SW = 8,   //通道号的宽度
  parameter SHW = 32,
  parameter THW = 6,  //THW = O_TAM_WIDTH ，需要合并 2^THW 个数据帧
  parameter THHW = 32,
  parameter FIFO_DEPTH_WIDTH = 6
)
(
  input  clk,
  input  reset,
  
  output reg i_ready,
  input  i_valid,
  input  i_last,
  input  [DW-1:0] i_data,
  input  [SHW-1:0] i_sh,
  input  [THHW-1:0] i_thh,
  output reg i_id,
  output reg [THW:0] i_th,
  
  input  o_ready,
  output reg o_valid,
  output reg o_last,
  output reg [DW-1:0] o_data,     //排序后的三元组
  output reg [THW-1:0] o_th,      //o_data 的时间高位
  output reg [SHW-1:0] o_sh,
  output reg [THHW-1:0] o_thh,
  output reg o_id
);

wire  i_ready0;
reg   i_valid0;
reg   i_last0;
reg   [DW-1:0] i_data0;
reg   [SHW-1:0] i_sh0;
reg   [THHW-1:0] i_thh0;
wire  [THW:0] ptr0;

reg   o_ready0;
wire  o_valid0;
wire  o_last0;
wire  [DW-1:0] o_data0;
wire  [THW-1:0] o_th0;
wire  [SHW-1:0] o_sh0;
wire  [THHW-1:0] o_thh0;

wire  i_ready1;
reg   i_valid1;
reg   i_last1;
reg   [DW-1:0] i_data1;
reg   [SHW-1:0] i_sh1;
reg   [THHW-1:0] i_thh1;
wire  [THW:0] ptr1;

reg   o_ready1;
wire  o_valid1;
wire  o_last1;
wire  [DW-1:0] o_data1;
wire  [THW-1:0] o_th1;
wire  [SHW-1:0] o_sh1;
wire  [THHW-1:0] o_thh1;

// 两个合并模块轮流工作
// i_id 表示正在输入的合并模块的编号
// o_id 表示正在输出的合并模块的编号
always@(i_id)
  if(i_id == 0)
    begin
      i_ready <= i_ready0;
      i_valid0 <= i_valid;
      i_last0 <= i_last;
      i_data0 <= i_data;
      i_sh0 <= i_sh;
      i_thh0 <= i_thh;
      i_valid1 <= 0;
      i_last1 <= 0;
      i_data1 <= 0;
      i_sh1 <= 0;
      i_thh1 <= 0;
      i_th <= ptr0;
    end
  else
    begin
      i_ready <= i_ready1;
      i_valid0 <= 0;
      i_last0 <= 0;
      i_data0 <= 0;
      i_sh0 <= 0;
      i_thh0 <= 0;
      i_valid1 <= i_valid;
      i_last1 <= i_last;
      i_data1 <= i_data;
      i_sh1 <= i_sh;
      i_thh1 <= i_thh;
      i_th <= ptr1;
    end

always@(o_id)
  if(o_id == 0)
    begin
      o_ready0 <= o_ready;
      o_ready1 <= 0;
      o_valid <= o_valid0;
      o_last <= o_last0;
      o_data <= o_data0;
      o_th <= o_th0;
      o_sh <= o_sh0;
      o_thh <= o_thh0;
    end
  else
    begin
      o_ready0 <= 0;
      o_ready1 <= o_ready;
      o_valid <= o_valid1;
      o_last <= o_last1;
      o_data <= o_data1;
      o_th <= o_th1;
      o_sh <= o_sh1;
      o_thh <= o_thh1;
    end

//输入 2**THW 个数据帧后跳到下一个合并模块
always@(posedge clk)
  if(reset)
    i_id <= 0;
  else
    if(i_th >= 2**THW)
      i_id <= ~i_id;

//输出 1 个数据帧后跳到下一个合并模块
always@(posedge clk)
  if(reset)
    o_id <= 0;
  else
    if(o_last)
      o_id <= ~o_id;

merge_fifo #(  .DW(DW),  .SW(SW),  .SHW(SHW),  .THW(THW),  .THHW(THHW),  .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)  )
merge_fifo0
(
  .clk(clk),  .reset(reset),
  .i_ready(i_ready0),  .i_valid(i_valid0),  .i_last(i_last0),  .i_data(i_data0),  .i_sh(i_sh0),  .i_thh(i_thh0),  .ptr(ptr0),
  .o_ready(o_ready0),  .o_valid(o_valid0),  .o_last(o_last0),  .o_data(o_data0),  .o_th(o_th0),  .o_sh(o_sh0),  .o_thh(o_thh0)
);

merge_fifo #(  .DW(DW),  .SW(SW),  .SHW(SHW),  .THW(THW),  .THHW(THHW),  .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)  )
merge_fifo1
(
  .clk(clk),  .reset(reset),
  .i_ready(i_ready1),  .i_valid(i_valid1),  .i_last(i_last1),  .i_data(i_data1),  .i_sh(i_sh1),  .i_thh(i_thh1),  .ptr(ptr1),
  .o_ready(o_ready1),  .o_valid(o_valid1),  .o_last(o_last1),  .o_data(o_data1),  .o_th(o_th1),  .o_sh(o_sh1),  .o_thh(o_thh1)
);

endmodule