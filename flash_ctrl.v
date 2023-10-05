// 鑱斿悎鐢ㄦ埛鍜宻pi

module flash_ctrl (
    input                               i_clk                       ,
    input                               i_rst                       ,

    /*---------- 鐢ㄦ埛绔彛 ----------*/
    input [1:0]                         i_user_op_type              ,       // 1         // 0娓呯┖ 1鍐? 2璇? 
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

    /*---------- SPI绔彛 ----------*/
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

// 杈撳嚭缁橲PI鐨勫厛鐢ㄥ瘎瀛樺櫒杩炴帴 缁橲PI鐨勮鍐欑殑鏁版嵁鍏堜笉鍔? 鍥犱负瑕佽蛋fifo 缁欑敤鎴风殑涔熷厛涓嶅姩
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

// 鍜岀敤鎴锋彙鎵?   
wire                                                        w_user_active                                       ;
assign                                                      w_user_active = o_user_op_ready & i_user_op_valid   ;

// 鎶妎_user_op_ready杩炴帴鍒板瘎瀛樺櫒
reg                                                         ro_user_op_ready                                    ;

reg [1:0]                                                   ri_user_op_type                                     ;
reg [23:0]                                                  ri_user_op_addr                                     ;
reg [8:0]                                                   ri_user_op_num                                      ;

localparam                                                  P_USER_OP_TYPE_CLEAR    =   0                       ,
                                                            P_USER_OP_TYPE_WRITE    =   1                       ,
                                                            P_USER_OP_TYPE_READ     =   2                       ;       // 杩欐槸鐢ㄦ埛鍙戣繃鏉ョ殑type

localparam                                                  P_SPI_OP_TYPE_INS       =   0                       ,
                                                            P_SPI_OP_TYPE_WRITE     =   1                       ,
                                                            P_SPI_OP_TYPE_READ      =   2                       ;       // 杩欐槸鍙戠粰SPI鐨則ypeP

// 浣跨敤鐘舵?佹満 鍥犱负鍐欐暟鎹? 鎴栬?? 璇绘暟鎹? 鏄繛缁緢澶氭spi鎻℃墜
reg [7:0]                                                   r_st_current                                        ;
reg [7:0]                                                   r_st_next                                           ;

// 鍜孲PI鎻℃墜
wire                                                        w_spi_active                                        ;
assign                                                      w_spi_active = o_spi_op_valid & i_spi_op_ready      ;

localparam                                                  P_ST_IDLE       =   0                               ,       // 榛樿鐘舵?? 娌℃湁鍜岀敤鎴锋彙鎵? 灏变笉鍜宻pi鎻℃墜
                                                            P_ST_RUN        =   1                               ,       // 鍜岀敤鎴锋彙鎵嬪悗 鍒ゆ柇瑕佽繘琛屼粈涔堟搷浣?
                                                            P_ST_W_EN       =   2                               ,       // 鍐欎娇鑳? 浠讳綍鍐欐搷浣滃墠瑕佸厛浣胯兘
                                                            P_ST_W_INS      =   3                               ,       // 鍐欐寚浠? 鍐欐暟鎹墠 鍏堟妸鎸囦护鍦板潃鍟ョ殑鍐欒繃鍘?
                                                            P_ST_W_DATA     =   4                               ,       // 鍐欐暟鎹? 鐢ㄦ埛缁欑殑鏁版嵁鍦╢ifo閲? 鏈塻pi缁欑殑req鍐嶅彂鍑虹粰spi
                                                            P_ST_R_INS      =   5                               ,       // 璇绘寚浠? 濡傛灉瑕佽 鎶婅鎸囦护浼犵粰spi
                                                            P_ST_R_DATA     =   6                               ,       // 璇绘暟鎹? 璇诲埌鐨勬暟鎹紶鍒癴ifo 鏁村悎鍦ㄤ竴璧峰啀浜ょ粰鐢ㄦ埛
                                                            P_ST_CLEAR      =   7                               ,       // 娓呯┖ 鎶婂啓杩沠lash鐨勫叏鎷夊洖1 杩欐牱涓嬫鎵嶈兘鍐?
                                                            P_ST_BUSY       =   8                               ,       // 璇诲瘎瀛樺櫒 鎶婃寚浠ゅ彂缁檚pi 绛夊緟spi杩斿洖鐨勫瘎瀛樺櫒鍊?
                                                            P_ST_BUSY_CHECK =   9                               ,       // 寰楀埌瀵勫瓨鍣ㄥ?煎悗 鐪嬩竴涓嬫渶浣庝綅 鍒ゆ柇蹇欏惁
                                                            P_ST_BUSY_WAIT  =   10                              ;       // 濡傛灉蹇? 绛夊緟

reg [15:0]                                                  r_st_cnt                                            ;

reg [7:0]                                                   ri_user_write_data                                  ;
reg                                                         ri_user_write_valid                                 ;

reg                                                         r_fifo_read_wren                                    ;
reg [7:0]                                                   ri_spi_read_data                                    ;
reg                                                         r_fifo_read_rden_pos_1d                             ;

// 浠?涔堟椂鍊欒緭鍑鸿鐨勬暟鎹憿锛? 銆娿?娿?婁篃瑕佽?冭檻鍚庨潰璇诲瘎瀛樺櫒璇诲繖鏃? 涓嶈兘杈撳嚭銆嬨?嬨??
reg                                                         r_fifo_read_rden                                    ;
// 鍙﹀ 璇讳娇鑳藉簲璇ュ緢闀挎椂闂翠负1 鍥犱负瑕佽鐨勬暟鎹 鎵?浠ヤ娇鐢╡mpty empty鍦╢ifo鍓╀竴涓暟鎹椂鎷夐珮 鍗充娇rden鍦ㄦ渶鍚庝竴涓暟鎹箣鍚庢媺浣? 閫氳繃鎺у埗濂絭alid涔熷彲浠ヤ娇鐢ㄦ埛鎷垮埌姝ｇ‘鐨勬暟
wire                                                        w_fifo_read_empty                                   ;

// 瑕佹娴媏mpty涓婂崌娌?
reg                                                         r_fifo_read_empty_1d                                ;
wire                                                        w_read_empty_pos                                    ;
assign                                                      w_read_empty_pos = !r_fifo_read_empty_1d & w_fifo_read_empty;

wire [7:0]                                                  w_fifo_read_data                                    ;

reg  [7:0]                                                  ro_user_read_data                                   ;
assign                                                      o_user_read_data = ro_user_read_data                ;

reg                                                         r_fifo_read_rden_1d                                 ;
wire                                                        w_fifo_read_rden_pos                                ;
assign                                                      w_fifo_read_rden_pos = r_fifo_read_rden & !r_fifo_read_rden_1d ;

reg                                                         ro_user_read_sop                                    ;
reg                                                         ro_user_read_eop                                    ;
reg                                                         ro_user_read_valid                                  ;
assign                                                      o_user_op_ready = ro_user_op_ready                  ;

assign				o_user_read_sop = ro_user_read_sop	;
assign				o_user_read_eop = ro_user_read_eop 	;                                  
assign				o_user_read_valid = ro_user_read_valid	;

always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_op_ready <= 'd1;
    else if (w_user_active)
                ro_user_op_ready <= 'd0;
    else if (r_st_current == P_ST_IDLE)
        ro_user_op_ready <= 'd1;                // 浠?涔堟椂鍊欐媺鍥瀝eady鏆傛椂鏀句竴涓?
    
    else
        ro_user_op_ready <= ro_user_op_ready;
end

// 鎶婅緭鍏ラ攣瀛? 杈撳叆鐨勫啓鐨勬暟鎹竴鏃忓厛涓嶅鐞? 鍥犱负鍜孎IFO鏈夊叧绯?


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



// 绗竴娈?
always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_st_current <= P_ST_IDLE;
    else
        r_st_current <= r_st_next;
end

// 绗簩娈?
always@(*)
begin
    case(r_st_current)
        P_ST_IDLE           :   r_st_next   =   w_user_active                           ?       P_ST_RUN            :       P_ST_IDLE           ;   // 鎻℃墜浜嗗氨寮?濮?
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

// 涓轰簡纭畾鍐欍?佽鏁版嵁鐘舵?佷粈涔堟椂鍊欑粨鏉? 闇?瑕佷娇鐢⊿PI鍙戣繃鏉ョ殑ready 涓轰簡鍙涓婂崌娌?(X) <<<杩欐槸閿欒鐨?>>> 鍏蜂綋鍙互鐢诲浘鏉ユ槑浜? 杩欓噷搴旇灏辫ready 鑰屼笉鏄笂鍗囨部
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

// 鍒拌揪绛夊緟鐘舵?佹椂 闇?瑕佽鏁板櫒鍒ゆ柇绛夊緟鏃堕暱


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

// 绗笁娈? 杩欎釜鐘舵?佹満涓昏鏄负浜嗗彂缁橲PI涓滆タ鐨? 鎵?浠ョ涓夋鐨勮緭鍑轰富瑕佸拰SPI鏈夊叧绯?
always@(posedge i_clk or posedge i_rst)     // op_data鍙兘杈撳叆32浣? 浣嗘槸閫氳繃杈撳叆鐨刼p_len纭畾鍝簺鏄渶瑕佺殑 鍙﹀ 鍙緭鍏?8浣嶇殑 鍚庨潰鍏?0
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
        ro_spi_op_len   <= 32;      // 鎸囦护鍜屽湴鍧?
        ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_R_INS) begin
        ro_spi_op_data  <= {8'h03,ri_user_op_addr};
        ro_spi_op_type  <= P_SPI_OP_TYPE_READ;
        ro_spi_op_len   <= 32;      // 鎸囦护鍜屽湴鍧?
        ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
        ro_spi_op_valid <= 'd1;
    end else if (r_st_current == P_ST_CLEAR) begin
        ro_spi_op_data  <= {8'h20,ri_user_op_addr};
        ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
        ro_spi_op_len   <= 32;      // 鎸囦护鍜屽湴鍧?
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

// 鐜板湪 鎴戜滑鍙互鍥炶繃澶存潵鐪嬩竴涓媢ser_ready鐨勬媺楂樻潯浠朵簡 涔熷氨鏄姸鎬佹満鍥炲埌idle 
// 涓嶇敤current next涓嶇浉鍚屼綔涓烘媺楂樻潯浠跺彲浠ヨ涓烘槸 鍜? spi鐨勬媺楂樻潯浠朵竴鏍? 鎵撲竴鎷嶅啀鎷夐珮 绠楁槸涓?涓繚闄╁惂

// 鐒跺悗灏辨槸澶勭悊澶嶆潅鐨? 濡傛灉瑕佸啓 瑕佽 鎬庝箞鍔?

// 棣栧厛鐪嬪啓
// i_user_write_data 
// i_user_write_sop  
// i_user_write_eop  
// i_user_write_valid

// 鐢ㄦ埛杈撳叆杩涙潵鐨勫啓鐨勬暟鎹? 涓嶈兘鐩存帴浜ょ粰SPI 瑕佺瓑SPI鐨剅eq
// 鐢‵IFO 浣嗘槸FIFO杈撳叆瑕佹墦鎷? 鍥犱负杈撳叆鎵撴媿浜? 瑕佺粰valid涔熸墦鎷?


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
    .din      (ri_user_write_data   ),               // 娉ㄦ剰 杈撳叆鍒癋IFO鐨勬暟鎹鎵撲竴鎷?
    .wr_en    (ri_user_write_valid  ),  
    .rd_en    (i_spi_write_req      ),                                 // 璇讳娇鑳斤紙SPI浠?涔堟椂鍊欏彲浠ュ彇鏁版嵁锛?  绛旓細req
    .dout     (o_user_write_data    ),               
    .full     (),                           // 鐢变簬鍐欐暟鎹拰鍐欏灏戞槸鐢ㄦ埛鍐冲畾锟??? 鐒跺悗鍦ㄤ竴锟???濮嬪氨浼犵粰spi鏃堕挓锟??? 锟???浠ヤ笉浼氬瓨鍦╯pi瑕佹暟鎹椂娌℃湁鏁版嵁 鎴栵拷?锟紽IFO婊′簡 涓嶈兘鍐欑殑鎯呭喌
    .empty    ()  
);

// 鐒跺悗鐪嬭
// o_user_read_data 
// o_user_read_sop  
// o_user_read_eop  
// o_user_read_valid

// i_spi_read_data 
// i_spi_read_valid

// SPI璇诲埌鐨勬暟鎹? 骞朵笉杩炵画 涓轰簡杩炵画 浣跨敤FIFO

FLASH_CTRL_FIFO_DATA FLASH_CTRL_FIFO_DATA_READ_U0 (
    .clk      (i_clk                ), 
    .srst     (i_rst                ), 
    .din      (ri_spi_read_data     ),           // 鍚屾牱瑕佹墦锟???
    .wr_en    (r_fifo_read_wren     ),         // 锟???涔堟椂鍊欏彲浠ヨ锛焩alid 浣嗘槸瑕佹敞锟??? 鏈変竴涓鏄锟??? 鏄笉锟???瑕佸線杩欓噷闈㈠啓锟??? 鍥犱负浠栧氨锟???涓暟锟??? 鍦╞usy_check灏辫锟??? 濡傛灉涔熷啓杩欓噷 鍚庨潰璇诲氨璇诲瘎瀛樺櫒锟???
    .rd_en    (r_fifo_read_rden     ), 
    .dout     (w_fifo_read_data     ), 
    .full     (),    
    .empty    (w_fifo_read_empty    )                            // 杩欓噷鍊熷姪锟???涓媏mpty 涓轰簡纭畾锟???涔堟椂鍊欑粨鏉熻(鎰熻杩欓噷涓嶇敤empty 鐢ㄨ緭鍏ョ粰鐨刵um涔熷彲浠ョ‘瀹氫粈涔堟椂鍊欎笉锟???)
);

// 鍐欎娇鑳借娉ㄦ剰 鍙湁璇绘暟鎹椂鎵嶈兘鍐? 鍚庨潰璇诲瘎瀛樺櫒璇诲繖涓嶅彲浠ュ啓


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_wren <= 'd0;
    else if (r_st_current == P_ST_R_INS)
        r_fifo_read_wren <= i_spi_read_valid;
    else
        r_fifo_read_wren <= 'd0;
end

// 杈撳叆鏁版嵁鎵撴媿 姝ｅソ鍜屼笂闈㈢殑valid鍚屾浜?


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ri_spi_read_data <= 'd0;
    else
        ri_spi_read_data <= i_spi_read_data;
end



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

// 澶氭柟鑰冭檻涓? 濡傛灉璇诲埌鐨勬暟鎹洿鎺ヨ繛缁欑敤鎴? 閭ｄ箞eop valid闅句互纭畾 鎵?浠ヨ繖閲屽厛鎶奻ifo璇诲埌鐨勬殏鐣? 鎵撴媿鍚庡啀缁欑敤鎴?


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        ro_user_read_data <= 'd0;
    else
        ro_user_read_data <= w_fifo_read_data;
end

// 杩欏洖鍐嶆牴鎹甧mpty鍜岃浣胯兘纭畾sop eop valid
// 瀵绘壘璇讳娇鑳戒俊鍙风殑涓婂崌娌?


always@(posedge i_clk or posedge i_rst)
begin
    if (i_rst)
        r_fifo_read_rden_1d <= 'd0;
    else
        r_fifo_read_rden_1d <= r_fifo_read_rden;
end

// 瀵绘壘empty鐨勪笂鍗囨部 涔嬪墠鏈変簡 w_read_empty_pos

// 瀵勫瓨鍣ㄨ繛鎺op eop valid


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
// 状�?�数量更�? 更容易理�?

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
//         ro_spi_op_len   <= 32;      // 指令和地�?
//         ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_R_DATA) begin
//         ro_spi_op_data  <= {8'h03,ri_user_op_addr};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_READ;
//         ro_spi_op_len   <= 32;      // 指令和地�?
//         ro_spi_clk_len  <= 32 + 8 * ri_user_op_num;
//         ro_spi_op_valid <= 'd1;
//     end else if (r_st_current == P_ST_CLEAR) begin
//         ro_spi_op_data  <= {8'h20,ri_user_op_addr};
//         ro_spi_op_type  <= P_SPI_OP_TYPE_INS;
//         ro_spi_op_len   <= 32;      // 指令和地�?
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

