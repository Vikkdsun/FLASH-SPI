module spi_drive#(
    parameter                           P_DATA_WIDTH        = 8 ,
                                        P_OP_LEN            = 32,
                                        P_READ_DATA_WIDTH   = 8 , 
                                        P_CPOL              = 0 ,
                                        P_CPHL              = 0 
)(                  
    input                               i_clk               ,//缁崵绮洪弮鍫曟寭
    input                               i_rst               ,//婢跺秳缍?

    output                              o_spi_clk           ,//spi閻ㄥ垻lk
    output                              o_spi_cs            ,//spi閻ㄥ嫮澧栭敓锟??
    output                              o_spi_mosi          ,//spi閻ㄥ嫪瀵岄張楦跨翻閿燂拷?
    input                               i_spi_miso          ,//spi閻ㄥ嫪绮犻張楦跨翻閿燂拷?

    input   [P_OP_LEN - 1 :0]           i_user_op_data      ,//閹垮秳缍旈弫鐗堝祦閿涘牊瀵氶敓锟??8bit+閸︽澘娼?24bit閿燂拷?
    input   [1 :0]                      i_user_op_type      ,//閹垮秳缍旂猾璇茬?烽敍鍫ｎ嚢閵嗕礁鍟撻妴浣瑰瘹娴犮倧绱?
    input   [15:0]                      i_user_op_len       ,//閹垮秳缍旈弫鐗堝祦閻ㄥ嫰鏆遍敓锟??32閿燂拷?8
    input   [15:0]                      i_user_clk_len      ,//閺冨爼鎸撻崨銊︽埂
    input                               i_user_op_valid     ,//閻€劍鍩涢惃鍕箒閺佸牅淇婇敓锟??
    output                              o_user_op_ready     ,//閻€劍鍩涢惃鍕櫙婢跺洣淇婇敓锟??

    input   [P_DATA_WIDTH - 1 :0]       i_user_write_data   ,//閸愭瑦鏆熼敓锟??
    output                              o_user_write_req    ,//閸愭瑦鏆熼幑顔款嚞閿燂拷?

    output  [P_READ_DATA_WIDTH - 1:0]   o_user_read_data    ,//鐠囩粯鏆熼敓锟??
    output                              o_user_read_valid    //鐠囩粯鏆熼幑顔芥箒閿燂拷?
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


// 鐢瓕顫夐柨浣哥摠鏉堟挸鍤獮鎯扮箾閹猴拷
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

// 閹烩剝澧?
wire                                                                        w_spi_active                                                        ;
assign                                                                      w_spi_active = i_user_op_valid & o_user_op_ready                    ;
reg                                                                         r_run                                                               ;
reg                                                                         r_spi_cnt                                                           ;
reg [15:0]                                                                  r_cnt                                                               ;
reg                                                                         r_run_1d                                                            ;

wire                                                                        w_run_neg                                                           ;
assign                                                                      w_run_neg = r_run_1d & !r_run                                       ;

reg [15:0]                                                      r_write_cnt                                         ;

reg                                     ro_user_write_req_1d                            ;
reg [P_DATA_WIDTH - 1 :0]               ri_user_write_data                              ;
reg [15:0]                                      r_read_cnt                                  ;

reg                                                                         r_spi_act_reg                                                       ;

reg                                                                         ro_user_op_ready_1d                                                 ;

wire                                                                        w_user_op_ready_neg                                                 ;
assign                                                                      w_user_op_ready_neg = !ro_user_op_ready & ro_user_op_ready_1d       ;
reg                                                                         r_run_neg_1d, r_run_neg_2d                                          ;
// 閹烩剝澧滈崥锟? ready閹峰缍? cs閹峰缍? run閹峰鐝? 閺佺増宓侀柨浣哥摠
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
        ri_user_op_type <= ri_user_op_type;
        ri_user_op_len  <= ri_user_op_len ;
        ri_user_clk_len <= ri_user_clk_len;
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

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_ready_1d <= 'd1;
    else 
        ro_user_op_ready_1d <= ro_user_op_ready;
end


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


// 娴溠呮晸clk闂囷拷鐟曚椒绔存稉鐚歯t


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

// 娴滃矁锟藉懍绮堟稊鍫熸閸婃瑦濯烘姗?娓剁憰浣风娑擃亣顓搁弫鏉挎珤


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

// 濮逛拷un娑撳妾峰▽锟?


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_run_1d <= 'd0;
    else
        r_run_1d <= r_run;
end

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


// 閹貉冨煑鏉堟挸鍤惃鍒k
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

// 娑撹桨绨￠懢宄扮繁鏉堟挸鍤? 鐎电绶崗顧祊_data閸嬫氨些娴ｅ秴鎷伴柨浣哥摠
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

// 閼板啳妾绘径宥嗘絽閻ㄥ嫯绶崙锟? 1 閸愶拷 2 鐠囷拷 
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

// 閸嬫矮绔存稉顏勫晸閺佺増宓侀弮鍓佹畱鐠佲剝鏆熼崳锟?

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

// 闁俺绻價eq瀵版鍩岄崘娆戞畱閺佺増宓? 鐎电懓绶遍崚鎵畱鐎靛嫬鐡?
// 妫ｆ牕鍘涢幍鎾茬閹峰吵eq

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_write_req_1d <= 'd0;
    else
        ro_user_write_req_1d <= ro_user_write_req;
end


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

// 婢跺嫮鎮婄拠鑽ゆ畱閺佺増宓?
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

// 閸嬫矮绔存稉顏囶嚢鐠佲剝鏆熼崳锟?

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
