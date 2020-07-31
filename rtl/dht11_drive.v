module dht11_drive (
    input                sys_clk    ,   //系统时钟
    input                rst_n      ,   //系统复位
                                        
    inout                dht11      ,   //dht11温湿度传感器单总线
    output  reg  [31:0]  data_valid     //有效输出数据
);                                      
                                        
//parameter define 
parameter  POWER_ON_NUM     = 1000_000; //上电延时等待时间,单位us
//状态机各个状态                     
parameter  st_power_on_wait = 3'd0;     //上电延时等待
parameter  st_low_20ms      = 3'd1;     //主机发送20ms低电平
parameter  st_high_13us     = 3'd2;     //主机释放总线13us
parameter  st_rec_low_83us  = 3'd3;     //接收83us低电平响应
parameter  st_rec_high_87us = 3'd4;     //等待87us高电平（准备接收数据）
parameter  st_rec_data      = 3'd5;     //接收40位数据
parameter  st_delay         = 3'd6;     //延时等待,延时完成后重新操作DHT11

//reg define
reg    [2:0]   cur_state   ;        //当前状态
reg    [2:0]   next_state  ;        //下一个状态
                                    
reg    [4:0]   clk_cnt     ;        //分频计数器
reg            clk_1m      ;        //1Mhz时钟
reg    [20:0]  us_cnt      ;        //1微秒计数器
reg            us_cnt_clr  ;        //1微秒计数器清零信号
                                    
reg    [39:0]  data_temp   ;        //缓存接收到的数据
reg            step        ;        //数据采集状态
reg    [5:0]   data_cnt    ;        //接收数据用计数器

reg            dht11_buffer;        //DHT11输出信号
reg            dht11_d0    ;        //DHT11输入信号寄存器0
reg            dht11_d1    ;        //DHT11输入信号寄存器1

//wire define                       
wire        dht11_pos      ;        //DHT11上升沿
wire        dht11_neg      ;        //DHT11下降沿

//*****************************************************
//**                    main code
//*****************************************************

assign dht11     = dht11_buffer;
assign dht11_pos = ~dht11_d1 & dht11_d0; //采集上升沿
assign dht11_neg = dht11_d1 & ~dht11_d0; //采集下降沿

//得到1Mhz分频时钟
always @ (posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 5'd0;
        clk_1m  <= 1'b0;
    end 
    else if (clk_cnt < 5'd24) 
        clk_cnt <= clk_cnt + 1'b1;       
    else begin
        clk_cnt <= 5'd0;
        clk_1m  <= ~ clk_1m;
    end 
end

//对DHT11输入信号连续寄存两次，用于边沿检测
always @ (posedge clk_1m or negedge rst_n) begin
    if (!rst_n) begin
        dht11_d0 <= 1'b1;
        dht11_d1 <= 1'b1;
    end 
    else begin
        dht11_d0 <= dht11;
        dht11_d1 <= dht11_d0;
    end 
end 

//1微秒计数器
always @ (posedge clk_1m or negedge rst_n) begin
    if (!rst_n)
        us_cnt <= 21'd0;
    else if (us_cnt_clr)
        us_cnt <= 21'd0;
    else 
        us_cnt <= us_cnt + 1'b1;
end 

//状态跳转
always @ (posedge clk_1m or negedge rst_n) begin
    if (!rst_n)
        cur_state <= st_power_on_wait;
    else 
        cur_state <= next_state;
end 

//状态机读取DHT11数据
always @ (posedge clk_1m or negedge rst_n) begin
    if(!rst_n) begin
        next_state   <= st_power_on_wait;
        data_temp    <= 40'd0;
        step         <= 1'b0; 
        us_cnt_clr   <= 1'b0;
        data_cnt     <= 6'd0;
        dht11_buffer <= 1'bz;   
    end 
    else begin
        case (cur_state)
                //上电后延时1秒等待DHT11稳定
            st_power_on_wait : begin                
                if(us_cnt < POWER_ON_NUM) begin
                    dht11_buffer <= 1'bz; //空闲状态释放总线
                    us_cnt_clr   <= 1'b0;
                end
                else begin            
                    next_state   <= st_low_20ms;
                    us_cnt_clr   <= 1'b1;
                end
            end
                //FPGA发送起始信号（20ms的低电平）    
            st_low_20ms: begin
                if(us_cnt < 20000) begin
                    dht11_buffer <= 1'b0; //起始信号为低电平 
                    us_cnt_clr   <= 1'b0;
                end
                else begin
                    dht11_buffer <= 1'bz; //起始信号结束后释放总线
                    next_state   <= st_high_13us;
                    us_cnt_clr   <= 1'b1;
                end    
            end 
                //等待DHT11的响应信号（等待10~20us）
            st_high_13us:begin                      
                if (us_cnt < 20) begin
                    us_cnt_clr   <= 1'b0;
                    if(dht11_neg) begin   //检测到DHT11响应信号
                        next_state <= st_rec_low_83us;
                        us_cnt_clr <= 1'b1; 
                    end
                end
                else                      //超过20us未响应
                    next_state <= st_delay;
            end 
                //等待DHT11的83us低电平响应信号结束
            st_rec_low_83us: begin                  
                if(dht11_pos)                   
                    next_state <= st_rec_high_87us;  
            end 
                //DHT11拉高87us通知FPGA准备接收数据
            st_rec_high_87us: begin
                if(dht11_neg) begin       //准备时间结束    
                    next_state <= st_rec_data; 
                    us_cnt_clr <= 1'b1;
                end
                else begin                //高电平准备接收数据
                    data_cnt  <= 6'd0;
                    data_temp <= 40'd0;
                    step  <= 1'b0;
                end
            end 
                //连续接收40位数据 
            st_rec_data: begin                                
                case(step)
                    0: begin              //接收数据低电平
                        if(dht11_pos) begin 
                            step   <= 1'b1;
                            us_cnt_clr <= 1'b1;
                        end            
                        else              //等待数据低电平结束
                            us_cnt_clr <= 1'b0;
                    end
                    1: begin              //接收数据高电平
                        if(dht11_neg) begin 
                            data_cnt <= data_cnt + 1'b1;
                                          //判断接收数据为0/1
                            if(us_cnt < 60)
                                data_temp <= {data_temp[38:0],1'b0};
                            else                
                                data_temp <= {data_temp[38:0],1'b1};
                            step <= 1'b0;
                            us_cnt_clr <= 1'b1;
                        end 
                        else              //等待数据高电平结束
                            us_cnt_clr <= 1'b0;
                    end
                endcase
                
                if(data_cnt == 40) begin  //数据传输结束，验证校验位
                    next_state <= st_delay;
                    if(data_temp[7:0] == data_temp[39:32] + data_temp[31:24] 
                                         + data_temp[23:16] + data_temp[15:8])
                        data_valid <= data_temp[39:8];  
                end
            end 
                //完成一次数据采集后延时2s
            st_delay:begin
                if(us_cnt < 2000_000)
                    us_cnt_clr <= 1'b0;
                else begin                //延时结束后重新发送起始信号
                    next_state <= st_low_20ms;      
                    us_cnt_clr <= 1'b1;
                end
            end
            default : ;
        endcase
    end 
end

endmodule                                     