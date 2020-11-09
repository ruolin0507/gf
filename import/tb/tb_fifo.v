module tb_fifo#(
	)();
reg clk=0;

	parameter WIDTH       = 8;
	parameter DEPTH_WIDTH = 8;
	reg                 rst;
	wire                 full;
	reg                 wr_en;
	reg      [WIDTH-1:0] din;
	wire                 empty;
	reg                 rd_en;
	wire     [WIDTH-1:0] dout;
	wire [DEPTH_WIDTH:0] count;

always #2 clk=~clk;
initial
	begin
		rst=1'b1;
		#100
		rst=1'b0;

		wr_en=1'b1;
		#30 wr_en=1'b0;
		#10 wr_en=1'b1;
		#100 wr_en=1'b0;

	end
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		din<=8'b1;
		wr_en<=1'b0;
	end
	else  begin
		wr_en<=1'b1;
		din<=din+1'b1;
	end
end
initial
	begin
			rd_en=1'b0;
		#30 rd_en=1'b1;
		#50 rd_en=1'b0;
		#40 rd_en=1'b1;
		#31 rd_en=1'b0;
	end
	fifo #(
			.WIDTH(WIDTH),
			.DEPTH_WIDTH(DEPTH_WIDTH)
		) inst_fifo (
			.clk   (clk),
			.rst   (rst),
			.full  (full),
			.wr_en (wr_en),
			.din   (din),
			.empty (empty),
			.rd_en (rd_en),
			.dout  (dout),
			.count (count)
		);
endmodule