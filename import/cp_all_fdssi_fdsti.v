module cp_all_fdssi_fdsti #(
  parameter            O_SAM_WIDTH              =2         ,
  parameter            I_FDSTI_WIDTH            =28        ,
  parameter            I_FDSSI_WIDTH            =12        ,
    )(
    input  [              2**O_SAM_WIDTH-1:0] valid  ,
    input  [              2**O_SAM_WIDTH-1:0] wt     ,
    input  [I_FDSTI_WIDTH*2**O_SAM_WIDTH-1:0] FDSTI  ,
    input  [I_FDSSI_WIDTH*2**O_SAM_WIDTH-1:0] FDSSI  ,
    output                                    valid_o,
    output                                    wt_o   ,
    output [                 I_FDSTI_WIDTH-1] FDSTI_o,
    output [                 I_FDSSI_WIDTH-1] FDSSI_o
);

wire  [2**(O_SAM_WIDTH+1)-1:0]                      valid_w;
wire  [2**(O_SAM_WIDTH+1)-1:0]                      wt_w;
wire  [I_FDSTI_WIDTH*(2**(O_SAM_WIDTH+1))-1:0]      FDSTI_w;
wire  [I_FDSSI_WIDTH*(2**(O_SAM_WIDTH+1))-1:0]      FDSSI_w;

assign valid_w[2**O_SAM_WIDTH+=2**O_SAM_WIDTH]=valid;
assign wt_w[2**O_SAM_WIDTH+=2**O_SAM_WIDTH]=wt;
assign FDSTI_w[(2**O_SAM_WIDTH)*I_FDSTI_WIDTH+=(2**O_SAM_WIDTH)*I_FDSTI_WIDTH]=FDSTI;
assign FDSSI_w[(2**O_SAM_WIDTH)*I_FDSSI_WIDTH+=(2**O_SAM_WIDTH)*I_FDSSI_WIDTH]=FDSSI;

assign valid_o=valid_w[1];
assign wt_o=wt_w[1];
assign FDSSI_o=FDSSI_w[I_FDSSI_WIDTH+=I_FDSSI_WIDTH];
assign FDSTI_o=FDSTI_w[I_FDSTI_WIDTH+=I_FDSTI_WIDTH];

genvar i;
generate for (i=1; i<2**O_SAM_WIDTH; i=i+1) begin: loop_i
        cp2_fdsti_fdssi #(
            .I_FDSTI_WIDTH(I_FDSTI_WIDTH),
            .I_FDSSI_WIDTH(I_FDSSI_WIDTH)
        ) inst_cp2_fdsti_fdssi (
            .valid   (valid_w[2*i+1:2*i]),
            .wt      (wt_w[2*i+1:2*i]),
            .FDSTI   (FDSTI_w[(2*i)*I_FDSTI_WIDTH+=2*I_FDSTI_WIDTH]),
            .FDSSI   (FDSSI_w[(2*i)*I_FDSSI_WIDTH+=2*I_FDSTI_WIDTH]),
            .valid_o (valid_w[i]),
            .wt_o    (wt_w[i]),
            .FDSTI_o (FDSTI_w[i*I_FDSTI_WIDTH+=I_FDSTI_WIDTH]),
            .FDSSI_o (FDSSI_w[i*I_FDSSI_WIDTH+=I_FDSSI_WIDTH])
        );
 end
endgenerate
   
endmodule