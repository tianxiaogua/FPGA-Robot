module Other_sensors(
								clk,
								rst_n,
								
								Infrared_signal,
								noise_signal,
								Gas_signal,
								
								signal_data_ASCII_2,
								signal_data_ASCII_1,
								signal_data_ASCII_0
							);
								
	input clk,rst_n;	
	
	input Infrared_signal;	//红外信号
	input noise_signal;	//噪声信号
	input Gas_signal;	 //有害气体信号
	
	output [7:0] signal_data_ASCII_2;
	output [7:0] signal_data_ASCII_1;
	output [7:0] signal_data_ASCII_0;

	wire clk,rst_n;
	
	wire Infrared_signal;	//红外信号
	wire noise_signal;	//噪声信号
	wire Gas_signal;	 //有害气体信号
	
	reg [7:0] signal_data_ASCII_2;
	reg [7:0] signal_data_ASCII_1;
	reg [7:0] signal_data_ASCII_0;
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			signal_data_ASCII_2 <= 8'h30;
			signal_data_ASCII_1 <= 8'h30;
			signal_data_ASCII_0 <= 8'h30;
			end
		else begin
			if(Infrared_signal)	signal_data_ASCII_2 <= 8'h31;
			else	signal_data_ASCII_2 <= 8'h30;
			
			if(noise_signal)	signal_data_ASCII_1 <= 8'h31;
			else	signal_data_ASCII_1 <= 8'h30;
			
			if(Gas_signal)	signal_data_ASCII_0 <= 8'h31;
			else	signal_data_ASCII_0 <= 8'h30;
		end
	end
	
	
endmodule
