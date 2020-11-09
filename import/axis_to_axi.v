//发起axi操作，arlen补齐到burst边界；
//在fifo前通过计数计算其起始和结束地址（每个FDSSI都有其特定起始地址）
module axis_to_axi #(
  parameter [ 5:0] I_SID           = 6'h00                                       ,
  parameter [ 1:0] I_DBT           = 2'b01                                       , //必须为2'b00
  parameter        I_FLEN          = 24                                          ,
  parameter        I_DMASK_WIDTH   = 24                                          ,
  parameter        I_DMASK_OFFSET  = 0                                           ,
  parameter        I_TMASK_WIDTH   = 0                                           ,
  parameter        I_TMASK_OFFSET  = 0                                           ,
  parameter        I_SMASK_WIDTH   = 0                                           ,
  parameter        I_SMASK_OFFSET  = 0                                           ,
  parameter        I_MTAR_WIDTH    = 32                                          ,
  parameter        I_MSAR_WIDTH    = 16                                          ,
  parameter        I_TSF           = 1                                           ,
  parameter        I_DATA_WIDTH    = 24                                          ,
  parameter [ 3:0] I_DDN           = 4'h1                                        ,
  parameter [11:0] I_DFF           = 12'hB00                                     ,
  parameter        I_SFL_WIDTH     = 32                                          ,
  parameter        I_DSFL          = 772                                         ,
  parameter        I_FDSTI_WIDTH   = 28                                          ,
  parameter        I_FDSSI_WIDTH   = 12                                          ,
  parameter        I_DBN           = 1                                           ,
  parameter        I_BN_WIDTH      = 8                                           ,
  parameter        I_STI_WIDTH     = 8                                           ,
  parameter        I_TIL_WIDTH     = 8                                           ,
  parameter        I_DTIL          = 16                                          ,
  parameter        I_SSI_WIDTH     = 8                                           ,
  parameter        I_SIL_WIDTH     = 8                                           ,
  parameter        I_DSIL          = 16                                          ,
  parameter        I_BL_WIDTH      = 16                                          ,
  parameter        I_DBL           = 768                                         ,
  parameter        I_TAM_WIDTH     = 0                                           ,
  parameter        I_TAM_OFFSET    = 0                                           ,
  parameter        I_SAM_WIDTH     = 0                                           ,
  parameter        I_SAM_OFFSET    = 0                                           ,
  parameter        I_TOM_WIDTH     = 0                                           ,
  parameter        I_TOM_OFFSET    = 2                                           ,
  parameter        I_SOM_WIDTH     = 0                                           ,
  parameter        I_SOM_OFFSET    = 2                                           ,
  parameter        I_OUTBAND_WIDTH = 16                                          ,
  parameter [ 5:0] O_SID           = 6'h00                                       ,
  parameter [ 1:0] O_DBT           = 2'b00                                       , //必须为2'b00
  parameter        O_FLEN          = 24                                          ,
  parameter        O_DMASK_WIDTH   = 24                                          ,
  parameter        O_DMASK_OFFSET  = 0                                           ,
  parameter        O_TMASK_WIDTH   = 0                                           ,
  parameter        O_TMASK_OFFSET  = 0                                           ,
  parameter        O_SMASK_WIDTH   = 0                                           ,
  parameter        O_SMASK_OFFSET  = 0                                           ,
  parameter        O_MTAR_WIDTH    = 32                                          ,
  parameter        O_MSAR_WIDTH    = 16                                          ,
  parameter        O_TSF           = 1                                           ,
  parameter        O_DATA_WIDTH    = 24                                          ,
  parameter [ 3:0] O_DDN           = 4'h1                                        ,
  parameter [11:0] O_DFF           = 12'hB00                                     ,
  parameter        O_SFL_WIDTH     = 32                                          ,
  parameter        O_DSFL          = 772                                         ,
  parameter        O_FDSTI_WIDTH   = 28                                          ,
  parameter        O_FDSSI_WIDTH   = 12                                          ,
  parameter        O_DBN           = 1                                           ,
  parameter        O_BN_WIDTH      = 8                                           ,
  parameter        O_STI_WIDTH     = 8                                           ,
  parameter        O_TIL_WIDTH     = 8                                           ,
  parameter        O_DTIL          = 16                                          ,
  parameter        O_SSI_WIDTH     = 8                                           ,
  parameter        O_SIL_WIDTH     = 8                                           ,
  parameter        O_DSIL          = 16                                          ,
  parameter        O_BL_WIDTH      = 16                                          ,
  parameter        O_DBL           = 768                                         ,
  parameter        O_TAM_WIDTH     = 2                                           ,
  parameter        O_TAM_OFFSET    = 2                                           ,
  parameter        O_SAM_WIDTH     = 2                                           ,
  parameter        O_SAM_OFFSET    = 2                                           ,
  parameter        O_TOM_WIDTH     = 0                                           ,
  parameter        O_TOM_OFFSET    = 4                                           ,
  parameter        O_SOM_WIDTH     = 1                                           ,
  parameter        O_SOM_OFFSET    = 3                                           ,
  parameter        O_OUTBAND_WIDTH = 16                                          ,
  parameter        AWIDTH          = 32                                          ,
  parameter        ID_WIDTH        = 4                                           ,
  parameter        LWIDTH          = 32                                          , //BLK中data最大个数
  parameter        INFO_DATA_WIDTH = I_FDSTI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH+LWIDTH,
  parameter        ADDR_DATA_WIDTH = I_FDSTI_WIDTH+2*AWIDTH
) (
  input      [                        1:0] SDMFi_d_EFF        , // Stream Frame Flag, EFF（Empty Frame Flag）为非2'b00时为空数据帧
  input      [                        1:0] SDMFi_d_PCF        , // Process Control Flag, 01=停止, 10=起始
  input      [            I_SFL_WIDTH-1:0] SDMFi_d_SFL        , // Stream Frame Length
  input      [          I_FDSTI_WIDTH-1:0] SDMFi_d_FDSTI      , // Father Domain Start Time Index
  input      [          I_FDSSI_WIDTH-1:0] SDMFi_d_FDSSI      , // Father Domain Start Space Index
  input      [             I_BN_WIDTH-1:0] SDMFi_d_BN         , // Block Number
  input      [                        1:0] SDMFi_d_FI_valid   ,
  input      [            I_STI_WIDTH-1:0] SDMFi_d_STI        , // Start Time Index
  input      [            I_TIL_WIDTH-1:0] SDMFi_d_TIL        , // Time Index Length
  input      [            I_SSI_WIDTH-1:0] SDMFi_d_SSI        , // Start Space Index
  input      [            I_SIL_WIDTH-1:0] SDMFi_d_SIL        , // Space Index Length
  input      [             I_BL_WIDTH-1:0] SDMFi_d_BL         , // Block length
  input      [                        1:0] SDMFi_d_BI_valid   ,
  input      [                      2-1:0] SDMFi_d_BI_valid   ,
  input                                    SDMFi_d_tvalid     ,
  output                                   SDMFi_d_tready     ,
  input                                    SDMFi_d_tlast      ,
  input      [         I_DATA_WIDTH/8-1:0] SDMFi_d_tkeep      ,
  input      [           I_DATA_WIDTH-1:0] SDMFi_d_tdata      ,
  input      [DEFAULT_CTRL_WORD_WIDTH-1:0] SDMFi_d_SFT        ,
  input      [        I_OUTBAND_WIDTH-1:0] SDMFi_d_outband    , // outband data
  input                                    SDMFi_d_frame_valid, // valid during the whole frame
  input                                    SDMFi_d_frame_last ,
  output                                   SDMFi_d_Frame_ack  ,
  output     [               ID_WIDTH-1:0] axi_awid           ,
  output reg [                 AWIDTH-1:0] axi_awaddr         ,
  output reg [                        7:0] axi_awlen          ,
  output     [                        2:0] axi_awsize         ,
  output     [                        1:0] axi_awburst        ,
  output     [                        1:0] axi_awlock         ,
  output     [                        3:0] axi_awcache        ,
  output     [                        2:0] axi_awprot         ,
  output     [                        3:0] axi_awqos          ,
  output reg                               axi_awvalid        ,
  input                                    axi_awready        ,
  output                                   axi_wlast          , // AXI MM last write data
  output     [           I_DATA_WIDTH-1:0] axi_wdata          , // AXI MM write data
  output                                   axi_wvalid         , // AXI MM write data valid
  input                                    axi_wready         , // AXI MM ready from slave
  output     [         I_DATA_WIDTH/8-1:0] axi_wstrb          , // AXI MM write strobe
  input      [                        1:0] axi_bresp          ,
  input                                    axi_bvalid         ,
  output reg                               axi_bready         ,
  output                                   m_addr_valid       ,
  input                                    m_addr_ready       ,
  output     [ I_FDSTI_WIDTH+2*AWIDTH-1:0] m_addr             ,
  output                                   m_info_valid       ,
  input                                    m_info_ready       ,
  output     [        INFO_DATA_WIDTH-1:0] m_info             ,
  input                                    burst_len
);

    wire                       m_axis_tvalid;
    wire                       m_axis_tready;
    wire                       m_axis_tlast ;
    wire [I_DATA_WIDTH/8*-1:0] m_axis_tkeep ;
    wire [   I_DATA_WIDTH-1:0] m_axis_tdata ;
    wire                       wr_enable    ;
    wire                       tlast_enable ;
    wire                       tlast_in     ;
    wire                       tlast_out    ;
    wire [          AWIDTH-1:0] wr_count     ;
    reg                        wait_wr      ;
    reg  [         AWIDTH-1:0] addr         ;
    reg                        not_bound    ;
    reg  [          AWIDTH-1:0] sum_len      ;
    reg  [                7:0] tlast_cnt    ;


    reg  [                AWIDTH-1:0] s_addr    ;
    reg  [                AWIDTH-1:0] e_addr    ;
    reg                               addr_valid;
    wire                              addr_ready;
    reg  [I_FDSTI_WIDTH+2*AWIDTH-1:0] addr      ;
    reg  [                LWIDTH-1:0] frame_len ;
    reg  [                LWIDTH-1:0] i_blk_cnt ;

    reg                                              info_valid;
    wire                                             info_ready;
    reg  [I_FDSTI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH-1:0] info      ;

function integer clogb2 (input integer bit_depth);
   begin
      bit_depth=bit_depth-1;
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
      bit_depth = bit_depth>>1;
  end
endfunction
parameter WR_SIZE= clog2(I_DATA_WIDTH/8);

assign SDMFi_d_Frame_ack=SDMFi_d_frame_last&&SDMFi_d_frame_valid;
    axis_fifo_th #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(DATA_WIDTH),
            .USER_ENABLE(1'b0),
        ) inst_axis_fifo_th (
            .clk               (clk),
            .rst               (rst),
            .s_axis_tdata      (SDMFi_d_tdata),
            .s_axis_tkeep      (SDMFi_d_tkeep),
            .s_axis_tvalid     (SDMFi_d_tvalid&&SDMFi_d_frame_valid),
            .s_axis_tready     (SDMFi_d_tready),
            .s_axis_tlast      (SDMFi_d_tlast),

            .m_axis_tdata      (m_axis_tdata),
            .m_axis_tkeep      (m_axis_tkeep),
            .m_axis_tvalid     (m_axis_tvalid),
            .m_axis_tready     (m_axis_tready),
            .m_axis_tlast      (m_axis_tlast)
            .fifo_count        (wr_count),//wr_ptr-rd_ptr
            .full_th           (),
            .empty_th          (),
            .almost_full       (),
            .almost_empty      ()

        );
//在发起一次aw操作后，wait_wr=1，写完后收到response信号，wait_wr=0
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        wait_wr<=0;
      end
      else if (axi_awvalid&&axi_awready) begin
        wait_wr<=1'b1
      end
      else if (axi_bready&&axi_bvalid) begin
        wait_wr<=1'b0;
      end
    end
      //wr_enable同时没有正在写入wr时发起操作
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        axi_awvalid<=0;
      end
      else if(axi_awvalid&&axi_awready)begin
        axi_awvalid<=0;
      end
      else if (wr_enable&&(!wait_wr)) begin
        axi_awvalid<=1'b1;
      end
    end

    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        axi_awaddr<=0;
      end
      else if (wr_enable&&(!wait_wr)) begin
        axi_awaddr<=addr;
      end
    end
    //写入地址
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        addr<=Start_addr;
      end
      else if (axi_awvalid&&axi_awready) begin
        addr<=addr+axi_awlen;
      end
    end

//此次burst length=axi_awlen+1
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        axi_awlen<=0;
      end
      else if (wr_enable&&(!wait_wr)) begin
      //未到burst边界（需先补齐到burst边界上），选择wr_count和(burst_len-sum_len)更小的,not_bound==0,到达边界，sum_len=0,与not_bound情况相同
          if (wr_count>=(burst_len-sum_len)) begin
            axi_awlen<=(burst_len-sum_len)-1;
          end
          else begin
            axi_awlen<=wr_count-1;
          end
      end
    end
//not_bound=0,上次到达边界处，此次从边界开始，not_bound=1上次未到边界处
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        not_bound<=1'b0;
      end
      else if(axi_awvalid&&axi_awready)begin
          //上一次在边界处
        if ((not_bound==0)&&((axi_awlen+1)<burst_len)) begin
          not_bound<=1'b1;
        end
          //上一次不在边界处
        else if ((not_bound)&&((axi_awlen+sum_len+1)==burst_len)) begin
          not_bound<=1'b0;
        end 
      end  
    end
//sum_len
//此次burst length=axi_awlen+1
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        sum_len<=0;
      end
      else if (axi_awvalid&&axi_awready) begin
       //若到边界则上一次sum_len=0,若未到边界为sum_len,是否到burst边界均可简化为下两种情况
        else if ((axi_awlen+1+sum_len)<burst_len) begin
          sum_len<=sum_len+(axi_awlen+1);
        end
        else  if((axi_awlen+1+sum_len)==burst_len)begin
          sum_len<=0;
        end
      end
    end


    //fifo中的tlast个数
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        tlast_cnt<=0;
      end
      else if (tlast_in&&~tlast_out) begin
        tlast_cnt<=tlast_cnt+1;
      end
      else if(tlast_out&&(~tlast_in))begin
        tlast_cnt<=tlast_cnt-1;
      end
    end

//可写入条件为当前数量超过busrt_size，或者该fifo中有一个tlast信号
    assign wr_enable =(wr_count>=busrt_size)|tlast_enable ;
    assign tlast_enable =tlast_cnt>0 ;
    assign tlast_in =SDMFi_d_tvalid&&SDMFi_d_frame_valid&&SDMFi_d_tlast&&SDMFi_d_tready ;
    assign tlast_out = m_axis_tvalid&&m_axis_tready&&m_axis_tlast;
//AXI信号
    assign axi_awsize=WR_SIZE;
    assign axi_awid    = 4'b0000;      //- IDs overwritten at top level
    assign axi_awburst = 2'b01;    // Incrementing burst
    assign axi_awlock  = 2'b00;    // Normal access
    assign axi_awcache = 4'b0011;  // Enable data packing   
    assign axi_awprot  = 3'b000;
    assign axi_awqos   = 4'b0000;

//addr fifo{fdsti,s_addr,e_addr}
    //frame_last是否只有一个时钟周期？？？？
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        s_addr<=Start_addr;
      end
      //下一个时钟周期的s_addr
      else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&SDMFi_d_Frame_ack) begin
        s_addr<=s_addr+frame_len;
      end
    end
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        e_addr<=Start_addr;
      end
      //该时钟周期的e_addr
      else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&SDMFi_d_Frame_ack) begin
        e_addr<=s_addr+frame_len-1;
      end
    end


    //add_valid
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        addr_valid<=1'b0;
        addr<=0;
      end
      else  if(addr_valid&&addr_ready)begin
        addr_valid<=1'b0;
      end
      else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&SDMFi_d_Frame_ack&&SDMFi_d_FI_valid[0]) begin
        addr_valid<=1'b1;
        addr<={SDMFi_d_FDSTI,s_addr,s_addr+frame_len-1}
      end
    end
    axis_fifo #(
      .DEPTH(DEPTH),
      .DATA_WIDTH(I_FDSTI_WIDTH+2*AWIDTH),
      .LAST_ENABLE(1'b0),
      .USER_ENABLE(1'b0),
      .FRAME_FIFO(1'b0)
    ) inst_axis_fifo_addr (
      .clk               (clk),
      .rst               (rst),
      .s_axis_tdata      (addr),
      .s_axis_tvalid     (addr_valid),
      .s_axis_tready     (addr_ready),
      .m_axis_tdata      (m_addr),
      .m_axis_tvalid     (m_addr_tvalid),
      .m_axis_tready     (m_addr_tready)
    );

    //frame_len
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        frame_len<=0;
      end
      else if(SDMFi_d_frame_valid&&SDMFi_d_frame_last)begin
        frame_len<=0;
      end
      else if (SDMFi_d_frame_valid&&SDMFi_d_tvalid&&SDMFi_d_tready) begin
        frame_len<=frame_len+I_DATA_WIDTH/8;
      end
    end
//info{fdsti,ssi,sti,blk_cnt}，在每个块tlast时写入fifo
      always @(posedge clk or posedge rst) begin
        if (rst) begin
          // reset
          info_valid<=0;
          info<=0;
        end
        else if (SDMFi_d_frame_valid&&SDMFi_d_tvalid&&SDMFi_d_tready&&SDMFi_d_tlast&&SDMFi_d_FI_valid[0]&&SDMFi_d_BI_valid[0]) begin
          info_valid<=1'b1;
          info<={SDMFi_d_FDSTI,SDMFi_d_SSI,SDMFi_d_STI,i_blk_cnt+1}
        end
        else if (info_valid&&info_ready) begin
          info_valid<=0;
        end
      end
      //i_blk_cnt为每一个数据块计数
      always @(posedge clk or posedge rst) begin
        if (rst) begin
          // reset
          i_blk_cnt<=0;
        end
        else if(SDMFi_d_frame_valid&&SDMFi_d_tvalid&&SDMFi_d_tready)begin
          if (SDMFi_d_tlast) begin
            i_blk_cnt<=0;
          end
          else begin
            i_blk_cnt<=i_blk_cnt+1'b1;
          end
        end
      end
    axis_fifo #(
      .DEPTH(DEPTH),
      .DATA_WIDTH(INFO_DATA_WIDTH),
      .LAST_ENABLE(1'b0),
      .USER_ENABLE(1'b0),
      .FRAME_FIFO(1'b0)
    ) inst_axis_fifo_info (
      .clk               (clk),
      .rst               (rst),
      .s_axis_tdata      (info),
      .s_axis_tvalid     (info_valid),
      .s_axis_tready     (info_ready),
      .m_axis_tdata      (m_info),
      .m_axis_tvalid     (m_info_tvalid),
      .m_axis_tready     (m_info_tready)
    );
    endmodule