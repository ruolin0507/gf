//将输入数据帧写入RAM
//同时记录每个数据帧在RAM中的地址
//fifo中记录{FDSSI,起始时间，结束时间}
module write_memory_mp #(
  //  parameter DW = 16,
  parameter        RAM_AW          = 8      ,
  parameter [ 5:0] I_SID           = 6'h00  ,
  parameter [ 1:0] I_DBT           = 2'b01  , //必须为2'b00
  parameter        I_FLEN          = 24     ,
  parameter        I_DMASK_WIDTH   = 24     ,
  parameter        I_DMASK_OFFSET  = 0      ,
  parameter        I_TMASK_WIDTH   = 0      ,
  parameter        I_TMASK_OFFSET  = 0      ,
  parameter        I_SMASK_WIDTH   = 0      ,
  parameter        I_SMASK_OFFSET  = 0      ,
  parameter        I_MTAR_WIDTH    = 32     ,
  parameter        I_MSAR_WIDTH    = 16     ,
  parameter        I_TSF           = 1      ,
  parameter        I_DATA_WIDTH    = 24     ,
  parameter [ 3:0] I_DDN           = 4'h1   ,
  parameter [11:0] I_DFF           = 12'hB00,
  parameter        I_SFL_WIDTH     = 32     ,
  parameter        I_DSFL          = 772    ,
  parameter        I_FDSTI_WIDTH   = 28     ,
  parameter        I_FDSSI_WIDTH   = 12     ,
  parameter        I_DBN           = 1      ,
  parameter        I_BN_WIDTH      = 8      ,
  parameter        I_STI_WIDTH     = 8      ,
  parameter        I_TIL_WIDTH     = 8      ,
  parameter        I_DTIL          = 16     ,
  parameter        I_SSI_WIDTH     = 8      ,
  parameter        I_SIL_WIDTH     = 8      ,
  parameter        I_DSIL          = 16     ,
  parameter        I_BL_WIDTH      = 16     ,
  parameter        I_DBL           = 768    ,
  parameter        I_TAM_WIDTH     = 0      ,
  parameter        I_TAM_OFFSET    = 0      ,
  parameter        I_SAM_WIDTH     = 0      ,
  parameter        I_SAM_OFFSET    = 0      ,
  parameter        I_TOM_WIDTH     = 0      ,
  parameter        I_TOM_OFFSET    = 2      ,
  parameter        I_SOM_WIDTH     = 0      ,
  parameter        I_SOM_OFFSET    = 2      ,
  parameter        I_OUTBAND_WIDTH = 16     ,
  parameter [ 5:0] O_SID           = 6'h00  ,
  parameter [ 1:0] O_DBT           = 2'b00  , //必须为2'b00
  parameter        O_FLEN          = 24     ,
  parameter        O_DMASK_WIDTH   = 24     ,
  parameter        O_DMASK_OFFSET  = 0      ,
  parameter        O_TMASK_WIDTH   = 0      ,
  parameter        O_TMASK_OFFSET  = 0      ,
  parameter        O_SMASK_WIDTH   = 0      ,
  parameter        O_SMASK_OFFSET  = 0      ,
  parameter        O_MTAR_WIDTH    = 32     ,
  parameter        O_MSAR_WIDTH    = 16     ,
  parameter        O_TSF           = 1      ,
  parameter        O_DATA_WIDTH    = 24     ,
  parameter [ 3:0] O_DDN           = 4'h1   ,
  parameter [11:0] O_DFF           = 12'hB00,
  parameter        O_SFL_WIDTH     = 32     ,
  parameter        O_DSFL          = 772    ,
  parameter        O_FDSTI_WIDTH   = 28     ,
  parameter        O_FDSSI_WIDTH   = 12     ,
  parameter        O_DBN           = 1      ,
  parameter        O_BN_WIDTH      = 8      ,
  parameter        O_STI_WIDTH     = 8      ,
  parameter        O_TIL_WIDTH     = 8      ,
  parameter        O_DTIL          = 16     ,
  parameter        O_SSI_WIDTH     = 8      ,
  parameter        O_SIL_WIDTH     = 8      ,
  parameter        O_DSIL          = 16     ,
  parameter        O_BL_WIDTH      = 16     ,
  parameter        O_DBL           = 768    ,
  parameter        O_TAM_WIDTH     = 2      ,
  parameter        O_TAM_OFFSET    = 2      ,
  parameter        O_SAM_WIDTH     = 2      ,
  parameter        O_SAM_OFFSET    = 2      ,
  parameter        O_TOM_WIDTH     = 0      ,
  parameter        O_TOM_OFFSET    = 4      ,
  parameter        O_SOM_WIDTH     = 1      ,
  parameter        O_SOM_OFFSET    = 3      ,
  parameter        O_OUTBAND_WIDTH = 16     ,
  parameter        PORT_NUM        = 4
) (
  input                                             clk                ,
  input                                             reset              ,
  // interface to AXI MM write address port

  input                                             merge_finish       , //该次合并结束（这个和乒乓会有冲突吗？？？？）
  output reg                                        addr_finish        ,
  //input signal
  input      [                      2*PORT_NUM-1:0] SDMFi_d_EFF        , // Stream Frame Flag, EFF（Empty Frame Flag）为非2'b00时为空数据帧
  input      [                      2*PORT_NUM-1:0] SDMFi_d_PCF        , // Process Control Flag, 01=停止, 10=起始
  input      [            I_SFL_WIDTH*PORT_NUM-1:0] SDMFi_d_SFL        , // Stream Frame Length
  input      [          I_FDSTI_WIDTH*PORT_NUM-1:0] SDMFi_d_FDSTI      , // Father Domain Start Time Index
  input      [          I_FDSSI_WIDTH*PORT_NUM-1:0] SDMFi_d_FDSSI      , // Father Domain Start Space Index
  input      [             I_BN_WIDTH*PORT_NUM-1:0] SDMFi_d_BN         , // Block Number
  input      [                      2*PORT_NUM-1:0] SDMFi_d_FI_valid   ,
  input      [            I_STI_WIDTH*PORT_NUM-1:0] SDMFi_d_STI        , // Start Time Index
  input      [            I_TIL_WIDTH*PORT_NUM-1:0] SDMFi_d_TIL        , // Time Index Length
  input      [            I_SSI_WIDTH*PORT_NUM-1:0] SDMFi_d_SSI        , // Start Space Index
  input      [            I_SIL_WIDTH*PORT_NUM-1:0] SDMFi_d_SIL        , // Space Index Length
  input      [             I_BL_WIDTH*PORT_NUM-1:0] SDMFi_d_BL         , // Block length
  input      [                      2*PORT_NUM-1:0] SDMFi_d_BI_valid   ,
  input      [                        PORT_NUM-1:0] SDMFi_d_tvalid     ,
  output     [                        PORT_NUM-1:0] SDMFi_d_tready     ,
  input      [                        PORT_NUM-1:0] SDMFi_d_tlast      ,
  input      [         I_DATA_WIDTH/8*PORT_NUM-1:0] SDMFi_d_tkeep      ,
  input      [           I_DATA_WIDTH*PORT_NUM-1:0] SDMFi_d_tdata      ,
  input      [DEFAULT_CTRL_WORD_WIDTH*PORT_NUM-1:0] SDMFi_d_SFT        ,
  input      [        I_OUTBAND_WIDTH*PORT_NUM-1:0] SDMFi_d_outband    , // outband data
  input      [                        PORT_NUM-1:0] SDMFi_d_frame_valid, // valid during the whole frame
  input      [                        PORT_NUM-1:0] SDMFi_d_frame_last ,
  output     [                        PORT_NUM-1:0] SDMFi_d_EF_ack     , // acknowledge signal for empty frame
  output                                   m_info_valid       ,
  input                                    m_info_ready       ,
  output     [        INFO_DATA_WIDTH-1:0] m_info             ,
  output                                   m_addr_valid       ,
  input                                    m_addr_ready       ,
  output     [ I_FDSTI_WIDTH+2*AWIDTH-1:0] m_addr             ,
  output     [               ID_WIDTH-1:0] m_axi_awid           ,
  output reg [                 AWIDTH-1:0] m_axi_awaddr         ,
  output reg [                        7:0] m_axi_awlen          ,
  output     [                        2:0] m_axi_awsize         ,
  output     [                        1:0] m_axi_awburst        ,
  output     [                        1:0] m_axi_awlock         ,
  output     [                        3:0] m_axi_awcache        ,
  output     [                        2:0] m_axi_awprot         ,
  output     [                        3:0] m_axi_awqos          ,
  output reg                               m_axi_awvalid        ,
  input                                    m_axi_awready        ,
  output                                   m_axi_wlast          , // AXI MM last write data
  output     [           I_DATA_WIDTH-1:0] m_axi_wdata          , // AXI MM write data
  output                                   m_axi_wvalid         , // AXI MM write data valid
  input                                    m_axi_wready         , // AXI MM ready from slave
  output     [         I_DATA_WIDTH/8-1:0] m_axi_wstrb          , // AXI MM write strobe
  input      [                        1:0] m_axi_bresp          ,
  input                                    m_axi_bvalid         ,
  output reg                               m_axi_bready         
);
reg   [O_SAM_WIDTH-1:0]     FDSSI_r;
reg   [I_FDSTI_WIDTH-1:0]   FDSTI_r;

wire  [O_SAM_WIDTH-1:0]     FDSSI_latch;
wire  [I_FDSTI_WIDTH-1:0]   FDSTI_latch;
reg   [O_SAM_WIDTH-1:0]     FDSSI_1;
reg   [I_FDSTI_WIDTH-1:0]   FDSTI_1;
reg   [RAM_AW-1:0]          s_addr;
reg   [RAM_AW-1:0]          s_addr_l;
reg   [RAM_AW-1:0]          e_addr;

reg[2**O_TAM_WIDTH-1:0]                      addr_valid;
reg[2**O_TAM_WIDTH-1:0]                      addr_ready;
wire[(2**O_TAM_WIDTH)*INFO_DATA_WIDTH-1:0]     addr_info;

 

genvar i;
generate for (i=0; i<2**O_SAM_WIDTH; i=i+1) begin: loop_i

 axis_to_axi #(
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
            .AWIDTH(AWIDTH),
            .ID_WIDTH(ID_WIDTH),
            .LWIDTH(LWIDTH),
            .INFO_DATA_WIDTH(INFO_DATA_WIDTH),
            .WR_SIZE(WR_SIZE)
        ) inst_axis_to_axi (
            .SDMFi_d_EFF         (SDMFi_d_EFF[2*i+:2]),
            .SDMFi_d_PCF         (SDMFi_d_PCF[2*i+:2]),
            .SDMFi_d_SFL         (SDMFi_d_SFL[I_SFL_WIDTH*i+:I_SFL_WIDTH]),
            .SDMFi_d_FDSTI       (SDMFi_d_FDSTI[I_FDSTI_WIDTH*i+:I_FDSTI_WIDTH]),
            .SDMFi_d_FDSSI       (SDMFi_d_FDSSI[I_FDSSI_WIDTH*i+:I_FDSSI_WIDTH]),
            .SDMFi_d_BN          (SDMFi_d_BN[I_BN_WIDTH*i+:I_BN_WIDTH]),
            .SDMFi_d_FI_valid    (SDMFi_d_FI_valid[2*i+:2]),
            .SDMFi_d_STI         (SDMFi_d_STI[I_STI_WIDTH*i+:I_STI_WIDTH]),
            .SDMFi_d_TIL         (SDMFi_d_TIL[I_TIL_WIDTH*i+:I_TIL_WIDTH]),
            .SDMFi_d_SSI         (SDMFi_d_SSI[I_SSI_WIDTH*i+:I_SSI_WIDTH]),
            .SDMFi_d_SIL         (SDMFi_d_SIL[I_SIL_WIDTH*i+:I_SIL_WIDTH]),
            .SDMFi_d_BL          (SDMFi_d_BL[I_BL_WIDTH*i+:I_BL_WIDTH]),
            .SDMFi_d_BI_valid    (SDMFi_d_BI_valid[2*i+:2]),
            .SDMFi_d_tvalid      (SDMFi_d_tvalid[i]),
            .SDMFi_d_tready      (SDMFi_d_tready[i]),
            .SDMFi_d_tlast       (SDMFi_d_tlast[i]),
            .SDMFi_d_tkeep       (SDMFi_d_tkeep[I_DATA_WIDTH/8*i+:I_DATA_WIDTH/8]),
            .SDMFi_d_tdata       (SDMFi_d_tdata[I_DATA_WIDTH*i+:I_DATA_WIDTH]),
            .SDMFi_d_SFT         (SDMFi_d_SFT[DEFAULT_CTRL_WORD_WIDTH*i+:DEFAULT_CTRL_WORD_WIDTH]),
            .SDMFi_d_outband     (SDMFi_d_outband[I_OUTBAND_WIDTH*i+:I_OUTBAND_WIDTH]),
            .SDMFi_d_frame_valid (SDMFi_d_frame_valid[2*i+:2]),
            .SDMFi_d_frame_last  (SDMFi_d_frame_last[i]),
            .SDMFi_d_Frame_ack   (SDMFi_d_Frame_ack[i]),
            .axi_awid            (axi_awid[ID_WIDTH*i+:ID_WIDTH]),
            .axi_awaddr          (axi_awaddr[AWIDTH*i+:AWIDTH]),
            .axi_awlen           (axi_awlen[8*i+:8]),
            .axi_awsize          (axi_awsize[3*i+:3]),
            .axi_awburst         (axi_awburst[2*i+:2]),
            .axi_awlock          (axi_awlock[2*i+:2]),
            .axi_awcache         (axi_awcache[4*i+:4]),
            .axi_awprot          (axi_awprot[3*i+:3]),
            .axi_awqos           (axi_awqos[4*i+:4]),
            .axi_awvalid         (axi_awvalid[i]),
            .axi_awready         (axi_awready[i]),
            .axi_wlast           (axi_wlast[i]),
            .axi_wdata           (axi_wdata[I_DATA_WIDTH*i+:I_DATA_WIDTH]),
            .axi_wvalid          (axi_wvalid[i]),
            .axi_wready          (axi_wready[i]),
            .axi_wstrb           (axi_wstrb[I_DATA_WIDTH/8*i+:I_DATA_WIDTH/8]),
            .axi_bresp           (axi_bresp[2*i+:2]),
            .axi_bvalid          (axi_bvalid[i]),
            .axi_bready          (axi_bready[i]),
            //fdssi_addr_fifo
            .m_addr_valid        (s_addr_valid[i]),
            .m_addr_ready        (s_addr_ready[i]),
            .m_addr              (s_addr[ADDR_DATA_WIDTH*i+:ADDR_DATA_WIDTH]),
            //fdssi_info_fifo
            .m_info_valid        (s_info_valid[i]),
            .m_info_ready        (s_info_ready[i]),
            .m_info              (s_info[INFO_DATA_WIDTH*i+:INFO_DATA_WIDTH]),
            .burst_len           (burst_len)
        );

end
endgenerate
//对于addr_fdssi_fifo进行转换fdsti_fifo
    addr_fdssi_to_fdsti_fifo #(
            .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
            .I_FDSSI_WIDTH(I_FDSSI_WIDTH),
            .O_SAM_WIDTH(O_SAM_WIDTH),
            .O_TAM_WIDTH(O_TAM_WIDTH),
            .AWIDTH(AWIDTH),
            .DEPTH(DEPTH),
            .S_ADDR_INFO_WITH(S_ADDR_INFO_WITH),
            .T_ADDR_INFO_WITH(T_ADDR_INFO_WITH)
        ) inst_addr_fdssi_to_fdsti_fifo (
            .addr_valid   (s_addr_valid),
            .addr_ready   (s_addr_ready),
            .addr         (s_addr),
            .m_addr_valid (m_addr_valid),
            .m_addr_ready (m_addr_ready),
            .m_addr       (m_addr),
            .in_finish    (in_finish)
        );
 //对于info_fdssi_fifo进行转换fdsti_fifo
    info_fdssi_to_fdsti_fifo #(
            .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
            .I_FDSSI_WIDTH(I_FDSSI_WIDTH),
            .I_STI_WIDTH(I_STI_WIDTH),
            .I_SSI_WIDTH(I_SSI_WIDTH),
            .O_SAM_WIDTH(O_SAM_WIDTH),
            .O_TAM_WIDTH(O_TAM_WIDTH),
            .AWIDTH(AWIDTH),
            .DEPTH(DEPTH),
            .LWIDTH(LWIDTH),
            .INFO_DATA_WIDTH(INFO_DATA_WIDTH),
            .T_INFO_DATA_WIDTH(T_INFO_DATA_WIDTH)
        ) inst_info_fdssi_to_fdsti_fifo (
            .info_valid   (s_info_valid),
            .info_ready   (s_info_ready),
            .info         (s_info),
            .m_info_valid (m_info_valid),
            .m_info_ready (m_info_ready),
            .m_info       (m_info),
            .in_finish    (in_finish)
        );
//对于axi的wr通道进行仲裁
 axi_interconnect #(
            .S_COUNT(2**O_SAM_WIDTH),
            .M_COUNT(1),
            .DATA_WIDTH(I_DATA_WIDTH),
            .ADDR_WIDTH(AWIDTH),
            .M_ADDR_WIDTH(AWIDTH)
        ) inst_axi_interconnect (
            .clk            (clk),
            .rst            (rst),
            .s_axi_awid     (axi_awid),
            .s_axi_awaddr   (axi_awaddr),
            .s_axi_awlen    (axi_awlen),
            .s_axi_awsize   (axi_awsize),
            .s_axi_awburst  (axi_awburst),
            .s_axi_awlock   (axi_awlock),
            .s_axi_awcache  (axi_awcache),
            .s_axi_awprot   (axi_awprot),
            .s_axi_awqos    (axi_awqos),
            .s_axi_awvalid  (axi_awvalid),
            .s_axi_awready  (axi_awready),
            .s_axi_wdata    (axi_wdata),
            .s_axi_wstrb    (axi_wstrb),
            .s_axi_wlast    (axi_wlast),
            .s_axi_wvalid   (axi_wvalid),
            .s_axi_wready   (axi_wready),
            .s_axi_bresp    (axi_bresp),
            .s_axi_buser    (axi_buser),
            .s_axi_bvalid   (axi_bvalid),
            .s_axi_bready   (axi_bready),
            .m_axi_awid     (m_axi_awid),
            .m_axi_awaddr   (m_axi_awaddr),
            .m_axi_awlen    (m_axi_awlen),
            .m_axi_awsize   (m_axi_awsize),
            .m_axi_awburst  (m_axi_awburst),
            .m_axi_awlock   (m_axi_awlock),
            .m_axi_awcache  (m_axi_awcache),
            .m_axi_awprot   (m_axi_awprot),
            .m_axi_awqos    (m_axi_awqos),
            .m_axi_awvalid  (m_axi_awvalid),
            .m_axi_awready  (m_axi_awready),
            .m_axi_wdata    (m_axi_wdata),
            .m_axi_wstrb    (m_axi_wstrb),
            .m_axi_wlast    (m_axi_wlast),
            .m_axi_wvalid   (m_axi_wvalid),
            .m_axi_wready   (m_axi_wready),
            .m_axi_bresp    (m_axi_bresp),
            .m_axi_buser    (m_axi_buser),
            .m_axi_bvalid   (m_axi_bvalid),
            .m_axi_bready   (m_axi_bready)
        );
endmodule