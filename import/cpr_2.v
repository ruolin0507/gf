//二元比较器
//输入 {FDSSI,SSI,s,FDSTI}
//输出 s 较小的{FDSSI,SSI,s,FDSTI}
//内部在父数据域进行变化
module cpr_2
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
  parameter            O_SOM_OFFSET             =3         ,
)
(

  // valid = 1             表示输入数据是有效的
  // valid = 0 且 wt = 1   表示输入数据是无效的，且需要等待数据输入
  // valid = 0 且 wt = 0   表示输入数据是无效的，且不需要等待数据输入
  
 
  //liurl
  input       [1:0]                            valid,
  input       [1:0]                            wt,
  input [I_FDSSI_WIDTH*2-1:0]                  FDSSI,
  input [O_TOM_WIDTH*2-1:0]                  FDSTI,
  input [I_SSI_WIDTH*2-1:0]                    SSI,
  input [I_SAM_OFFSET*2-1:0]                   s,

  output reg                                   valid_o,
  output reg                                   wt_o,
  output wire  [I_FDSSI_WIDTH-1:0]             FDSSI_o,
  output wire  [O_TOM_WIDTH-1:0]             FDSTI_o,
  output wire  [I_SSI_WIDTH-1:0]               SSI_o,
  output wire  [I_SAM_OFFSET-1:0]              s_o
);

wire [I_FDSSI_WIDTH+I_SAM_OFFSET-1:0]         s_abs[1:0];  

//绝对s坐标
genvar i;
generate for (i=0; i<2; i=i+1) begin: loop_i
    assign s_abs[i] =(FDSSI[(i+1)*I_FDSSI_WIDTH-1:i*I_FDSSI_WIDTH]<<I_SAM_OFFSET)+(SSI[(i+1)*I_SOM_OFFSET-1:i*I_SOM_OFFSET])+s;
endgenerate
  

always @(*) begin
  valid_o=1'b0;
  wt_o=1'b1;
  num=0;
  case(valid)
    2'b11:
      begin
        valid_o=1;
        //修改为|wt
        wt_o=|wt;
        num=(s_abs[1]<s_abs[0])?1:0;
      end
    2'b10:
      begin
        valid_o= ~wt[0];
        wt_o= wt[0];
        num=1;
      end
    2'b01:
      begin
        valid_o= ~wt[1];
        wt_o= wt[1];
        num=0;
      end
    2'b00:
      begin
        valid_o= 0;
        wt_o= |wt;
      end
  endcase
end

assign           FDSSI_o=FDSSI[I_FDSSI_WIDTH*(num+1)-1:I_FDSSI_WIDTH*num];
assign           SSI_o=SSI[I_SSI_WIDTH*(num+1)-1:I_SSI_WIDTH*num];
assign           s_o=s[I_SAM_OFFSET*(num+1)-1:I_SAM_OFFSET*num];
assign           FDSTI_o=FDSTI[O_TOM_WIDTH*(num+1)-1:O_TOM_WIDTH*num];
   endmodule   


   