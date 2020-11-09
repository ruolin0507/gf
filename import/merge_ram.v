//基于RAM的合并
module merge_ram
#(
  parameter SW = 4,     //通道号的宽度
  parameter THW = 2,    //THW = O_TAM_WIDTH ，需要合并 2^THW 个数据帧
  parameter DW = 8,     //输入三元组的宽度
  parameter  [5:0]     I_SID                    =6'h00     ,
  parameter  [1:0]     I_DBT                    =2'b01     ,    //必须为2'b00
  parameter            I_FLEN                   =24        ,     
  parameter            I_DMASK_WIDTH            =24        ,
  parameter            I_DMASK_OFFSET           =0         ,
  parameter            I_TMASK_WIDTH            =0         ,
  parameter            I_TMASK_OFFSET           =0         ,
  parameter            I_SMASK_WIDTH            =0         ,
  parameter            I_SMASK_OFFSET           =0         ,
  parameter            I_MTAR_WIDTH             =32        ,
  parameter            I_MSAR_WIDTH             =16        ,
  parameter            I_TSF                    =1         ,          
  parameter            I_DATA_WIDTH             =24        ,
  parameter  [3:0]     I_DDN                    =4'h1      ,
  parameter  [11:0]    I_DFF                    =12'hB00   ,
  parameter            I_SFL_WIDTH              =32        ,
  parameter            I_DSFL                   =772       ,          
  parameter            I_FDSTI_WIDTH            =28        ,
  parameter            I_FDSSI_WIDTH            =12        ,
  parameter            I_DBN                    =1         ,           
  parameter            I_BN_WIDTH               =8         , 
  parameter            I_STI_WIDTH              =8         ,
  parameter            I_TIL_WIDTH              =8         ,
  parameter            I_DTIL                   =16        ,        
  parameter            I_SSI_WIDTH              =8         ,
  parameter            I_SIL_WIDTH              =8         ,
  parameter            I_DSIL                   =16        ,        
  parameter            I_BL_WIDTH               =16        ,
  parameter            I_DBL                    =768       ,           
  parameter            I_TAM_WIDTH              =0         ,
  parameter            I_TAM_OFFSET             =0         ,
  parameter            I_SAM_WIDTH              =0         ,
  parameter            I_SAM_OFFSET             =0         ,
  parameter            I_TOM_WIDTH              =0         ,
  parameter            I_TOM_OFFSET             =2         ,
  parameter            I_SOM_WIDTH              =0         ,
  parameter            I_SOM_OFFSET             =2         ,
  parameter            I_OUTBAND_WIDTH          =16        ,
        
  parameter  [5:0]     O_SID                    =6'h00     ,
  parameter  [1:0]     O_DBT                    =2'b00     ,    //必须为2'b00    
  parameter            O_FLEN                   =24        ,     
  parameter            O_DMASK_WIDTH            =24        ,
  parameter            O_DMASK_OFFSET           =0         ,
  parameter            O_TMASK_WIDTH            =0         ,
  parameter            O_TMASK_OFFSET           =0         ,
  parameter            O_SMASK_WIDTH            =0         ,
  parameter            O_SMASK_OFFSET           =0         ,
  parameter            O_MTAR_WIDTH             =32        ,
  parameter            O_MSAR_WIDTH             =16        ,
  parameter            O_TSF                    =1         ,          
  parameter            O_DATA_WIDTH             =24        ,
  parameter  [3:0]     O_DDN                    =4'h1      ,
  parameter  [11:0]    O_DFF                    =12'hB00   ,
  parameter            O_SFL_WIDTH              =32        ,
  parameter            O_DSFL                   =772       ,          
  parameter            O_FDSTI_WIDTH            =28        ,
  parameter            O_FDSSI_WIDTH            =12        ,
  parameter            O_DBN                    =1         ,           
  parameter            O_BN_WIDTH               =8         , 
  parameter            O_STI_WIDTH              =8         ,    
  parameter            O_TIL_WIDTH              =8         ,    
  parameter            O_DTIL                   =16        ,        
  parameter            O_SSI_WIDTH              =8         ,
  parameter            O_SIL_WIDTH              =8         ,
  parameter            O_DSIL                   =16        ,        
  parameter            O_BL_WIDTH               =16        ,
  parameter            O_DBL                    =768       ,           
  parameter            O_TAM_WIDTH              =2         ,
  parameter            O_TAM_OFFSET             =2         ,
  parameter            O_SAM_WIDTH              =2         ,
  parameter            O_SAM_OFFSET             =2         ,
  parameter            O_TOM_WIDTH              =0         ,
  parameter            O_TOM_OFFSET             =4         ,
  parameter            O_SOM_WIDTH              =1         ,
  parameter            O_SOM_OFFSET             =3         ,
  parameter            O_OUTBAND_WIDTH          =16        ,

  parameter            RAM_AW                   = 8,
  parameter            FIFO_NUM_OBLK            =O_TOM_OFFSET-O_TAM_OFFSET,
  parameter            O_BLK_WITH               =O_SOM_OFFSET-O_SAM_OFFSET,
  parameter            INBL_CNT_MAX             = 8,
  parameter            INFO_DATA_WIDTH          =I_FDSSI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH+INBL_CNT_MAX  ,
  parameter            FIFO_DEPTH_WIDTH        = 4
)
(
  input  clk,
  input  reset,
  
  input   [1:0]                             SDMFi_d_EFF,                    // Stream Frame Flag, EFF（Empty Frame Flag）为非2'b00时为空数据帧
  input   [1:0]                             SDMFi_d_PCF,                    // Process Control Flag, 01=停止, 10=起始
  input   [I_SFL_WIDTH-1:0]                 SDMFi_d_SFL,                    // Stream Frame Length  
  input   [I_FDSTI_WIDTH-1:0]               SDMFi_d_FDSTI,                  // Father Domain Start Time Index 
  input   [I_FDSSI_WIDTH-1:0]               SDMFi_d_FDSSI,                  // Father Domain Start Space Index 
  input   [I_BN_WIDTH-1:0]                  SDMFi_d_BN,                     // Block Number
  input   [1:0]                             SDMFi_d_FI_valid,                                                  

  input   [I_STI_WIDTH-1:0]                 SDMFi_d_STI,                    // Start Time Index
  input   [I_TIL_WIDTH-1:0]                 SDMFi_d_TIL,                    // Time Index Length
  input   [I_SSI_WIDTH-1:0]                 SDMFi_d_SSI,                    // Start Space Index
  input   [I_SIL_WIDTH-1:0]                 SDMFi_d_SIL,                    // Space Index Length
  input   [I_BL_WIDTH-1:0]                  SDMFi_d_BL,                     // Block length
  input   [1:0]                             SDMFi_d_BI_valid,                

  input                                     SDMFi_d_tvalid,
  output                                    SDMFi_d_tready,
  input                                     SDMFi_d_tlast,
  input   [I_DATA_WIDTH/8-1:0]              SDMFi_d_tkeep,   
  input   [I_DATA_WIDTH-1:0]                SDMFi_d_tdata,
  input   [DEFAULT_CTRL_WORD_WIDTH-1:0]     SDMFi_d_SFT,
  input   [I_OUTBAND_WIDTH-1:0]             SDMFi_d_outband,                // outband data
  input                                     SDMFi_d_frame_valid,            // valid during the whole frame
  input                                     SDMFi_d_frame_last,
  output                                    SDMFi_d_EF_ack,                 // acknowledge signal for empty frame 
 //output signal
  output  [1:0]                             SDMFo_d_EFF,
  output  [1:0]                             SDMFo_d_PCF,                    // Process Control Flag, 01=停止, 10=起始
  output  [O_SFL_WIDTH-1:0]                 SDMFo_d_SFL,
  output  [O_FDSTI_WIDTH-1:0]               SDMFo_d_FDSTI,                  // Father Domain Start Time Index 
  output  [O_FDSSI_WIDTH-1:0]               SDMFo_d_FDSSI,
  output  [O_BN_WIDTH-1:0]                  SDMFo_d_BN, 
  output  [1:0]                             SDMFo_d_FI_valid,                                                  

  output  [O_STI_WIDTH-1:0]                 SDMFo_d_STI,                    // Start Time Index
  output  [O_TIL_WIDTH-1:0]                 SDMFo_d_TIL,                    // Time Index Length
  output  [O_SSI_WIDTH-1:0]                 SDMFo_d_SSI,                    // Start Space Index
  output  [O_SIL_WIDTH-1:0]                 SDMFo_d_SIL,                    // Space Index Length
  output  [O_BL_WIDTH-1:0]                  SDMFo_d_BL, 
  output  [1:0]                             SDMFo_d_BI_valid,                

  output                                    SDMFo_d_tvalid,
  input                                     SDMFo_d_tready,
  output                                    SDMFo_d_tlast,
  output  [O_DATA_WIDTH/8-1:0]              SDMFo_d_tkeep,
  output  [O_DATA_WIDTH-1:0]                SDMFo_d_tdata,
  output  [DEFAULT_CTRL_WORD_WIDTH-1:0]     SDMFo_d_SFT,
  output  [O_OUTBAND_WIDTH-1:0]             SDMFo_d_outband,
  output  reg                               SDMFo_d_frame_valid,            // valid during the whole frame
  output  reg                               SDMFo_d_frame_last,            // valid during the whole frame
  input                                     SDMFo_d_EF_ack,

  output reg o_valid,
  output o_last,
  output reg [THW-1:0] o_th,      //o_data 的时间高位
  output reg [DW-1:0] o_data,     //排序后的三元组
  input  o_ready
);

wire [2**FIFO_NUM_OBLK-1:0]                        fifo_wrreq;
wire [I_DATA_WIDTH*(2**FIFO_NUM_OBLK)-1:0]         fifo_data;
wire [2**FIFO_NUM_OBLK-1:0]                        fifo_wt;
wire [2**FIFO_NUM_OBLK-1:0]                        fifo_empty;
wire [(FIFO_DEPTH_WIDTH+1)*(2**FIFO_NUM_OBLK)-1:0] fifo_count;

wire                            valid_o;
wire                            wt_o;
wire [FIFO_NUM_OBLK-1:0]        th_o;
wire [I_DATA_WIDTH-1:0]         data_o;

wire rst;

reg [O_TMASK_WIDTH-1:0]               SDMFo_d_t;
reg [O_SMASK_WIDTH-1:0]               SDMFo_d_s;
wire[O_SAM_OFFSET+I_FDSSI_WIDTH-1:0]  ab_s;
wire[O_TAM_OFFSET+I_FDSTI_WIDTH-1:0]  ab_t; 
assign rst = reset || (o_last && o_ready);

assign o_last = ~valid_o && ~wt_o;

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

in_ram_out #(
      .I_SID(I_SID),
      .I_DBT(I_DBT),
      .I_FLEN(I_FLEN),
      .I_DMASK_WIDTH(I_DMASK_WIDTH),
      .I_DMASK_OFFSET(I_DMASK_OFFSET),
      .I_TMASK_WIDTH(I_TMASK_WIDTH),
      .I_TMASK_OFFSET(I_TMASK_OFFSET),
      .I_SMASK_WIDTH(I_SMASK_WIDTH),
      .I_SMASK_OFFSET(I_SMASK_OFFSET),
      .I_MTAR_WIDTH(I_MTAR_WIDTH),
      .I_MSAR_WIDTH(I_MSAR_WIDTH),
      .I_TSF(I_TSF),
      .I_DATA_WIDTH(I_DATA_WIDTH),
      .I_DDN(I_DDN),
      .I_DFF(I_DFF),
      .I_SFL_WIDTH(I_SFL_WIDTH),
      .I_DSFL(I_DSFL),
      .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
      .I_FDSSI_WIDTH(I_FDSSI_WIDTH),
      .I_DBN(I_DBN),
      .I_BN_WIDTH(I_BN_WIDTH),
      .I_STI_WIDTH(I_STI_WIDTH),
      .I_TIL_WIDTH(I_TIL_WIDTH),
      .I_DTIL(I_DTIL),
      .I_SSI_WIDTH(I_SSI_WIDTH),
      .I_SIL_WIDTH(I_SIL_WIDTH),
      .I_DSIL(I_DSIL),
      .I_BL_WIDTH(I_BL_WIDTH),
      .I_DBL(I_DBL),
      .I_TAM_WIDTH(I_TAM_WIDTH),
      .I_TAM_OFFSET(I_TAM_OFFSET),
      .I_SAM_WIDTH(I_SAM_WIDTH),
      .I_SAM_OFFSET(I_SAM_OFFSET),
      .I_TOM_WIDTH(I_TOM_WIDTH),
      .I_TOM_OFFSET(I_TOM_OFFSET),
      .I_SOM_WIDTH(I_SOM_WIDTH),
      .I_SOM_OFFSET(I_SOM_OFFSET),
      .I_OUTBAND_WIDTH(I_OUTBAND_WIDTH),
      .O_SID(O_SID),
      .O_DBT(O_DBT),
      .O_FLEN(O_FLEN),
      .O_DMASK_WIDTH(O_DMASK_WIDTH),
      .O_DMASK_OFFSET(O_DMASK_OFFSET),
      .O_TMASK_WIDTH(O_TMASK_WIDTH),
      .O_TMASK_OFFSET(O_TMASK_OFFSET),
      .O_SMASK_WIDTH(O_SMASK_WIDTH),
      .O_SMASK_OFFSET(O_SMASK_OFFSET),
      .O_MTAR_WIDTH(O_MTAR_WIDTH),
      .O_MSAR_WIDTH(O_MSAR_WIDTH),
      .O_TSF(O_TSF),
      .O_DATA_WIDTH(O_DATA_WIDTH),
      .O_DDN(O_DDN),
      .O_DFF(O_DFF),
      .O_SFL_WIDTH(O_SFL_WIDTH),
      .O_DSFL(O_DSFL),
      .O_FDSTI_WIDTH(O_FDSTI_WIDTH),
      .O_FDSSI_WIDTH(O_FDSSI_WIDTH),
      .O_DBN(O_DBN),
      .O_BN_WIDTH(O_BN_WIDTH),
      .O_STI_WIDTH(O_STI_WIDTH),
      .O_TIL_WIDTH(O_TIL_WIDTH),
      .O_DTIL(O_DTIL),
      .O_SSI_WIDTH(O_SSI_WIDTH),
      .O_SIL_WIDTH(O_SIL_WIDTH),
      .O_DSIL(O_DSIL),
      .O_BL_WIDTH(O_BL_WIDTH),
      .O_DBL(O_DBL),
      .O_TAM_WIDTH(O_TAM_WIDTH),
      .O_TAM_OFFSET(O_TAM_OFFSET),
      .O_SAM_WIDTH(O_SAM_WIDTH),
      .O_SAM_OFFSET(O_SAM_OFFSET),
      .O_TOM_WIDTH(O_TOM_WIDTH),
      .O_TOM_OFFSET(O_TOM_OFFSET),
      .O_SOM_WIDTH(O_SOM_WIDTH),
      .O_SOM_OFFSET(O_SOM_OFFSET),
      .O_OUTBAND_WIDTH(O_OUTBAND_WIDTH),
      .RAM_AW(RAM_AW),
      .FIFO_NUM_OBLK(FIFO_NUM_OBLK),
      .O_BLK_WITH(O_BLK_WITH),
      .INBL_CNT_MAX(INBL_CNT_MAX),
      .INFO_DATA_WIDTH(INFO_DATA_WIDTH),
      .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)
    ) inst_in_ram_out (
      .clk                 (clk),
      .rst                 (rst),
      .SDMFi_d_EFF         (SDMFi_d_EFF),
      .SDMFi_d_PCF         (SDMFi_d_PCF),
      .SDMFi_d_SFL         (SDMFi_d_SFL),
      .SDMFi_d_FDSTI       (SDMFi_d_FDSTI),
      .SDMFi_d_FDSSI       (SDMFi_d_FDSSI),
      .SDMFi_d_BN          (SDMFi_d_BN),
      .SDMFi_d_FI_valid    (SDMFi_d_FI_valid),
      .SDMFi_d_STI         (SDMFi_d_STI),
      .SDMFi_d_TIL         (SDMFi_d_TIL),
      .SDMFi_d_SSI         (SDMFi_d_SSI),
      .SDMFi_d_SIL         (SDMFi_d_SIL),
      .SDMFi_d_BL          (SDMFi_d_BL),
      .SDMFi_d_BI_valid    (SDMFi_d_BI_valid),
      .SDMFi_d_tvalid      (SDMFi_d_tvalid),
      .SDMFi_d_tready      (SDMFi_d_tready),
      .SDMFi_d_tlast       (SDMFi_d_tlast),
      .SDMFi_d_tkeep       (SDMFi_d_tkeep),
      .SDMFi_d_tdata       (SDMFi_d_tdata),
      .SDMFi_d_SFT         (SDMFi_d_SFT),
      .SDMFi_d_outband     (SDMFi_d_outband),
      .SDMFi_d_frame_valid (SDMFi_d_frame_valid),
      .SDMFi_d_frame_last  (SDMFi_d_frame_last),
      .SDMFi_d_EF_ack      (SDMFi_d_EF_ack),

      .info                (info),
      .info_tready         (info_tready),
      .info_tvalid         (info_tvalid),

      .fifo_wrreq          (fifo_wrreq),
      .fifo_data           (fifo_data),
      .fifo_wt             (fifo_wt),
      .fifo_empty          (fifo_empty),
      .fifo_count          (fifo_count)
    );

cpr_fifo #(
      .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH),
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
      .O_SOM_OFFSET(O_SOM_OFFSET),
      .INBL_CNT_MAX(INBL_CNT_MAX),
      .I_SID(I_SID),
      .I_DBT(I_DBT),
      .I_FLEN(I_FLEN),
      .I_DMASK_WIDTH(I_DMASK_WIDTH),
      .I_DMASK_OFFSET(I_DMASK_OFFSET),
      .I_TMASK_WIDTH(I_TMASK_WIDTH),
      .I_TMASK_OFFSET(I_TMASK_OFFSET),
      .I_SMASK_WIDTH(I_SMASK_WIDTH),
      .I_SMASK_OFFSET(I_SMASK_OFFSET),
    ) inst_cpr_fifo (
      .clk         (clk),
      .rst         (rst),

      .wrreq       (fifo_wrreq),
      .data        (fifo_data),
      .wt          (fifo_wt),
      .full        (),
      .empty       (fifo_empty),
      .count       (fifo_count),

      .info_tready (info_tready),
      .info_tvalid (info_tvalid),
      .info        (info),

      .valid_o_d1     (valid_o),
      .wt_o_d1        (wt_o),
      .FDSSI_o_d1     (FDSSI_o),
      .FDSTI_o_all_d1 (FDSTI_o),
      .SSI_o_d1       (SSI_o),
      .s_o_d1         (s_o),
      .ready_o        (o_ready),
      .o_blk_tlast    (o_blk_tlast),
      .o_frame_last   (o_frame_last)
    );
//目前只考虑了非空帧；
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFo_d_frame_valid<=0;
  end
  //若没有下一个数据帧发送来
  else if (SDMFo_d_frame_last&&SDMFo_d_frame_valid&&(!valid_o)) begin
    SDMFo_d_frame_valid<=0;
  end
  else if (valid_o) begin
    SDMFo_d_frame_valid<=1;
  end
end
//SDMFo_d_s/SDMFo_d_t为父数据域的新的data中的s,t
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFo_d_FDSTI<=0;
    SDMFo_d_STI<=0;
    SDMFo_d_t<=0;
  end
  else if (valid_o&&o_ready) begin
    SDMFo_d_FDSTI<=FDSTI_o>>O_TAM_WIDTH;
    SDMFo_d_STI<=ab_t[O_TAM_WIDTH+O_TAM_OFFSET-1:0]>>O_TOM_OFFSET;
    SDMFo_d_t<=ab_t[O_TOM_OFFSET-1:0];
  end
end
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFo_d_FDSSI<=0;
    SDMFo_d_SSI<=0;
    SDMFo_d_s<=0;
  end
  else if (valid_o&&o_ready) begin
    SDMFo_d_FDSSI<=PN_ADDR;
    SDMFo_d_SSI<=ab_s[O_SAM_OFFSET+O_SAM_WIDTH-1:0]>>O_SOM_OFFSET;
    SDMFo_d_s<=ab_s[O_SOM_OFFSET-1:0];
  end
end
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFo_d_tdata<=0;
    SDMFo_d_tvalid<=0;
    SDMFo_d_tlast<=0;
    SDMFo_d_frame_last<=0;
  end
  else if (o_ready) begin
    SDMFo_d_tdata<={SDMFo_d_s,SDMFo_d_t,data_o[I_DMASK_WIDTH-1:0]};
    SDMFo_d_tvalid<=valid_o;
    SDMFo_d_tlast<=o_blk_tlast;
    SDMFo_d_frame_last<=o_frame_last;
  end
end
//绝对的时间空间地址
assign ab_t =FDSTI_o<<O_TAM_OFFSET+STI_o<<I_TOM_OFFSET+t ;
assign ab_s =FDSSI_o<<O_SAM_OFFSET+SSI_o<<I_SOM_OFFSET+s ;
assign SDMFo_d_s = ab_s[O_SOM_OFFSET-1:0];
assign SDMFo_d_t = ab_t[O_TOM_OFFSET-1:0];



always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFo_d_FI_valid<=0;
  end
  else if(SDMFo_d_frame_last&&SDMFo_d_frame_valid&&(!valid_o)) begin
    SDMFo_d_FI_valid<=0;
  end
  else if (valid_o) begin
    SDMFo_d_FI_valid<=2'b1;
  end
end
endmodule