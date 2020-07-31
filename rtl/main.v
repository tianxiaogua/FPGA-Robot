module main(
				clk,
				rst_n,
				TX,
				tx2,
				RX,
				led,
				choose_data_length,    //选择发送模式，在256字节发送模式，1M字节和256字节之间选择 0 1 2 3分别代表三种模式和停止发送
				conter_data, //输出 三种模式下输出不同的数据，第一种模式输出0至256 第二种模式输出0至1M 第三种是2M
				//.tx_down(tx_down),         //串口发送完成一个字节的高电平脉冲
				target_data ,       //串口要发送的实际数据
				Data_received //串口的数输出
				);

	//输入输出定义
	input clk;
	input rst_n;
	input RX;
	output TX;
	output tx2;
	output [3:0]led;
	input [1:0] choose_data_length;
	input [7:0] target_data;
	output [11:0] conter_data;
	output [7:0] Data_received; //串口的数输出 不会直接输出数据，会输出标志
	
	wire clk; //系统时钟 板载50MHz晶振
	wire rst_n; //系统复位信号
	
	wire TX; //串口发送数据，连接esp8266的RX引脚
	wire RX; //串口接收数据，连接esp8266的TX引脚
	
	wire tx2;  //把esp8266发送到串口的数据转发到PC机上，连接PC上位机的RX引脚
	assign tx2 = RX; 
	
	wire [7:0] data;  //串口接收到的数据
	wire flag;  //接收完成标志
	wire tx_down; //串口发送完成的高电平脉冲
	
	reg en; //串口发送的使能信号
	reg [3:0] led;  //串口工作的状态指示信号
	
	reg [7:0]rec_data; //串口要发送的数据
	wire [7:0] target_data;
	reg [7:0] target_data_;
	
	reg [4:0]stata;  //接收指令的状态机
	reg [5:0]stata2; //发送指令的状态机

	reg [4:0]flag_work; //状态机的循环寄存器
	
	reg [7:0] Data_received;//串口的数输出
	reg [3:0] Data_received_sign; //串口获取的状态机标志
	
	reg [26:0] conter; //101 1111 0101 1110 0001 0000 0000 //用来延时
	localparam two_seconds    = 100000000; //用来延时2秒钟  20n时钟周期的1秒时间  1秒=1000000000 纳秒(ns) 
	localparam one_second     =  50000000; //用来延时1秒钟
	localparam ten_ms         =   1000000; //用来延时10毫秒
	
	wire [1:0] choose_data_length; //选择要发送的目标长度
	reg [11:0] conter_data; //1000 0000 0000 //计数器
	
	localparam _256data = 12'd256; //选择一次发送256字节
	localparam _1Mdata =  12'd1024; //选择一次发送1M字节
	localparam _2Mdata =  12'd2048; //选择一次发送2M字节
	 
	reg [1:0]Target_data_length; //选择要发送的数据长度 //默认0 发送256字节 1发送1M字节 2发送2M字节
	
	//-----------------------------------------------------
	//串口发送模块
	//-----------------------------------------------------
	uart_tx uart_tx(
				//input
				.clk(clk),//模块的时钟 50MHz
				.rst_n(rst_n), //系统复位信号
				.set_Baud_rate(4'd4),//波特率大小设置
				.data(rec_data), //要发送的一个字节数据
				.en(en),
				
				//output
				.TX(TX), //串口输出信号
				.tx_down(tx_down) //发送完成标志，每完成一次发送就产生一段时间高电平
				);
	
	//-----------------------------------------------------
	//串口接收模块
	//-----------------------------------------------------
	uart_rx uart_rx(
	
			// system signals
               .sclk(clk) ,
               .s_rst_n(rst_n),
         // UART Interface
               .rs232_rx(RX),
         // others
               .rx_data(data),
               .po_flag(flag)
				);	
	
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			target_data_ <= 8'd0;
		else
			target_data_ <= target_data;
	end
	//-----------------------------------------------------
	//主要状态机
	//初始化->确认ok标志->连接WiFi->确认ok标志->设置服务器模式->确认OK标志->设置端口号->确认OK标志->查询ip->等待连接标志->
	//  ->发送数据长度->延时10ms->发送数据->发送成功标志/发送失败重新连接
	//			^											|
	//			|											v
	//			———————每隔10ms发送一次数据————————	
	//-----------------------------------------------------
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			flag_work <= 0; //用于产生外层循环的状态机标志
			en <= 0;
			stata2 <=0; //用于内层产生字符串的状态机标志
			rec_data <= 0;  //要发送的字符串的数据的一个字节变量寄存器
			stata <= 0;  //接收状态内的状态机标志
			led <= 4'b1111;   //显示标志
			conter <= 27'd0;
			conter_data <= 0;
			//choose_data_length <= 2'd0;
		end
		else
		case(flag_work)
			4'd0:begin
				en <= 1;
				if(tx_down == 1'b1) //初始化向esp8266发送指令：AT+CWMODE_CUR=1 设置模块为sta模式，即作为设备去连接别人的WiFi热点；
					case(stata2) //41 54 2B 43 57 4D 4F 44 45 5F 43 55 52 3D 31 0D 0A 转成16进制数据，末尾需要加换行符和回车
						5'd0:  begin rec_data<= 8'h41 ; stata2<= 5'd1;end
						5'd1:  begin rec_data<= 8'h54 ; stata2<= 5'd2;end
						5'd2:  begin rec_data<= 8'h2B ; stata2<= 5'd3;end
						5'd3:  begin rec_data<= 8'h43 ; stata2<= 5'd4;end
						5'd4:  begin rec_data<= 8'h57 ; stata2<= 5'd5;end
						5'd5:  begin rec_data<= 8'h4D ; stata2<= 5'd6;end
						5'd6:  begin rec_data<= 8'h4F ; stata2<= 5'd7;end
						5'd7:  begin rec_data<= 8'h44 ; stata2<= 5'd8;end
						5'd8:  begin rec_data<= 8'h45 ; stata2<= 5'd9;end
						5'd9:  begin rec_data<= 8'h5F ; stata2<= 5'd10;end
						5'd10: begin rec_data<= 8'h43 ; stata2<= 5'd11;end
						5'd11: begin rec_data<= 8'h55 ; stata2<= 5'd12;end
						5'd12: begin rec_data<= 8'h52 ; stata2<= 5'd13;end
						5'd13: begin rec_data<= 8'h3D ; stata2<= 5'd14;end
						5'd14: begin rec_data<= 8'h31 ; stata2<= 5'd15;end
						5'd15: begin rec_data<= 8'h0D ; stata2<= 5'd16;end
						5'd16: begin rec_data<= 8'h0A ; stata2<= 5'd17;end 
						5'd17: begin rec_data<= 8'h0D ; stata2<= 5'd18;end
						5'd18: begin rec_data<= 8'h0A ; stata2<= 5'd19; end
						5'd19: begin en<=1; flag_work <= 4'd1; rec_data<= 8'h0 ; stata2 <=0;end
						default stata2 <=0;
					endcase
			end
			4'd1:begin
				if(flag == 1'b1) //接收判断 ：ok
					case(stata) 
						5'd0: begin if(data == 8'h4F)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h4B)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h0D)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd2; en<=0;end else stata <= 5'd0; end //43
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd2:begin
				en<=1;
				if(tx_down == 1'b1) //向esp8266发送指令： AT+CWJAP_DEF="tianxiaohua_2.4G","111111111" 连接WiFi
					case(stata2) //41 54 2B 43 57 4D 4F 44 45 5F 43 55 52 3D 31 0D 0A 
						6'd0: begin  rec_data<= 8'h41 ; stata2<= 6'd1;end
						6'd1: begin  rec_data<= 8'h54 ; stata2<= 6'd2;end
						6'd2: begin  rec_data<= 8'h2B ; stata2<= 6'd3;end
						6'd3: begin  rec_data<= 8'h43 ; stata2<= 6'd4;end
						6'd4: begin  rec_data<= 8'h57 ; stata2<= 6'd5;end
						6'd5: begin  rec_data<= 8'h4A ; stata2<= 6'd6;end
						6'd6: begin  rec_data<= 8'h41 ; stata2<= 6'd7;end
						6'd7: begin  rec_data<= 8'h50 ; stata2<= 6'd8;end
						6'd8: begin  rec_data<= 8'h5F ; stata2<= 6'd9;end
						6'd9: begin  rec_data<= 8'h44 ; stata2<= 6'd10;end
						6'd10: begin  rec_data<= 8'h45 ; stata2<= 6'd11;end
						6'd11: begin  rec_data<= 8'h46 ; stata2<= 6'd12;end
						6'd12: begin  rec_data<= 8'h3D ; stata2<= 6'd13;end
						6'd13: begin  rec_data<= 8'h22 ; stata2<= 6'd14;end
						6'd14: begin  rec_data<= 8'h74 ; stata2<= 6'd15;end
						6'd15: begin  rec_data<= 8'h69 ; stata2<= 6'd16;end
						6'd16: begin  rec_data<= 8'h61 ; stata2<= 6'd17;end
						6'd17: begin  rec_data<= 8'h6E ; stata2<= 6'd18;end
						6'd18: begin  rec_data<= 8'h78 ; stata2<= 6'd19;end
						6'd19: begin  rec_data<= 8'h69 ; stata2<= 6'd20;end
						6'd20: begin  rec_data<= 8'h61 ; stata2<= 6'd21;end
						6'd21: begin  rec_data<= 8'h6F ; stata2<= 6'd22;end
						6'd22: begin  rec_data<= 8'h68 ; stata2<= 6'd23;end
						6'd23: begin  rec_data<= 8'h75 ; stata2<= 6'd24;end
						6'd24: begin  rec_data<= 8'h61 ; stata2<= 6'd25;end
						6'd25: begin  rec_data<= 8'h5F ; stata2<= 6'd26;end
						6'd26: begin  rec_data<= 8'h32 ; stata2<= 6'd27;end
						6'd27: begin  rec_data<= 8'h2E ; stata2<= 6'd28;end
						6'd28: begin  rec_data<= 8'h34 ; stata2<= 6'd29;end
						6'd29: begin  rec_data<= 8'h47 ; stata2<= 6'd30;end
						6'd30: begin  rec_data<= 8'h22 ; stata2<= 6'd31;end
						6'd31: begin  rec_data<= 8'h2C ; stata2<= 6'd32;end
						6'd32: begin  rec_data<= 8'h22 ; stata2<= 6'd33;end
						6'd33: begin  rec_data<= 8'h31 ; stata2<= 6'd34;end
						6'd34: begin  rec_data<= 8'h31 ; stata2<= 6'd35;end
						6'd35: begin  rec_data<= 8'h31 ; stata2<= 6'd36;end
						6'd36: begin  rec_data<= 8'h31 ; stata2<= 6'd37;end
						6'd37: begin  rec_data<= 8'h31 ; stata2<= 6'd38;end
						6'd38: begin  rec_data<= 8'h31 ; stata2<= 6'd39;end
						6'd39: begin  rec_data<= 8'h31 ; stata2<= 6'd40;end
						6'd40: begin  rec_data<= 8'h31 ; stata2<= 6'd41;end
						6'd41: begin  rec_data<= 8'h31 ; stata2<= 6'd42;end
						6'd42: begin  rec_data<= 8'h22 ; stata2<= 6'd43;end
						6'd43: begin  rec_data<= 8'h0D ; stata2<= 6'd44;end
						6'd44: begin  rec_data<= 8'h0A ; stata2<= 6'd45;end
						6'd45: begin  en<=1; rec_data<= 8'h0 ; flag_work <= 4'd3; stata2 <=0; led <= 4'b1100;end
						default stata2 <=0;
					endcase
			end
			4'd3:begin
				if(flag == 1'b1) //接收判断 ：ok
					case(stata) 
						5'd0: begin if(data == 8'h4F)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h4B)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h0D)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd4; en<=0; led <= 4'b1000;end else stata <= 5'd0; end //43
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd4:begin
				en <= 1;
				if(tx_down == 1'b1) //向esp8266发送指令：AT+CIPMUX=1 设置成服务器可以多连模式；
					case(stata2) //41 54 2B 43 57 4D 4F 44 45 5F 43 55 52 3D 31 0D 0A 
						5'd0: begin  rec_data<= 8'h41 ; stata2<= 5'd1;end
						5'd1: begin  rec_data<= 8'h54 ; stata2<= 5'd2;end
						5'd2: begin  rec_data<= 8'h2B ; stata2<= 5'd3;end
						5'd3: begin  rec_data<= 8'h43 ; stata2<= 5'd4;end
						5'd4: begin  rec_data<= 8'h49 ; stata2<= 5'd5;end
						5'd5: begin  rec_data<= 8'h50 ; stata2<= 5'd6;end
						5'd6: begin  rec_data<= 8'h4D ; stata2<= 5'd7;end
						5'd7: begin  rec_data<= 8'h55 ; stata2<= 5'd8;end
						5'd8: begin  rec_data<= 8'h58 ; stata2<= 5'd9;end
						5'd9: begin  rec_data<= 8'h3D ; stata2<= 5'd10;end
						5'd10: begin rec_data<= 8'h31 ; stata2<= 5'd11;end
						5'd11: begin rec_data<= 8'h0D ; stata2<= 5'd12;end
						5'd12: begin rec_data<= 8'h0A ; stata2<= 5'd13;end
						5'd13: begin en<=1; flag_work <= 4'd5; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0000;end
						default stata2 <=0;
					endcase
			end
			4'd5:begin
				if(flag == 1'b1) //接收判断 ：ok
					case(stata) 
						5'd0: begin if(data == 8'h4F)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h4B)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h0D)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd6; en<=0; led <= 4'b1111; end else stata <= 5'd0; end //43
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd6:begin
				en <= 1;
				if(tx_down == 1'b1) //向esp8266发送指令： AT+CIPSERVER=1,8266 设置端口的端口号，可以自己定义
					case(stata2) //41 54 2B 43 57 4D 4F 44 45 5F 43 55 52 3D 31 0D 0A 
						5'd0: begin   rec_data<= 8'h41 ;  stata2<= 5'd1;end
						5'd1: begin   rec_data<= 8'h54 ;  stata2<= 5'd2;end
						5'd2: begin   rec_data<= 8'h2B ;  stata2<= 5'd3;end
						5'd3: begin   rec_data<= 8'h43 ;  stata2<= 5'd4;end
						5'd4: begin   rec_data<= 8'h49 ;  stata2<= 5'd5;end
						5'd5: begin   rec_data<= 8'h50 ;  stata2<= 5'd6;end
						5'd6: begin   rec_data<= 8'h53 ;  stata2<= 5'd7;end
						5'd7: begin   rec_data<= 8'h45 ;  stata2<= 5'd8;end
						5'd8: begin   rec_data<= 8'h52 ;  stata2<= 5'd9;end
						5'd9: begin   rec_data<= 8'h56 ;  stata2<= 5'd10;end
						5'd10: begin  rec_data<= 8'h45 ;  stata2<= 5'd11;end
						5'd11: begin  rec_data<= 8'h52 ;  stata2<= 5'd12;end
						5'd12: begin  rec_data<= 8'h3D ;  stata2<= 5'd13;end
						5'd13: begin  rec_data<= 8'h31 ;  stata2<= 5'd14;end
						5'd14: begin  rec_data<= 8'h2C ;  stata2<= 5'd15;end
						5'd15: begin  rec_data<= 8'h38 ;  stata2<= 5'd16;end
						5'd16: begin  rec_data<= 8'h32 ;  stata2<= 5'd17;end
						5'd17: begin  rec_data<= 8'h36 ;  stata2<= 5'd18;end
						5'd18: begin  rec_data<= 8'h36 ;  stata2<= 5'd19;end
						5'd19: begin  rec_data<= 8'h0D ;  stata2<= 5'd20;end
						5'd20: begin  rec_data<= 8'h0A ;  stata2<= 5'd21;end
						5'd21: begin en<=1; flag_work <= 4'd7; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0111;end
						default stata2 <=0;
					endcase
			end
			4'd7:begin
				if(flag == 1'b1) //接收判断 ：ok
					case(stata) 
						5'd0: begin if(data == 8'h4F)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h4B)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h0D)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd8; en<=0; led <= 4'b1111; end else stata <= 5'd0; end //43
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd8:begin
				en <= 1;
				if(tx_down == 1'b1) //向esp8266发送指令：  AT+CIPSTA_CUR? 查询当前8266的IP地址，得到第一个数据ip后面的就是TCP服务器的IP地址；
					case(stata2) //41 54 2B 43 57 4D 4F 44 45 5F 43 55 52 3D 31 0D 0A 
						5'd0: begin  rec_data<= 8'h41 ;  stata2<= 5'd1;end
						5'd1: begin  rec_data<= 8'h54 ;  stata2<= 5'd2;end
						5'd2: begin  rec_data<= 8'h2B ;  stata2<= 5'd3;end
						5'd3: begin  rec_data<= 8'h43 ;  stata2<= 5'd4;end
						5'd4: begin  rec_data<= 8'h49 ;  stata2<= 5'd5;end
						5'd5: begin  rec_data<= 8'h50 ;  stata2<= 5'd6;end
						5'd6: begin  rec_data<= 8'h53 ;  stata2<= 5'd7;end
						5'd7: begin  rec_data<= 8'h54 ;  stata2<= 5'd8;end
						5'd8: begin  rec_data<= 8'h41 ;  stata2<= 5'd9;end
						5'd9: begin  rec_data<= 8'h5F ;  stata2<= 5'd10;end
						5'd10: begin rec_data<= 8'h43 ;  stata2<= 5'd11;end
						5'd11: begin rec_data<= 8'h55 ;  stata2<= 5'd12;end
						5'd12: begin rec_data<= 8'h52 ;  stata2<= 5'd13;end
						5'd13: begin rec_data<= 8'h3F ;  stata2<= 5'd14;end
						5'd14: begin rec_data<= 8'h0D ;  stata2<= 5'd15;end
						5'd15: begin rec_data<= 8'h0A ;  stata2<= 5'd16;end
						5'd16: begin en<=1; flag_work <= 4'd9; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0000;end
						default stata2 <=0;
					endcase
			end
			4'd9:begin
				if(flag == 1'b1) //接收判断 ：ok
					case(stata) 
						5'd0: begin if(data == 8'h4F)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h4B)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h0D)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd10; en<=1; led <= 4'b1111; end else stata <= 5'd0; end //43
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd10:begin
				if(flag == 1'b1)// 接收判断 ： 0,CONNECT 判断连接状态
					case(stata) //30 2C 43 4F 4E 4E 45 43 54 
						5'd0: begin if(data == 8'h30)stata <= 5'd1; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h2C)stata <= 5'd2; else stata <= 5'd0; end //54
						5'd2: begin if(data == 8'h43)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h4F)stata <= 5'd4; else stata <= 5'd0; end //41
						5'd4: begin if(data == 8'h4E)stata <= 5'd5; else stata <= 5'd0; end //54
						5'd5: begin if(data == 8'h4E)stata <= 5'd6; else stata <= 5'd0; end //2B
						5'd6: begin if(data == 8'h45)stata <= 5'd7; else stata <= 5'd0; end //41
						5'd7: begin if(data == 8'h43)stata <= 5'd8; else stata <= 5'd0; end //54
						5'd8: begin if(data == 8'h54)stata <= 5'd9; else stata <= 5'd0; end //54
						5'd9: begin if(data == 8'h0D)stata <= 5'd10; else stata <= 5'd0; end //2B
						5'd10: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd11; en<=0; led <= 4'b0111; end else stata <= 5'd0; end 
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end
			4'd11:begin
				en <= 1;
				if(tx_down == 1'b1) // 发送数据：AT+CIPSEND=0,265 表示要发送数据，0是客户端的序号，第二个值是你要发送的数据长度，
					case(stata2) //41 54 2B 43 49 50 53 45 4E 44 3D 30 2C 32 35 36  
						5'd0: begin  rec_data<= 8'h41 ;  stata2<= 5'd1;end
						5'd1: begin  rec_data<= 8'h54 ;  stata2<= 5'd2;end
						5'd2: begin  rec_data<= 8'h2B ;  stata2<= 5'd3;end
						5'd3: begin  rec_data<= 8'h43 ;  stata2<= 5'd4;end
						5'd4: begin  rec_data<= 8'h49 ;  stata2<= 5'd5;end
						5'd5: begin  rec_data<= 8'h50 ;  stata2<= 5'd6;end
						5'd6: begin  rec_data<= 8'h53 ;  stata2<= 5'd7;end
						5'd7: begin  rec_data<= 8'h45 ;  stata2<= 5'd8;end
						5'd8: begin  rec_data<= 8'h4E ;  stata2<= 5'd9;end
						5'd9: begin  rec_data<= 8'h44 ;  stata2<= 5'd10;end
						5'd10: begin rec_data<= 8'h3D ;  stata2<= 5'd11;end
						5'd11: begin rec_data<= 8'h30 ;  stata2<= 5'd12;end
						5'd12: begin rec_data<= 8'h2C ;  stata2<= 5'd13;end
						5'd13: begin if(choose_data_length == 2'd0)      begin rec_data<= 8'h32 ; stata2<= 5'd14;end  //256
										 else if(choose_data_length == 2'd1) begin rec_data<= 8'h31 ; stata2<= 5'd19;end //1024
										 else if(choose_data_length == 2'd2) begin rec_data<= 8'h32 ; stata2<= 5'd24;end //2048
								 end
						5'd14: begin rec_data<= 8'h35 ;  stata2<= 5'd15;end
						5'd15: begin rec_data<= 8'h36 ;  stata2<= 5'd16;end
						5'd16: begin rec_data<= 8'h0D ;  stata2<= 5'd17;end
						5'd17: begin rec_data<= 8'h0A ;  stata2<= 5'd18;end
						5'd18: begin en<=0; flag_work <= 4'd12; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0011;end
						
						5'd19: begin rec_data<= 8'h30 ;  stata2<= 5'd20;end //1024
						5'd20: begin rec_data<= 8'h32 ;  stata2<= 5'd21;end
						5'd21: begin rec_data<= 8'h34 ;  stata2<= 5'd22;end
						5'd22: begin rec_data<= 8'h0D ;  stata2<= 5'd23;end
						5'd23: begin rec_data<= 8'h0A ;  stata2<= 5'd18;end
						
						5'd24: begin rec_data<= 8'h30 ;  stata2<= 5'd25;end //2048
						5'd25: begin rec_data<= 8'h34 ;  stata2<= 5'd26;end
						5'd26: begin rec_data<= 8'h38 ;  stata2<= 5'd27;end
						5'd27: begin rec_data<= 8'h0D ;  stata2<= 5'd28;end
						5'd28: begin rec_data<= 8'h0A ;  stata2<= 5'd18;end
						
						default stata2 <=0;
					endcase
			end 
			4'd12:begin //接近10ms的延时
				if(conter == ten_ms)begin
					conter <= 27'd0;
					flag_work <= 4'd13;
				end
				else
					conter <= conter + 27'd1;
			end
			4'd13:begin
				en <= 1;
				if(tx_down == 1'b1 && choose_data_length == 2'd0) //发送数据：256个字节
					if(conter_data == _256data)
						case(stata2) // 0D 0A 
							5'd0: begin rec_data<= 8'h0D ; stata2<= 5'd1; conter_data <= _256data;end
							5'd1: begin rec_data<= 8'h0A ; stata2<= 5'd2; conter_data <= _256data;end
							5'd2: begin en<=1; flag_work <= 5'd14; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0001; conter_data <= 0; end
							default stata2 <=0;
						endcase
					else begin
						conter_data <= conter_data + 12'd1;
						rec_data<= target_data_ ;//target_data; //8'h30 ;
					end
				else if(tx_down == 1'b1 && choose_data_length == 2'd1) //发送数据：1M字节
					if(conter_data == _1Mdata)
						case(stata2) // 0D 0A 
							5'd0: begin rec_data<= 8'h0D ; stata2<= 5'd1; conter_data <= _1Mdata;end
							5'd1: begin rec_data<= 8'h0A ; stata2<= 5'd2; conter_data <= _1Mdata;end
							5'd2: begin en<=1; flag_work <= 5'd14; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0001; conter_data <= 0; end
							default stata2 <=0;
						endcase
					else begin
						conter_data <= conter_data + 12'd1;
						rec_data<= 8'h31;
					end
				else if(tx_down == 1'b1 && choose_data_length == 2'd2) //发送数据：2M字节 
					if(conter_data == _2Mdata)
						case(stata2) // 0D 0A 
							5'd0: begin rec_data<= 8'h0D ; stata2<= 5'd1; conter_data <= _2Mdata;end
							5'd1: begin rec_data<= 8'h0A ; stata2<= 5'd2; conter_data <= _2Mdata;end
							5'd2: begin en<=1; flag_work <= 5'd14; rec_data<= 8'h0 ; stata2 <=0; led <= 4'b0001; conter_data <= 0; end
							default stata2 <=0;
						endcase
					else begin
						conter_data <= conter_data + 12'd1;
						rec_data<= 8'h32 ;
					end
			end
			4'd14:begin
				if(flag == 1'b1) //接收判断 ：SEND OK 
					case(stata)  //53 45 4E 44 20 4F 4B 0D 0A
						5'd0: begin if(data == 8'h53)stata <= 5'd1; else if(data == 8'h46)stata <= 5'd9; else if(data == 8'h45)stata <= 5'd12; else stata <= 5'd0; end //41
						5'd1: begin if(data == 8'h45)stata <= 5'd2; else stata <= 5'd0; end //41
						5'd2: begin if(data == 8'h4E)stata <= 5'd3; else stata <= 5'd0; end //2B
						5'd3: begin if(data == 8'h44)stata <= 5'd4; else stata <= 5'd0; end //41
						5'd4: begin if(data == 8'h20)stata <= 5'd5; else stata <= 5'd0; end //41
						5'd5: begin if(data == 8'h4F)stata <= 5'd6; else stata <= 5'd0; end //2B
						5'd6: begin if(data == 8'h4B)stata <= 5'd7; else stata <= 5'd0; end //41
						5'd7: begin if(data == 8'h0D)stata <= 5'd8; else stata <= 5'd0; end //41
						5'd8: begin if(data == 8'h0A)begin stata <= 5'd0; flag_work <= 4'd11; en<=0; led <= 4'b0000; end else stata <= 5'd0; end 
						//如果接收到发送失败的信号 返回到等待接收连接状态
						5'd9:  begin if(data == 8'h41)stata <= 5'd10; else stata <= 5'd0; end 
						5'd10: begin if(data == 8'h49)stata <= 5'd11; else stata <= 5'd0; end 
						5'd11: begin if(data == 8'h4C) begin stata <= 5'd0; flag_work <= 4'd10; en<=1; led <= 4'b1111; end else stata <= 5'd0; end 
						//如果接收到发送失败的信号 返回到等待接收连接状态
						5'd12:  begin if(data == 8'h52)stata <= 5'd13; else stata <= 5'd0; end 
						5'd13: begin if(data == 8'h52) stata <= 5'd14; else stata <= 5'd0; end 
						5'd14: begin if(data == 8'h4F) begin stata <= 5'd0; flag_work <= 4'd10; en<=1; led <= 4'b1111; end else stata <= 5'd0; end 
						default stata <= 5'd0; 
					endcase
				else
					stata <= stata;
			end 
			default:flag_work <= flag_work;
		endcase 
	end
	
	always @(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			Data_received_sign <= 4'd0;
			Data_received <= 0;
			end
		else begin
			if(flag == 1'b1)//2B 49 50 44 2C 30 2C 31 3A 31 
				case (Data_received_sign) //2B 49 50 44 2C 30 2C 31 3A 31 
					4'd0 : begin if(data == 8'h2B) Data_received_sign <= 4'd1; else Data_received_sign <= 4'd0; Data_received <= 0; end
					4'd1 : begin if(data == 8'h49) Data_received_sign <= 4'd2; else Data_received_sign <= 4'd0; end
					4'd2 : begin if(data == 8'h50) Data_received_sign <= 4'd3; else Data_received_sign <= 4'd0; end
					4'd3 : begin if(data == 8'h44) Data_received_sign <= 4'd4; else Data_received_sign <= 4'd0; end
					4'd4 : begin if(data == 8'h2C) Data_received_sign <= 4'd5; else Data_received_sign <= 4'd0; end
					4'd5 : begin if(data == 8'h30) Data_received_sign <= 4'd6; else Data_received_sign <= 4'd0; end
					4'd6 : begin if(data == 8'h2C) Data_received_sign <= 4'd7; else Data_received_sign <= 4'd0; end
					4'd7 : begin if(data == 8'h31) Data_received_sign <= 4'd8; else Data_received_sign <= 4'd0; end
					4'd8 : begin if(data == 8'h3A) Data_received_sign <= 4'd9; else Data_received_sign <= 4'd0; end
					4'd9 : begin if(data == 8'h31) begin Data_received_sign <= 4'd10; Data_received <= 8'd1; end else Data_received_sign <= 4'd0; //1
									 if(data == 8'h32) begin Data_received_sign <= 4'd10; Data_received <= 8'd2; end else Data_received_sign <= 4'd0; //2
									 if(data == 8'h33) begin Data_received_sign <= 4'd10; Data_received <= 8'd3; end else Data_received_sign <= 4'd0; //3
									 if(data == 8'h34) begin Data_received_sign <= 4'd10; Data_received <= 8'd4; end else Data_received_sign <= 4'd0; //4
									 if(data == 8'h35) begin Data_received_sign <= 4'd10; Data_received <= 8'd5; end else Data_received_sign <= 4'd0; //5
									 if(data == 8'h36) begin Data_received_sign <= 4'd10; Data_received <= 8'd6; end else Data_received_sign <= 4'd0; //6
									 if(data == 8'h37) begin Data_received_sign <= 4'd10; Data_received <= 8'd7; end else Data_received_sign <= 4'd0; //7
									 if(data == 8'h38) begin Data_received_sign <= 4'd10; Data_received <= 8'd8; end else Data_received_sign <= 4'd0; //8
									 if(data == 8'h39) begin Data_received_sign <= 4'd10; Data_received <= 8'd9; end else Data_received_sign <= 4'd0; //9
									 if(data == 8'h30) begin Data_received_sign <= 4'd10; Data_received <= 8'd0; end else Data_received_sign <= 4'd0; //0
									 
									 if(data == 8'h61) begin Data_received_sign <= 4'd10; Data_received <= 8'd10; end else Data_received_sign <= 4'd0; //a
									 if(data == 8'h62) begin Data_received_sign <= 4'd10; Data_received <= 8'd11; end else Data_received_sign <= 4'd0; //b
									 if(data == 8'h63) begin Data_received_sign <= 4'd10; Data_received <= 8'd12; end else Data_received_sign <= 4'd0; //c
									 if(data == 8'h64) begin Data_received_sign <= 4'd10; Data_received <= 8'd13; end else Data_received_sign <= 4'd0; //d
									 if(data == 8'h65) begin Data_received_sign <= 4'd10; Data_received <= 8'd14; end else Data_received_sign <= 4'd0; //e
									 if(data == 8'h66) begin Data_received_sign <= 4'd10; Data_received <= 8'd15; end else Data_received_sign <= 4'd0; //f
							 end
					default : begin Data_received <= 0; Data_received_sign <= 4'd0;  end
				endcase
			else begin
				Data_received_sign <= Data_received_sign;
				Data_received <= 0;
			end
		end
	end
	
//SEND OK

//+IPD,0,9:123123123AT+CIPSEND=0,4

//OK
//> 
endmodule	
