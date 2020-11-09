// N 元比较器的输入端连接 N 个 FIFO ， N = 2**THW
//wt晚一个周期
module cpr_fifo
#(
  parameter           FIFO_DEPTH_WIDTH          = 4,
  parameter            I_FDSTI_WIDTH            =28        ,
  parameter            I_FDSSI_WIDTH            =12        ,
  parameter            I_STI_WIDTH              =8         ,        
  parameter            I_SSI_WIDTH              =8         ,          
  parameter            I_TAM_WIDTH              =0         ,
  parameter            I_TAM_OFFSET             =0         ,
  parameter            I_SAM_WIDTH              =0         ,
  parameter            I_SAM_OFFSET             =0         ,
  parameter            I_TOM_WIDTH              =0         ,
  parameter            I_TOM_OFFSET             =2         ,
  parameter            I_SOM_WIDTH              =0         ,
  parameter            I_SOM_OFFSET             =2         ,           
  parameter            O_TAM_WIDTH              =2         ,
  parameter            O_TAM_OFFSET             =2         ,
  parameter            O_SAM_WIDTH              =2         ,
  parameter            O_SAM_OFFSET             =2         ,
  parameter            O_TOM_WIDTH              =0         ,
  parameter            O_TOM_OFFSET             =4         ,
  parameter            O_SOM_WIDTH              =1         ,
  parameter            O_SOM_OFFSET             =3         ,
  parameter  [5:0]     I_SID                    =6'h00     ,
  parameter  [1:0]     I_DBT                    =2'b01     ,    //必须为2'b00
  parameter            I_FLEN                   =24        ,     
  parameter            I_DMASK_WIDTH            =24        ,
  parameter            I_DMASK_OFFSET           =0         ,
  parameter            I_TMASK_WIDTH            =0         ,
  parameter            I_TMASK_OFFSET           =0         ,
  parameter            I_SMASK_WIDTH            =0         ,
  parameter            I_SMASK_OFFSET           =0         ,
  parameter            I_DATA_WIDTH             =I_DMASK_WIDTH+I_TMASK_WIDTH+I_SMASK_OFFSET,
  parameter            IN_OBLK_WIDTH            =O_SOM_OFFSET-O_SAM_OFFSET,
  //每个o_blk中包含的子数据域数据帧的个数
  parameter            FIFO_NUM_O_BLK           =O_TOM_OFFSET-O_TAM_OFFSET,
  //每个输入数据块中最大的个数
  parameter            INBL_CNT_MAX             =8
)
)
(
  input  clk,
  input  rst,

  input  [2**FIFO_NUM_O_BLK-1:0] wrreq,
  input  [I_DATA_WIDTH*(2**FIFO_NUM_O_BLK)-1:0] data,
  input  [2**FIFO_NUM_O_BLK-1:0] wt,
  output [2**FIFO_NUM_O_BLK-1:0] full,
  output [2**FIFO_NUM_O_BLK-1:0] empty,
  output [(FIFO_DEPTH_WIDTH+1)*(2**FIFO_NUM_O_BLK)-1:0] count,
  
  output [O_TAM_WIDTH-1:0]                   info_tready,
  input  [O_TAM_WIDTH-1:0]                   info_tvalid,                                     
  input  [O_TAM_WIDTH*INFO_DATA_WIDTH-1:0]   info ,
//输出的FDSSI_o,FDSTI_o，SSI_o，s_o为子数据域中的值，未变换
  output reg                                     valid_o_d1,
  output reg                                     wt_o_d1,
  output reg                 [I_FDSSI_WIDTH-1:0] FDSSI_o_d1,
  output reg                 [FIFO_NUM_O_BLK-1:0] FDSTI_o_all_d1,//FDSTI_o为FIFO编号，FDSTI_o_all_d1为真实fdsti
  output reg                   [I_SSI_WIDTH-1:0] SSI_o_d1,
  output reg                  [I_SAM_OFFSET-1:0] s_o_d1,
  input                                           ready_o,
  output reg                   [I_DATA_WIDTH-1:0]  data_o_d1,
  output wire                                      o_blk_tlast,//o_blk tlast与valid_o_d1对齐
  output reg                                       o_frame_last

);

  reg  [O_TAM_WIDTH-1:0]                   info_tvalid;                                     
  reg  [O_TAM_WIDTH*INFO_DATA_WIDTH-1:0]   info;
wire [SW*(2**THW)-1:0]  s;
wire [THW*(2**THW)-1:0] th;

  wire                                                valid_o;
  wire                                                wt_o;
  wire                            [I_FDSSI_WIDTH-1:0] FDSSI_o;
  wire                           [FIFO_NUM_O_BLK-1:0] FDSTI_o_all;
  wire                              [I_SSI_WIDTH-1:0] SSI_o;
  wire                             [I_SAM_OFFSET-1:0] s_o;
  wire                             [I_DATA_WIDTH-1:0] data_o;

wire [2**THW-1:0] rdreq;
wire [I_DATA_WIDTH*(2**THW)-1:0] q;

reg[2**FIFO_NUM_O_BLK-1:0]    o_blk_s_bd;
wire[2**FIFO_NUM_O_BLK-1:0]   oblk_bound;
wire                          o_blk_tlast;
reg  [O_TAM_WIDTH-1:0]                   info_tvalid;                                     
reg  [O_TAM_WIDTH*INFO_DATA_WIDTH-1:0]   info ;

wire [I_FDSSI_WIDTH*(2**FIFO_NUM_O_BLK)-1:0]        FDSSI;
wire [I_FDSTI_WIDTH*(2**FIFO_NUM_O_BLK)-1:0]        FDSTI;
wire [I_SSI_WIDTH*(2**FIFO_NUM_O_BLK)-1:0]          SSI;
wire [INBL_CNT_MAX*(2**FIFO_NUM_O_BLK)-1:0]         in_blk_cnt;

wire [I_FDSSI_WIDTH*(2**FIFO_NUM_O_BLK)-1:0]        FDSSI_nxt_inblk;

reg[INBL_CNT_MAX-1:0]                               count[2**FIFO_NUM_O_BLK-1:0];
wire[2**FIFO_NUM_O_BLK-1:0]                         in_blk_tlast;
reg[2**FIFO_NUM_O_BLK-1:0]                          o_blk_s_bd;                                   
wire[2**FIFO_NUM_O_BLK-1:0]                         oblk_bound;


wire [O_SSI_WIDTH-1:0]   o_SSI[FIFO_NUM_O_BLK-1:0];
wire [O_SSI_WIDTH-1:0]   o_SSI_nxt[FIFO_NUM_O_BLK-1:0];//记录上一个块时的o_ssi


reg [O_TOM_WIDTH-1:0]     o_blk_ptr;

//FDSTI_o为fifo号，FDSTI_o_all为实际的子数据域的FDSTI编号
assign  FDSTI_o_all= FDSTI_o+o_blk_ptr*(2**FIFO_NUM_O_BLK);
assign  s_oblk_fdsti= o_blk_ptr*(2**FIFO_NUM_O_BLK);
  cpr_th #(
      .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
      .I_FDSSI_WIDTH(I_FDSSI_WIDTH),
      .I_STI_WIDTH(I_STI_WIDTH),
      .I_SSI_WIDTH(I_SSI_WIDTH),
      .I_TAM_WIDTH(I_TAM_WIDTH),
      .I_TAM_OFFSET(I_TAM_OFFSET),
      .I_SAM_WIDTH(I_SAM_WIDTH),
      .I_SAM_OFFSET(I_SAM_OFFSET),
      .I_TOM_WIDTH(I_TOM_WIDTH),
      .I_TOM_OFFSET(I_TOM_OFFSET),
      .I_SOM_WIDTH(I_SOM_WIDTH),
      .I_SOM_OFFSET(I_SOM_OFFSET),
      .O_TAM_WIDTH(O_TAM_WIDTH),
      .O_TAM_OFFSET(O_TAM_OFFSET),
      .O_SAM_WIDTH(O_SAM_WIDTH),
      .O_SAM_OFFSET(O_SAM_OFFSET),
      .O_TOM_WIDTH(O_TOM_WIDTH),
      .O_TOM_OFFSET(O_TOM_OFFSET),
      .O_SOM_WIDTH(O_SOM_WIDTH),
      .O_SOM_OFFSET(O_SOM_OFFSET)
    ) inst_cpr_th (
      .valid   (valid_in),
      .wt      (wt),
      .FDSSI   (FDSSI),
      .FDSTI   (FDSTI),
      .SSI     (SSI),
      .s       (s),
      .valid_o (valid_o),
      .wt_o    (wt_o),
      .FDSSI_o (FDSSI_o),
      .FDSTI_o (FDSTI_o),
      .SSI_o   (SSI_o),
      .s_o     (s_o)
    );
assign rdreq = valid_o ? (ready_o << FDSTI_o) : 0;                        //从第 FDSTI_o 个FIFO中读取数据，第 FDSTI_o 个FIFO的读使能拉高，其他FIFO的读使能拉低
assign data_o = q [(FDSTI_o+1)*I_DATA_WIDTH-1:FDSTI_o*I_DATA_WIDTH]       //输出第 th_o 个FIFO中的数据
//FI和数据同时有效
//若最后一帧丢失则，s_o_blk_chg在新o_frame的第二个clk才输出，需要oblk_bound在第一个clk就输出
assign valid_in =(~empty)&(info_tvalid_d1[(1+o_blk_ptr)*(2**FIFO_NUM_O_BLK)-1:o_blk_ptr*(2**FIFO_NUM_O_BLK)])&(~o_blk_s_bd) ;

genvar i;
generate for (i=0; i<2**FIFO_NUM_O_BLK; i=i+1) begin: loop_i
  fifo
  #(.WIDTH(I_DATA_WIDTH),.DEPTH_WIDTH(FIFO_DEPTH_WIDTH))
  fifo_i
  (
    .clk(clk),
    .rst(rst),
    .din(data[(i+1)*I_DATA_WIDTH-1:i*I_DATA_WIDTH]),
    .rd_en(rdreq[i]),
    .wr_en(wrreq[i]),
    .empty(empty[i]),                              
    .full(full[i]),
    .dout(q[(i+1)*I_DATA_WIDTH-1:i*I_DATA_WIDTH]),
    .count(count[(i+1)*(FIFO_DEPTH_WIDTH+1)-1:i*(FIFO_DEPTH_WIDTH+1)])
  );

//读对于当前合并的数据的各个fdssi，fdsti，sti，ssi，blknum
  assign s[(i+1)*I_SMASK_WIDTH-1:i*I_SMASK_WIDTH] = q[(i+1)*I_DATA_WIDTH-1:(i+1)*I_DATA_WIDTH-I_SMASK_WIDTH];
 // assign FDSSI[(i+1)*I_FDSSI_WIDTH-1:I_FDSSI_WIDTH*i]=info_d1[(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-1:(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-I_FDSSI_WIDTH];
  assign FDSSI[(i+1)*I_FDSSI_WIDTH-1:I_FDSSI_WIDTH*i]=info_d1[(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-1:(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-I_FDSSI_WIDTH];
  
  assign FDSTI[(i+1)*I_FDSTI_WIDTH-1:I_FDSTI_WIDTH*i] =i ;
  assign SSI[(i+1)*I_SSI_WIDTH-1:I_SSI_WIDTH*i] =info_d1[(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-I_FDSSI_WIDTH-1:(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-I_FDSSI_WIDTH-I_SSI_WIDTH] ;
  assign in_blk_cnt[(i+1)*INBL_CNT_MAX-1:INBL_CNT_MAX*i] =info_d1[(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i)*INFO_DATA_WIDTH+INBL_CNT_MAX-1:(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i)*INFO_DATA_WIDTH] ;
//读取FI_FIF中的下一个数据块的fdssi，fdsti，sti，ssi，blknum
assign FDSSI_nxt_inblk[(i+1)*I_FDSSI_WIDTH-1:I_FDSSI_WIDTH*i]=info[(o_blk_ptr*(2**FIFO_NUM_O_BLK)+i+1)*INFO_DATA_WIDTH-1:(o_blk_ptr+i+1)*INFO_DATA_WIDTH-I_FDSSI_WIDTH]
  
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        count[i]<=0;
      end
      //每输出一个数据，count变化
      else if ((i==FDSTI_o)&&valid_o&&ready_o) begin
      //该in_blk最后一个clk
          if (count[i]==(in_blk_cnt[(i+1)*INBL_CNT_MAX-1:INBL_CNT_MAX*i]-1)) begin
            count[i]<=0;
          end
          else begin
            count[i]<=count[i]+1;
          end
      end
    end
    //在当前数据块的最后一个clk，输出info_tready
    assign in_blk_tlast[i] =info_tvalid_d1[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i]&&(count[i]==(in_blk_cnt[(i+1)*INBL_CNT_MAX-1:INBL_CNT_MAX*i]-1))&&valid_o&&ready_o ;
    assign info_tready[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i] =in_blk_tlast[i]?1'b1:1'b0;
//判断结尾；fifo中的FI当前的O_SSI与下一个O_SSI不同

 assign  o_SSI[i]       =FDSSI[(i+1)*I_FDSSI_WIDTH-1:I_FDSSI_WIDTH*i]>>IN_OBLK_WIDTH ;
 assign  o_SSI_nxt[i] =FDSSI_nxt_inblk[(i+1)*I_FDSSI_WIDTH-1:I_FDSSI_WIDTH*i]>>IN_OBLK_WIDTH  ;

 //判断边界
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    o_blk_s_bd[i]<=0;
  end
  //该周期与下个周期的o_ssi不相同且为in_blk最后一个
   //下个周期没有输入的info且为in_blk最后一个
  else if (oblk_bound[i]) begin
    o_blk_s_bd[i]<=1'b1;
  end
  //为了保证&o_blk_s_bd与valid_o_d1同步,为避免当时ready_o=0,未将数据打出去
  else if ((&o_blk_s_bd)&&ready_o)begin
    o_blk_s_bd[i]<=0;
  end
end
assign oblk_bound[i] =in_blk_tlast[i]&&
                      ((o_SSI[i]!=o_SSI_nxt[i])&&(info_tvalid_d1[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i])&&info_tvalid[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i]|
                        (info_tvalid_d1[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i])&&(!info_tvalid[o_blk_ptr*(2**FIFO_NUM_O_BLK)+i]));
end
endgenerate


always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    o_blk_ptr<=0;
  end
  //到达o_blk边界,最小单位为一个（子数据域）数据帧 
  else if ((&o_blk_s_bd)&&ready_o) begin
    if (o_blk_ptr==2**O_TAM_WIDTH-1) begin
      o_blk_ptr<=0;
    end
    else begin
      o_blk_ptr<=o_blk_ptr+1'b1;
    end
  end
end
//将每一个info延迟一拍输出
//info d1
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    info_d1<=0;
    info_tvalid_d1<=0;
  end
  else if (info_tready) begin
    info_d1<=0;
    info_tvalid_d1<=0;
  end
end

assign o_blk_tlast = &o_blk_s_bd;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    valid_o_d1<=0;
    data_o_d1<=0;
    wt_o_d1<=0;
    FDSSI_o_d1<=0;
    FDSTI_o_all_d1<=0;
    SSI_o_d1<=0;
    s_o_d1<=0;
    data_o_d1<=0;
  end
  else if (ready_o) begin
    
    valid_o_d1<=valid_o;
    data_o_d1<=data_o;
    wt_o_d1<=wt_o;
    FDSSI_o_d1<=FDSSI_o;
    FDSTI_o_all_d1<=FDSTI_o_all;
    SSI_o_d1<=SSI_o;
    s_o_d1<=s_o;
    data_o_d1<=data_o;
  end
end
//一次合并结束
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    o_frame_last<=0;
  end
  else if(o_frame_last)begin
    o_frame_last<=0;
  end
  else if (((&info_tvalid)|(&info_tvalid_d1))==0) begin
    o_frame_last<=1'b1;
  end
end
endmodule