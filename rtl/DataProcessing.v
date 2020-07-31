
module DataProcessing(
								clk, //系统时钟50MHz
								rst_n, //系统复位信号
								target_data, //串口要发送的实际数据
								conter_data,
								data_valid,
								
								Temperature_data_ASCII_5,
								Temperature_data_ASCII_4,
								Temperature_data_ASCII_3,
								Temperature_data_ASCII_2,
								Temperature_data_ASCII_1,
								Temperature_data_ASCII_0,
								
								humidity_data_ASCII_5,
								humidity_data_ASCII_4,
								humidity_data_ASCII_3,
								humidity_data_ASCII_2,
								humidity_data_ASCII_1,
								humidity_data_ASCII_0,
								
								length_data_ASCII_5,
								length_data_ASCII_4,
								length_data_ASCII_3,
								length_data_ASCII_2,
								length_data_ASCII_1,
								length_data_ASCII_0,
								
								signal_data_ASCII_2,
								signal_data_ASCII_1,
								signal_data_ASCII_0
							);
							
	
	input clk; //系统时钟50MHz
	input rst_n;//系统复位信号
	
	output [7:0] target_data; //串口要发送的实际数据
	
	input [7:0] conter_data; 
	
	input [31:0] data_valid;
	
	input [7:0]Temperature_data_ASCII_5;
	input [7:0]Temperature_data_ASCII_4;
	input [7:0]Temperature_data_ASCII_3;
	input [7:0]Temperature_data_ASCII_2;
	input [7:0]Temperature_data_ASCII_1;
	input [7:0]Temperature_data_ASCII_0;
									
	input [7:0]humidity_data_ASCII_5;
	input [7:0]humidity_data_ASCII_4;
	input [7:0]humidity_data_ASCII_3;
	input [7:0]humidity_data_ASCII_2;
	input [7:0]humidity_data_ASCII_1;
	input [7:0]humidity_data_ASCII_0;
									
	input [7:0]length_data_ASCII_5;
	input [7:0]length_data_ASCII_4;
	input [7:0]length_data_ASCII_3;
	input [7:0]length_data_ASCII_2;
	input [7:0]length_data_ASCII_1;
	input [7:0]length_data_ASCII_0;
	
	input [7:0] signal_data_ASCII_2;
	input [7:0] signal_data_ASCII_1;
	input [7:0] signal_data_ASCII_0;
	
	wire clk;
	wire rst_n;//系统复位信号
	
	reg [7:0] target_data; //串口要发送的实际数据
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			target_data <= 8'h00;
		else begin
			case(conter_data)
					12'd0 :  target_data<= 8'h28;
					12'd1 :  target_data<= data_valid[31:24]; //有用 湿度的第一位
					12'd2 :  target_data<= data_valid[23:16];
					12'd3 :  target_data<= data_valid[15:8];
					12'd4 :  target_data<= data_valid[7:0]; 
					12'd5 :  target_data<= 8'h29;
					12'd6 :  target_data<= 8'h28;
					12'd7 :  target_data<= Temperature_data_ASCII_5;
					12'd8 :  target_data<= Temperature_data_ASCII_4;
					12'd9 :  target_data<= Temperature_data_ASCII_3;
					12'd10:  target_data<= Temperature_data_ASCII_2;
					12'd11:  target_data<= 8'h2E; //小数点的位置
					12'd12:  target_data<= Temperature_data_ASCII_1;
					12'd13:  target_data<= Temperature_data_ASCII_0;
					12'd14 : target_data<= 8'h29;
					12'd15 : target_data<= 8'h28;
					12'd16 : target_data<= humidity_data_ASCII_5;
					12'd17 : target_data<= humidity_data_ASCII_4;
					12'd18 : target_data<= humidity_data_ASCII_3;
					12'd19 : target_data<= humidity_data_ASCII_2;
					12'd20 : target_data<= 8'h2E; //小数点的位置
					12'd21 : target_data<= humidity_data_ASCII_1;
					12'd22 : target_data<= humidity_data_ASCII_0;
					12'd23 : target_data<= 8'h29;
					12'd24 : target_data<= 8'h28;
					12'd25 : target_data<= length_data_ASCII_5;
					12'd26 : target_data<= length_data_ASCII_4;
					12'd27 : target_data<= length_data_ASCII_3;
					12'd28 : target_data<= length_data_ASCII_2;
					12'd29 : target_data<= length_data_ASCII_1;
					12'd30 : target_data<= length_data_ASCII_0;
					12'd31 : target_data<= 8'h29;
					12'd32 : target_data<= 8'h28;
					12'd33 : target_data<= signal_data_ASCII_2;
					12'd34 : target_data<= signal_data_ASCII_1;
					12'd35 : target_data<= signal_data_ASCII_0;
					12'd36 : target_data<= 8'h29;
				default	:  target_data<= 8'h21;
			endcase
		end
	end
endmodule