module spi_drive#(
    parameter                           P_DATA_WIDTH        = 8 ,
                                        P_OP_LEN            = 32,
                                        P_READ_DATA_WIDTH   = 8 , 
                                        P_CPOL              = 0 ,
                                        P_CPHL              = 0 
)(                  
    input                               i_clk               ,//绯荤粺鏃堕挓
    input                               i_rst               ,//澶嶄綅

    output                              o_spi_clk           ,//spi鐨刢lk
    output                              o_spi_cs            ,//spi鐨勭墖锟�?
    output                              o_spi_mosi          ,//spi鐨勪富鏈鸿緭锟�?
    input                               i_spi_miso          ,//spi鐨勪粠鏈鸿緭锟�?

    input   [P_OP_LEN - 1 :0]           i_user_op_data      ,//鎿嶄綔鏁版嵁锛堟寚锟�?8bit+鍦板潃24bit锟�?
    input   [1 :0]                      i_user_op_type      ,//鎿嶄綔绫诲瀷锛堣銆佸啓銆佹寚浠わ級
    input   [15:0]                      i_user_op_len       ,//鎿嶄綔鏁版嵁鐨勯暱锟�?32锟�?8
    input   [15:0]                      i_user_clk_len      ,//鏃堕挓鍛ㄦ湡
    input                               i_user_op_valid     ,//鐢ㄦ埛鐨勬湁鏁堜俊锟�?
    output                              o_user_op_ready     ,//鐢ㄦ埛鐨勫噯澶囦俊锟�?

    input   [P_DATA_WIDTH - 1 :0]       i_user_write_data   ,//鍐欐暟锟�?
    output                              o_user_write_req    ,//鍐欐暟鎹锟�?

    output  [P_READ_DATA_WIDTH - 1:0]   o_user_read_data    ,//璇绘暟锟�?
    output                              o_user_read_valid    //璇绘暟鎹湁锟�?

    
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

// 更新一下操作 因为mosi第一个数据x 所以打算让spi启动推迟一个周期

// 甯歌閿佸瓨杈撳嚭骞惰繛鎺�
reg                                                                         ro_spi_clk                                                          ;   
reg                                                                         ro_spi_cs                                                           ;   
reg                                                                         ro_spi_mosi                                                         ;   
reg                                                                         ro_user_op_ready                                                    ;   
reg                                                                         ro_user_write_req                                                   ;       
reg [P_READ_DATA_WIDTH - 1:0]                                               ro_user_read_data                                                   ;
reg                                                                         ro_user_read_valid                                                  ;

reg [P_OP_LEN - 1 :0]                                                       ri_user_op_data                                                     ;
reg [1 :0]                                                                  ri_user_op_type                                                     ;
reg [15:0]                                                                  ri_user_op_len                                                      ;
reg [15:0]                                                                  ri_user_clk_len                                                     ;

assign                                                                      o_spi_clk         = ro_spi_clk                                      ;
assign                                                                      o_spi_cs          = ro_spi_cs                                       ;
assign                                                                      o_spi_mosi        = ro_spi_mosi                                     ;
assign                                                                      o_user_op_ready   = ro_user_op_ready                                ;
assign                                                                      o_user_write_req  = ro_user_write_req                               ;
assign                                                                      o_user_read_data  = ro_user_read_data                               ;
assign                                                                      o_user_read_valid = ro_user_read_valid                              ;

// 鎻℃墜
wire                                                                        w_spi_active                                                        ;
assign                                                                      w_spi_active = i_user_op_valid & o_user_op_ready                    ;



// 鎻℃墜鍚� ready鎷変綆 cs鎷変綆 run鎷夐珮 鏁版嵁閿佸瓨
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        ri_user_op_type <= 'd0;
        ri_user_op_len  <= 'd0;
        ri_user_clk_len <= 'd0;
    end else if (w_spi_active) begin
        ri_user_op_type <= i_user_op_type;
        ri_user_op_len  <= i_user_op_len ;
        ri_user_clk_len <= i_user_clk_len;
    end else begin
        ri_user_op_type <= i_user_op_type;
        ri_user_op_len  <= i_user_op_len ;
        ri_user_clk_len <= i_user_clk_len;
    end
end


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_ready <= 'd1;
    else if (w_run_neg)
        ro_user_op_ready <= 'd1;
    else if (w_spi_active)      
        ro_user_op_ready <= 'd0;
    else
        ro_user_op_ready <= ro_user_op_ready;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_spi_cs <= 'd1;
    else if (w_run_neg)
        ro_spi_cs <= 'd1;
    else if (w_spi_active)      
        ro_spi_cs <= 'd0;
    else
        ro_spi_cs <= ro_spi_cs;
end

reg                                                                         r_run                                                               ;

reg                                                                         ro_user_op_ready_1d                                                 ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_ready_1d <= 'd1;
    else 
        ro_user_op_ready_1d <= ro_user_op_ready;
end

wire                                                                        w_user_op_ready_neg                                                 ;
assign                                                                      w_user_op_ready_neg = !ro_user_op_ready & ro_user_op_ready_1d       ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_run <= 'd0;
    else if (r_cnt == ri_user_clk_len - 1 && r_spi_cnt)
        r_run <= 'd0;
    else if (w_user_op_ready_neg)                          // 这里做了这样的更改 把run启动条件改为ready下降沿 这样就慢了
        r_run <= 'd1;
    else
        r_run <= r_run;
end

// 浜х敓clk闇�瑕佷竴涓猚nt
reg                                                                         r_spi_cnt                                                           ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_spi_cnt <= 'd0;
    else if (r_run && r_spi_cnt == 1)
        r_spi_cnt <= 'd0;
    else if (r_run)  
        r_spi_cnt <= r_spi_cnt + 1;
    else
        r_spi_cnt <= r_spi_cnt;
end

// 浜岃�呬粈涔堟椂鍊欐媺楂橀渶瑕佷竴涓鏁板櫒
reg [15:0]                                                                  r_cnt                                                               ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_cnt <= 'd0;
    else if (r_run && r_cnt == ri_user_clk_len - 1 && r_spi_cnt)
        r_cnt <= 'd0;
    else if (r_run && r_spi_cnt)
        r_cnt <= r_cnt + 1;
    else
        r_cnt <= r_cnt;
end

// 姹俽un涓嬮檷娌�
reg                                                                         r_run_1d                                                            ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_run_1d <= 'd0;
    else
        r_run_1d <= r_run;
end

wire                                                                        w_run_neg                                                           ;
assign                                                                      w_run_neg = r_run_1d & !r_run                                       ;

// 为了ready打两拍后拉高
reg                                                                         r_run_neg_1d, r_run_neg_2d                                          ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst) begin
        r_run_neg_1d <= 'd0;
        r_run_neg_2d <= 'd0;
    end else begin
        r_run_neg_1d <= w_run_neg;
        r_run_neg_2d <= r_run_neg_1d;
    end
end

// 鎺у埗杈撳嚭鐨刢lk
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_spi_clk <= 'd0;
    else if (r_cnt == ri_user_clk_len - 1 && r_spi_cnt)
        ro_spi_clk <= 'd0;
    else if (r_run)
        ro_spi_clk <= ~ro_spi_clk;
    else
        ro_spi_clk <= ro_spi_clk;
end

// 涓轰簡鑾峰緱杈撳嚭 瀵硅緭鍏p_data鍋氱Щ浣嶅拰閿佸瓨
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_user_op_data <= 'd0;
    else if (w_spi_active)
        ri_user_op_data <= i_user_op_data;
    else if (w_user_op_ready_neg)
        ri_user_op_data <= ri_user_op_data << 1;   
    else if (r_run && r_spi_cnt && r_cnt < ri_user_op_len)
        ri_user_op_data <= ri_user_op_data << 1;
    else
        ri_user_op_data <= ri_user_op_data;
end

// 鑰冭檻澶嶆潅鐨勮緭鍑� 1 鍐� 2 璇� 
// 给握手打一拍
reg                                                                         r_spi_act_reg                                                       ;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_spi_act_reg <= 'd0;
    else 
        r_spi_act_reg <= w_spi_active;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_spi_mosi <= 'd0;
    else if (r_spi_act_reg)
        ro_spi_mosi <= ri_user_op_data[ri_user_op_len - 1];
    else if (r_run && r_spi_cnt && r_cnt < ri_user_op_len - 1)
        ro_spi_mosi <= ri_user_op_data[ri_user_op_len - 1];


    else if (ri_user_op_type == 1 && ro_user_write_req_1d && r_spi_cnt)
        ro_spi_mosi <= i_user_write_data[P_DATA_WIDTH - 1];
    else if (ri_user_op_type == 1 && r_run && r_spi_cnt && r_cnt >= ri_user_op_len-1)
        ro_spi_mosi <= ri_user_write_data[P_DATA_WIDTH - 1];
    else
        ro_spi_mosi <= ro_spi_mosi;
end

// req
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_req <= 'd0;
    else if (ri_user_op_type == 1 && r_cnt == ri_user_op_len - 2 && r_spi_cnt)
        ro_user_write_req <= 'd1;
    else if (ri_user_op_type == 1 && r_write_cnt == P_DATA_WIDTH - 2 && r_spi_cnt && r_cnt < ri_user_clk_len - 5)
        ro_user_write_req <= 'd1;
    else
        ro_user_write_req <= 'd0;
end

// 鍋氫竴涓啓鏁版嵁鏃剁殑璁℃暟鍣�
reg [15:0]                                                      r_write_cnt                                         ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)  
        r_write_cnt <= 'd0;
    else if (ri_user_op_type == 1 && r_cnt >= ri_user_op_len && r_write_cnt == P_DATA_WIDTH - 1 && r_spi_cnt)
        r_write_cnt <= 'd0;
    else if (ri_user_op_type == 1 && r_cnt >= ri_user_op_len && r_spi_cnt)  
        r_write_cnt <= r_write_cnt + 1;
    else
        r_write_cnt <= r_write_cnt;
end

// 閫氳繃req寰楀埌鍐欑殑鏁版嵁 瀵瑰緱鍒扮殑瀵勫瓨
// 棣栧厛鎵撲竴鎷峳eq
reg                                     ro_user_write_req_1d                            ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_req_1d <= 'd0;
    else
        ro_user_write_req_1d <= ro_user_write_req;
end

reg [P_DATA_WIDTH - 1 :0]               ri_user_write_data                              ;
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_user_write_data <= 'd0;
    else if (ro_user_write_req_1d)
        ri_user_write_data <= i_user_write_data << 1;
    else if (ri_user_op_type == 1 && r_cnt >= ri_user_op_len - 1 && r_spi_cnt)
        ri_user_write_data <= ri_user_write_data << 1;
    else
        ri_user_write_data <= ri_user_write_data;
end

// 澶勭悊璇荤殑鏁版嵁
always@(posedge ro_spi_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_data <= 'd0;
    else if (ri_user_op_type == 2 && r_cnt >= ri_user_op_len)  
        ro_user_read_data <= {ro_user_read_data[P_DATA_WIDTH-2 : 0], i_spi_miso};
    else
        ro_user_read_data <= ro_user_read_data;
end

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_valid <= 'd0;
    else if (ri_user_op_type == 2 && r_read_cnt == P_DATA_WIDTH - 1 && !r_spi_cnt)
        ro_user_read_valid <= 'd1;
    else
        ro_user_read_valid <= 'd0;
end

// 鍋氫竴涓璁℃暟鍣�
reg [15:0]                                      r_read_cnt                                  ;
always@(posedge ro_spi_clk or posedge i_rst)
begin
    if (i_rst)
        r_read_cnt <= 'd0;
    else if (ri_user_op_type == 2 && r_cnt >= ri_user_op_len && r_read_cnt == P_DATA_WIDTH - 1)
        r_read_cnt <= 'd0;
    else if (ri_user_op_type == 2 && r_cnt >= ri_user_op_len)
        r_read_cnt <= r_read_cnt + 1;
    else
        r_read_cnt <= r_read_cnt;
end

endmodule
