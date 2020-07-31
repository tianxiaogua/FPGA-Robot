module  uart_rx(
					  // system signals
					  input sclk ,
					  input s_rst_n ,
					  // UART Interface
					  input rs232_rx ,
					  // others
					  output  reg [ 7:0]  rx_data ,
					  output  reg po_flag
					);


	`ifndef SIM
	localparam      BAUD_END = 433;
	`else
	localparam      BAUD_END = 28;
	`endif
	localparam      BAUD_M = BAUD_END/2 - 1;
	localparam      BIT_END = 8;

	reg rx_r1;
	reg rx_r2;
	reg rx_r3;
	reg rx_flag;
	reg [12:0] baud_cnt;
	reg bit_flag;
	reg [ 3:0] bit_cnt;

	wire rx_neg;


	assign  rx_neg  =       ~rx_r2 & rx_r3;

	always  @(posedge sclk) begin
			  rx_r1   <=      rs232_rx;
			  rx_r2   <=      rx_r1;
			  rx_r3   <=      rx_r2;
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 rx_flag <=      1'b0;
			  else if(rx_neg == 1'b1)
						 rx_flag <=      1'b1;
			  else if(bit_cnt == 'd0 && baud_cnt == BAUD_END)
						 rx_flag <=      1'b0;
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 baud_cnt        <=      'd0;
			  else if(baud_cnt == BAUD_END)
						 baud_cnt        <=      'd0;
			  else if(rx_flag == 1'b1)
						 baud_cnt        <=      baud_cnt + 1'b1;
			  else
						 baud_cnt        <=      'd0;
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 bit_flag        <=      1'b0;
			  else if(baud_cnt == BAUD_M)
						 bit_flag        <=      1'b1;
			  else
						 bit_flag        <=      1'b0;
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 bit_cnt <=      'd0;
			  else if(bit_flag == 1'b1 && bit_cnt == BIT_END) 
						 bit_cnt <=      'd0;
			  else if(bit_flag == 1'b1)
						 bit_cnt <=      bit_cnt + 1'b1;
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 rx_data <=      'd0;
			  else if(bit_flag == 1'b1 && bit_cnt >= 'd1)
						 rx_data <=      {rx_r2, rx_data[7:1]};
	end

	always  @(posedge sclk or negedge s_rst_n) begin
			  if(s_rst_n == 1'b0)
						 po_flag <=      1'b0;
			  else if(bit_cnt == BIT_END && bit_flag == 1'b1)
						 po_flag <=      1'b1;
			  else
						 po_flag <=      1'b0;
	end

endmodule