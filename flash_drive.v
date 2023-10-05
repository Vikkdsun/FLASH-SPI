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
    
    /*---------- 鐢ㄦ埛绔彛 ----------*/  
    .i_user_op_type         (i_user_op_type         )               ,       // 1         // 0娓呯┖ 1鍐� 2璇� 
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
    
    /*---------- SPI绔彛 ----------*/   
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
    .i_clk                  (i_clk                  )               ,      //缁崵绮洪弮鍫曟寭
    .i_rst                  (i_rst                  )               ,      //婢跺秳缍�

    .o_spi_clk              (o_spi_clk              )               ,      //spi閻ㄥ垻lk
    .o_spi_cs               (o_spi_cs               )               ,      //spi閻ㄥ嫮澧栭敓锟�?
    .o_spi_mosi             (o_spi_mosi             )               ,      //spi閻ㄥ嫪瀵岄張楦跨翻閿燂拷?
    .i_spi_miso             (i_spi_miso             )               ,      //spi閻ㄥ嫪绮犻張楦跨翻閿燂拷?

    .i_user_op_data         (w_spi_op_data          )               ,      //閹垮秳缍旈弫鐗堝祦閿涘牊瀵氶敓锟�?8bit+閸︽澘娼�24bit閿燂拷?
    .i_user_op_type         (w_spi_op_type          )               ,      //閹垮秳缍旂猾璇茬�烽敍鍫ｎ嚢閵嗕礁鍟撻妴浣瑰瘹娴犮倧绱�
    .i_user_op_len          (w_spi_op_len           )               ,      //閹垮秳缍旈弫鐗堝祦閻ㄥ嫰鏆遍敓锟�?32閿燂拷?8
    .i_user_clk_len         (w_spi_clk_len          )               ,      //閺冨爼鎸撻崨銊︽埂
    .i_user_op_valid        (w_spi_op_valid         )               ,      //閻€劍鍩涢惃鍕箒閺佸牅淇婇敓锟�?
    .o_user_op_ready        (w_spi_op_ready         )               ,      //閻€劍鍩涢惃鍕櫙婢跺洣淇婇敓锟�?
    .i_user_write_data      (w_user_write_data      )               ,      //閸愭瑦鏆熼敓锟�?
    .o_user_write_req       (w_spi_write_req        )               ,      //閸愭瑦鏆熼幑顔款嚞閿燂拷?
    .o_user_read_data       (w_spi_read_data        )               ,      //鐠囩粯鏆熼敓锟�?
    .o_user_read_valid      (w_spi_read_valid       )                      //鐠囩粯鏆熼幑顔芥箒閿燂拷?
);

endmodule
