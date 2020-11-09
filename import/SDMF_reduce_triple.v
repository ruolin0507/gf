//三元组数据帧的合并，仅支持DBT=1
module SDMF_reduce_triple
#(
  parameter  [5:0]     I_SID                    =6'h00     ,
  parameter  [1:0]     I_DBT                    =2'b01     ,    //必须为2'b01
  parameter            I_FLEN                   =24        ,     
  parameter            I_DMASK_WIDTH            =0        ,
  parameter            I_DMASK_OFFSET           =0         ,
  parameter            I_TMASK_WIDTH            =0         ,
  parameter            I_TMASK_OFFSET           =0         ,
  parameter            I_SMASK_WIDTH            =8         ,    //通道号的宽度
  parameter            I_SMASK_OFFSET           =0         ,    
  parameter            I_MTAR_WIDTH             =32        ,
  parameter            I_MSAR_WIDTH             =16        ,
  parameter            I_TSF                    =1         ,          
  parameter            I_DATA_WIDTH             =24        ,    //输入三元组的宽度
  parameter  [3:0]     I_DDN                    =4'h1      ,
  parameter  [11:0]    I_DFF                    =12'hB00   ,
  parameter            I_SFL_WIDTH              =32        ,
  parameter            I_DSFL                   =772       ,          
  parameter            I_FDSTI_WIDTH            =28        ,
  parameter            I_FDSTI_WIDTH_PORT       =8         ,
  parameter            I_FDSSI_WIDTH            =12        ,
  parameter            I_FDSSI_WIDTH_PORT       =8         ,
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
  parameter            I_TAM_WIDTH              =4         ,
  parameter            I_TAM_OFFSET             =0         ,
  parameter            I_SAM_WIDTH              =4         ,
  parameter            I_SAM_OFFSET             =0         ,
  parameter            I_TOM_WIDTH              =0         ,
  parameter            I_TOM_OFFSET             =4         ,
  parameter            I_SOM_WIDTH              =0         ,
  parameter            I_SOM_OFFSET             =4         ,
  parameter            I_OUTBAND_WIDTH          =16        ,
  parameter            I_MAX_FDSSI              =16        ,
        
  parameter  [5:0]     O_SID                    =6'h00     ,
  parameter  [1:0]     O_DBT                    =2'b01     ,    //必须为2'b01
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
  parameter            O_FDSTI_WIDTH_PORT       =8         ,
  parameter            O_FDSSI_WIDTH            =12        ,
  parameter            O_FDSSI_WIDTH_PORT       =8         ,
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
  parameter            O_TAM_WIDTH              =4         ,
  parameter            O_TAM_OFFSET             =0         ,
  parameter            O_SAM_WIDTH              =4         ,
  parameter            O_SAM_OFFSET             =0         ,
  parameter            O_TOM_WIDTH              =0         ,
  parameter            O_TOM_OFFSET             =4         ,
  parameter            O_SOM_WIDTH              =0         ,
  parameter            O_SOM_OFFSET             =4         ,
  parameter            O_OUTBAND_WIDTH          =16        ,
  parameter            O_MAX_FDSSI              =16        ,
        
  parameter            REDUCE_MODE              =0         ,    //reduce的工作模式：  REDUCE_MODE=0为基于FIFO的合并；
                                                                //                    REDUCE_MODE=1为基于FIFO的流水线合并；
                                                                //                    REDUCE_MODE=2为基于FIFO的分级合并；
                                                                //                    REDUCE_MODE=3为基于RAM的合并。
  parameter            RAM_ADDR_WIDTH           =16        ,    //RAM的地址宽度
  parameter            DEFAULT_CTRL_WORD_WIDTH  =16        ,  
  parameter            FIFO_DEPTH_WIDTH         =8              //FIFO的深度为2^FIFO_DEPTH_WIDTH
)
(
  input  clk,
  input  reset,
  
  input  [O_FDSSI_WIDTH-1:0]  PN_addr,        //输出的FDSSI
  input  [I_FDSSI_WIDTH-1:0]  FDSSI_L,
  input  [I_FDSSI_WIDTH-1:0]  FDSSI_H,
  
  //input signal
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
  input                                     SDMFo_d_EF_ack
);

assign SDMFo_d_EFF = 2'b00;
assign SDMFo_d_PCF = SDMFi_d_PCF;
assign SDMFo_d_SFL = 0;
assign SDMFo_d_FDSTI = SDMFi_d_FDSTI >> O_TAM_WIDTH;
assign SDMFo_d_FDSSI = PN_addr;
assign SDMFo_d_BN = 0;
assign SDMFo_d_FI_valid = {1'b0,SDMFo_d_frame_valid};
assign SDMFo_d_STI = 0;
assign SDMFo_d_TIL = 0;
assign SDMFo_d_SSI = 0;
assign SDMFo_d_SIL = 0;
assign SDMFo_d_BL = 0;
assign SDMFo_d_BI_valid = 2'b00;
assign SDMFo_d_tkeep = {(O_DATA_WIDTH/8){1'b1}};
assign SDMFo_d_SFT = SDMFi_d_SFT;
assign SDMFo_d_outband = SDMFi_d_outband;
assign SDMFi_d_EF_ack = 1;

reg  i_valid,i_last;
always@(*)
  if(SDMFi_d_frame_valid && (|SDMFi_d_FI_valid) && SDMFi_d_EFF != 2'b00)   //空数据帧
    begin
      i_valid = 0;
      i_last = 1;
    end
  else
    begin
      i_valid = SDMFi_d_frame_valid && SDMFi_d_tvalid;
      i_last = SDMFi_d_frame_valid && SDMFi_d_tlast;
    end

wire o_valid,o_last,o_ready;
assign SDMFo_d_tvalid = SDMFo_d_frame_valid && o_valid;
assign SDMFo_d_tlast = SDMFo_d_frame_valid && o_last;
//modified by liurl 9.28
//assign o_ready = SDMFo_d_frame_valid && SDMFo_d_tready;
assign o_ready =   SDMFo_d_tready;


always@(posedge clk or posedge reset)
  if(reset)
    SDMFo_d_frame_valid <= 0;
  else
    if(o_valid && o_last && o_ready)
      SDMFo_d_frame_valid <= 0;
    else
      if(o_valid)
        SDMFo_d_frame_valid <= 1;

wire [I_DATA_WIDTH-1:0] o_data;       //排序后的三元组
wire [O_TAM_WIDTH-1:0] o_th;          //o_data的时间高位
assign SDMFo_d_tdata = {o_data[I_DATA_WIDTH-1:I_DATA_WIDTH-I_SMASK_WIDTH],o_th,o_data[I_DATA_WIDTH-I_SMASK_WIDTH-1:0]};   //输出三元组由 o_data 和 o_th 拼接得到

generate
  if(REDUCE_MODE == 0)                //基于FIFO的合并
    begin
      merge_fifo
      #(
        //modified liurl 9.28
        .DW(I_DATA_WIDTH),
        .SW(I_SMASK_WIDTH),
        .THW(O_TAM_WIDTH),
        .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)
      )
      merge_fifo_inst
      (
        .clk(clk),
        .reset(reset),
        .i_ready(SDMFi_d_tready),
        .i_valid(i_valid),
        .i_last(i_last),
        .i_data(SDMFi_d_tdata),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .o_last(o_last),
        .o_data(o_data),
        .o_th(o_th)
      );
    end
  else if(REDUCE_MODE == 1)           //基于FIFO的合并（流水线）
    begin
      merge_pipeline
      #(
        .DW(I_DATA_WIDTH),
        .SW(I_SMASK_WIDTH),
        .THW(O_TAM_WIDTH),
        .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)
      )
      merge_pipeline_inst
      (
        .clk(clk),
        .reset(reset),
        .i_ready(SDMFi_d_tready),
        .i_valid(i_valid),
        .i_last(i_last),
        .i_data(SDMFi_d_tdata),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .o_last(o_last),
        .o_data(o_data),
        .o_th(o_th)
      );
    end
  else if(REDUCE_MODE == 2)           //基于FIFO的合并（流水线、分级）
    begin
      merge_cascade
      #(
        .DW(I_DATA_WIDTH),
        .SW(I_SMASK_WIDTH),
        .THW(O_TAM_WIDTH),
        .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)
      )
      merge_cascade_inst
      (
        .clk(clk),
        .reset(reset),
        .i_ready(SDMFi_d_tready),
        .i_valid(i_valid),
        .i_last(i_last),
        .i_data(SDMFi_d_tdata),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .o_last(o_last),
        .o_data(o_data),
        .o_th(o_th)
      );
    end
  else                                //基于RAM的合并
    begin
      merge_ram
      #(
        .DW(I_DATA_WIDTH),
        .SW(I_SMASK_WIDTH),
        .THW(O_TAM_WIDTH),
        .FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH),
        .AW(RAM_ADDR_WIDTH)
      )
      merge_ram_inst
      (
        .clk(clk),
        .reset(reset),
        .i_ready(SDMFi_d_tready),
        .i_valid(i_valid),
        .i_last(i_last),
        .i_data(SDMFi_d_tdata),
        .o_ready(o_ready),
        .o_valid(o_valid),
        .o_last(o_last),
        .o_data(o_data),
        .o_th(o_th)
      );
    end
endgenerate

endmodule