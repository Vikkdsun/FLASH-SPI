module flash_drive(
    input                               i_clk                       ,
    input                               i_rst                       ,

    input [1:0]                         i_user_op_type              ,
    input [23:0]                        i_user_op_addr              ,
    input [8:0]                         i_user_op_num               ,
    input                               i_user_op_valid             ,
    output                              o_user_op_ready             ,

    input [7:0]                         i_user_write_data           ,
    input                               i_user_write_sop            ,
    input                               i_user_write_eop            ,
    input                               i_user_write_valid          ,

    output [7:0]                        o_user_read_data            ,
    output                              o_user_read_sop             ,
    output                              o_user_read_eop             ,
    output                              o_user_read_valid           ,

    output                              o_spi_clk                   ,
    output                              o_spi_cs                    ,
    output                              o_spi_mosi                  ,
    input                               i_spi_miso                  
);

wire [31:0]                             w_spi_op_data               ;
wire [1:0]                              w_spi_op_type               ;
wire [15:0]                             w_spi_op_len                ;
wire [15:0]                             w_spi_clk_len               ;
wire                                    w_spi_op_valid              ;
wire                                    w_spi_op_ready              ;
wire [7 :0]                             w_user_write_data           ;
wire                                    w_spi_write_req             ;
wire [7:0]                              w_spi_read_data             ;
wire                                    w_spi_read_valid            ;

flash_ctrl flash_ctrl_u0(
    .i_clk                  (i_clk                  )               ,
    .i_rst                  (i_rst                  )               ,
    
    /*---------- 用户端口 ----------*/  
    .i_user_op_type         (i_user_op_type         )               ,       // 1         // 0清空 1写 2读 
    .i_user_op_addr         (i_user_op_addr         )               ,       // 1
    .i_user_op_num          (i_user_op_num          )               ,       // 1
    .i_user_op_valid        (i_user_op_valid        )               ,       // 1
    .o_user_op_ready        (o_user_op_ready        )               ,       // 1
    
    .i_user_write_data      (i_user_write_data      )               ,       // 1
    .i_user_write_sop       (i_user_write_sop       )               ,
    .i_user_write_eop       (i_user_write_eop       )               ,
    .i_user_write_valid     (i_user_write_valid     )               ,       // 1
    
    .o_user_read_data       (o_user_read_data       )               ,       // 1
    .o_user_read_sop        (o_user_read_sop        )               ,       // 1
    .o_user_read_eop        (o_user_read_eop        )               ,       // 1
    .o_user_read_valid      (o_user_read_valid      )               ,       // 1
    
    /*---------- SPI端口 ----------*/   
    .o_spi_op_data          (w_spi_op_data          )               ,       // 1
    .o_spi_op_type          (w_spi_op_type          )               ,       // 1
    .o_spi_op_len           (w_spi_op_len           )               ,       // 1
    .o_spi_clk_len          (w_spi_clk_len          )               ,       // 1
    .o_spi_op_valid         (w_spi_op_valid         )               ,       // 1
    .i_spi_op_ready         (w_spi_op_ready         )               ,
    .o_user_write_data      (w_user_write_data      )               ,       // 1
    .i_spi_write_req        (w_spi_write_req        )               ,       // 1
    .i_spi_read_data        (w_spi_read_data        )               ,       // 1
    .i_spi_read_valid       (w_spi_read_valid       )                       // 1

);

spi_drive#(
    .P_DATA_WIDTH           (      8                )               ,
    .P_OP_LEN               (      32               )               ,
    .P_READ_DATA_WIDTH      (      8                )               , 
    .P_CPOL                 (      0                )               ,
    .P_CPHL                 (      0                )               
)           
spi_drive_u0
(                           
    .i_clk                  (i_clk                  )               ,      //绯荤粺鏃堕挓
    .i_rst                  (i_rst                  )               ,      //澶嶄綅

    .o_spi_clk              (o_spi_clk              )               ,      //spi鐨刢lk
    .o_spi_cs               (o_spi_cs               )               ,      //spi鐨勭墖锟�?
    .o_spi_mosi             (o_spi_mosi             )               ,      //spi鐨勪富鏈鸿緭锟�?
    .i_spi_miso             (i_spi_miso             )               ,      //spi鐨勪粠鏈鸿緭锟�?

    .i_user_op_data         (w_spi_op_data          )               ,      //鎿嶄綔鏁版嵁锛堟寚锟�?8bit+鍦板潃24bit锟�?
    .i_user_op_type         (w_spi_op_type          )               ,      //鎿嶄綔绫诲瀷锛堣銆佸啓銆佹寚浠わ級
    .i_user_op_len          (w_spi_op_len           )               ,      //鎿嶄綔鏁版嵁鐨勯暱锟�?32锟�?8
    .i_user_clk_len         (w_spi_clk_len          )               ,      //鏃堕挓鍛ㄦ湡
    .i_user_op_valid        (w_spi_op_valid         )               ,      //鐢ㄦ埛鐨勬湁鏁堜俊锟�?
    .o_user_op_ready        (w_spi_op_ready         )               ,      //鐢ㄦ埛鐨勫噯澶囦俊锟�?
    .i_user_write_data      (w_user_write_data      )               ,      //鍐欐暟锟�?
    .o_user_write_req       (w_spi_write_req        )               ,      //鍐欐暟鎹锟�?
    .o_user_read_data       (w_spi_read_data        )               ,      //璇绘暟锟�?
    .o_user_read_valid      (w_spi_read_valid       )                      //璇绘暟鎹湁锟�?
);

endmodule
