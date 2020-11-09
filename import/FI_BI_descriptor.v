//在该模块中记录数据块的FDSSI,SSI,STI,块内数据个数，提供接口可读取各个FDSTI的FIFO中的数据块的个数
module FI_BI_descriptor	#(
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
  parameter 		       DEPTH                	  = 4096	   ,
  parameter 		       INBL_CNT_MAX				      = 8,
  parameter            INFO_DATA_WIDTH          =I_FDSSI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH+INBL_CNT_MAX
  )(
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
  input                                     SDMFi_d_tready,
  input                                     SDMFi_d_tlast,
  input   [I_DATA_WIDTH/8-1:0]              SDMFi_d_tkeep,   
  input   [I_DATA_WIDTH-1:0]                SDMFi_d_tdata,
  input   [DEFAULT_CTRL_WORD_WIDTH-1:0]     SDMFi_d_SFT,
  input   [I_OUTBAND_WIDTH-1:0]             SDMFi_d_outband,                // outband data
  input                                     SDMFi_d_frame_valid,            // valid during the whole frame

  input  									clk,
  input  									rst,

  input   [2**O_TAM_WIDTH-1:0]             			  m_info_tready,
  output  [2**O_TAM_WIDTH-1:0]							        m_info_tvalid,                                     
  output  [(2**O_TAM_WIDTH)*INFO_DATA_WIDTH-1:0]		m_info 
  );
reg [INBL_CNT_MAX-1:0]	in_block_cnt;
reg [INBL_CNT_MAX-1:0]	in_block_cnt_1;
reg  [O_SAM_WIDTH-1:0]     FDSSI_1;
reg  [I_FDSTI_WIDTH-1:0]   FDSTI_1;

reg  [I_STI_WIDTH-1:0]     STI_1;
reg  [I_SSI_WIDTH-1:0]     SSI_1;
wire [O_TAM_WIDTH-1:0]	   wr_id;

reg   [O_SAM_WIDTH-1:0]     FDSSI_r;
reg   [I_FDSTI_WIDTH-1:0]   FDSTI_r;

reg   [I_STI_WIDTH-1:0]     STI_r;
reg   [I_SSI_WIDTH-1:0]     SSI_r;

wire  [O_SAM_WIDTH-1:0]     FDSSI_latch;
wire  [I_FDSTI_WIDTH-1:0]   FDSTI_latch;

wire  [I_STI_WIDTH-1:0]     STI_latch;
wire  [I_SSI_WIDTH-1:0]     SSI_latch;


wire 	[INFO_DATA_WIDTH*(2**O_TAM_WIDTH)-1:0]		info;
reg		[2**O_TAM_WIDTH-1:0]						info_tvalid;
wire	[2**O_TAM_WIDTH-1:0]						info_tready;

wire 	[INFO_DATA_WIDTH*(2**O_TAM_WIDTH)-1:0]		m_info;
wire	[2**O_TAM_WIDTH-1:0]						m_info_tvalid;
wire	[2**O_TAM_WIDTH-1:0]						m_info_tready;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		in_block_cnt<=0;
		in_block_cnt_1<=0;
		FDSSI_1<=0;
		FDSTI_1<=0;
		STI_1<=0;
		SSI_1<=0;
	end
	//锁存该block的info（FDSSI,SSI,STI,in_block_cnt）
	else if (SDMFi_d_tvalid&&SDMFi_d_tready&&SDMFi_d_tlast) begin
		in_block_cnt<=0;
		in_block_cnt_1<=in_block_cnt+1;
		FDSSI_1<=SDMFi_d_FDSSI;
		FDSTI_1<=SDMFi_d_FDSTI;
		STI_1<=SDMFi_d_STI;
		SSI_1<=SDMFi_d_SSI;
	end
	else if (SDMFi_d_tvalid&&SDMFi_d_tready) begin
		in_block_cnt<=in_block_cnt+1'b1;
	end
end
//将其描述信息写入对应的fdsti的fifo
assign  wr_id= SDMFi_d_FDSTI[O_TAM_WIDTH-1:0];

genvar i;
generate for (i=0; i<2**O_TAM_WIDTH; i=i+1) begin : info_valid_i
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // reset
      info_tvalid[i]<=1'b0;
    end
    else if (SDMFi_d_tvalid&&SDMFi_d_tready&&SDMFi_d_tlast&&(i==wr_id)) begin
      info_tvalid[i]<=1'b1;
    end
    else if(info_tvalid[i]&&info_tready[i])begin
      info_tvalid[i]<=1'b0;
    end
  end
end
endgenerate


//产生fifo
genvar i;
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
			.s_axis_tdata      (info[i*INFO_DATA_WIDTH+:INFO_DATA_WIDTH]),
			.s_axis_tvalid     (info_tvalid[i]),
			.s_axis_tready     (info_tready[i]),
			.m_axis_tdata      (m_info[i*INFO_DATA_WIDTH+:INFO_DATA_WIDTH]),
			.m_axis_tvalid     (m_info_tvalid[i]),
			.m_axis_tready     (m_info_tready[i])
		);
end
assign info[(i+1)*INFO_DATA_WIDTH:i*INFO_DATA_WIDTH] ={FDSSI_1,SSI_1,STI_1,in_block_cnt_1} ;
endgenerate


endmodule