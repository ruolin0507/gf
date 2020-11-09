`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/27 15:49:45
// Design Name: 
// Module Name: reduce_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module reduce_tb_simple(

    );

        parameter FDSTI_WIDTH = 32;
        parameter FDSSI_WIDTH = 2;
        parameter I_DATA_WIDTH            = 16;
        parameter O_DATA_WIDTH = 24;
        parameter TOM_WIDTH = 0;
        parameter TOM_OFFSET = 2;
        parameter SOM_OFFSET = 2;
        parameter I_SMASK_WIDTH           = 4;

        parameter O_TAM_WIDTH             = 4;
        parameter O_TAM_OFFSET            = 4;
        parameter O_SAM_WIDTH             = 4;
        parameter O_SAM_OFFSET            = 4;
        parameter O_FDSSI_WIDTH           = 12;

reg clk,reset;
initial
    begin
        clk = 1;
        reset = 1;
        #10
        reset = 0;
    end
always
    begin
        #4
        clk = 0;
        #5
        clk = 1;
        #1
        clk = 1;
    end


reg SDMFi_d_frame_valid;
reg SDMFi_d_FI_valid;
wire [FDSTI_WIDTH-1:0] SDMFi_d_FDSTI;
wire [FDSSI_WIDTH-1:0] SDMFi_d_FDSSI;
reg SDMFi_d_tvalid;
wire SDMFi_d_tready;
wire SDMFi_d_tlast;
wire [I_DATA_WIDTH-1:0] SDMFi_d_tdata;


wire SDMFo_d_frame_valid;
wire SDMFo_d_FI_valid;
//modified by liurl 9.29
wire [FDSTI_WIDTH-O_TAM_WIDTH-1:0] SDMFo_d_FDSTI;
wire SDMFo_d_BI_valid;
wire [TOM_WIDTH+TOM_OFFSET-1:0] SDMFo_d_STI;
wire [7:0] SDMFo_d_TIL;
wire [FDSSI_WIDTH+SOM_OFFSET-1:0] SDMFo_d_SSI;
wire [7:0] SDMFo_d_SIL;
wire SDMFo_d_tvalid,SDMFo_d_tlast;
wire [O_DATA_WIDTH-1:0] SDMFo_d_tdata;
wire [O_SAM_OFFSET-1:0] s;
wire [O_TAM_OFFSET-1:0] t;
reg [FDSSI_WIDTH+FDSTI_WIDTH-1:0] count;
wire [O_FDSSI_WIDTH-1:0] SDMFo_d_FDSSI;
//assign SDMFi_d_tdata = {SDMFi_d_FDSTI[FDSTI_WIDTH-1:2],SDMFi_d_FDSSI,count[3:2],SDMFi_d_FDSTI[1:0],count[1:0]};
//modified by liurl 9.28

assign SDMFi_d_FDSSI = count[FDSSI_WIDTH+FDSTI_WIDTH-1:O_TAM_OFFSET+ O_SAM_OFFSET+O_TAM_WIDTH];
assign SDMFi_d_FDSTI = count[O_TAM_OFFSET+ O_SAM_OFFSET+O_TAM_WIDTH-1:O_TAM_OFFSET+ O_SAM_OFFSET];
assign SDMFi_d_tdata = {s,t,count[I_DATA_WIDTH- O_SAM_OFFSET- O_TAM_OFFSET-1:0]};
assign s = count[O_TAM_OFFSET+ O_SAM_OFFSET-1:O_TAM_OFFSET]  ;
assign t = count[O_TAM_OFFSET-1:0] ;
assign SDMFi_d_tlast =( count[O_TAM_OFFSET+ O_SAM_OFFSET-1:0] ==(2**(O_TAM_OFFSET+ O_SAM_OFFSET)-1)) ;

always@(posedge clk or posedge reset)
    if(reset)
        begin
            SDMFi_d_frame_valid <= 0;
            SDMFi_d_FI_valid <= 0;
            SDMFi_d_tvalid <= 0;
            count <= 0;            
        end
    else
        if(SDMFi_d_frame_valid == 0)
            begin
                if(count<25600)
                    begin
                        SDMFi_d_frame_valid <= 1;
                        SDMFi_d_FI_valid <= 1;
                    end
            end
        else
            if(SDMFi_d_FI_valid)
                begin
                    SDMFi_d_FI_valid <= 0;
                    SDMFi_d_tvalid <= 1;
                end
            else
                if(SDMFi_d_tready  )
                    begin
                        count <= count + 1;
                        if(SDMFi_d_tlast) begin
                            SDMFi_d_frame_valid <= 0;
                            SDMFi_d_tvalid <= 0;
                        end
                    end

SDMF_reduce_triple
#(
  .I_MAX_FDSSI        ({FDSSI_WIDTH{1'b1}}),
  .I_FDSSI_WIDTH      (FDSSI_WIDTH),     
  .I_FDSTI_WIDTH      (FDSTI_WIDTH), 
  .I_TOM_WIDTH        (TOM_WIDTH),
  .I_TOM_OFFSET       (TOM_OFFSET), 
  .I_SOM_OFFSET       (SOM_OFFSET),  
  .I_DATA_WIDTH       (I_DATA_WIDTH),
  .O_DATA_WIDTH       (O_DATA_WIDTH),
  .O_TAM_WIDTH        (O_TAM_WIDTH),
  .O_TAM_OFFSET       (O_TAM_OFFSET),
  .I_SMASK_WIDTH      (I_SMASK_WIDTH),
  .O_FDSSI_WIDTH      (O_FDSSI_WIDTH),
  .AXI_BUS_WIDTH      (32),
  .AXI_ADDR_LEN       (11),
  .I_DATA_WIDTH       (I_DATA_WIDTH)
)
reduce_merge_inst
(
  .clk(clk),
  .reset(reset),
  .PN_addr(3),
  .FDSSI_L(1),
  .FDSSI_H(3),
  .SDMFi_d_EFF(0),                   
  .SDMFi_d_PCF(0),                  
  .SDMFi_d_FDSTI(SDMFi_d_FDSTI),                 
  .SDMFi_d_FDSSI(SDMFi_d_FDSSI),                
  .SDMFi_d_FI_valid({1'b0,SDMFi_d_frame_valid}),                                                  
  .SDMFi_d_STI(0),                  
  .SDMFi_d_TIL(0),                 
  .SDMFi_d_SSI(0),                
  .SDMFi_d_SIL(0),                   
  .SDMFi_d_BI_valid({1'b0,SDMFi_d_frame_valid}),                
  .SDMFi_d_tvalid(SDMFi_d_tvalid),
  .SDMFi_d_tready(SDMFi_d_tready),
  .SDMFi_d_tlast(SDMFi_d_tlast),
  .SDMFi_d_tdata(SDMFi_d_tdata),
  .SDMFi_d_frame_valid(SDMFi_d_frame_valid),           
  .SDMFi_d_EF_ack(),                
  .SDMFo_d_PCF(),                   
  .SDMFo_d_FDSTI(SDMFo_d_FDSTI),  
  .SDMFo_d_FDSSI (SDMFo_d_FDSSI),               
  .SDMFo_d_FI_valid(SDMFo_d_FI_valid),                                                  
  .SDMFo_d_STI(SDMFo_d_STI),                    
  .SDMFo_d_TIL(SDMFo_d_TIL),                   
  .SDMFo_d_SSI(SDMFo_d_SSI),                 
  .SDMFo_d_SIL(SDMFo_d_SIL),                 
  .SDMFo_d_BI_valid(SDMFo_d_BI_valid),                
  .SDMFo_d_tvalid(SDMFo_d_tvalid),
  .SDMFo_d_tready(1),
  .SDMFo_d_tlast(SDMFo_d_tlast),
  .SDMFo_d_tdata(SDMFo_d_tdata),
  .SDMFo_d_frame_valid(SDMFo_d_frame_valid)             
);

endmodule
