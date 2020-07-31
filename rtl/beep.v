module beep(
					clk, //系统时钟50MHz
					rst_n, //系统复位信号
					beep_pin, //蜂鸣器的引脚
					key //按键或者一个少于1秒的高电平脉冲
					);
	
	input clk; //系统时钟50MHz
	input rst_n;//系统复位信号
	output beep_pin; //蜂鸣器的引脚
	input [7:0] key; //按键或者一个少于1秒的高电平脉冲
	
	wire clk;
	wire rst_n;//系统复位信号
	wire beep_pin;
	wire second_out;
	
	wire [7:0] key; //按键或者一个少于1秒的高电平脉冲
	
	//驱动蜂鸣器发声
	beep__	beep__(
							.clk(clk),
							.rst_n(rst_n),
							.beep_pin(beep_pin),
							.en(second_out)
						);
	
	//产生一个0.5秒的高电平来让蜂鸣器发声一秒钟
	time1s	time1s(
							.clk(clk),
							.rst_n(rst_n),
							.second_out(second_out),
							.en_in(key)
						);
	
endmodule

module time1s(
					clk, //系统时钟50MHz
					rst_n,
					second_out,
					en_in
					);
	
	input clk; //系统时钟50MHz
	input rst_n;//系统复位信号
	input [7:0] en_in;
	
	output second_out;
	
	wire clk,rst_n;
	wire [7:0]en_in;
	reg second_out;
	
	reg [27:0] cont;
	
	//产生0.5秒钟的高电平，随后全为低电平
	always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n) begin
				cont <= 0;
				second_out <= 0;
			end
			else if (cont == 28'd12999999)begin
				cont <= 0;
				second_out <= 0;
			end
			else if(en_in == 8'd1 || en_in == 8'd2 || en_in == 8'd3 || en_in == 8'd4 || en_in == 8'd5 || en_in == 8'd6 || 
					  en_in == 8'd7 || en_in == 8'd8 || en_in == 8'd9 || en_in == 8'd16||second_out == 1)begin //一旦检测到有信号就开启蜂鸣器
				second_out <= 1;
				cont <= cont + 1'b1;
			end
		end
		
endmodule



module beep__(
					clk, //系统时钟50MHz
					rst_n,//系统复位信号
					beep_pin,
					en
					);
	
	input clk;//系统时钟50MHz
	input rst_n;//系统复位信号
	output beep_pin; //蜂鸣器的引脚
	input en;
	
	wire clk;
	wire rst_n;
	reg beep_pin; //蜂鸣器的引脚
	wire en;
	
	reg [28:0] cont;
	
	//板载基本50M时钟信号处理
	always@(posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				cont <= 0;
			else if (cont == 28'd40000)
				cont <= 0;
			else
				cont <= cont + 1'b1;
		end
		
	//分频电路
	always@(posedge clk or negedge rst_n)
		begin
			if (!rst_n)
				beep_pin <= 0;
			else if (cont == 28'd40000 && en == 1)
				beep_pin <=~ beep_pin;
			else
				beep_pin <= beep_pin;
		end
endmodule









