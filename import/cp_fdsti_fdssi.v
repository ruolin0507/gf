//输出FDSTI小的值
module cp2_fdsti_fdssi #(
    parameter I_FDSTI_WIDTH = 28,
    parameter I_FDSSI_WIDTH = 12
) (
    input  [              1:0] valid  ,
    input  [              1:0] wt     ,
    input  [I_FDSTI_WIDTH*2-1] FDSTI  ,
    input  [I_FDSSI_WIDTH*2-1] FDSSI  ,
    output                     valid_o,
    output                     wt_o   ,
    output [  I_FDSTI_WIDTH-1] FDSTI_o,
    output [  I_FDSSI_WIDTH-1] FDSSI_o
);


    input [I_FDSTI_WIDTH*2-1] FDSTI_in[1:0];


    genvar i;
    generate for (i=0; i<2; i=i+1) begin : FDSTI_in
        assign FDSTI_in[i] =FDSTI[i*I_FDSTI_WIDTH+=I_FDSTI_WIDTH] ;

    end
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
        num=(FDSTI_in[1]<FDSTI_in[0])?1:0;
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
assign FDSTI_o=FDSTI[num*I_FDSTI_WIDTH+=I_FDSTI_WIDTH] ;
assign FDSSI_o=FDSSI[num*I_FDSSI_WIDTH+=I_FDSSI_WIDTH] ;
endmodule
