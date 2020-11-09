module data_generator_sdmf_triple#(
parameter FDSTI_WIDTH = 32,
parameter FDSSI_WIDTH = 2,
parameter DATA_WIDTH = 24,
parameter TOM_WIDTH = 0,
parameter TOM_OFFSET = 2,
parameter SOM_OFFSET = 2
	)(
	input clk;
	
	);

parameter FDSTI_WIDTH = 32;
parameter FDSSI_WIDTH = 2;
parameter DATA_WIDTH = 24;
reg SDMFi_d_frame_valid;
reg SDMFi_d_FI_valid;
wire [FDSTI_WIDTH-1:0] SDMFi_d_FDSTI;
wire [FDSSI_WIDTH-1:0] SDMFi_d_FDSSI;
reg SDMFi_d_tvalid;
wire SDMFi_d_tready;
wire SDMFi_d_tlast;
wire [DATA_WIDTH-1:0] SDMFi_d_tdata;

parameter TOM_WIDTH = 0;
parameter TOM_OFFSET = 2;
parameter SOM_OFFSET = 2;
wire SDMFo_d_frame_valid;
wire SDMFo_d_FI_valid;
wire [FDSTI_WIDTH-TOM_WIDTH-1:0] SDMFo_d_FDSTI;
wire SDMFo_d_BI_valid;
wire [TOM_WIDTH+TOM_OFFSET-1:0] SDMFo_d_STI;
wire [7:0] SDMFo_d_TIL;
wire [FDSSI_WIDTH+SOM_OFFSET-1:0] SDMFo_d_SSI;
wire [7:0] SDMFo_d_SIL;
wire SDMFo_d_tvalid,SDMFo_d_tlast;
wire [DATA_WIDTH-1:0] SDMFo_d_tdata;
wire [1:0] s;
wire [1:0] t;
reg [FDSSI_WIDTH+FDSTI_WIDTH-1:0] count;
//assign SDMFi_d_tdata = {SDMFi_d_FDSTI[FDSTI_WIDTH-1:2],SDMFi_d_FDSSI,count[3:2],SDMFi_d_FDSTI[1:0],count[1:0]};

assign SDMFi_d_FDSSI = count[5:4];
assign SDMFi_d_FDSTI = count[FDSSI_WIDTH+FDSTI_WIDTH-1:6];
assign SDMFi_d_tdata = {2'b00,s,2'b00,t,count[7:0]};
assign s = count[3:2]  ;
assign t = count[1:0] ;
assign SDMFi_d_tlast = count[3:0] == 15;

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

endmodule