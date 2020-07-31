module get_length(
							clk, //系统时钟50MHz
							rst_n, //系统复位信号
							Tring, //超声波模块信号控制引脚
							Echo,	//距离长度数据引脚
							
							data_ASCII_0,
							data_ASCII_1,
							data_ASCII_2,
							data_ASCII_3,
							data_ASCII_4,
							data_ASCII_5
							
						//	cont_delay,
						//	flag,
						//	cont,
						//	length_value
						);
	
	input clk; //系统时钟50MHz
	input rst_n; //系统复位信号	
	
	output Tring; //超声波模块信号控制引脚
	input Echo;	//距离长度数据引脚
	
	output     [7:0] data_ASCII_0;
	output     [7:0] data_ASCII_1;
	output     [7:0] data_ASCII_2;
	output     [7:0] data_ASCII_3;
	output     [7:0] data_ASCII_4;
	output     [7:0] data_ASCII_5;
	
//	output [29:0] cont_delay;
//	output [4:0] flag;
//	output [29:0] length_value;
//	output [29:0] cont;
	
	wire clk,rst_n;	
	reg Tring;
	wire Echo;
	
	reg [9:0] en_time10us;
	
	reg [29:0] length_value; //测得的距离 最大值1023 1111 1111 11 1073 7418 23    44999999
	
	reg [4:0] flag;
	reg [29:0] cont; //测量高电平脉冲时间
	reg [29:0] cont_delay;
	reg en_cont;
	
	//wire define
	wire   [3:0]              data0    ;        // 个位数
	wire   [3:0]              data1    ;        // 十位数
	wire   [3:0]              data2    ;        // 百位数
	wire   [3:0]              data3    ;        // 千位数
	wire   [3:0]              data4    ;        // 万位数
	wire   [3:0]              data5    ;        // 十万位数
	
	reg [7:0] data_ASCII_0;
	reg [7:0] data_ASCII_1;
	reg [7:0] data_ASCII_2;
	reg [7:0] data_ASCII_3;
	reg [7:0] data_ASCII_4;
	reg [7:0] data_ASCII_5;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			length_value <= 30'd0;
			flag <= 5'd0;
			cont <= 0;
			cont_delay <= 0; 
			Tring <= 1'b0;
			en_time10us <= 10'd0;
			end
		else begin
			case (flag)
				5'd0 : begin 
							if(cont_delay == 30'd12999999) begin //延时1秒
								cont_delay <= 30'd0; 
								flag <= 5'd1;
								end
							else begin
								cont_delay <= cont_delay + 30'd1; 
								flag <= 5'd0;
							end
						end
				5'd1 : begin flag <= 5'd2; Tring <= 1'b1; end //发送20微妙高电平触发信号
				5'd2 : begin 
							if(en_time10us == 10'd5000) begin//20um延时
								en_time10us <= 10'd0;
								flag <= 5'd3;
								end
							else begin
								en_time10us <= en_time10us + 10'd1;
								flag <= 5'd2;
								end
						end
				5'd3 : begin flag <= 5'd4; Tring <= 1'b0; end
				5'd4 : begin 
							if(Echo == 1)  //等待信号到来
								flag <= 5'd5; 
							else 
								flag <= 5'd4;
						end
				5'd5 :begin 
							cont <= cont + 30'd1; //计数器计数高电平的时间
							if(Echo == 0) begin
								flag <= 5'd6;
								length_value <= (cont*17)/1000000 ; 
								//length_value <= cont;
								end
							else 
								flag <= 5'd5;
						end
				5'd6 : begin flag <= 5'd0; cont <= 0; end
				default: flag <= 5'd0; 
				endcase
			end
	end
	
	//提取显示数值所对应的十进制数的各个位
	assign  data0 = length_value % 4'd10;               // 个位数
	assign  data1 = length_value / 4'd10 % 4'd10   ;    // 十位数
	assign  data2 = length_value / 7'd100 % 4'd10  ;    // 百位数
	assign  data3 = length_value / 10'd1000 % 4'd10 ;   // 千位数
	assign  data4 = length_value / 14'd10000 % 4'd10;   // 万位数
	assign  data5 = length_value / 17'd100000;          // 十万位数

	//查找表 将20位2进制数转换 ASCII
	always @ (posedge clk or negedge rst_n) begin
		 if (!rst_n) begin 
			data_ASCII_0 <= 8'd0; // 个位数
			data_ASCII_1 <= 8'd0; // 十位数
			data_ASCII_2 <= 8'd0; // 百位数
			data_ASCII_3 <= 8'd0; // 千位数
			data_ASCII_4 <= 8'd0; // 万位数
			data_ASCII_5 <= 8'd0; // 十万位数
			end
		 else begin
				case(data0)
					4'b0000 : data_ASCII_0 <= 8'h30;
					4'b0001 : data_ASCII_0 <= 8'h31;
					4'b0010 : data_ASCII_0 <= 8'h32;
					4'b0011 : data_ASCII_0 <= 8'h33;
					4'b0100 : data_ASCII_0 <= 8'h34;
					4'b0101 : data_ASCII_0 <= 8'h35;
					4'b0110 : data_ASCII_0 <= 8'h36;
					4'b0111 : data_ASCII_0 <= 8'h37;
					4'b1000 : data_ASCII_0 <= 8'h38;
					4'b1001 : data_ASCII_0 <= 8'h39;
					default : data_ASCII_0 <= 8'h30;
					endcase
				case(data1)
					4'b0000 : data_ASCII_1 <= 8'h30;
					4'b0001 : data_ASCII_1 <= 8'h31;
					4'b0010 : data_ASCII_1 <= 8'h32;
					4'b0011 : data_ASCII_1 <= 8'h33;
					4'b0100 : data_ASCII_1 <= 8'h34;
					4'b0101 : data_ASCII_1 <= 8'h35;
					4'b0110 : data_ASCII_1 <= 8'h36;
					4'b0111 : data_ASCII_1 <= 8'h37;
					4'b1000 : data_ASCII_1 <= 8'h38;
					4'b1001 : data_ASCII_1 <= 8'h39;
					default : data_ASCII_1 <= 8'h30;
					endcase
				case(data2)
					4'b0000 : data_ASCII_2 <= 8'h30;
					4'b0001 : data_ASCII_2 <= 8'h31;
					4'b0010 : data_ASCII_2 <= 8'h32;
					4'b0011 : data_ASCII_2 <= 8'h33;
					4'b0100 : data_ASCII_2 <= 8'h34;
					4'b0101 : data_ASCII_2 <= 8'h35;
					4'b0110 : data_ASCII_2 <= 8'h36;
					4'b0111 : data_ASCII_2 <= 8'h37;
					4'b1000 : data_ASCII_2 <= 8'h38;
					4'b1001 : data_ASCII_2 <= 8'h39;
					default : data_ASCII_2 <= 8'h30;
					endcase
				case(data3)
					4'b0000 : data_ASCII_3 <= 8'h30;
					4'b0001 : data_ASCII_3 <= 8'h31;
					4'b0010 : data_ASCII_3 <= 8'h32;
					4'b0011 : data_ASCII_3 <= 8'h33;
					4'b0100 : data_ASCII_3 <= 8'h34;
					4'b0101 : data_ASCII_3 <= 8'h35;
					4'b0110 : data_ASCII_3 <= 8'h36;
					4'b0111 : data_ASCII_3 <= 8'h37;
					4'b1000 : data_ASCII_3 <= 8'h38;
					4'b1001 : data_ASCII_3 <= 8'h39;
					default : data_ASCII_3 <= 8'h30;
					endcase
				case(data4)
					4'b0000 : data_ASCII_4 <= 8'h30;
					4'b0001 : data_ASCII_4 <= 8'h31;
					4'b0010 : data_ASCII_4 <= 8'h32;
					4'b0011 : data_ASCII_4 <= 8'h33;
					4'b0100 : data_ASCII_4 <= 8'h34;
					4'b0101 : data_ASCII_4 <= 8'h35;
					4'b0110 : data_ASCII_4 <= 8'h36;
					4'b0111 : data_ASCII_4 <= 8'h37;
					4'b1000 : data_ASCII_4 <= 8'h38;
					4'b1001 : data_ASCII_4 <= 8'h39;
					default : data_ASCII_4 <= 8'h30;
					endcase
				case(data5)
					4'b0000 : data_ASCII_5 <= 8'h30;
					4'b0001 : data_ASCII_5 <= 8'h31;
					4'b0010 : data_ASCII_5 <= 8'h32;
					4'b0011 : data_ASCII_5 <= 8'h33;
					4'b0100 : data_ASCII_5 <= 8'h34;
					4'b0101 : data_ASCII_5 <= 8'h35;
					4'b0110 : data_ASCII_5 <= 8'h36;
					4'b0111 : data_ASCII_5 <= 8'h37;
					4'b1000 : data_ASCII_5 <= 8'h38;
					4'b1001 : data_ASCII_5 <= 8'h39;
					default : data_ASCII_5 <= 8'h30;
					endcase
				end
		end
	
endmodule
