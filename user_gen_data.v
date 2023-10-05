// 鏁版嵁浜х敓妯″潡

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

// 瀵逛氦缁機TRL妯″潡鐨勮緭鍑洪渶瑕佹牴鎹笉鍚岀殑鎿嶄綔鍐冲畾 閲囩敤鐘舵?佹満
reg [7:0]                                                       r_st_current                                            ;
reg [7:0]                                                       r_st_next                                               ;

localparam                                                      P_ST_GEN_IDLE   =   0                                   ,
                                                                P_ST_GEN_CLEAR  =   1                                   ,
                                                                P_ST_GEN_WRITE  =   2                                   ,
                                                                P_ST_GEN_READ   =   3                                   ;
reg				ri_user_op_ready			;
wire				w_user_ready_pos			;
assign				w_user_ready_pos = !ri_user_op_ready & i_user_op_ready;
// 绗竴娈?
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_GEN_IDLE;
    else
        r_st_current <= r_st_next;
end 

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_user_op_ready <= 'd1;
    else
        ri_user_op_ready <= i_user_op_ready;
end
// 绗簩娈?
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

// 绗笁娈?
// o_user_op_type 
// o_user_op_addr 
// o_user_op_num  
// o_user_op_valid
// 鎶婅緭鍑哄拰瀵勫瓨鍣ㄨ繛鎺?
reg [1:0]                                                       ro_user_op_type                                         ;
reg [23:0]                                                      ro_user_op_addr                                         ;
reg [8:0]                                                       ro_user_op_num                                          ;
reg                                                             ro_user_op_valid                                        ;

assign                                                          o_user_op_type  = ro_user_op_type                       ;
assign                                                          o_user_op_addr  = ro_user_op_addr                       ;
assign                                                          o_user_op_num   = ro_user_op_num                        ;
assign                                                          o_user_op_valid = ro_user_op_valid                      ;

// 鎻℃墜
wire                                                            w_user_active                                           ;
assign                                                          w_user_active = o_user_op_valid & i_user_op_ready       ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ro_user_op_type  <= 'd0;
        ro_user_op_addr  <= 'd2;
        ro_user_op_num   <= 'd0;
    end else if (r_st_next == P_ST_GEN_CLEAR) begin
        ro_user_op_type  <= 'd0;
        ro_user_op_addr  <= 'd2;
        ro_user_op_num   <= 'd0;
    end else if (r_st_next == P_ST_GEN_WRITE) begin
        ro_user_op_type  <= 'd1;
        ro_user_op_addr  <= 'd2;
        ro_user_op_num   <= 'd4;
    end else if (r_st_next == P_ST_GEN_READ) begin
        ro_user_op_type  <= 'd2;
        ro_user_op_addr  <= 'd2;
        ro_user_op_num   <= 'd4;
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

// 澶勭悊瑕佸啓鐨勬暟鎹?
// o_user_write_data 
// o_user_write_sop  
// o_user_write_eop  
// o_user_write_valid
// 杩炴帴杈撳嚭鍜屽瘎瀛樺櫒
reg [7:0]                                                       ro_user_write_data                                      ;
reg                                                             ro_user_write_sop                                       ;
reg                                                             ro_user_write_eop                                       ;
reg                                                             ro_user_write_valid                                     ;

assign                                                          o_user_write_data  = ro_user_write_data                 ;
assign                                                          o_user_write_sop   = ro_user_write_sop                  ;
assign                                                          o_user_write_eop   = ro_user_write_eop                  ;
assign                                                          o_user_write_valid = ro_user_write_valid                ;

// 鍏跺疄浠?涔堟椂鍊欏啓杩涙暟鎹兘鍙互 浣嗘槸涓轰簡鏇村ソ鍒嗘瀽 鎴戝啓鏁版嵁鍦ㄦ彙鎵嬪悗缁欏嚭
// 鍐欎竴涓瘎瀛樺櫒涓轰簡鍚庨潰璁℃暟
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

// 璁℃暟鍐欎簡鍑犱釜
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
