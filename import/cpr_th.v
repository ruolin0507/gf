// N 元比较器， N=2**THW
module cpr_th
#(
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
  parameter            O_SOM_OFFSET             =3         
)
(  
  //输入 2**O_TOM_WIDTH 个{FDSSI,SSI,s,FDSTI}
  input [2**O_TOM_WIDTH-1:0]                            valid,
  input [2**O_TOM_WIDTH-1:0]                            wt,
  input [I_FDSSI_WIDTH*(2**O_TOM_WIDTH)-1:0]            FDSSI,
  input [O_TOM_WIDTH*(2**O_TOM_WIDTH)-1:0]              FDSTI,
  input [I_SSI_WIDTH*(2**O_TOM_WIDTH)-1:0]              SSI,
  input [I_SAM_OFFSET*(2**O_TOM_WIDTH)-1:0]             s,
  //输出 s 最小 {FDSSI,SSI,s,FDSTI}
  output                                    valid_o,
  output                                    wt_o,
  output   [I_FDSSI_WIDTH-1:0]              FDSSI_o,
  output   [O_TOM_WIDTH-1:0]               FDSTI_o,
  output   [I_SSI_WIDTH-1:0]                SSI_o,
  output   [I_SAM_OFFSET-1:0]               s_o
);


  wire   [2**(O_TOM_WIDTH+1)-1:0]                              valid_w,
  wire   [2**(O_TOM_WIDTH+1)-1:0]                              wt_w,
  wire   [I_FDSSI_WIDTH*(2**(O_TOM_WIDTH+1))-1:0]              FDSSI_w,
  wire   [O_TOM_WIDTH*(2**(O_TOM_WIDTH+1))-1:0]               FDSTI_w,
  wire   [I_SSI_WIDTH*(2**(O_TOM_WIDTH+1))-1:0]                SSI_w,
  wire   [I_SAM_OFFSET*(2**(O_TOM_WIDTH+1))-1:0]               s_w

assign valid_w[2**(O_TOM_WIDTH+1)-1:2**O_TOM_WIDTH]                               = valid;
assign wt_w[2**(O_TOM_WIDTH+1)-1:2**O_TOM_WIDTH]                                  = wt;
assign FDSTI_w[O_TOM_WIDTH*(2**(O_TOM_WIDTH+1))-1:O_TOM_WIDTH*(2**O_TOM_WIDTH)] =FDSTI ;
assign FDSSI_w[I_FDSSI_WIDTH*(2**(O_TOM_WIDTH+1))-1:I_FDSSI_WIDTH*(2**O_TOM_WIDTH)] =FDSSI;
assign SSI_w[I_SSI_WIDTH*(2**(O_TOM_WIDTH+1))-1:I_SSI_WIDTH*(2**O_TOM_WIDTH)] =SSI ;
assign s_w[I_SAM_OFFSET*(2**(O_TOM_WIDTH+1))-1:I_SAM_OFFSET*(2**O_TOM_WIDTH)]    = s;

assign valid_o = valid_w[1];
assign wt_o    = wt_w[1];
assign s_o     = s_w[I_SAM_OFFSET*2-1:I_SAM_OFFSET];
assign FDSTI_o = FDSTI_w[O_TOM_WIDTH*2-1:O_TOM_WIDTH];
assign FDSSI_o = FDSSI_w[I_FDSSI_WIDTH*2-1:I_FDSSI_WIDTH];
assign SSI_o   = SSI_w[I_SSI_WIDTH*2-1:I_SSI_WIDTH];


// 2**O_TOM_WIDTH 元比较器通过 2**O_TOM_WIDTH-1 个二元比较器级联实现
genvar i;
generate for (i=1; i<2**O_TOM_WIDTH; i=i+1) begin: loop_i

  cpr_2 #(
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
    ) inst_cpr_2 (
      .valid   (valid_w[i*2+1:i*2]),
      .wt      (wt_w[i*2+1:i*2]),
      .FDSSI   (FDSSI[I_FDSSI_WIDTH*(i*2+2)-1:I_FDSSI_WIDTH*i*2]),
      .FDSTI   (FDSTI[O_TOM_WIDTH*(i*2+2)-1:O_TOM_WIDTH*i*2]),
      .SSI     (SSI[I_SSI_WIDTH*(i*2+2)-1:I_SSI_WIDTH*i*2]),
      .s       (s[SW*(i*2+2)-1:SW*i*2]),
      .valid_o (valid_w[i]),
      .wt_o    (wt_w[i]),
      .FDSSI_o (FDSSI_w[I_FDSSI_WIDTH*(i+1)-1:I_FDSSI_WIDTH*i]),
      .FDSTI_o (FDSTI_w[O_TOM_WIDTH*(i+1)-1:O_TOM_WIDTH*i]),
      .SSI_o   (SSI_w[I_SSI_WIDTH*(i+1)-1:I_SSI_WIDTH*i]),
      .s_o     (s_w[I_SOM_OFFSET*(i+1)-1:I_SOM_OFFSET*i])
    );

end
endgenerate

endmodule