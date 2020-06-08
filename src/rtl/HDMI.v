// (c) fpga4fun.com & KNJN LLC 2013
// This code is not compatible with GPL and must be replaced!
////////////////////////////////////////////////////////////////////////
module HDMI(
	input inclk,  // Video clock
    input R_IN,
    input G_IN,
    input B_IN,
    output reg NEW_ROW_OUT,
    output reg NEW_SCREEN_OUT,
	output TMDS2,
    output TMDS1,
    output TMDS0,
	output TMDS_clock
);


////////////////////////////////////////////////////////////////////////
// Viewing area and sync pulse generation
reg [9:0] CounterX, CounterY;
reg hSync, vSync, DrawArea;
always @(posedge pixclk) DrawArea <= (CounterX<720) && (CounterY<576);

always @(posedge pixclk) CounterX <= (CounterX==863) ? 0 : CounterX+1;
always @(posedge pixclk) if(CounterX==863) CounterY <= (CounterY==624) ? 0 : CounterY+1;

always @(posedge pixclk) hSync <= (CounterX>=736) && (CounterX<815);
always @(posedge pixclk) vSync <= (CounterY>=586) && (CounterY<588);
always @(posedge pixclk) NEW_ROW_OUT <= (CounterX==0);
always @(posedge pixclk) NEW_SCREEN_OUT <= (CounterY==0);
////////////////
// Pattern generator
reg [7:0] red, green, blue;
always @(posedge pixclk) red <= R_IN ? 255 : 0;
always @(posedge pixclk) green <= G_IN ? 255 : 0;
always @(posedge pixclk) blue <= B_IN ? 255 : 0;

////////////////////////////////////////////////////////////////////////
// TMDS encoding
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;
TMDS_encoder encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_red));
TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_green));
TMDS_encoder encode_B(.clk(pixclk), .VD(blue ), .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));

////////////////////////////////////////////////////////////////////////
// PLL and TMDS Clock generation
wire clk_TMDS, DCM_TMDS_CLKFX;  // 25MHz x 10 = 250MHz
pll pll_inst(.inclk0(inclk),	.c0(pixclk), .c1(DCM_TMDS_CLKFX));
obuf_iobuf_out_tvs BUFG_TMDSp(.datain(DCM_TMDS_CLKFX), .dataout(clk_TMDS));

////////////////////////////////////////////////////////////////////////
// Output buffer
reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;
always @(posedge clk_TMDS) TMDS_shift_load <= (TMDS_mod10==4'd9);

always @(posedge clk_TMDS)
begin
	TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];
	TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];
	TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];	
	TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;
end

obuf_iobuf_out_tvs OBUFDS_red  (.datain(TMDS_shift_red  [0]), .dataout(TMDS2));
obuf_iobuf_out_tvs OBUFDS_green(.datain(TMDS_shift_green[0]), .dataout(TMDS1));
obuf_iobuf_out_tvs OBUFDS_blue (.datain(TMDS_shift_blue [0]), .dataout(TMDS0));
obuf_iobuf_out_tvs OBUFDS_clock(.datain(pixclk), 				  .dataout(TMDS_clock));
endmodule

////////////////////////////////////////////////////////////////////////
// TMDS Encoder module
module TMDS_encoder(
	input clk,
	input [7:0] VD,  // video data (red, green or blue)
	input [1:0] CD,  // control data
	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
	output reg [9:0] TMDS = 0
);

wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};

reg [3:0] balance_acc = 0;
wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
wire balance_sign_eq = (balance[3] == balance_acc[3]);
wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);

always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;

endmodule


////////////////////////////////////////////////////////////////////////
