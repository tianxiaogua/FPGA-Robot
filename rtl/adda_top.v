module adda_top(
    
    input                sys_clk    ,    // 系统时钟
    input                sys_rst_n  ,    // 系统复位

    output               scl        ,    // i2c时钟线
    inout                sda        ,    // i2c数据线

	 output [19:0] num
);

//parameter define
parameter    SLAVE_ADDR =  7'h48        ; 
parameter    BIT_CTRL   =  1'b0         ; 
parameter    CLK_FREQ   = 26'd50_000_000; 
parameter    I2C_FREQ   = 18'd250_000   ; 
parameter    POINT      = 6'b00_1000    ; 
wire           clk       ;                // I2C操作时钟
wire           i2c_exec  ;                // i2c触发控制
wire   [15:0]  i2c_addr  ;                // i2c操作地址
wire   [ 7:0]  i2c_data_w;                // i2c写入的数据
wire           i2c_done  ;                // i2c操作结束标志
wire           i2c_rh_wl ;                // i2c读写控制
wire   [ 7:0]  i2c_data_r;                // i2c读出的数据
//wire    [19:0]  num       ;                // 电压的大小

//*****************************************************
//**                    main code
//*****************************************************

//例化AD/DA模块
pcf8591 u_pcf8591(
    //global clock
    .clk         (clk       ),            // 时钟信号
    .rst_n       (sys_rst_n ),            // 复位信号
    //i2c interface
    .i2c_exec    (i2c_exec  ),            // I2C触发执行信号
    .i2c_rh_wl   (i2c_rh_wl ),            // I2C读写控制信号
    .i2c_addr    (i2c_addr  ),            // I2C器件内地址
    .i2c_data_w  (i2c_data_w),            // I2C要写的数据
    .i2c_data_r  (i2c_data_r),            // I2C读出的数据
    .i2c_done    (i2c_done  ),            // I2C一次操作完成
    //user interface
    .num         (num       )             // 采集到的电压
);

//例化i2c_dri
i2c_dri #(
    .SLAVE_ADDR  (SLAVE_ADDR),            // slave address从机地址，放此处方便参数传递
    .CLK_FREQ    (CLK_FREQ  ),            // i2c_dri模块的驱动时钟频率(CLK_FREQ)
    .I2C_FREQ    (I2C_FREQ  )             // I2C的SCL时钟频率
) u_i2c_dri(
    //global clock
    .clk         (sys_clk   ),            // i2c_dri模块的驱动时钟(CLK_FREQ)
    .rst_n       (sys_rst_n ),            // 复位信号
    //i2c interface
    .i2c_exec    (i2c_exec  ),            // I2C触发执行信号
    .bit_ctrl    (BIT_CTRL  ),            // 器件地址位控制(16b/8b)
    .i2c_rh_wl   (i2c_rh_wl ),            // I2C读写控制信号
    .i2c_addr    (i2c_addr  ),            // I2C器件内地址
    .i2c_data_w  (i2c_data_w),            // I2C要写的数据
    .i2c_data_r  (i2c_data_r),            // I2C读出的数据
    .i2c_done    (i2c_done  ),            // I 2C一次操作完成
    .scl         (scl       ),            // I2C的SCL时钟信号
    .sda         (sda       ),            // I2C的SDA信号
    //user interface
    .dri_clk     (clk       )             // I2C操作时钟
);


endmodule