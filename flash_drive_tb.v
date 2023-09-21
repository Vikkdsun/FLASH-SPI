`timescale 1ns/1ps

module flash_deive_tb();

reg     clk, rst        ;

initial
begin
    rst = 1;
    # 20;
    @(posedge clk)  rst = 0;
end

always
begin
    clk = 1;
    # 10;
    clk = 0;
    # 10;
end

wire [1:0]                                  w_user_op_type                  ;
wire [23:0]                                 w_user_op_addr                  ;
wire [8:0]                                  w_user_op_num                   ;
wire                                        w_user_op_valid                 ;
wire                                        w_user_op_ready                 ;

wire [7:0]                                  w_user_write_data               ;
wire                                        w_user_write_sop                ;
wire                                        w_user_write_eop                ;
wire                                        w_user_write_valid              ;

wire [7:0]                                  w_user_read_data                ;
wire                                        w_user_read_sop                 ;
wire                                        w_user_read_eop                 ;
wire                                        w_user_read_valid               ;

wire                                        w_spi_clk                       ;
wire                                        w_spi_cs                        ;
wire                                        w_spi_mosi                      ;
wire                                        w_spi_miso                      ;

wire                                        WPn                             ;
wire                                        HOLDn                           ;

flash_drive flash_drive_u0(
    .i_clk                      (clk                )          ,
    .i_rst                      (rst                )          ,
            
    .i_user_op_type             (w_user_op_type     )          ,
    .i_user_op_addr             (w_user_op_addr     )          ,
    .i_user_op_num              (w_user_op_num      )          ,
    .i_user_op_valid            (w_user_op_valid    )          ,
    .o_user_op_ready            (w_user_op_ready    )          ,
            
    .i_user_write_data          (w_user_write_data  )          ,
    .i_user_write_sop           (w_user_write_sop   )          ,
    .i_user_write_eop           (w_user_write_eop   )          ,
    .i_user_write_valid         (w_user_write_valid )          ,
            
    .o_user_read_data           (w_user_read_data   )          ,
    .o_user_read_sop            (w_user_read_sop    )          ,
    .o_user_read_eop            (w_user_read_eop    )          ,
    .o_user_read_valid          (w_user_read_valid  )          ,
            
    .o_spi_clk                  (w_spi_clk          )          ,
    .o_spi_cs                   (w_spi_cs           )          ,
    .o_spi_mosi                 (w_spi_mosi         )          ,
    .i_spi_miso                 (w_spi_miso         )          
);

user_gen_data user_gen_data_u0(
    .i_clk                      (clk                )          ,
    .i_rst                      (rst                )          ,

    .o_user_op_type             (w_user_op_type     )          ,       // 1
    .o_user_op_addr             (w_user_op_addr     )          ,       // 1
    .o_user_op_num              (w_user_op_num      )          ,       // 1
    .o_user_op_valid            (w_user_op_valid    )          ,       // 1
    .i_user_op_ready            (w_user_op_ready    )          ,       // 1

    .o_user_write_data          (w_user_write_data  )          ,       // 1
    .o_user_write_sop           (w_user_write_sop   )          ,       // 1
    .o_user_write_eop           (w_user_write_eop   )          ,       // 1
    .o_user_write_valid         (w_user_write_valid )          ,       // 1

    .i_user_read_data           (w_user_read_data   )          ,
    .i_user_read_sop            (w_user_read_sop    )          ,
    .i_user_read_eop            (w_user_read_eop    )          ,
    .i_user_read_valid          (w_user_read_valid  )          
);

pullup( w_spi_mosi   );
pullup( w_spi_miso   );
pullup( WPn          );
pullup( HOLDn        );

W25Q128JVxIM W25Q128JVxIM_u0(
   .CSn                         (w_spi_cs           )           , 
   .CLK                         (w_spi_clk          )           , 
   .DIO                         (w_spi_mosi         )           , 
   .DO                          (w_spi_miso         )           , 
   .WPn                         (WPn                )           , 
   .HOLDn                       (HOLDn              )           
);

endmodule
