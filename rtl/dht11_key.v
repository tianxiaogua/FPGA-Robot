module dht11_key(
						sys_clk,
						sys_rst_n,

						//key_flag,
						//key_value,
						data_valid,
						//data,

						data_ASCII_0,
						data_ASCII_1,
						data_ASCII_2,
						data_ASCII_3,
						data_ASCII_4,
						data_ASCII_5,
						
						humidity_data_ASCII_0,
						humidity_data_ASCII_1,
						humidity_data_ASCII_2,
						humidity_data_ASCII_3,
						humidity_data_ASCII_4,
						humidity_data_ASCII_5,
						sign,
						//en,
						point
					);

	input             sys_clk;
	input             sys_rst_n;
	 
	//input             key_flag;
	//input             key_value;
	input      [31:0] data_valid;
	 
	//output     [31:0] data;
	 //data_temperature,
	 //data_humidity,
	output     [7:0] data_ASCII_0;
	output     [7:0] data_ASCII_1;
	output     [7:0] data_ASCII_2;
	output     [7:0] data_ASCII_3;
	output     [7:0] data_ASCII_4;
	output     [7:0] data_ASCII_5;
	
	output     [7:0] humidity_data_ASCII_0;
	output     [7:0] humidity_data_ASCII_1;
	output     [7:0] humidity_data_ASCII_2;
	output     [7:0] humidity_data_ASCII_3;
	output     [7:0] humidity_data_ASCII_4;
	output     [7:0] humidity_data_ASCII_5;
	
	output        sign;
	//output            en   ;           
	output     [ 5:0] point;

	wire sys_clk;
	wire sys_rst_n;
	//wire key_flag;
	//wire key_value;
	wire [31:0] data_valid;
	
	
	reg [7:0] data_ASCII_0;
	reg [7:0] data_ASCII_1;
	reg [7:0] data_ASCII_2;
	reg [7:0] data_ASCII_3;
	reg [7:0] data_ASCII_4;
	reg [7:0] data_ASCII_5;
	
	reg [7:0] humidity_data_ASCII_0;
	reg [7:0] humidity_data_ASCII_1;
	reg [7:0] humidity_data_ASCII_2;
	reg [7:0] humidity_data_ASCII_3;
	reg [7:0] humidity_data_ASCII_4;
	reg [7:0] humidity_data_ASCII_5;
	
	
	reg sign;
	//wire en;
	wire  [ 5:0] point;
//reg define                            
reg       flag ; // 温/湿度标志信号

wire [31:0] data;
wire [31:0] data_humidity;
reg [7:0] data__0; // 小数部分
reg [7:0] data__1; // 整数部分

reg [7:0] data_humidity_0; 
reg [7:0] data_humidity_1;

//wire define
wire   [3:0]              data0    ;        // 个位数
wire   [3:0]              data1    ;        // 十位数
wire   [3:0]              data2    ;        // 百位数
wire   [3:0]              data3    ;        // 千位数
wire   [3:0]              data4    ;        // 万位数
wire   [3:0]              data5    ;        // 十万位数

wire   [3:0]              humidity_data0    ;        // 个位数
wire   [3:0]              humidity_data1    ;        // 十位数
wire   [3:0]              humidity_data2    ;        // 百位数
wire   [3:0]              humidity_data3    ;        // 千位数
wire   [3:0]              humidity_data4    ;        // 万位数
wire   [3:0]              humidity_data5    ;        // 十万位数

//*****************************************************
//**                    main code
//*****************************************************

//数码管使能信号
//assign en    = 1'b1;



//小数点左移两位
assign point = 6'b000100;


//flag为“0”时显示温度，为“1”时显示湿度
always @ (posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        data__0 <= 8'd0;
        data__1 <= 8'd0;
		  data_humidity_0 <= 8'd0;
		  data_humidity_1 <= 8'd0;
        sign  <= 1'b0;
    end
    else begin
        data__0 <= data_valid[6:0];  //温度小数部分最高位为符号位
        data__1 <= data_valid[15:8];
		  data_humidity_0 <= data_valid[23:16]; //湿度数值
        data_humidity_1 <= data_valid[31:24];
        if(data_valid[7])
            sign <= 1'b1;          //bit7为1表示负温度
        else
            sign <= 1'b0;
    end
end

//显示的数值为 (整数 + 0.1*小数)*100
assign data  = data__1 * 100 + data__0*10;
//显示的数值为 (整数 + 0.1*小数)*100
assign data_humidity  = data_humidity_1 * 100 + data_humidity_0*10;

//提取显示数值所对应的十进制数的各个位
assign  data0 = data % 4'd10;               // 个位数
assign  data1 = data / 4'd10 % 4'd10   ;    // 十位数
assign  data2 = data / 7'd100 % 4'd10  ;    // 百位数
assign  data3 = data / 10'd1000 % 4'd10 ;   // 千位数
assign  data4 = data / 14'd10000 % 4'd10;   // 万位数
assign  data5 = data / 17'd100000;          // 十万位数

//提取显示数值所对应的十进制数的各个位
assign  humidity_data0 = data_humidity % 4'd10;               // 个位数
assign  humidity_data1 = data_humidity / 4'd10 % 4'd10   ;    // 十位数
assign  humidity_data2 = data_humidity / 7'd100 % 4'd10  ;    // 百位数
assign  humidity_data3 = data_humidity / 10'd1000 % 4'd10 ;   // 千位数
assign  humidity_data4 = data_humidity / 14'd10000 % 4'd10;   // 万位数
assign  humidity_data5 = data_humidity / 17'd100000;          // 十万位数

//查找表 将20位2进制数转换 ASCII
always @ (posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin 
		data_ASCII_0 <= 8'd0; // 个位数
		data_ASCII_1 <= 8'd0; // 十位数
		data_ASCII_2 <= 8'd0; // 百位数
		data_ASCII_3 <= 8'd0; // 千位数
		data_ASCII_4 <= 8'd0; // 万位数
		data_ASCII_5 <= 8'd0; // 十万位数
		
		humidity_data_ASCII_0 <= 8'd0; // 个位数
		humidity_data_ASCII_1 <= 8'd0; // 十位数
		humidity_data_ASCII_2 <= 8'd0; // 百位数
		humidity_data_ASCII_3 <= 8'd0; // 千位数
		humidity_data_ASCII_4 <= 8'd0; // 万位数
		humidity_data_ASCII_5 <= 8'd0; // 十万位数
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
				
				
			case(humidity_data0)
				4'b0000 : humidity_data_ASCII_0 <= 8'h30;
				4'b0001 : humidity_data_ASCII_0 <= 8'h31;
				4'b0010 : humidity_data_ASCII_0 <= 8'h32;
				4'b0011 : humidity_data_ASCII_0 <= 8'h33;
				4'b0100 : humidity_data_ASCII_0 <= 8'h34;
				4'b0101 : humidity_data_ASCII_0 <= 8'h35;
				4'b0110 : humidity_data_ASCII_0 <= 8'h36;
				4'b0111 : humidity_data_ASCII_0 <= 8'h37;
				4'b1000 : humidity_data_ASCII_0 <= 8'h38;
				4'b1001 : humidity_data_ASCII_0 <= 8'h39;
				default : humidity_data_ASCII_0 <= 8'h30;
				endcase
			case(humidity_data1)
				4'b0000 : humidity_data_ASCII_1 <= 8'h30;
				4'b0001 : humidity_data_ASCII_1 <= 8'h31;
				4'b0010 : humidity_data_ASCII_1 <= 8'h32;
				4'b0011 : humidity_data_ASCII_1 <= 8'h33;
				4'b0100 : humidity_data_ASCII_1 <= 8'h34;
				4'b0101 : humidity_data_ASCII_1 <= 8'h35;
				4'b0110 : humidity_data_ASCII_1 <= 8'h36;
				4'b0111 : humidity_data_ASCII_1 <= 8'h37;
				4'b1000 : humidity_data_ASCII_1 <= 8'h38;
				4'b1001 : humidity_data_ASCII_1 <= 8'h39;
				default : humidity_data_ASCII_1 <= 8'h30;
				endcase
			case(humidity_data2)
				4'b0000 : humidity_data_ASCII_2 <= 8'h30;
				4'b0001 : humidity_data_ASCII_2 <= 8'h31;
				4'b0010 : humidity_data_ASCII_2 <= 8'h32;
				4'b0011 : humidity_data_ASCII_2 <= 8'h33;
				4'b0100 : humidity_data_ASCII_2 <= 8'h34;
				4'b0101 : humidity_data_ASCII_2 <= 8'h35;
				4'b0110 : humidity_data_ASCII_2 <= 8'h36;
				4'b0111 : humidity_data_ASCII_2 <= 8'h37;
				4'b1000 : humidity_data_ASCII_2 <= 8'h38;
				4'b1001 : humidity_data_ASCII_2 <= 8'h39;
				default : humidity_data_ASCII_2 <= 8'h30;
				endcase
			case(humidity_data3)
				4'b0000 : humidity_data_ASCII_3 <= 8'h30;
				4'b0001 : humidity_data_ASCII_3 <= 8'h31;
				4'b0010 : humidity_data_ASCII_3 <= 8'h32;
				4'b0011 : humidity_data_ASCII_3 <= 8'h33;
				4'b0100 : humidity_data_ASCII_3 <= 8'h34;
				4'b0101 : humidity_data_ASCII_3 <= 8'h35;
				4'b0110 : humidity_data_ASCII_3 <= 8'h36;
				4'b0111 : humidity_data_ASCII_3 <= 8'h37;
				4'b1000 : humidity_data_ASCII_3 <= 8'h38;
				4'b1001 : humidity_data_ASCII_3 <= 8'h39;
				default : humidity_data_ASCII_3 <= 8'h30;
				endcase
			case(humidity_data4)
				4'b0000 : humidity_data_ASCII_4 <= 8'h30;
				4'b0001 : humidity_data_ASCII_4 <= 8'h31;
				4'b0010 : humidity_data_ASCII_4 <= 8'h32;
				4'b0011 : humidity_data_ASCII_4 <= 8'h33;
				4'b0100 : humidity_data_ASCII_4 <= 8'h34;
				4'b0101 : humidity_data_ASCII_4 <= 8'h35;
				4'b0110 : humidity_data_ASCII_4 <= 8'h36;
				4'b0111 : humidity_data_ASCII_4 <= 8'h37;
				4'b1000 : humidity_data_ASCII_4 <= 8'h38;
				4'b1001 : humidity_data_ASCII_4 <= 8'h39;
				default : humidity_data_ASCII_4 <= 8'h30;
				endcase
			case(humidity_data5)
				4'b0000 : humidity_data_ASCII_5 <= 8'h30;
				4'b0001 : humidity_data_ASCII_5 <= 8'h31;
				4'b0010 : humidity_data_ASCII_5 <= 8'h32;
				4'b0011 : humidity_data_ASCII_5 <= 8'h33;
				4'b0100 : humidity_data_ASCII_5 <= 8'h34;
				4'b0101 : humidity_data_ASCII_5 <= 8'h35;
				4'b0110 : humidity_data_ASCII_5 <= 8'h36;
				4'b0111 : humidity_data_ASCII_5 <= 8'h37;
				4'b1000 : humidity_data_ASCII_5 <= 8'h38;
				4'b1001 : humidity_data_ASCII_5 <= 8'h39;
				default : humidity_data_ASCII_5 <= 8'h30;
				endcase
      end
	end	  

endmodule 








