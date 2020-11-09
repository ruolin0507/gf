//{fdsti,s_addr,e_addr}->{fdssi,s_addr,e_addr}
//该模块将fdssi_fifo->fdsti_fifo（fdssi_fifo为FIFO内为相同FDSSI不同FDSTI，fdsti_fifo为FIFO内为相同FDSTI不同FDSSI）
//先选择FDSTI最小的，若相同，选择小的FDSSI，写入对应FDSTI的FIFO中
module fdssi_to_fdsti_fifo #(

    parameter            I_FDSTI_WIDTH            =28        ,
    parameter            I_FDSSI_WIDTH            =12        ,
    parameter            O_SAM_WIDTH              =2         ,
    parameter            O_TAM_WIDTH              =2         ,
    parameter               AWIDTH         = 32,
    parameter               DEPTH         = 4096,
    parameter               S_ADDR_INFO_WITH = I_FDSTI_WIDTH+2*AWIDTH,
    parameter               T_ADDR_INFO_WITH = I_FDSSI_WIDTH+2*AWIDTH

)(
    input  [                           2**O_SAM_WIDTH-1:0] addr_valid  ,
    output [                           2**O_SAM_WIDTH-1:0] addr_ready  ,
    input  [(I_FDSTI_WIDTH+2*AWIDTH-1)*(2**O_SAM_WIDTH)-1:0] addr        ,
    output [                           2**O_TAM_WIDTH-1:0] m_addr_valid,
    input  [                           2**O_TAM_WIDTH-1:0] m_addr_ready,
    output [(I_FDSSI_WIDTH+2*AWIDTH-1)*(2**O_TAM_WIDTH)-1:0]  m_addr,

    input                                               in_finish
);

wire [                2**O_SAM_WIDTH-1:0] valid  ;
wire [I_FDSTI_WIDTH*(2**O_SAM_WIDTH)-1:0] FDSTI  ;
wire [I_FDSSI_WIDTH*(2**O_SAM_WIDTH)-1:0] FDSSI  ;
wire                                      valid_o;
wire                                      wt_o   ;
wire [                   I_FDSTI_WIDTH-1] FDSTI_o;
wire [                   I_FDSSI_WIDTH-1] FDSSI_o;

reg in_finish_r     ;
reg fdsti_addr_valid;
reg[2*AWIDTH+I_FDSSI_WIDTH-1:0]     fdsti_addr;

wire [                             2**O_TAM_WIDTH-1:0] t_addr_valid;
wire [                             2**O_TAM_WIDTH-1:0] t_addr_ready;
wire [(I_FDSSI_WIDTH+2*AWIDTH-1)*(2**O_TAM_WIDTH)-1:0] t_addr      ;


genvar i;
generate for (i=0; i<2**O_SAM_WIDTH; i=i+1) begin: loop_i

    assign valid=addr_valid;
    assign FDSTI[i*I_FDSTI_WIDTH+:I_FDSTI_WIDTH]=addr[(i+1)*S_ADDR_INFO_WITH-1-I_FDSTI_WIDTH+:I_FDSTI_WIDTH];
    assign FDSSI[i*I_FDSSI_WIDTH+:I_FDSSI_WIDTH]=i;
//对于FDSSI_o的fifo发出addr_ready信号
    assign addr_ready[i] =((i==FDSSI_o)&&valid_o&&in_finish_r)?t_addr_ready[FDSSI_o]:0;

end
endgenerate


//输入比较器
     cp_all_fdssi_fdsti #(
            .O_SAM_WIDTH(O_SAM_WIDTH),
            .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
            .I_FDSSI_WIDTH(I_FDSSI_WIDTH)
        ) inst_cp_all_fdssi_fdsti (
            .valid   (valid),
            .wt      (wt),
            .FDSTI   (FDSTI),
            .FDSSI   (FDSSI),
            .valid_o (valid_o),
            .wt_o    (wt_o),
            .FDSTI_o (FDSTI_o),
            .FDSSI_o (FDSSI_o)
        );
//完全输入一次可合并数据后开始对fifo进行排序
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                // reset
                in_finish_r<=0;
            end
            else if (in_finish) begin
                in_finish_r<=1;
            end
        end           
//输入完毕信号到来后，对于valid_o,{fdssi_o,s_addr,e_addr}锁存一拍
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        fdsti_addr_valid<=0
    end
    else if ((in_finish_r)&&addr_ready[FDSTI_o]) begin
        fdsti_addr_valid<=valid_o;
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // reset
        fdsti_addr<=0;
    end
    else if ((in_finish_r)&&addr_ready[FDSTI_o]) begin
        fdsti_addr<={FDSSI_o,addr[i*S_ADDR_INFO_WITH+:2*AWIDTH]};
    end
end

//写入FDSTI_o fifo中
genvar j;
generate for (j=0; j<2**O_TAM_WIDTH; j=j+1) begin: T_LOOP
    assign t_addr_valid[j] =((j==FDSTI_o)&&valid_o&&in_finish_r)? fdsti_addr_valid:0;
    assign t_addr[j*T_ADDR_INFO_WITH+:T_ADDR_INFO_WITH] =((j==FDSTI_o)&&valid_o&&in_finish_r)?fdsti_addr:0 ;

     axis_fifo #(
            .DEPTH(DEPTH),
            .DATA_WIDTH(T_ADDR_INFO_WITH),
            .LAST_ENABLE(1'b0),
            .USER_ENABLE(1'b0),
            .FRAME_FIFO(1'b0)
        ) inst_axis_fifo (
            .clk               (clk),
            .rst               (rst),
            .s_axis_tdata      (t_addr[j*T_ADDR_INFO_WITH+:T_ADDR_INFO_WITH]),
            .s_axis_tvalid     (t_addr_valid[j]),
            .s_axis_tready     (t_addr_ready[j]),
            .m_axis_tdata      (m_addr[j*T_ADDR_INFO_WITH+:T_ADDR_INFO_WITH]),
            .m_axis_tvalid     (m_addr_tvalid[j]),
            .m_axis_tready     (m_addr_tready[j])
        );
end
endgenerate

endmodule