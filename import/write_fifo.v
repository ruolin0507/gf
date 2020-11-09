//根据 2**THW 个FIFO的空满情况，将某个数据帧的数据从RAM中读出一部分，并写入相应的FIFO

module write_fifo
#(
  parameter             RAM_AW = 8,
  //liurl 
   parameter           FIFO_DEPTH_WIDTH         =4,
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
  parameter            FIFO_NUM_OBLK            =O_TOM_OFFSET-O_TAM_OFFSET,
  parameter            O_BLK_WITH               =O_SOM_OFFSET-O_SAM_OFFSET,
  parameter            INBL_CNT_MAX             = 8,
  parameter            INFO_DATA_WIDTH          =I_FDSSI_WIDTH+I_SSI_WIDTH+I_STI_WIDTH+INBL_CNT_MAX
)
(
  input  clk,
  input  rst,
  
//  input  [AW*(2**THW)-1:0] addr_r,
  output reg ren,
  output [RAM_AW-1:0] raddr,
  output [RAM_AW-1:0] rlength,
  
  input  dvalid,
  input  dlast,
  input  [I_DATA_WIDTH-1:0] dout,
  
  output [2**FIFO_NUM_OBLK-1:0] fifo_wrreq,
  output [I_DATA_WIDTH*(2**FIFO_NUM_OBLK)-1:0] fifo_data,
  output reg [2**FIFO_NUM_OBLK-1:0] fifo_wt,
  input  [2**FIFO_NUM_OBLK-1:0] fifo_empty,
  input  [(FIFO_DEPTH_WIDTH+1)*(2**FIFO_NUM_OBLK)-1:0] fifo_count
  //liurl
  input                                               addr_finish,
  input     [O_TAM_WIDTH-1:0]                         m_addr_valid,
  output reg[O_TAM_WIDTH-1:0]                         m_addr_ready,
  input     [INFO_DATA_WIDTH*(2**O_TAM_WIDTH)-1:0]    m_addr ,

  output    [O_TOM_WIDTH-1:0]                         o_blk_ptr
  //一次合并中同一个fdsti数据帧是否均写入fifo中 0为均写入

);

wire [2**FIFO_NUM_OBLK-1:0] half_empty;

wire [2**FIFO_NUM_OBLK-1:0] fifo_empty2;
wire [2**FIFO_NUM_OBLK-1:0] half_empty2;

wire                        any_empty;
wire                        any_half_empty;

reg [FIFO_NUM_OBLK-1:0]     empty_id;
reg [FIFO_NUM_OBLK-1:0]     half_empty_id;

reg                         nidle;
reg [FIFO_NUM_OBLK-1:0]     pid;

reg                         addr_finish_r;
wire [2**FIFO_NUM_OBLK-1:0] fifo_wt2;


wire [O_TAM_WIDTH-1:0]      i_ptr;
wire [RAM_AW-1:0]           s_addr[2**FIFO_NUM_OBLK-1:0];
wire [RAM_AW-1:0]           e_addr[2**FIFO_NUM_OBLK-1:0];
wire [I_FDSSI_WIDTH-1:0]    fdssi [2**FIFO_NUM_OBLK-1:0];

reg                            rd_data;
reg  [2**FIFO_NUM_OBLK-1:0]     first_ren;
reg  【2**FIFO_NUM_OBLK-1:0]     blk_bound;
reg  [RAM_AW-1:0]              now_addr[2**FIFO_NUM_OBLK-1:0];


wire [O_TOM_WIDTH-1:0]      o_ssi[2**FIFO_NUM_OBLK-1:0];
reg  [O_TOM_WIDTH-1:0]      o_ssi_r[2**FIFO_NUM_OBLK-1:0];

//assign raddr = addr_s[pid];

assign fifo_empty2 = fifo_empty & fifo_wt2 &(!bound);
assign half_empty2 = half_empty & fifo_wt2 &(!bound);

assign any_empty = |fifo_empty2;
assign any_half_empty = |half_empty2;

always@(posedge clk)
  if(rst)
    addr_finish_r <= 0;
  else
    addr_finish_r <= addr_finish;

genvar i;
generate for (i=0; i<2**FIFO_NUM_OBLK; i=i+1) begin: loop_i

  assign half_empty[i] = fifo_count[(i+1)*(FIFO_DEPTH_WIDTH+1)-1:i*(FIFO_DEPTH_WIDTH+1)] < 2**(FIFO_DEPTH_WIDTH-1);
  assign fifo_data[(i+1)*I_DATA_WIDTH-1:i*I_DATA_WIDTH] = dout;
 // assign addr_r_w[i] = addr_r[(i+1)*AW-1:i*AW];
 // assign fifo_wt2[i] = (addr_finish_r == 0) ? 1 : (addr_s[i] < addr_r_w[i]);
 //地址有效（若该地址对应数据被读走则m_addr_valid==0）
  assign fifo_wt2[i] = (addr_finish_r == 0) ? 1 : m_addr_valid[i+o_blk_ptr];
  assign fifo_wrreq[i] = (i == pid) ? dvalid : 0;

end
endgenerate
//liurl

integer k;
always@(fifo_empty2)
	for(k=2**FIFO_NUM_OBLK-1;k>=0;k=k-1)
		if(fifo_empty2[k])
			empty_id <= k;

always@(half_empty2)
	for(k=2**FIFO_NUM_OBLK-1;k>=0;k=k-1)
		if(half_empty2[k])
			half_empty_id <= k;

always@(posedge clk)
  if(rst)
    for(k=0;k<2**FIFO_NUM_OBLK;k=k+1)
      fifo_wt[k] <= 1;
  else
    fifo_wt <= fifo_wt2;

//rd_data=1时不能发起新的ren操作；rd_data表示在ren之后数据还未完全返回
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    rd_data<=1'b0;
  end
  else if (ren) begin
    rd_data<=1'b1;
  end
  else if (dvalid&&dlast)begin
    rd_data<=1'b0;
  end
end
//有空的fifo或者半空的fifo时发起ren
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
        ren<=1'b0;
        pid<=0;
  end
  else if(ren)begin
        ren<=1'b0;
  end
  else if (addr_finish&&(any_empty|any_half_empty)&&(!rd_data)) begin
    if (any_empty) begin
        pid <= empty_id;
        ren<=1'b1;
    end
    else if(any_half_empty)begin
        pid<=half_empty_id;
        ren<=1'b1;
    end
  end
end

assign raddr = s_addr[pid];
assign rlength = 2**(FIFO_DEPTH_WIDTH-1) <(e_addr[pid] - s_addr[pid])? 2**(FIFO_DEPTH_WIDTH-1) :e_addr[pid] - s_addr[pid];
//当fifo均到达边界时 o_blk_ptr改变
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    o_blk_ptr<=0;
  end
  else if (&blk_bound) begin
    if (o_blk_ptr==(O_TOM_WIDTH-1)) begin
      o_blk_ptr<=0;
    end
    else begin
      o_blk_ptr<=o_blk_ptr+1'b1;
    end
  end
end

genvar i;
generate for (i=0; i<2**FIFO_NUM_OBLK; i=i+1) begin: now_addr_i
//标记为（i_ptr）fifo的一个数据帧的是否为第一次ren，在读完一个数据帧后（m_addr_ready[i_ptr]）=0
    always @(posedge clk or posedge rst) begin
      if (rst) begin
        // reset
        first_ren[i]<=1'b0;
      end
      //一个数据帧的第一次ren
      else if ((!first_ren[i])&&ren&&(i==pid)) begin
        first_ren[i]<=1'b1;
      end
      else if(first_ren[i]&&(m_addr_ready[i_ptr]))begin
        first_ren[i]<=1'b0;
      end
    end
//

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      // reset
      now_addr[i]<=0;
    end
    //在一个数据帧的第一次ren初始化now_addr[i]
    else if ((!first_ren[i])&&ren&&(i==pid)) begin
      now_addr[i]<=s_addr[i];
    end
    //每次pid读完一次now_addr[i]变化
    else if ((i==pid)&&dvalid&&dlast) begin
      now_addr[i]<=rlength;
    end
  end
//起始地址和结束地址
//assign s_addr[i] = m_addr_valid[i_ptr] ? m_addr_info[i_ptr][2*RAM_AW-1:RAM_AW]:0;
//assign e_addr[i] = m_addr_valid[i_ptr] ? m_addr_info[i_ptr][RAM_AW-1:0]:0;
//assign fdssi[i] =m_addr_valid[i_ptr] ? m_addr_info[i_ptr][INFO_DATA_WIDTH:2*RAM_AW]:0;
assign i_ptr        = i + o_blk_ptr*2**FIFO_NUM_OBLK ;
assign s_addr[i]    = m_addr_valid[i_ptr] ? m_addr[i_ptr*INFO_DATA_WIDTH+2*RAM_AW-1:RAM_AW+i_ptr*INFO_DATA_WIDTH]:0;
assign e_addr[i]    = m_addr_valid[i_ptr] ? m_addr[i_ptr*INFO_DATA_WIDTH+RAM_AW-1:i_ptr*INFO_DATA_WIDTH]:0;
assign fdssi[i]     = m_addr_valid[i_ptr] ? m_addr[(i_ptr+1)*INFO_DATA_WIDTH:i_ptr*INFO_DATA_WIDTH+2*RAM_AW]:0;
//assign nxt_fdssi[i] = m_addr_valid[i_ptr] ?  m_addr[(i_ptr+1)*INFO_DATA_WIDTH:i_ptr*INFO_DATA_WIDTH+2*RAM_AW]:0;

//在该次读完后将读至e_addr[i]
//这里有风险是可能m_addr_valid[i_ptr]此刻并不有效
assign m_addr_ready[i_ptr]=(i==pid)&&((now_addr[i]+rlength)==e_addr[i])&&dvalid&&dlast;
    //到达o_blk的边界boundary
    //两种情况：1. o_ssi_r!=o_ssi 2.当前addr_fifo中为最后一个


always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    blk_bound[i]<=0;
  end
  else if(&blk_bound)begin
    blk_bound[i]<=1'b0;
  end
  else if (m_axis_tready[i_ptr]&&(fdssi[i][O_BLK_WITH-1:0]==(2**O_BLK_WITHT-1)) begin
    blk_bound[i]<=1'b1;
  end
  else if ((o_ssi[i]!=o_ssi_r[i])&&m_addr_valid[i_ptr]) begin
    blk_bound[i]<=1'b1;
  end
end
//
assign o_ssi[i]     = fdssi[i][I_FDSSI_WIDTH-1:O_BLK_WITH] ;
always @(posedge clk or posedge rst) begin
  if (rst) begin
    // reset
    o_ssi_r[i]<=0;
  end
  else if (m_addr_valid[i_ptr]) begin
    o_ssi_r[i]<=o_ssi[i];
  end
end

assign o_ssi_chg[i] = (o_ssi[i]!=o_ssi_r[i])?1'b1:1'b0;
assign bound[i] = blk_bound[i]|o_ssi_chg[i] ;

end
endgenerate


endmodule



