module uart_tx(
				//input
				clk,//模块的时钟 50MHz
				rst_n, //系统复位信号
				set_Baud_rate,//波特率大小设置
				data, //要发送的一个字节数据
				en, //模块工作的使能信号
				//output
				TX, //串口输出信号
				tx_down //发送完成标志，每完成一次发送就产生一段高脉冲
				);
			
	input clk; //模块的时钟 50MHz
	input rst_n; //系统复位信号
	input [7:0] data; //要发送的一个字节数据
	input [3:0] set_Baud_rate;  //波特率大小设置
	input en; //模块工作的使能信号
	
	output TX; //串口输出信号
	output tx_down; //发送完成标志，每完成一次发送就产生一段高脉冲
	
	wire clk;
	wire	rst_n;	
	wire en;
	
	reg TX;
	reg tx_down;
	
	//模块内部的寄存器
	reg flag5207;
	reg [7:0] rev_data;
	reg [13:0] conter;
	reg [4:0]con;
	reg [13:0] Baud_rate; //波特率
	//localparam Baud_rate=433;//设置波特率
	
	//接收设置的波特率大小
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			Baud_rate <= 5207;
		else 
			case (set_Baud_rate)
				0: Baud_rate <= 5207; //9600
				1: Baud_rate <= 2603;
				2: Baud_rate <= 1301;
				3: Baud_rate <= 867;
				4: Baud_rate <= 433; //115200
				default: Baud_rate <= 5207;
			endcase
	end
	
	//接收外来的要发送的数据；
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			rev_data <= 7'd0;
		else
			rev_data <= data;
	end
	
	//为最基本的计数器分频，产生例如9600Hz的信号提供给其他部分
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			flag5207 <= 0;
		else if(en)//增加使能信号控制
		begin
			if(conter == Baud_rate)
			flag5207 <= 1'b1;
			else
				flag5207 <= 1'b0;
		end
		else
			flag5207 <= 1'b0;//如果不使能相当于给复位了  使能：en=1；
	end
	
	//为了后面分频给后面的逻辑电路，让5207计数器每次循环计数到1时就产生一个高电平的使能信号给下面的电路。
	always@(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			conter <= 0;
		else if(conter == Baud_rate)
			conter <= 0;
		else
			conter <= conter +1'b1;
	end
	
	//11进制计数器为了发送一个字节数据需要循环发送起始信号、数据段、结束信号，
	//加在一起一共需要10bit，最后1个bit需要保持高电平防止信号不稳定
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			con <= 0;
		else if(flag5207 == 1'b1)
		begin
			if(con == 4'd11)
				con <= 0;
			else
				con <= con +1'b1;
		end
		else
			con <= con;
	end
	
	//来产生最后的输出信号，需要接收11进制计数器的数据，
	//选择发送从0到11的数据。分别代表了数据起始位和数据位以及数结束位
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			TX <= 1'b1; //没有信号的状态应该是高电位
		else if(rev_data <= 8'd0)
			TX <= 1'b1;
		else
		begin
			case(con)
			0:TX <= 1'b0;
			1:TX <= rev_data[0]; //bit0
			2:TX <= rev_data[1]; //bit1
			3:TX <= rev_data[2]; //bit2
			4:TX <= rev_data[3]; //bit3
			5:TX <= rev_data[4]; //bit4
			6:TX <= rev_data[5]; //bit5
			7:TX <= rev_data[6]; //bit6
			8:TX <= rev_data[7]; //bit7
			default: TX <= 1'b1;
			endcase
		end
	end
	
	//发送一个字节完成的标志位，高电平
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			tx_down <=0;
		else if(con == 4'd11 && conter == Baud_rate)
			tx_down <= 1'b1;
		else
			tx_down <= 1'b0;
	end
	
endmodule

