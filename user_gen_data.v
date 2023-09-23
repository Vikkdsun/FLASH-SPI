// 数据产生模块

module user_gen_data(
    input                                   i_clk                       ,
    input                                   i_rst                       ,
    
    output [1:0]                            o_user_op_type              ,       // 1
    output [23:0]                           o_user_op_addr              ,       // 1
    output [8:0]                            o_user_op_num               ,       // 1
    output                                  o_user_op_valid             ,       // 1
    input                                   i_user_op_ready             ,       // 1

    output [7:0]                            o_user_write_data           ,       // 1
    output                                  o_user_write_sop            ,       // 1
    output                                  o_user_write_eop            ,       // 1
    output                                  o_user_write_valid          ,       // 1

    input [7:0]                             i_user_read_data            ,
    input                                   i_user_read_sop             ,
    input                                   i_user_read_eop             ,
    input                                   i_user_read_valid           
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

// 对交给CTRL模块的输出需要根据不同的操作决定 采用状态机
reg [7:0]                                                       r_st_current                                            ;
reg [7:0]                                                       r_st_next                                               ;

localparam                                                      P_ST_GEN_IDLE   =   0                                   ,
                                                                P_ST_GEN_CLEAR  =   1                                   ,
                                                                P_ST_GEN_WRITE  =   2                                   ,
                                                                P_ST_GEN_READ   =   3                                   ;

// 第一段
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_GEN_IDLE;
    else
        r_st_current <= r_st_next;
end 

// 第二段 这里出现了一个重大错误 就是从一个状态到另一个状态 不能通过i_user_op_ready判断 而是判断上升沿 否则 一握手 ready拉低  立马就到下一个状态了 或者 没握手成功也会转
always@(*)
begin
    case(r_st_current)
        P_ST_GEN_IDLE   :   r_st_next   =   P_ST_GEN_CLEAR      ;
        P_ST_GEN_CLEAR  :   r_st_next   =   w_user_ready_pos     ?       P_ST_GEN_WRITE      :       P_ST_GEN_CLEAR      ;
        P_ST_GEN_WRITE  :   r_st_next   =   w_user_ready_pos     ?       P_ST_GEN_READ       :       P_ST_GEN_WRITE      ;
        P_ST_GEN_READ   :   r_st_next   =   w_user_ready_pos     ?       P_ST_GEN_IDLE       :       P_ST_GEN_READ       ;
        default         :   r_st_next   =   P_ST_GEN_IDLE       ;
    endcase
end

// 写一个监测上升沿
reg				ri_user_op_ready			;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_user_op_ready <= 'd1;
    else
        ri_user_op_ready <= i_user_op_ready;
end

wire				w_user_ready_pos			;
assign				w_user_ready_pos = !ri_user_op_ready & i_user_op_ready;

// 第三段
// o_user_op_type 
// o_user_op_addr 
// o_user_op_num  
// o_user_op_valid
// 把输出和寄存器连接
reg [1:0]                                                       ro_user_op_type                                         ;
reg [23:0]                                                      ro_user_op_addr                                         ;
reg [8:0]                                                       ro_user_op_num                                          ;
reg                                                             ro_user_op_valid                                        ;

assign                                                          o_user_op_type  = ro_user_op_type                       ;
assign                                                          o_user_op_addr  = ro_user_op_addr                       ;
assign                                                          o_user_op_num   = ro_user_op_num                        ;
assign                                                          o_user_op_valid = ro_user_op_valid                      ;

// 握手
wire                                                            w_user_active                                           ;
assign                                                          w_user_active = o_user_op_valid & i_user_op_ready       ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ro_user_op_type  <= 'd0;
        ro_user_op_addr  <= 'd0;
        ro_user_op_num   <= 'd0;
    end else if (r_st_next == P_ST_GEN_CLEAR) begin
        ro_user_op_type  <= 'd0;
        ro_user_op_addr  <= 'd0;
        ro_user_op_num   <= 'd0;
    end else if (r_st_next == P_ST_GEN_WRITE) begin
        ro_user_op_type  <= 'd1;
        ro_user_op_addr  <= 'd0;
        ro_user_op_num   <= 'd2;
    end else if (r_st_next == P_ST_GEN_READ) begin
        ro_user_op_type  <= 'd2;
        ro_user_op_addr  <= 'd0;
        ro_user_op_num   <= 'd2;
    end else begin
        ro_user_op_type  <= ro_user_op_type ;
        ro_user_op_addr  <= ro_user_op_addr ;
        ro_user_op_num   <= ro_user_op_num  ;
    end
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_valid <= 'd0;
    else if (w_user_active)
        ro_user_op_valid <= 'd0;
    else if (r_st_current != P_ST_GEN_CLEAR && r_st_next == P_ST_GEN_CLEAR)
        ro_user_op_valid <= 'd1;
    else if (r_st_current != P_ST_GEN_WRITE && r_st_next == P_ST_GEN_WRITE)
        ro_user_op_valid <= 'd1;
    else if (r_st_current != P_ST_GEN_READ && r_st_next == P_ST_GEN_READ)
        ro_user_op_valid <= 'd1;
    else
        ro_user_op_valid <= ro_user_op_valid;
end

// 处理要写的数据
// o_user_write_data 
// o_user_write_sop  
// o_user_write_eop  
// o_user_write_valid
// 连接输出和寄存器
reg [7:0]                                                       ro_user_write_data                                      ;
reg                                                             ro_user_write_sop                                       ;
reg                                                             ro_user_write_eop                                       ;
reg                                                             ro_user_write_valid                                     ;

assign                                                          o_user_write_data  = ro_user_write_data                 ;
assign                                                          o_user_write_sop   = ro_user_write_sop                  ;
assign                                                          o_user_write_eop   = ro_user_write_eop                  ;
assign                                                          o_user_write_valid = ro_user_write_valid                ;

// 其实什么时候写进数据都可以 但是为了更好分析 我写数据在握手后给出
// 写一个寄存器为了后面计数
reg                                                             r_for_cnt_sig                                           ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_data <= 'd0;
    else if (r_w_cnt >0 && r_w_cnt < ro_user_op_num - 1)
        ro_user_write_data <= ro_user_write_data + 1;
    else if (w_user_active && r_st_current == P_ST_GEN_WRITE)
        ro_user_write_data <= ro_user_write_data + 1;
    else if (r_for_cnt_sig)
        ro_user_write_data <= ro_user_write_data + 1;
    else
        ro_user_write_data <= ro_user_write_data;
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_for_cnt_sig <= 'd0;
    else if (w_user_active && r_st_current == P_ST_GEN_WRITE)
        r_for_cnt_sig <= 'd1;
    else
        r_for_cnt_sig <= 'd0;
end

// 计数写了几个
reg [15:0]                                                      r_w_cnt                                                 ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_w_cnt <= 'd0;
    else if (r_w_cnt == ro_user_op_num - 1)
        r_w_cnt <= 'd0;
    else if (r_for_cnt_sig || r_w_cnt > 0)
        r_w_cnt <= r_w_cnt + 1;
    else
        r_w_cnt <= r_w_cnt;
end

// valid
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_valid <= 'd0;
    else if (r_w_cnt == ro_user_op_num - 1)
        ro_user_write_valid <= 'd0;
    else if (w_user_active && r_st_current == P_ST_GEN_WRITE)
        ro_user_write_valid <= 'd1;
    else
        ro_user_write_valid <= ro_user_write_valid;
end

// sop eop
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_sop <= 'd0;
    else if (r_for_cnt_sig)
        ro_user_write_sop <= 'd0;
    else if (w_user_active && r_st_current == P_ST_GEN_WRITE)
        ro_user_write_sop <= 'd1;
    else
        ro_user_write_sop <= 'd0;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_eop <= 'd0;
    else if (r_w_cnt ==  ro_user_op_num - 1)  
        ro_user_write_eop <= 'd0;
    else if (r_w_cnt ==  ro_user_op_num - 2)
        ro_user_write_eop <= 'd1;
    else
        ro_user_write_eop <= 'd0;
end

endmodule
