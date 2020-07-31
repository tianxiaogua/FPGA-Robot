module motor(
					clk, //系统时钟50MHz
					rst_n, //系统复位信号
					m1a, //电机1
					m1b, //电机1
					m2a, //电机2
					m2b, //电机2
					motor_setting //电机状态设置
				);

	input clk;
	input rst_n;
	input [7:0] motor_setting;
	
	output m1a;
	output m1b;
	output m2a;
	output m2b;
	
	wire clk;
	wire rst_n;
	wire [7:0] motor_setting;
	
	reg m1a;
	reg m1b;
	reg m2a;
	reg m2b;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			m1a <= 0;
			m2a <= 0;
			m1b <= 0;
			m2b <= 0;
			end
		else begin
			case (motor_setting)
				8'd5: begin //停止状态
							m1a <= 0;
							m1b <= 0;
							m2a <= 0;
							m2b <= 0;
							end
				8'd1: begin //前进状态
							m1a <= 0;
							m1b <= 1;
							m2a <= 1;
							m2b <= 0;
							end
				8'd2: begin //后退状态
							m1a <= 1;
							m1b <= 0;
							m2a <= 0;
							m2b <= 1;
							end
				8'd3: begin //右转
							m1a <= 0;
							m1b <= 1;
							m2a <= 0;
							m2b <= 1;
							end
				8'd4: begin //左转
							m1a <= 1;
							m1b <= 0;
							m2a <= 1;
							m2b <= 0;
							end
				default:begin //左转
							m1a <= m1a;
							m1b <= m1b;
							m2a <= m2a;
							m2b <= m2b;
							end
						
			endcase
		end
			
	end
	
endmodule
	
	
	
	
	

	