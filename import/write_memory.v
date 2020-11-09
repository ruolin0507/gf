//将输入数据帧写入RAM
//同时记录每个数据帧在RAM中的地址
//fifo中记录{FDSSI,起始时间，结束时间}
module write_memory
#(
//  parameter DW = 16,
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
)
(

  /*
  output i_ready,
  input  i_valid,
  input  i_last,
  input  [DW-1:0] i_data,
  */
 // output reg [THW:0] i_th,
  input                                     clk,
  input                                     reset,
  input                                     ram_ready,
  output                                    ram_wen,
  output reg [RAM_AW-1:0]                   ram_waddr,
  output [I_DATA_WIDTH-1:0]                 ram_din,
  
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
 
  output[2**O_TAM_WIDTH-1:0]                      m_addr_info_tvalid,
  input [2**O_TAM_WIDTH-1:0]                      m_addr_info_ready,
  output[(2**O_TAM_WIDTH)*INFO_DATA_WIDTH-1:0]      m_addr_info 

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

//assign addr_finish = i_th[THW];
assign SDMFi_d_tready = ram_ready &&( ~addr_finish|o_frame_bud);
assign ram_wen = SDMFi_d_tvalid &&( ~addr_finish|o_frame_bud);
assign ram_din = SDMFi_d_tdata;

always@(posedge clk)
  if(reset)
    ram_waddr <= 0;
  else
    if(ram_ready && ram_wen)
      ram_waddr <= ram_waddr + 1;

// 空帧
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    SDMFi_d_EF_ack<=1'b0;
  end
  else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&(SDMFi_d_EFF!=2'b00)&&SDMFi_d_EF_ack) begin
    SDMFi_d_EF_ack<=1'b0;
  end
  else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&(SDMFi_d_EFF!=2'b00)) begin
    SDMFi_d_EF_ack<=1'b1;
  end
end

//锁存FDSSI

//记录结束地址，起始地址
//起始地址
always @(posedge clk or  rst) begin
  if (rst) begin
    // reset
    s_addr<=0;
    s_addr_l<=0;
  end
  else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&(SDMFi_d_EFF==2'b00)) begin
    s_addr<=ram_waddr;
    s_addr_l<=s_addr;
  end
end
//结束地址
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    e_addr<=0;
  end
  else if (SDMFi_d_frame_valid&&SDMFi_d_frame_last&&(SDMFi_d_EFF==2'b00)) begin
    e_addr<=ram_waddr-1;
  end
end
//缓存刚传输完的数据帧的FDSSI,FDSTI
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    FDSSI_l<=0;
    FDSTI_1<=0;
  end
  else if (SDMFi_d_frame_valid&&SDMFi_d_FI_valid[0]) begin
    FDSSI_l<=SDMFi_d_FDSSI;
    FDSTI_1<=SDMFi_d_FDSTI;
  end
end
   
//在last信号下一个周期时写入fifo
//上一个数据帧
assign  wr_id= SDMFi_d_FDSTI[O_TAM_WIDTH-1:0];

genvar i;
generate for (i=0; i<2**O_TAM_WIDTH; i=i+1) begin :addr_valid
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // reset
      addr_valid[i]<=1'b0;
    end
    else if (addr_valid[i]&&addr_ready[i]) begin
      addr_valid[i]<=1'b0;
    end
    else if(SDMFi_d_frame_valid&&SDMFi_d_frame_last&&(SDMFi_d_EFF==2'b00)&&(i==wr_id))begin
      addr_valid[i]<=1'b1;
    end
  end

end
endgenerate

//产生多个fifo

genvar i;
parameter INFO_DATA_WIDTH=I_FDSSI_WIDTH+2*RAM_AW;
generate for (i=0; i<2**O_TAM_WIDTH; i=i+1) begin 
   axis_fifo #(
      .DEPTH(DEPTH),
      .DATA_WIDTH(INFO_DATA_WIDTH),
      .LAST_ENABLE(1'b0),
      .USER_ENABLE(1'b0),
      .FRAME_FIFO(1'b0)
    ) inst_axis_fifo (
      .clk               (clk),
      .rst               (rst),
      .s_axis_tdata      (addr_info[i*INFO_DATA_WIDTH+:INFO_DATA_WIDTH]),
      .s_axis_tvalid     (addr_valid[i]),
      .s_axis_tready     (addr_ready[i]),
      .m_axis_tdata      (m_addr_info[i*INFO_DATA_WIDTH+:INFO_DATA_WIDTH]),
      .m_axis_tvalid     (m_addr_info_tvalid[i]),
      .m_axis_tready     (m_addr_info_tready[i])
    );
end
assign addr_info[(i+1)*INFO_DATA_WIDTH-1:i*INFO_DATA_WIDTH] ={FDSSI_l,s_addr_l,e_addr} ;
endgenerate
+=
//产生结束信号
//记录目前写到了第几个FIFO，是否到边界
//判断边界两种方式 1.最后一个帧到达边界2.出现丢帧情况下一个帧在父数据域的新帧中
always @(posedge clk or posedge rst) begin                            
  if (rst) begin
    // reset
    addr_finish<=1'b0;
  end
  else if ((SDMFi_d_FDSTI[O_TAM_WIDTH-1:0]==(2**O_TAM_WIDTH-1))&&(SDMFi_d_FDSSI[O_SAM_WIDTH-1:0]==(2**O_SAM_WIDTH-1))&&SDMFi_d_frame_last|o_frame_bud) begin
    addr_finish<=1'b1;
  end
  else if((addr_finish==1'b1)&&(merge_finish)) begin
    addr_finish<=1'b0;
  end
end
assign o_fdsti_last = FDSTI_1>>O_TAM_WIDTH ;
assign o_fdsti      =SDMFi_d_FDSTI>>O_TAM_WIDTH ;
assign o_frame_bud = (SDMFi_d_frame_valid && SDMFi_d_FI_valid[0] &&(o_fdsti_last!=o_fdsti))? 1'b1: 1'b0 ;
endmodule