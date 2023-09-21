// 联合用户和spi

module flash_ctrl (
    input                               i_clk                       ,
    input                               i_rst                       ,

    /*---------- 用户端口 ----------*/
    input [1:0]                         i_user_op_type              ,       // 1         // 0清空 1写 2读 
    input [23:0]                        i_user_op_addr              ,       // 1
    input [8:0]                         i_user_op_num               ,       // 1
    input                               i_user_op_valid             ,       // 1
    output                              o_user_op_ready             ,       // 1

    input [7:0]                         i_user_write_data           ,       // 1
    input                               i_user_write_sop            ,
    input                               i_user_write_eop            ,
    input                               i_user_write_valid          ,       // 1

    output [7:0]                        o_user_read_data            ,       // 1
    output                              o_user_read_sop             ,       // 1
    output                              o_user_read_eop             ,       // 1
    output                              o_user_read_valid           ,       // 1

    /*---------- SPI端口 ----------*/
    output [31:0]                       o_spi_op_data               ,       // 1
    output [1:0]                        o_spi_op_type               ,       // 1
    output [15:0]                       o_spi_op_len                ,       // 1
    output [15:0]                       o_spi_clk_len               ,       // 1
    output                              o_spi_op_valid              ,       // 1
    input                               i_spi_op_ready              ,

    output [7 :0]                       o_user_write_data           ,       // 1
    input                               i_spi_write_req             ,       // 1

    input  [7:0]                        i_spi_read_data             ,       // 1
    input                               i_spi_read_valid                    // 1

);

/*
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)

    else if ()

    else if ()

    else

end
*/

// 输出给SPI的先用寄存器连接 给SPI的要写的数据先不动 因为要走fifo 给用户的也先不动
reg [31:0]                                                  ro_spi_op_data                                      ;
reg [1:0]                                                   ro_spi_op_type                                      ;
reg [15:0]                                                  ro_spi_op_len                                       ;
reg [15:0]                                                  ro_spi_clk_len                                      ;
reg                                                         ro_spi_op_valid                                     ;

assign                                                      o_spi_op_data  = ro_spi_op_data                     ;
assign                                                      o_spi_op_type  = ro_spi_op_type                     ;
assign                                                      o_spi_op_len   = ro_spi_op_len                      ;
assign                                                      o_spi_clk_len  = ro_spi_clk_len                     ;
assign                                                      o_spi_op_valid = ro_spi_op_valid                    ;

// 和用户握手   
wire                                                        w_user_active                                       ;
assign                                                      w_user_active = o_user_op_ready & i_user_op_valid   ;

// 把o_user_op_ready连接到寄存器
reg                                                         ro_user_op_ready                                    ;
assign				o_user_op_ready = ro_user_op_ready    ;                                    
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_ready <= 'd1;
    else if (w_user_active)
        ro_user_op_ready <= 'd0;		// 注意优先级
    else if (r_st_current == P_ST_IDLE)
        ro_user_op_ready <= 'd1;                // 什么时候拉回ready暂时放一下
    else
        ro_user_op_ready <= ro_user_op_ready;
end

// 把输入锁存 输入的写的数据一族先不处理 因为和FIFO有关系
reg [7:0]                                                   ri_user_op_type                                     ;
reg                                                         ri_user_op_addr                                     ;
reg                                                         ri_user_op_num                                      ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_user_op_type <= 'd0;
        ri_user_op_addr <= 'd0;
        ri_user_op_num  <= 'd0;
    end else if (w_user_active) begin
        ri_user_op_type <= i_user_op_type;
        ri_user_op_addr <= i_user_op_addr;
        ri_user_op_num  <= i_user_op_num ;
    end else begin
        ri_user_op_type <= ri_user_op_type;
        ri_user_op_addr <= ri_user_op_addr;
        ri_user_op_num  <= ri_user_op_num ;
    end
end

localparam                                                  P_USER_OP_TYPE_CLEAR    =   0                       ,
                                                            P_USER_OP_TYPE_WRITE    =   1                       ,
                                                            P_USER_OP_TYPE_READ     =   2                       ;       // 这是用户发过来的type

localparam                                                  P_SPI_OP_TYPE_INS       =   0                       ,
                                                            P_SPI_OP_TYPE_WRITE     =   1                       ,
                                                            P_SPI_OP_TYPE_READ      =   2                       ;       // 这是发给SPI的typeP

// 使用状态机 因为写数据 或者 读数据 是连续很多次spi握手
reg [7:0]                                                   r_st_current                                        ;
reg [7:0]                                                   r_st_next                                           ;

// 和SPI握手
wire                                                        w_spi_active                                        ;
assign                                                      w_spi_active = o_spi_op_valid & i_spi_op_ready      ;

localparam                                                  P_ST_IDLE       =   0                               ,       // 默认状态 没有和用户握手 就不和spi握手
                                                            P_ST_RUN        =   1                               ,       // 和用户握手后 判断要进行什么操作
                                                            P_ST_W_EN       =   2                               ,       // 写使能 任何写操作前要先使能
                                                            P_ST_W_INS      =   3                               ,       // 写指令 写数据前 先把指令地址啥的写过去
                                                            P_ST_W_DATA     =   4                               ,       // 写数据 用户给的数据在fifo里 有spi给的req再发出给spi
                                                            P_ST_R_INS      =   5                               ,       // 读指令 如果要读 把读指令传给spi
                                                            P_ST_R_DATA     =   6                               ,       // 读数据 读到的数据传到fifo 整合在一起再交给用户
                                                            P_ST_CLEAR      =   7                               ,       // 清空 把写进flash的全拉回1 这样下次才能写
                                                            P_ST_BUSY       =   8                               ,       // 读寄存器 把指令发给spi 等待spi返回的寄存器值
                                                            P_ST_BUSY_CHECK =   9                               ,       // 得到寄存器值后 看一下最低位 判断忙否
                                                            P_ST_BUSY_WAIT  =   10                              ;       // 如果忙 等待

// 第一段
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_IDLE;
    else
        r_st_current <= r_st_next;
end

// 第二段
always@(*)
begin
    case(r_st_current)
        P_ST_IDLE           :   r_st_next   =   w_user_active                           ?       P_ST_RUN            :       P_ST_IDLE           ;  
        P_ST_RUN            :   r_st_next   =   ri_user_op_type == P_USER_OP_TYPE_READ  ?       P_ST_R_INS          :       P_ST_W_EN;
        P_ST_W_EN           :   r_st_next   =   r_st_cnt == 18                            ?       ri_user_op_type == P_USER_OP_TYPE_WRITE ? P_ST_W_INS     :  P_ST_CLEAR   :       P_ST_W_EN           ;  // 18 = 2xclk_len + 2
        P_ST_W_INS          :   r_st_next   =   r_st_cnt == 2*(32 + 8 * ri_user_op_num +1)                            ?       P_ST_W_DATA         :       P_ST_W_INS          ;
        P_ST_W_DATA         :   r_st_next   =   i_spi_op_ready                          ?       P_ST_BUSY           :       P_ST_W_DATA         ;
        P_ST_R_INS          :   r_st_next   =   r_st_cnt == 2*(32 + 8 * ri_user_op_num +1)                            ?       P_ST_R_DATA         :       P_ST_R_INS          ;
        P_ST_R_DATA         :   r_st_next   =   i_spi_op_ready                          ?       P_ST_BUSY           :       P_ST_R_DATA         ;
        P_ST_CLEAR          :   r_st_next   =   r_st_cnt == 66                            ?       P_ST_BUSY           :       P_ST_CLEAR          ;
        P_ST_BUSY           :   r_st_next   =   r_st_cnt == 33                           ?       P_ST_BUSY_CHECK     :       P_ST_BUSY           ;
        P_ST_BUSY_CHECK     :   r_st_next   =   i_spi_read_valid                      ?       i_spi_read_data[0]  ?       P_ST_BUSY_WAIT      :       P_ST_IDLE   :   P_ST_BUSY_CHECK ;
        P_ST_BUSY_WAIT      :   r_st_next   =   r_st_cnt == 255                         ?       P_ST_BUSY           :       P_ST_BUSY_WAIT      ;
        default             :   r_st_next   =   P_ST_IDLE                               ;
    endcase
end

// 为了确定写、读数据状态什么时候结束 需要使用SPI发过来的ready 为了只要上升沿(X) <<<这是错误的>>> 具体可以画图来明了会跳转很快 这里应该就要ready 而不是上升沿
// reg                                                         ri_spi_op_ready                                     ;
// wire                                                        w_spi_op_ready_pos                                  ;

// assign                                                      w_spi_op_ready_pos = i_spi_op_ready & !ri_spi_op_ready;

// always@(posedge i_clk or posedge i_rst)
// begin
//     if (i_rst)
//         ri_spi_op_ready <= 'd1;
//     else
//         ri_spi_op_ready <= i_spi_op_ready;
// end

// 到达等待状态时 需要计数器判断等待时长
reg [15:0]                                                  r_st_cnt                                            ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_cnt <= 'd0;
    else if (r_st_cnt == 255)
        r_st_cnt <= 'd0;
    else if (r_st_current != r_st_next)
        r_st_cnt <= 'd0;
    else
        r_st_cnt <= r_st_cnt + 1;
end

// 第三段 这个状态机主要是为了发给SPI东西的 所以第三段的输出主要和SPI有关系
always@(posedge i_clk or posedge i_rst)     
begin
    if (i_rst) begin
        ro_spi_op_data  <= 'd0;
        ro_spi_op_type  <= 'd0;
        ro_spi_op_len   <= 'd0;
        ro_spi_clk_len  <= 'd0;
        ro_spi_op_valid <= 'd0; 
    end else if (r_st_current == P_ST_W_EN) begin
        ro_spi_op_data  <= {8'h00,8'h00,8'h00,8'h06};
        ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
        ro_spi_op_len   <= 8;
        ro_spi_clk_len  <= 8;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_W_INS) begin
        ro_spi_op_data  <= {8'h02,ri_user_op_addr};
        ro_spi_op_type  <= P_SPI_OP_TYPE_WRITE;
        ro_spi_op_len   <= 32;      
        ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_R_INS) begin
        ro_spi_op_data  <= {8'h03,ri_user_op_addr};
        ro_spi_op_type  <= P_SPI_OP_TYPE_READ;
        ro_spi_op_len   <= 32;      
        ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_CLEAR) begin
        ro_spi_op_data  <= {8'h20,ri_user_op_addr};
        ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
        ro_spi_op_len   <= 32;      
        ro_spi_clk_len  <= 32;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_BUSY) begin
        ro_spi_op_data  <= {24'd0,8'h05};
        ro_spi_op_type  <= P_SPI_OP_TYPE_READ;
        ro_spi_op_len   <= 8;      
        ro_spi_clk_len  <= 16;
        ro_spi_op_valid <= 'd1;
    end else begin
        ro_spi_op_data  <= ro_spi_op_data;
        ro_spi_op_type  <= ro_spi_op_type;
        ro_spi_op_len   <= ro_spi_op_len ;
        ro_spi_clk_len  <= ro_spi_clk_len;
        ro_spi_op_valid <= 'd0; 
    end
end


// 现在 我们可以回过头来看一下user_ready的拉高条件了 也就是状态机回到idle 
// 不用current next不相同作为拉高条件可以认为是 和 spi的拉高条件一样 打一拍再拉高 算是一个保险吧

// 然后就是处理复杂的 如果要写 要读 怎么办

// 首先看写
// i_user_write_data 
// i_user_write_sop  
// i_user_write_eop  
// i_user_write_valid

// 用户输入进来的写的数据 不能直接交给SPI 要等SPI的req
// 用FIFO 但是FIFO输入要打拍 因为输入打拍了 要给valid也打拍
reg [7:0]                                                   ri_user_write_data                                  ;
reg                                                         ri_user_write_valid                                 ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_user_write_data  <= 'd0;
        ri_user_write_valid <= 'd0;
    end else begin
        ri_user_write_data  <= i_user_write_data ;
        ri_user_write_valid <= i_user_write_valid;
    end
end

FLASH_CTRL_FIFO_DATA FLASH_CTRL_FIFO_DATA_U0 (
    .clk      (i_clk                ),  
    .srst     (i_rst                ),  
    .din      (ri_user_write_data   ),               // 注意 输入到FIFO的数据要打一拍
    .wr_en    (ri_user_write_valid  ),  
    .rd_en    (i_spi_write_req      ),                                 // 读使能（SPI什么时候可以取数据）  答：req
    .dout     (o_user_write_data    ),               
    .full     (),                           // 由于写数据和写多少是用户决定�?? 然后在一�??始就传给spi时钟�?? �??以不会存在spi要数据时没有数据 或�?�FIFO满了 不能写的情况
    .empty    ()  
);

// 然后看读
// o_user_read_data 
// o_user_read_sop  
// o_user_read_eop  
// o_user_read_valid

// i_spi_read_data 
// i_spi_read_valid

// SPI读到的数据 并不连续 为了连续 使用FIFO

FLASH_CTRL_FIFO_DATA FLASH_CTRL_FIFO_DATA_READ_U0 (
    .clk      (i_clk                ), 
    .srst     (i_rst                ), 
    .din      (ri_spi_read_data     ),           // 同样要打�??
    .wr_en    (r_fifo_read_wren     ),         // �??么时候可以读？valid 但是要注�?? 有一个读是读�?? 是不�??要往这里面写�?? 因为他就�??个数�?? 在busy_check就读�?? 如果也写这里 后面读就读寄存器�??
    .rd_en    (r_fifo_read_rden     ), 
    .dout     (w_fifo_read_data     ), 
    .full     (),    
    .empty    (w_fifo_read_empty    )                            // 这里借助�??下empty 为了确定�??么时候结束读(感觉这里不用empty 用输入给的num也可以确定什么时候不�??)
);

// 写使能要注意 只有读数据时才能写 后面读寄存器读忙不可以写
reg                                                         r_fifo_read_wren                                    ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_wren <= 'd0;
    else if (r_st_current == P_ST_R_INS)
        r_fifo_read_wren <= i_spi_read_valid;
    else
        r_fifo_read_wren <= 'd0;
end

// 输入数据打拍 正好和上面的valid同步了
reg [7:0]                                                   ri_spi_read_data                                    ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_spi_read_data <= 'd0;
    else
        ri_spi_read_data <= i_spi_read_data;
end

// 什么时候输出读的数据呢？ 《《《也要考虑后面读寄存器读忙时 不能输出》》》
reg                                                         r_fifo_read_rden                                    ;
// 另外 读使能应该很长时间为1 因为要读的数据多 所以使用empty empty在fifo剩一个数据时拉高 即使rden在最后一个数据之后拉低 通过控制好valid也可以使用户拿到正确的数
wire                                                        w_fifo_read_empty                                   ;

// 要检测empty上升沿
reg                                                         r_fifo_read_empty_1d                                ;
wire                                                        w_read_empty_pos                                    ;
assign                                                      w_read_empty_pos = !r_fifo_read_empty_1d & w_fifo_read_empty;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_empty_1d <= 'd0;
    else
        r_fifo_read_empty_1d <= w_fifo_read_empty;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_rden <= 'd0;
    else if (w_read_empty_pos)
        r_fifo_read_rden <= 'd0;
    else if (r_st_current == P_ST_R_DATA && r_st_next != P_ST_R_DATA)
        r_fifo_read_rden <= 'd1;
    else
        r_fifo_read_rden <= r_fifo_read_rden;
end

// 多方考虑下 如果读到的数据直接连给用户 那么eop valid难以确定 所以这里先把fifo读到的暂留 打拍后再给用户
wire [7:0]                                                  w_fifo_read_data                                    ;

reg  [7:0]                                                  ro_user_read_data                                   ;
assign                                                      o_user_read_data = ro_user_read_data                ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_data <= 'd0;
    else
        ro_user_read_data <= w_fifo_read_data;
end

// 这回再根据empty和读使能确定sop eop valid
// 寻找读使能信号的上升沿
reg                                                         r_fifo_read_rden_1d                                 ;
wire                                                        w_fifo_read_rden_pos                                ;
assign                                                      w_fifo_read_rden_pos = r_fifo_read_rden & !r_fifo_read_rden_1d ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_rden_1d <= 'd0;
    else
        r_fifo_read_rden_1d <= r_fifo_read_rden;
end

// 寻找empty的上升沿 之前有了 w_read_empty_pos

// 寄存器连接sop eop valid
reg                                                         ro_user_read_sop                                    ;
reg                                                         ro_user_read_eop                                    ;
reg                                                         ro_user_read_valid                                  ;

assign				o_user_read_sop = ro_user_read_sop	;
assign				o_user_read_eop = ro_user_read_eop 	;                                  
assign				o_user_read_valid = ro_user_read_valid	;

reg                                                         r_fifo_read_rden_pos_1d                             ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_rden_pos_1d <= 'd0;
    else
        r_fifo_read_rden_pos_1d <= w_fifo_read_rden_pos;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_sop <= 'd0;
    else if (r_fifo_read_rden_pos_1d)
        ro_user_read_sop <= 'd1;
    else
        ro_user_read_sop <= 'd0;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_eop <= 'd0;
    else if (w_read_empty_pos)
        ro_user_read_eop <= 'd1;
    else
        ro_user_read_eop <= 'd0;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_valid <= 'd0;
    else if (ro_user_read_eop)
        ro_user_read_valid <= 'd0;
    else if (r_fifo_read_rden_pos_1d)
        ro_user_read_valid <= 'd1;
    else    
        ro_user_read_valid <= ro_user_read_valid;
end

endmodule

// 我在这里写下另一种状态机控制
// 状态数量更少 更容易理解

// localparam                          P_ST_IDLE   =   0                       ,
//                                     P_ST_RUN    =   1                       ,
//                                     P_ST_W_EN   =   2                       ,
//                                     P_ST_W_DATA =   3                       ,
//                                     P_ST_R_DATA =   4                       ,
//                                     P_ST_BUSY   =   5                       ,
//                                     P_ST_WAIT   =   6                       ,
//                                     P_ST_CLEAR  =   7                       ;

// always@(*)
// begin
//     case(r_st_current)
//         P_ST_IDLE           :   r_st_next   =   w_user_active                           ?       P_ST_RUN            :       P_ST_IDLE           ;
//         P_ST_RUN            :   r_st_next   =   ri_user_op_type == P_USER_OP_TYPE_READ  ?       P_ST_R_DATA         :       ri_user_op_type == P_USER_OP_TYPE_CLEAR?    P_ST_CLEAR  : 
//         P_ST_W_EN           :   r_st_next   =   r_st_cnt        == 18                   ?       P_ST_W_DATA         :       P_ST_W_EN           ;
//         P_ST_W_DATA         :   r_st_next   =   r_st_cnt == 2*(32 + 8 * ri_user_op_num +1)  ?   P_ST_BUSY           :       P_ST_W_DATA         ;
//         P_ST_R_DATA         :   r_st_next   =   r_st_cnt == 2*(32 + 8 * ri_user_op_num +1)  ?   P_ST_BUSY           :       P_ST_R_DATA         ;
//         P_ST_BUSY           :   r_st_next   =   i_spi_read_valid                        ?       i_spi_read_data[0]  ?       P_ST_BUSY_WAIT      :       P_ST_IDLE   :   P_ST_BUSY_CHECK ;
//         P_ST_WAIT           :   r_st_next   =   r_st_cnt == 255                         ?       P_ST_BUSY           :       P_ST_BUSY_WAIT      ;
//         P_ST_CLEAR          :   r_st_next   =   r_st_cnt == 66                          ?       P_ST_BUSY           :       P_ST_CLEAR          ;
//         default             :   r_st_next   =   P_ST_IDLE                               ;
//     endcase
// end

// always@(posedge i_clk or posedge i_rst)
// begin
//     if (i_rst) begin
//         ro_spi_op_data  <= 'd0;
//         ro_spi_op_type  <= 'd0;
//         ro_spi_op_len   <= 'd0;
//         ro_spi_clk_len  <= 'd0;
//         ro_spi_op_valid <= 'd0; 
//     end else if (r_st_current == P_ST_W_EN) begin
//         ro_spi_op_data  <= {8'h06,8'h00,8'h00,8'h00};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
//         ro_spi_op_len   <= 8;
//         ro_spi_clk_len  <= 8;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_W_DATA) begin
//         ro_spi_op_data  <= {8'h02,ri_user_op_addr};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_WRITE;
//         ro_spi_op_len   <= 32;      // 指令和地址
//         ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_R_DATA) begin
//         ro_spi_op_data  <= {8'h03,ri_user_op_addr};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_READ;
//         ro_spi_op_len   <= 32;      // 指令和地址
//         ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_CLEAR) begin
//         ro_spi_op_data  <= {8'h20,ri_user_op_addr};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
//         ro_spi_op_len   <= 32;      // 指令和地址
//         ro_spi_clk_len  <= 32;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_BUSY) begin
//         ro_spi_op_data  <= {8'h05,24'd0};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
//         ro_spi_op_len   <= 8;      
//         ro_spi_clk_len  <= 16;
//         ro_spi_op_valid <= 'd1;
//     end else begin
//         ro_spi_op_data  <= ro_spi_op_data;
//         ro_spi_op_type  <= ro_spi_op_type;
//         ro_spi_op_len   <= ro_spi_op_len ;
//         ro_spi_clk_len  <= ro_spi_clk_len;
//         ro_spi_op_valid <= 'd0; 
//     end
// end




