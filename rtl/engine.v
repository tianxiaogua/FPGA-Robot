module engine(
					clk, //系统时钟50MHz
					rst_n, //系统复位信号

					pwm, //PWM输出IO
					pwm1, //PWM输出IO
					pwm2, //PWM输出IO
					pwm3,
					
					key
				); 

	input clk; //系统时钟50MHz
	input rst_n; //系统复位信号
	output pwm; //PWM输出IO
	output pwm1; //PWM输出IO
	output pwm2; //PWM输出IO
	output pwm3; //PWM输出IO
	
	input [7:0] key;

	
	wire clk;
	wire rst_n;
	
	wire pwm;
	wire pwm1;
	wire pwm2;
	wire pwm3;
	
	wire [7:0] key;
	
	
	reg  [27:0] cnt_f; //用来产生延时信号的加法器寄存器
	
	reg [7:0] angle1; //用来产生角度控制信号
	reg [7:0] angle2; //用来产生角度控制信号
	reg [7:0] angle3; //用来产生角度控制信号
	reg [7:0] angle0; //用来产生角度控制信号
	
	//角度控制模块 设计ok
	engine_driver engine_driver(
											.clk(clk),
											.rst_n(rst_n),
											.angle_setting(angle0),
											.pwm(pwm)
										); 
										
	//角度控制模块 设计ok
	engine_driver engine_driver1(
											.clk(clk),
											.rst_n(rst_n),
											.angle_setting(angle1),
											.pwm(pwm1)
										); 
										
	//角度控制模块 设计ok
	engine_driver engine_driver2(
											.clk(clk),
											.rst_n(rst_n),
											.angle_setting(angle2),
											.pwm(pwm2)
										); 
										
	//角度控制模块 设计ok
	engine_driver engine_driver3(
											.clk(clk),
											.rst_n(rst_n),
											.angle_setting(angle3),
											.pwm(pwm3)
										); 
	
	//根据输入的多个角度控制信号，增加或减少合适的角度
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			angle0 <= 8'd90;
			angle1 <= 8'd90;
			angle2 <= 8'd90;
			angle3 <= 8'd90;
			end
		else begin
			case (key)
				8'd6 : begin //1号舵机角度控制 增加
							if(angle0 == 8'd170) angle0 <= 8'd170;
							else angle0 <= angle0 + 8'd5;
						 end
				8'd7 : begin //1号舵机角度控制 减少
							if(angle0 == 8'd10) angle0 <=  8'd10;
							else angle0 <= angle0 - 8'd5;
						 end
				8'd8 : begin //2号舵机角度控制 增加
							if(angle1 == 8'd170) angle1 <= 8'd170;
							else angle1 <= angle1 + 8'd5;
						 end
				8'd9 : begin //2号舵机角度控制 减少
							if(angle1 == 8'd10) angle1 <=  8'd10;
							else angle1 <= angle1 - 8'd5;
						 end
				8'd10 : begin //3号舵机角度控制 增加
							if(angle2 == 8'd170) angle2 <= 8'd170;
							else angle2 <= angle2 + 8'd5;
						 end
				8'd11 : begin //3号舵机角度控制 减少
							if(angle2 == 8'd10) angle2 <=  8'd10;
							else angle2 <= angle2 - 8'd5;
						 end
				8'd12 : begin //4号舵机角度控制 增加
							if(angle3 == 8'd170) angle3 <= 8'd10;
							else angle3 <= angle3 + 8'd5;
						 end
				8'd13 : begin //4号舵机角度控制 减少
							if(angle3 == 8'd10) angle3 <=  8'd10;
							else angle3 <= angle3 - 8'd5;
						 end
				default : begin
							angle1 <= angle1;
							angle0 <= angle0;
							angle2 <= angle2;
							angle3 <= angle3;
							end
			endcase
		end
	end

endmodule






