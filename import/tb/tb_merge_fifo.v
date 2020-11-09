module tb_merge_fifo#()();

	parameter DW               = 8;
	parameter SW               = 4;
	parameter SHW              = 32;
	parameter THW              = 2;
	parameter THHW             = 32;
	parameter FIFO_DEPTH_WIDTH = 8;
	parameter CLK_PERIOD       =4;
	reg 			clk=1'b1;
	reg            reset;
	wire            i_ready;
	reg            i_valid;
	reg            i_last;
	reg   [DW-1:0] i_data;

	wire            o_ready=1'b1;
	wire            o_valid;
	wire            o_last;
	wire   [DW-1:0] o_data;
	wire  [THW-1:0] o_th;
	wire  [SHW-1:0] o_sh;
	wire [THHW-1:0] o_thh;
	wire    [THW:0] ptr;
always #(CLK_PERIOD/2) clk=~clk;

initial
	begin
		reset=1'b1;
		#10
		reset=1'b0;
		#10
		#1
		i_valid=1'b1;
		i_data=8'h10;
		i_last=1'b0;
		#CLK_PERIOD
		i_data=8'h14;
		#CLK_PERIOD
		i_data=8'h18;
		#CLK_PERIOD
		i_data=8'h1c;
		#CLK_PERIOD
		i_data=8'h20;
		#CLK_PERIOD
		i_data=8'h24;
		i_last=1'b1;
		#CLK_PERIOD
		i_valid=1'b0;
		i_data=8'h00;
		i_last=1'b0;
		#CLK_PERIOD
		i_last=1'b1;
		#CLK_PERIOD
		i_last=1'b0;
		#CLK_PERIOD
		i_valid=1'b1;
		i_data=8'h02;
		#CLK_PERIOD
		i_data=8'h03;
		#CLK_PERIOD
		i_data=8'h04;
		#CLK_PERIOD
		i_data=8'h0d;
		i_last=1'b1; 
		#CLK_PERIOD
		i_data=8'h14;
		i_last=1'b0;
		#CLK_PERIOD
		i_data=8'h16;
		#CLK_PERIOD
		i_data=8'h18;
		#CLK_PERIOD
		i_data=8'h1f;
		#CLK_PERIOD
		i_data=8'h28;
		i_last=1'b1;
		#CLK_PERIOD
		i_valid=1'b0;
		i_data=8'h00;
		i_last=1'b0;

	end
	merge_fifo #(
			.DW(DW),
			.SW(SW),
			.SHW(SHW),
			.THW(THW),
			.THHW(THHW),
			.FIFO_DEPTH_WIDTH(FIFO_DEPTH_WIDTH)
		) inst_merge_fifo (
			.clk     (clk),
			.reset   (reset),
			.i_ready (i_ready),
			.i_valid (i_valid),
			.i_last  (i_last),
			.i_data  (i_data),
			.i_sh    (i_sh),
			.i_thh   (i_thh),
			.ptr     (ptr),
			.o_ready (o_ready),
			.o_valid (o_valid),
			.o_last  (o_last),
			.o_data  (o_data),
			.o_th    (o_th),
			.o_sh    (o_sh),
			.o_thh   (o_thh)
		);
endmodule