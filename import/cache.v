//将输入的数据帧写入RAM，记录写入的地址
//根据读出地址从RAM中读取数据
module cache
#(
  parameter            RAM_AW                   =8,
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
  parameter            INBL_CNT_MAX             = 8,
  parameter            INFO_DATA_WIDTH          =I_FDSSI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH+INBL_CNT_MAX
)
(

  input                                     ren,
  input  [RAM_AW-1:0]                       raddr,
  input  [RAM_AW-1:0]                       rlength,
  
  output                                    dvalid,
  output                                    dlast,
  output [I_DATA_WIDTH-1:0]                 dout

  input                                     clk,
  input                                     reset,
  
  //output reg [RAM_AW*(2**THW)-1:0] addr_r,
  input                                     merge_finish,//该次合并结束（这个和乒乓会有冲突吗？？？？）
  output reg                                addr_finish,
  
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
  input                                     SDMFi_d_frame_last,
  output                                    SDMFi_d_EF_ack,                 // acknowledge signal for empty frame 
 
  output[2**O_TAM_WIDTH-1:0]                   addr_info_tvalid,
  input [2**O_TAM_WIDTH-1:0]                   addr_info_ready,
  output[(2**O_TAM_WIDTH)*INFO_DATA_WIDTH-1:0]   addr_info,


  input [2**O_TAM_WIDTH-1:0]                   info_tready,
  output[2**O_TAM_WIDTH-1:0]                   info_tvalid,                                     
  output[(2**O_TAM_WIDTH)*INFO_DATA_WIDTH-1:0] info 

);

wire                    ram_wen;
wire [I_DATA_WIDTH-1:0] ram_din;
wire [RAM_AW-1:0]       ram_waddr;
wire [RAM_AW-1:0]       ram_raddr;
wire [RAM_AW-1:0]       ram_dout;

ram #(
  .DWIDTH(I_DATA_WIDTH),
  .AWIDTH(RAM_AW))
ram0
(
  .clk(clk),
  .wen(ram_wen),
  .din(ram_din),
  .waddr(ram_waddr),
  .raddr(ram_raddr),
  .dout(ram_dout)
);

  write_memory #(
      .RAM_AW(RAM_AW),
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
      .INFO_DATA_WIDTH(INFO_DATA_WIDTH)
    ) inst_write_memory (
      .clk                 (clk),
      .reset               (rst),
      .ram_ready           (1),
      .ram_wen             (ram_wen),
      .ram_waddr           (ram_waddr),
      .ram_din             (ram_din),

      .merge_finish        (merge_finish),
      //一帧要合并的数据帧输入结束
      .addr_finish         (addr_finish),
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

      .m_addr_info_tvalid  (addr_info_tvalid),
      .m_addr_info_ready   (addr_info_ready),
      .m_addr_info         (addr_info)
    );


  FI_BI_descriptor #(
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
      .DEPTH(DEPTH),
      .INBL_CNT_MAX(INBL_CNT_MAX),
      .INFO_DATA_WIDTH(INFO_DATA_WIDTH)
    ) inst_FI_BI_descriptor (
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
      .clk                 (clk),
      .rst                 (rst),
      .m_info_tready       (info_tready),
      .m_info_tvalid       (info_tvalid),
      .m_info              (info)
    );


read_memory
#(
  .DW(I_DATA_WIDTH),
  .RAM_AW(RAM_AW)
)
read_memory0
(
  .clk(clk),
  .reset(rst),
  
  .ren(ren),
  .raddr(raddr),
  .rlength(rlength),
  
  .dvalid(dvalid),
  .dlast(dlast),
  .dout(dout),
  
  .o_raddr(ram_raddr),
  .din(ram_dout)
);

endmodule