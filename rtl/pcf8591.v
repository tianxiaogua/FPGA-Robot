module pcf8591(
   
    input                 clk        ,    
    input                 rst_n      ,    

    
    output   reg          i2c_rh_wl  ,    
    output   reg          i2c_exec   ,    
    output   reg  [15:0]  i2c_addr   ,    
    output   reg  [ 7:0]  i2c_data_w ,    
    input         [ 7:0]  i2c_data_r ,   
    input                 i2c_done   ,  

    output   reg  [19:0]  num             
);


parameter    CONTORL_BYTE = 8'b0100_0000; 
parameter    V_REF        = 12'd3300    ; 

reg    [7:0]    da_data   ;               // DA数据
reg    [7:0]    ad_data   ;               // AD数据
reg    [3:0]    flow_cnt  ;               
reg    [18:0]   wait_cnt  ;               


wire   [19:0]   num_t     ;               // AD寄存的数据



assign num_t = V_REF * ad_data ;


always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        da_data  <= 8'd0;
    end
    else if(i2c_rh_wl == 1'b0 & i2c_done == 1'b1)begin
        if(da_data == 8'd255)
            da_data<= 8'd0;
        else
            da_data<= da_data + 1'b1;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        num <= 20'd0;
    end
    else
        num <= num_t >> 4'd8;
end


always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        i2c_exec <= 1'b0;
        i2c_rh_wl<= 1'b0;
        i2c_addr <= 8'd0;
        i2c_data_w <=  8'd0;
        flow_cnt   <=  4'd0;
        wait_cnt   <= 17'd0;
    end
    else begin
        i2c_exec <= 1'b0;
        case(flow_cnt)
            'd0: begin
                if(wait_cnt == 17'd100) begin
                    wait_cnt<= 17'd0;
                    flow_cnt<= flow_cnt + 1'b1;
                end
                else
                    wait_cnt<= wait_cnt + 1'b1;
            end
            
            'd1: begin
                i2c_exec  <= 1'b1;
                i2c_addr  <= CONTORL_BYTE;
                i2c_rh_wl <= 1'b0;
                i2c_data_w<= da_data;
                flow_cnt  <= flow_cnt + 1'b1;
            end
            'd2: begin
                if(i2c_done == 1'b1) begin
                    flow_cnt<= flow_cnt + 1'b1;
                end
            end
            'd3: begin
        
                if(wait_cnt == 17'd128906) begin
                    wait_cnt<= 17'd0;
                    flow_cnt<= flow_cnt + 1'b1;
                end
                else
                    wait_cnt<= wait_cnt + 1'b1;
            end
            //AD转换输入
            'd4: begin
                i2c_exec  <= 1'b1;
                i2c_addr  <= CONTORL_BYTE;
                i2c_rh_wl <= 1'b1;
                flow_cnt  <= flow_cnt + 1'b1;
            end
            'd5: begin
                if(i2c_done == 1'b1) begin
                    ad_data <= i2c_data_r;
                    flow_cnt<= 4'd0;
                end
            end
            default: flow_cnt <= 4'd0;
        endcase
    end
end

endmodule