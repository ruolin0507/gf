//分级合并
module merge_cascade
#(
  parameter DW = 32,  //输入三元组的宽度
  parameter SW = 8,   //通道号的宽度
  parameter THW = 6,  //THW = O_TAM_WIDTH ，需要合并 2^THW 个数据帧
  
  parameter THW1 = THW/2,       //第一级合并 2^THW1 个数据帧
  parameter THW2 = THW - THW1,  //第二级合并 2^THW2 个数据帧
  
  parameter FIFO_DEPTH_WIDTH = 6, //第一级合并FIFO的深度为 2^FIFO_DEPTH_WIDTH
  parameter FIFO_DEPTH_WIDTH2 = FIFO_DEPTH_WIDTH + THW1 //第二级合并FIFO的深度为 2^FIFO_DEPTH_WIDTH2
)
(
  input  clk,
  input  reset,
  
  output i_ready,
  input  i_valid,
  input  i_last,
  input  [DW-1:0] i_data,
  
  input  o_ready,
  output o_valid,
  output o_last,
  output [DW+THW-1:0] o_data2,
  output [DW-1:0] o_data,     //排序后的三元组
  output [THW-1:0] o_th       //o_data 的时间高位
);

wire w_ready;
wire w_valid;
wire w_last;

wire [DW-1:0] w_data1;
wire [THW1-1:0] w_th1;
wire [DW+THW1-1:0] w_data2;
wire [THW2-1:0] w_th2;

//两个流水线合并模块串联
merge_pipeline        //流水线合并模块1
#(  .DW(DW),  .SW(SW),  .THW(THW1),  .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)  )
merge_pipeline_1
(
  .clk(clk),  .reset(reset),
  .i_ready(i_ready),  .i_valid(i_valid),  .i_last(i_last),  .i_data(i_data),
  .o_ready(w_ready),  .o_valid(w_valid),  .o_last(w_last),  .o_data(w_data1),  .o_th(w_th1)
);

merge_pipeline        //流水线合并模块2
#(  .DW(DW+THW1),  .SW(SW),  .THW(THW2),  .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH2)  )
merge_pipeline_2
(
  .clk(clk),  .reset(reset),
  .i_ready(w_ready),  .i_valid(w_valid),  .i_last(w_last),  .i_data(  { w_data1[DW-1:DW-SW] , w_th1 , w_data1[DW-SW-1:0] }  ),
  .o_ready(o_ready),  .o_valid(o_valid),  .o_last(o_last),  .o_data(w_data2),  .o_th(w_th2)
);

//输出三元组的拼接和拆分
assign o_data2 = { w_data2[DW+THW1-1:DW+THW1-SW] , w_th2 , w_data2[DW+THW1-SW-1:0] };
assign o_th = o_data2[DW+THW-1-SW:DW-SW];
assign o_data = {o_data2[DW+THW-1:DW+THW-SW],o_data2[DW-1-SW:0]};

endmodule