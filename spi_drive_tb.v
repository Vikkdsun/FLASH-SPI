`timescale 1ns/1ps

module spi_drive_tb ();

localparam P_CLK_PERIOD_HALF = 10;

reg clk, rst;

initial begin
    clk = 0;
    rst = 1;
    #20;
    @(posedge clk)rst = 0;        // 同步释放
end

always #10 clk = ~clk;

wire                w_spi_clk           ;
wire                w_spi_cs            ;
wire                w_spi_mosi          ;
reg                 r_spi_miso          ;

reg [31:0]         w_user_op_data      ;
reg [1:0]          w_user_op_type      ;
reg [15:0]         w_user_op_len       ;
reg [15:0]         w_user_clk_len      ;
reg                w_user_op_valid     ;
wire                w_user_op_ready     ;

reg  [7:0]         r_user_write_data   ;
wire                w_user_write_req    ;
wire   [7:0]         w_user_read_data    ;
wire                 w_user_read_valid   ;

spi_drive#(
    .P_DATA_WIDTH        (8             )                ,  
    .P_OP_LEN            (32            )                ,  
    .P_CPOL              (0             )                ,   
    .P_CPHL              (0             )                ,  
    .P_READ_DATA_WIDTH   (8             )                
)
spi_drive_u0
(
    .i_clk               (clk   )                ,       // 系统时钟
    .i_rst               (rst   )                ,       // 复位

    .o_spi_clk           (w_spi_clk     )                ,       // spi时钟
    .o_spi_cs            (w_spi_cs      )                ,       // spi片�??
    .o_spi_mosi          (w_spi_mosi    )                ,       // 主机输出
    .i_spi_miso          (r_spi_miso    )                ,       // 从机输出

    .i_user_op_data      (w_user_op_data)                ,       // 操作数据：指令（8bit+地址24bit�?
    .i_user_op_type      (w_user_op_type)                ,       // 操作类型�? 只传指令 1：指令和地址 2: 传指令和地址，写完地�?后，得到�?个脉�?(req)，接�?传数据，每要传一个，就脉冲一�?
    .i_user_op_len       (w_user_op_len )                ,       // 操作数据的长�?32�?8
    .i_user_clk_len      (w_user_clk_len  )                ,       // 时钟周期�? 如果要写数据 32 + �?/读周�?  8<<(字节�?-1)  
    .i_user_op_valid     (w_user_op_valid )                ,       // 用户的有效信�?
    .o_user_op_ready     (w_user_op_ready)                ,       // 用户的准备信�? (握手后把输入锁存)

    .i_user_write_data  (r_user_write_data)                ,       // 写数据（用户方收到一个req就发�?个byte�?
    .o_user_write_req    (w_user_write_req )                ,       // 写数据请�?

    .o_user_read_data    (w_user_read_data )                ,       // 读数�?
    .o_user_read_valid   (w_user_read_valid)                        // 读数据有�?
);

always@(posedge clk or posedge rst)
begin
    if (rst)
        r_user_write_data <= 'd0;
    else if (w_user_write_req)
        r_user_write_data <= 8'b1111_1111;
    else 
        r_user_write_data <= r_user_write_data;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        w_user_op_data <= 32'd1426063618;
    else 
        w_user_op_data <= 32'd1426063618;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        w_user_op_type <= 'd0;
    else 
        w_user_op_type <= 'd1;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        w_user_op_len <= 'd0;
    else 
        w_user_op_len <= 'd32;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        w_user_clk_len <= 'd0;
    else 
        w_user_clk_len <= 'd48;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        w_user_op_valid <= 'd0;
    else 
        w_user_op_valid <= 'd1;
end

always@(posedge clk or posedge rst)
begin
    if (rst)
        r_spi_miso <= 'd0;
    else 
        r_spi_miso <= 'd1;
end

endmodule