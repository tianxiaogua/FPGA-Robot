module automation(
							clk,
							rst_n,
							Gas_signal,
							key_value_in,
							key_value_out
						);
						
	input clk;
	input rst_n;
	input Gas_signal;
	input [7:0] key_value_in;
	output [7:0] key_value_out;
	
	wire clk,rst_n;
	
	wire Gas_signal; //烟雾检测信号
	
	wire [7:0] key_value_in;
	
	reg [7:0] key_value_out;
	
	wire clk_05;
	
	reg stat;
	
	//产生周期为0.5秒钟的高电平脉冲，脉冲长度为一个时钟周期
	time05s time05s(
							.clk(clk), //系统时钟50MHz
							.rst_n(rst_n),
							.clk_05(clk_05)
						);
						
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			stat <= 0;
			end
		else if(key_value_in == 8'd15)
		   stat <= ! stat;
		else 
			stat <= stat;
	end
	
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			key_value_out <= 8'd17; //无效状态即为不控制
			end
			
		else if(stat)  //有上位控制的状态
			if(clk_05) 
				key_value_out <= 8'd12; //控制舵机旋转
			else 
				key_value_out <= 8'd17; //无效状态即为不控制
				
		else begin      //无上位机控制的状态
			if(!Gas_signal)
				key_value_out <= 8'd16;
			else
				key_value_out <= key_value_in;
				end
		end
		
endmodule


module time05s(
					clk, //系统时钟50MHz
					rst_n,
					clk_05
					);
	
	input clk; //系统时钟50MHz
	input rst_n;//系统复位信号
	
	output clk_05;
	wire clk,rst_n;

	reg [27:0] cont;
	reg clk_05;
	//产生0.5秒钟的高电平，随后全为低电平
	always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n) begin
				cont <= 0;
				clk_05 <= 0;
			end
			else if (cont == 28'd24999999)begin
				clk_05 <= 1;
				cont <= 28'd0;
				end
			else begin
				cont <= cont + 28'd1;
				clk_05 <= 0;
				end
		end
		
endmodule




