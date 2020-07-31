module TopDesign(
						clk,
						rst_n,
						TX,
						tx2,
						RX,
						led,
						dht11_wire,
						Infrared_signal,
						noise_signal,
						Gas_signal,
						scl,
						sda,
						beep_pin,//蜂鸣器的引脚
						
						pwm, //PWM输出IO
						pwm1, //PWM输出IO
						pwm2, //PWM输出IO
						pwm3, //PWM输出IO
						m1a,
						m1b,
						m2a,
						m2b,
						
						Tring, //超声波模块信号控制引脚
						Echo	//距离长度数据引脚
						);

	//输入输出定义
	input clk;
	input rst_n;
	input RX;
	output TX;
	output tx2;
	output [3:0]led;
	
	inout dht11_wire;
	input Infrared_signal;	//红外信号
	input noise_signal;	//噪声信号
	input Gas_signal;	 //有害气体信号
	
	
	output scl;   // i2c时钟线
   inout sda ;   // i2c数据线
	
	output beep_pin; //蜂鸣器的引脚
	
	output pwm; //PWM输出IO
	output pwm1; //PWM输出IO
	output pwm2; //PWM输出IO
	output pwm3; //PWM输出IO
	
	output m1a;
	output m1b;
	output m2a;
	output m2b;
	
	output Tring; //超声波模块信号控制引脚
	input Echo;	//距离长度数据引脚
	
	wire clk;
	wire rst_n;
	
	wire TX;
	wire tx2;
	wire RX;
	
	wire [3:0]led;
	
	wire [11:0] conter_data;      //三种模式下输出不同的数据，第一种模式输出0至256 第二种模式输出0至1M 第三种是2M
	wire tx_down;          //串口发送完成一个字节的高电平脉冲
	wire[7:0] target_data; //串口要发送的实际数据
	
	wire [31:0] data_valid; //有效输出数据
	
	wire [19:0] num;
	
	wire [7:0] Temperature_data_ASCII_0;
	wire [7:0] Temperature_data_ASCII_1;
	wire [7:0] Temperature_data_ASCII_2;
	wire [7:0] Temperature_data_ASCII_3;
	wire [7:0] Temperature_data_ASCII_4;
	wire [7:0] Temperature_data_ASCII_5;
	
	wire [7:0] humidity_data_ASCII_0;
	wire [7:0] humidity_data_ASCII_1;
	wire [7:0] humidity_data_ASCII_2;
	wire [7:0] humidity_data_ASCII_3;
	wire [7:0] humidity_data_ASCII_4;
	wire [7:0] humidity_data_ASCII_5;
	 
	wire [7:0] key_value; //从ESP8266串口接收到的值
	wire [7:0] key_____value; //从ESP8266串口接收到的值
	
	wire beep_pin;//蜂鸣器的引脚
	
	wire pwm;
	wire pwm1;
	wire pwm2;
	wire pwm3;
	
	wire m1a;
	wire m1b;
	wire m2a;
	wire m2b;
	
	wire Tring;
	wire Echo;

	wire [7:0] length_data_ASCII_0;
	wire [7:0] length_data_ASCII_1;
	wire [7:0] length_data_ASCII_2;
	wire [7:0] length_data_ASCII_3;
	wire [7:0] length_data_ASCII_4;
	wire [7:0] length_data_ASCII_5;
	
	wire Infrared_signal;	//红外信号
	wire noise_signal;	//噪声信号
	wire Gas_signal;	 //有害气体信号
	
	wire [7:0] signal_data_ASCII_2;
	wire [7:0] signal_data_ASCII_1;
	wire [7:0] signal_data_ASCII_0;
	
	automation automation(
									.clk(clk),
									.rst_n(rst_n),
									.Gas_signal(Gas_signal), //烟雾模块数据
									.key_value_in(key_____value),
									.key_value_out(key_value)
								);
								
								
	get_length  get_length(
									.clk(clk), //系统时钟50MHz
									.rst_n(rst_n), //系统复位信号
									
									.Tring(Tring), //超声波模块信号控制引脚
									.Echo(Echo),	//距离长度数据引脚
									
									.data_ASCII_0(length_data_ASCII_0),
									.data_ASCII_1(length_data_ASCII_1),
									.data_ASCII_2(length_data_ASCII_2),
									.data_ASCII_3(length_data_ASCII_3),
									.data_ASCII_4(length_data_ASCII_4),
									.data_ASCII_5(length_data_ASCII_5)
								);
						
	//控制底盘的两个电机
	motor 		motor		(
									.clk(clk), //系统时钟50MHz
									.rst_n(rst_n), //系统复位信号
									.m1a(m1a), //电机1
									.m1b(m1b), //电机1
									.m2a(m2a), //电机2
									.m2b(m2b), //电机2
									.motor_setting(key_value) //电机状态设置
								);
				
	//主要模块，串口控制ESP8266部分
	main 			main		(
									.clk(clk),
									.rst_n(rst_n),
									.TX(TX),
									.tx2(tx2),
									.RX(RX),
									.led(led),
									.choose_data_length(0),    //选择发送模式，在256字节发送模式，1M字节和256字节之间选择 0 1 2 3分别代表三种模式和停止发送
									.conter_data(conter_data), //输出 三种模式下输出不同的数据，第一种模式输出0至256 第二种模式输出0至1M 第三种是2M
									//.tx_down(tx_down),         //串口发送完成一个字节的高电平脉冲
									.target_data(target_data),        //串口要发送的实际数据
									.Data_received(key_____value) //串口的数输出
								);	
	
	//蜂鸣器设计
	beep				beep  (
									.clk(clk), //系统时钟50MHz
									.rst_n(rst_n), //系统复位信号
									.beep_pin(beep_pin), //蜂鸣器的引脚
									.key(key_value) //按键或者一个少于1秒的高电平脉冲
							   );
	
	//控制四个舵机
	engine 		engine   (
									.clk(clk), //系统时钟50MHz
									.rst_n(rst_n), //系统复位信号

									.pwm(pwm), //PWM输出IO
									.pwm1(pwm1), //PWM输出IO
									.pwm2(pwm2), //PWM输出IO
									.pwm3(pwm3), //PWM输出IO
									
									.key(key_value)
							   ); 
	
	//控制温湿度传感器模块
	dht11_drive dht11_drive(
									.sys_clk(clk),   //系统时钟
									.rst_n(rst_n),   //系统复位             
									.dht11(dht11_wire),   //dht11温湿度传感器单总线
									.data_valid(data_valid)     //有效输出数据
									);  
	
	//控制温湿度传感器输出转换好的数据
	dht11_key   dht11_key(
									.sys_clk(clk),
									.sys_rst_n(rst_n),

									.data_valid(data_valid),

									.data_ASCII_0(Temperature_data_ASCII_0),
									.data_ASCII_1(Temperature_data_ASCII_1),
									.data_ASCII_2(Temperature_data_ASCII_2),
									.data_ASCII_3(Temperature_data_ASCII_3),
									.data_ASCII_4(Temperature_data_ASCII_4),
									.data_ASCII_5(Temperature_data_ASCII_5),
									
									.humidity_data_ASCII_0(humidity_data_ASCII_0),
									.humidity_data_ASCII_1(humidity_data_ASCII_1),
									.humidity_data_ASCII_2(humidity_data_ASCII_2),
									.humidity_data_ASCII_3(humidity_data_ASCII_3),
									.humidity_data_ASCII_4(humidity_data_ASCII_4),
									.humidity_data_ASCII_5(humidity_data_ASCII_5),
									.sign(),
									.point()
								);
						
	Other_sensors Other_sensors(
									.clk(clk),
									.rst_n(rst_n),
									
									.Infrared_signal(Infrared_signal),
									.noise_signal(noise_signal),
									.Gas_signal(Gas_signal),
									
									.signal_data_ASCII_2(signal_data_ASCII_2),
									.signal_data_ASCII_1(signal_data_ASCII_1),
									.signal_data_ASCII_0(signal_data_ASCII_0)
								);
		
	//控制检测模拟量						
	adda_top		 adda_top(   
									.sys_clk(clk)    ,    // 系统时钟
									.sys_rst_n(rst_n)  ,    // 系统复位
									.scl(scl)        ,    // i2c时钟线
									.sda(sda)        ,    // i2c数据线
									.num(num)
								);
							
	DataProcessing DataProcessing(
												.clk(clk), //系统时钟50MHz
												.rst_n(rst_n), //系统复位信号
												.target_data(target_data), //串口要发送的实际数据
												.conter_data(conter_data),
												.data_valid(data_valid),
												
												.Temperature_data_ASCII_5(Temperature_data_ASCII_5),
												.Temperature_data_ASCII_4(Temperature_data_ASCII_4),
												.Temperature_data_ASCII_3(Temperature_data_ASCII_3),
												.Temperature_data_ASCII_2(Temperature_data_ASCII_2),
												.Temperature_data_ASCII_1(Temperature_data_ASCII_1),
												.Temperature_data_ASCII_0(Temperature_data_ASCII_0),
												
												.humidity_data_ASCII_5(humidity_data_ASCII_5),
												.humidity_data_ASCII_4(humidity_data_ASCII_4),
												.humidity_data_ASCII_3(humidity_data_ASCII_3),
												.humidity_data_ASCII_2(humidity_data_ASCII_2),
												.humidity_data_ASCII_1(humidity_data_ASCII_1),
												.humidity_data_ASCII_0(humidity_data_ASCII_0),
												
												.length_data_ASCII_5(length_data_ASCII_5),
												.length_data_ASCII_4(length_data_ASCII_4),
												.length_data_ASCII_3(length_data_ASCII_3),
												.length_data_ASCII_2(length_data_ASCII_2),
												.length_data_ASCII_1(length_data_ASCII_1),
												.length_data_ASCII_0(length_data_ASCII_0),
												
												.signal_data_ASCII_2(signal_data_ASCII_2),
												.signal_data_ASCII_1(signal_data_ASCII_1),
												.signal_data_ASCII_0(signal_data_ASCII_0)
											
											);

endmodule 