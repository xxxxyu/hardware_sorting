`define PERIOD 10 
module sorter_tb2;
    // input wire [4095:0] din,        // 128*32 bit, divided into 8 ways
    reg clk;                 // system clk
    reg ena;                 // enable sorting system
    reg rst;                 // reset when rst == 1
    
    // output reg [4095:0] dout,       // sorted numbers
    wire [31:0] dout;
    wire [7:0] out_cnt;      // count output
    wire finished;            // sorting finished

    
    // module SortingNetwork (
    // input wire [511:0] data_in,     // 16*32bit, is splitted afterward
    // input wire clk,                 // posedge triggered
    // input wire ena,                 // enable sorting
    // input wire rst,                 // reset when rst == 1
    // output reg [511:0] data_out,    // 16*32bit, is splitted afterward
    // output wire valid               // data_out is valid after 12 clock cycles enabled 
    // );

    // split din into 8 ways
    reg [4095:0] din;
    wire [511:0] din1, din2, din3, din4, din5, din6, din7, din8; 
    assign {din1, din2, din3, din4, din5, din6, din7, din8} = din;

    wire s_rst;
    reg s_ena;
    // reg [31:0] data_in [15:0];
    reg [511:0] s_din;

    // assign s_din = {data_in[0], data_in[1], data_in[2], data_in[3], data_in[4], data_in[5], 
    //                 data_in[6], data_in[7], data_in[8], data_in[9], data_in[10], data_in[11],
    //                 data_in[12], data_in[13], data_in[14], data_in[15]};

    wire [511:0] s_dout;
    wire s_valid;

    SortingNetwork sorting_network(.data_in(s_din), .clk(clk), .ena(s_ena), 
                                    .rst(s_rst), .data_out(s_dout), .valid(s_valid));

    
    // module InputModule (
    // input wire [511:0] din,     // sorting network output
    // input wire clk, 
    // input wire rst, 
    // input wire valid,           // sorting network output valid
    // input wire full,            // merge sorter tree input buffer is full
    // output wire [31:0] im_dout,    // this module's data output
    // output wire ib_enq, 
    // output wire req             // data request
    // );

    reg [7:0] im_ena;
    wire im_rst;
    wire [7:0] ib_full;
    wire [31:0] im_dout [0:7];
    wire [7:0] ib_enq;
    wire [7:0] im_req;


    InputModule input_module_0(s_dout, clk, im_rst, s_valid && im_ena[0], ib_full[0], im_dout[0], ib_enq[0], im_req[0]);
    InputModule input_module_1(s_dout, clk, im_rst, s_valid && im_ena[1], ib_full[1], im_dout[1], ib_enq[1], im_req[1]);
    InputModule input_module_2(s_dout, clk, im_rst, s_valid && im_ena[2], ib_full[2], im_dout[2], ib_enq[2], im_req[2]);
    InputModule input_module_3(s_dout, clk, im_rst, s_valid && im_ena[3], ib_full[3], im_dout[3], ib_enq[3], im_req[3]);
    InputModule input_module_4(s_dout, clk, im_rst, s_valid && im_ena[4], ib_full[4], im_dout[4], ib_enq[4], im_req[4]);
    InputModule input_module_5(s_dout, clk, im_rst, s_valid && im_ena[5], ib_full[5], im_dout[5], ib_enq[5], im_req[5]);
    InputModule input_module_6(s_dout, clk, im_rst, s_valid && im_ena[6], ib_full[6], im_dout[6], ib_enq[6], im_req[6]);
    InputModule input_module_7(s_dout, clk, im_rst, s_valid && im_ena[7], ib_full[7], im_dout[7], ib_enq[7], im_req[7]);

    // module MergeSorterTree (
    // input wire [255:0] din,     // 8*32bit
    // input wire enq [0:7],       // select which way to enqueue
    // input wire clk,             // posedge
    // input wire irst,            // input buffer reset
    // input wire frst,            // fifo reset
    // input wire deq,             // dequeue this tree
    // output wire [31:0] dout,
    // output wire full [0:7],     // this tree is full
    // output wire empty           // this tree (f01 node) is empty
    // );

    wire irst, frst;
    reg t_deq;
    wire [31:0] t_dout;
    wire t_empty;
    wire [255:0] t_din;

    assign t_din = {im_dout[0], im_dout[1], im_dout[2], im_dout[3], im_dout[4], im_dout[5], im_dout[6], im_dout[7]};

    MergeSorterTree merge_sorter_tree(.din(t_din), .enq(ib_enq), .clk(clk), .irst(irst), .frst(frst),
                    .deq(t_deq), .dout(t_dout), .full(ib_full), .empty(t_empty), .out_cnt(out_cnt));


    assign dout = t_dout;

    assign s_rst = rst;
    assign im_rst = rst;
    assign irst = rst;
    assign frst = rst;

    reg [10:0] cnt;    // count clk cycles

    // control logic
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            s_ena <= 0;
            im_ena <= 0;
            s_din <= 0;
            t_deq <= 0;
            cnt <= 0;
            // cnt_dout <= 0;
            // t_dout_prev <= 0;
            // dout <= 0;
            // test input
            din <= 4096'b0010011100011000111100111011011010101001011011011110001111111100011111111011100000111011111111000000111011000011011000101110010001001101001110011100100101010100010100101000110011110100011100011001110000100101110101110001101101001010100100011011010001101001001100011001110011000101001111010001101101011000110000101011011001000001000000001101000111111111100110111111000100111001101110110011101010110111111111000011101111100010001010101010110011100110010011010111000100011010101110100010111110011100101010011111110001100111100101101100111011000100010110101111001111111001101011000010111100000010010010010010100111111011000010101010001101100100000010100001100110010011011011101110010100101111000011000000101101100110100111010001000100110110010010010111011010011000000011111001001110110101001100100101101010110001001000000111111110111001110000100001100110111001000010110010010111001100000001000001000101110111000011010011101110110100010101001001100111111100101110001110110101111000011001110001001111100010010111010000011111111101110100000001010000000010011110110000000101001100111000011011000101111100010010001010010010110111000010001011101000011111001010110101011100101110100110001001001100111010100100101001110110100100001001101100101011110001101101110000111100000100101101010110010110001111010101001110110110100110110101001100000000010010101001011011001111011101100110110001010101011000101010001110110001100000110011010110111000110001001001101000100000110010000111001101011001001101010001001100011110101011110100110101100001111001101011000011101011100011011000010000111001110010010010010111010000110010001111011010011110000101110110110001000000010000111101000101100101010101100111101010000011011010000000010011110010011100010001001010011101110011001000110111110100010001000111110001111110101111110001000101011111111010011100010110001110111110000100010101001100000101000000111010111101111100101100111001000101110011000001101101110111000101000111001110110111001110011111010011100000010111101111000101000101010110011111101100101010011000101111111101010010101000101011101001110110010000110100011011110010001111101010011000100111011011011111100110110011110101100110101001111101110111101000111010110110010001010111001000001111111011010100000011010101111011101011011111100011011010111010110010010110110000100000000101101001101100000001000000010010010010111101011000001111000001111110111010010110110110101000001111101100100110111010111000110100010000000101100010100011011001100100111011010001111001100101011101110101000111001001001010010101000011011010000011110010010000100001100000010011110000101010101000000111110110000100011000011010111010101010100000101100111010000111010000111000011001010010100100000001010110011001110011010110001101100100011010011001100111011111011101101100011100101011000110001100010000001001000111110000110111110110110000111101011000011101101010010101100101111001101111100110110110100001010110101010111001100101111011001101110001011000001111010111111111011011010101011010100000001101010100100001000001011101011000000000100011011110011000101100100010100000011111111101101111000010000010010011110010101001010001110100000011101111110101100011110101001110100010011001110001000110001100010100001100000000000001110101110011010010010111001101101111100001101101110001101000100010110111111111111110011111100000010101010010110100110111110001010001101011110010100111110100110101101001111111100000001000000010101101000000010011001110010110100011010011001100100110101100110001110010111101010100001011011111111001001011000011110011000110000010111110101110100010100001101111011100010011010000101110001110101010110000101110100100101001100001011100000010100010101000010001010011010101010100111100111110010111011011001111111000101011111011011101111111100000110111100110101111100110011010001001011110001001011111011110100110111111001101000110110000100000110111101000011101000101010110010010110001110111100001100111010011101110110100110100001101011001011001000110000110010011011110001110101101000000000110111101010111011001101111100100001111111100000100010000010010001011101001110010001001010100001001;
        end else begin
            cnt <= cnt + 1;
            case (cnt)// 25
                11'd10: begin
                    s_din <= din1;
                    s_ena <= 1;
                    im_ena <= 8'b00000001;
                end 
                11'd20: begin
                    s_din <= din2;
                end 
                11'd35: begin
                    im_ena <= 8'b00000010;
                end
                11'd45: begin
                    s_din <= din3;
                end 
                11'd60: begin
                    im_ena <= 8'b00000100;
                end
                11'd70: begin
                    s_din <= din4;
                end 
                11'd85: begin
                    im_ena <= 8'b00001000;
                end
                11'd95: begin
                    s_din <= din5;
                end 
                11'd110: begin
                    im_ena <= 8'b00010000;
                end
                11'd120: begin
                    s_din <= din6;
                end 
                11'd135: begin
                    im_ena <= 8'b00100000;
                end
                11'd145: begin
                    s_din <= din7;
                end 
                11'd160: begin
                    im_ena <= 8'b01000000;
                end
                11'd175: begin
                    s_din <= din8;
                end 
                11'd185: begin
                    im_ena <= 8'b10000000;
                end
                11'd210: begin
                    im_ena <= 8'b00000000;
                    t_deq <= 1;
                end
            endcase
        end
    end

    // reg [31:0] t_dout_prev;
    // reg [7:0] cnt_dout;

    assign finished = out_cnt >= 8'd128;

    // read data output
    // use negedge to avoid conflict
    // always @(negedge clk ) begin
    //     if(t_deq & ~finished) begin
    //         // t_dout_prev <= t_dout;
    //         // dout <= {dout[4095-32:0], t_dout};
    //         cnt_dout <= cnt_dout +1; 
    //     end
    // end
    always begin
        #(`PERIOD/2) clk = ~clk;
    end

    initial begin
        clk = 0;
        ena = 0;
        rst = 0;
        #(30*`PERIOD) rst = 1;
        #(2*`PERIOD) rst = 0;
        #(2*`PERIOD) ena = 1;

        #(400*`PERIOD) $finish;
    end

endmodule