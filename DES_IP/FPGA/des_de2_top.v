`timescale 1ns/1ps

module des_de2_top (
    // Clock and Reset
    input           CLOCK_50,       // 50MHz clock
    input   [3:0]   KEY,            // 4 push buttons (active low)
    input   [17:0]  SW,             // 18 switches
    
    // LEDs
    output  [17:0]  LEDR,           // 18 red LEDs
    output  [8:0]   LEDG,           // 9 green LEDs
    
    // 7-segment displays
    output  [6:0]   HEX0,
    output  [6:0]   HEX1,
    output  [6:0]   HEX2,
    output  [6:0]   HEX3,
    output  [6:0]   HEX4,
    output  [6:0]   HEX5,
    output  [6:0]   HEX6,
    output  [6:0]   HEX7
);

// Internal signals
reg     [63:0]  des_data;
reg     [63:0]  des_key;
reg             des_encipher_en;
reg             des_decipher_en;
wire    [63:0]  des_result;
wire            des_ready;

wire            clk;
wire            rst_n;
reg             key0_pressed, key1_pressed, key2_pressed;
reg     [1:0]   key0_sync, key1_sync, key2_sync;

// Button definitions (active low):
// KEY[0] - Reset (active low)
// KEY[1] - Start Encryption
// KEY[2] - Start Decryption  
// KEY[3] - Load Data/Key
// SW[17:16] - Mode select: 00=set data low, 01=set data high, 10=set key low, 11=set key high
// SW[15:0] - Data/Key input (16 bits at a time)

assign clk = CLOCK_50;
assign rst_n = KEY[0];

// Synchronize button inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key0_sync <= 2'b11;
        key1_sync <= 2'b11;
        key2_sync <= 2'b11;
    end else begin
        key0_sync <= {key0_sync[0], KEY[1]};
        key1_sync <= {key1_sync[0], KEY[2]};
        key2_sync <= {key2_sync[0], KEY[3]};
    end
end

// Detect button press (falling edge)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key0_pressed <= 1'b0;
        key1_pressed <= 1'b0;
        key2_pressed <= 1'b0;
    end else begin
        key0_pressed <= key0_sync[1] & ~key0_sync[0];
        key1_pressed <= key1_sync[1] & ~key1_sync[0];
        key2_pressed <= key2_sync[1] & ~key2_sync[0];
    end
end

// Load data and key registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        des_data <= 64'h0123456789ABCDEF;  // Default test data
        des_key  <= 64'h133457799BBCDFF1;  // Default test key
    end else if (key2_pressed) begin
        // Load data or key based on SW[17]
        if (!SW[17]) begin
            // Load data (SW[17] = 0)
            case (SW[16:15])
                2'b00: des_data[15:0]  <= SW[15:0];   // Load data bits [15:0]
                2'b01: des_data[31:16] <= SW[15:0];   // Load data bits [31:16]
                2'b10: des_data[47:32] <= SW[15:0];   // Load data bits [47:32]
                2'b11: des_data[63:48] <= SW[15:0];   // Load data bits [63:48]
            endcase
        end else begin
            // Load key (SW[17] = 1)
            case (SW[16:15])
                2'b00: des_key[15:0]  <= SW[15:0];    // Load key bits [15:0]
                2'b01: des_key[31:16] <= SW[15:0];    // Load key bits [31:16]
                2'b10: des_key[47:32] <= SW[15:0];    // Load key bits [47:32]
                2'b11: des_key[63:48] <= SW[15:0];    // Load key bits [63:48]
            endcase
        end
    end
end

// Control encryption/decryption
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        des_encipher_en <= 1'b0;
        des_decipher_en <= 1'b0;
    end else begin
        if (key0_pressed && des_ready)
            des_encipher_en <= 1'b1;
        else
            des_encipher_en <= 1'b0;
            
        if (key1_pressed && des_ready)
            des_decipher_en <= 1'b1;
        else
            des_decipher_en <= 1'b0;
    end
end

// Instantiate DES core
des_core des_inst (
    .clk                (clk),
    .rst_n              (rst_n),
    .des_encipher_en    (des_encipher_en),
    .des_decipher_en    (des_decipher_en),
    .des_data           (des_data),
    .des_key_in         (des_key),
    .desc_result        (des_result),
    .desc_ready         (des_ready)
);

// LED outputs
assign LEDR[17:0] = SW[17:0];  // Show switch states
assign LEDG[8] = des_ready;     // Green LED shows ready status
assign LEDG[7] = des_encipher_en;
assign LEDG[6] = des_decipher_en;
assign LEDG[5:0] = 6'b0;

// 7-segment display - show result
hex_to_7seg hex0_inst (.hex(des_result[3:0]),   .seg(HEX0));
hex_to_7seg hex1_inst (.hex(des_result[7:4]),   .seg(HEX1));
hex_to_7seg hex2_inst (.hex(des_result[11:8]),  .seg(HEX2));
hex_to_7seg hex3_inst (.hex(des_result[15:12]), .seg(HEX3));
hex_to_7seg hex4_inst (.hex(des_result[19:16]), .seg(HEX4));
hex_to_7seg hex5_inst (.hex(des_result[23:20]), .seg(HEX5));
hex_to_7seg hex6_inst (.hex(des_result[27:24]), .seg(HEX6));
hex_to_7seg hex7_inst (.hex(des_result[31:28]), .seg(HEX7));

endmodule

//========================================================================
// DES Core Module - Integrated into DE2 Top
//========================================================================
module des_core (
   desc_result, desc_ready, 
   clk, rst_n, des_encipher_en, des_decipher_en, des_data, des_key_in
   );
//
//inputs
//
input		clk;
input		rst_n;
input		des_encipher_en;
input		des_decipher_en;
input	[63:0]	des_data;
input	[63:0]	des_key_in;
//
//outputs
//
output	wire	[63:0]	desc_result;
output	wire		desc_ready;
//
//internal signals
//
wire	[63:0] ip_input;
wire	[31:0]	l0, r0;
wire	[31:0]	l_input, r_input;
wire	[47:0]	re;
wire	[47:0]	re_xor_key;
wire	[5:0]	s1_in, s2_in, s3_in, s4_in, s5_in, s6_in, s7_in, s8_in;
reg	[3:0]	s1_out, s2_out, s3_out, s4_out, s5_out, s6_out, s7_out, s8_out;
wire	[31:0]	p_in;
wire	[31:0]	f_value;
wire		rkey_sel;
wire	[27:0]	c0, d0;
wire	[27:0]	cin, din;
reg	[27:0]	cn, dn;
wire	[55:0]	cn_dn;
wire	[47:0]	round_key;
reg	[3:0]	rcounter;
wire		k16_complete;
wire		shift_left_1;
reg		key_process;
reg	[31:0]	ln, rn;
wire	[63:0]	inv_p_input;
reg		k16_calculation;
reg		decipher_process;
wire		shift_right_1;
wire		shift_left;
wire		set_decipher;
reg		encipher_process;
reg		encipher_en_sync;
wire		lr_sel;
//
//Cipher
//---------------- Initial Permutation - IP -------------
assign ip_input	= {des_data[6], des_data[14], des_data[22], des_data[30], des_data[38], des_data[46], des_data[54], des_data[62],
		des_data[4], des_data[12], des_data[20], des_data[28], des_data[36], des_data[44], des_data[52], des_data[60],
		des_data[2], des_data[10], des_data[18], des_data[26], des_data[34], des_data[42], des_data[50], des_data[58],
		des_data[0], des_data[8], des_data[16], des_data[24], des_data[32], des_data[40], des_data[48], des_data[56],
		des_data[7], des_data[15], des_data[23], des_data[31], des_data[39], des_data[47], des_data[55], des_data[63],
		des_data[5], des_data[13], des_data[21], des_data[29], des_data[37], des_data[45], des_data[53], des_data[61],
		des_data[3], des_data[11], des_data[19], des_data[27], des_data[35], des_data[43], des_data[51], des_data[59],
		des_data[1], des_data[9], des_data[17], des_data[25], des_data[33], des_data[41], des_data[49], des_data[57]};
assign	l0	= ip_input[63:32];
assign	r0	= ip_input[31:0];
//-------------------------------------------------------
//Cipher function - f (R,K)
//-------------------------------------------------------
assign	lr_sel	= (encipher_process)? (rcounter == 4'd1): (~rkey_sel);
assign	l_input	= (lr_sel)? l0: ln;
assign	r_input	= (lr_sel)? r0: rn;
//----------------- E table - Converting 32-bit R to 48-bit value ---------------------------
assign	re	= {r_input[0], r_input[31], r_input[30], r_input[29], r_input[28], r_input[27],
		r_input[28], r_input[27], r_input[26], r_input[25], r_input[24], r_input[23],
		r_input[24], r_input[23], r_input[22], r_input[21], r_input[20], r_input[19],
		r_input[20], r_input[19], r_input[18], r_input[17], r_input[16], r_input[15],
		r_input[16], r_input[15], r_input[14], r_input[13], r_input[12], r_input[11],
		r_input[12], r_input[11], r_input[10], r_input[9], r_input[8], r_input[7],
		r_input[8], r_input[7], r_input[6], r_input[5], r_input[4], r_input[3],
		r_input[4], r_input[3], r_input[2], r_input[1], r_input[0], r_input[31]};
//----------------- After converting from 32-bit to 48-bit, Right data XOR with Round KEY -----------------------
assign	re_xor_key	= re ^ round_key;
//----------------- S1/2/3/4/5/6/7/8 Converting 48-bit (with KEY) to 32-bit -----------------
assign	s1_in	= re_xor_key[47:42];
assign	s2_in	= re_xor_key[41:36];
assign	s3_in	= re_xor_key[35:30];
assign	s4_in	= re_xor_key[29:24];
assign	s5_in	= re_xor_key[23:18];
assign	s6_in	= re_xor_key[17:12];
assign	s7_in	= re_xor_key[11:6];
assign	s8_in	= re_xor_key[5:0];
//----------------- S1 -------------------------------
always @ (*) begin
	case ({s1_in[5], s1_in[0]})
		2'b00: begin
			case (s1_in[4:1])
				4'd0:	s1_out	= 4'd14;
				4'd1:	s1_out	= 4'd4;
				4'd2:	s1_out	= 4'd13;
				4'd3:	s1_out	= 4'd1;
				4'd4:	s1_out	= 4'd2;
				4'd5:	s1_out	= 4'd15;
				4'd6:	s1_out	= 4'd11;
				4'd7:	s1_out	= 4'd8;
				4'd8:	s1_out	= 4'd3;
				4'd9:	s1_out	= 4'd10;
				4'd10:	s1_out	= 4'd6;
				4'd11:	s1_out	= 4'd12;
				4'd12:	s1_out	= 4'd5;
				4'd13:	s1_out	= 4'd9;
				4'd14:	s1_out	= 4'd0;
				default: s1_out	= 4'd7;
			endcase
		end
		2'b01: begin
			case (s1_in[4:1])
				4'd0:	s1_out	= 4'd0;
				4'd1:	s1_out	= 4'd15;
				4'd2:	s1_out	= 4'd7;
				4'd3:	s1_out	= 4'd4;
				4'd4:	s1_out	= 4'd14;
				4'd5:	s1_out	= 4'd2;
				4'd6:	s1_out	= 4'd13;
				4'd7:	s1_out	= 4'd1;
				4'd8:	s1_out	= 4'd10;
				4'd9:	s1_out	= 4'd6;
				4'd10:	s1_out	= 4'd12;
				4'd11:	s1_out	= 4'd11;
				4'd12:	s1_out	= 4'd9;
				4'd13:	s1_out	= 4'd5;
				4'd14:	s1_out	= 4'd3;
				default: s1_out	= 4'd8;
			endcase
		end
		2'b10: begin
			case (s1_in[4:1])
				4'd0:	s1_out	= 4'd4;
				4'd1:	s1_out	= 4'd1;
				4'd2:	s1_out	= 4'd14;
				4'd3:	s1_out	= 4'd8;
				4'd4:	s1_out	= 4'd13;
				4'd5:	s1_out	= 4'd6;
				4'd6:	s1_out	= 4'd2;
				4'd7:	s1_out	= 4'd11;
				4'd8:	s1_out	= 4'd15;
				4'd9:	s1_out	= 4'd12;
				4'd10:	s1_out	= 4'd9;
				4'd11:	s1_out	= 4'd7;
				4'd12:	s1_out	= 4'd3;
				4'd13:	s1_out	= 4'd10;
				4'd14:	s1_out	= 4'd5;
				default: s1_out	= 4'd0;
			endcase
		end
		default: begin
			case (s1_in[4:1])
				4'd0:	s1_out	= 4'd15;
				4'd1:	s1_out	= 4'd12;
				4'd2:	s1_out	= 4'd8;
				4'd3:	s1_out	= 4'd2;
				4'd4:	s1_out	= 4'd4;
				4'd5:	s1_out	= 4'd9;
				4'd6:	s1_out	= 4'd1;
				4'd7:	s1_out	= 4'd7;
				4'd8:	s1_out	= 4'd5;
				4'd9:	s1_out	= 4'd11;
				4'd10:	s1_out	= 4'd3;
				4'd11:	s1_out	= 4'd14;
				4'd12:	s1_out	= 4'd10;
				4'd13:	s1_out	= 4'd0;
				4'd14:	s1_out	= 4'd6;
				default: s1_out	= 4'd13;
			endcase
		end
	endcase
end
//----------------- S2 -------------------------------
always @ (*) begin
	case ({s2_in[5], s2_in[0]})
		2'b00: begin
			case (s2_in[4:1])
				4'd0:	s2_out	= 4'd15;
				4'd1:	s2_out	= 4'd1;
				4'd2:	s2_out	= 4'd8;
				4'd3:	s2_out	= 4'd14;
				4'd4:	s2_out	= 4'd6;
				4'd5:	s2_out	= 4'd11;
				4'd6:	s2_out	= 4'd3;
				4'd7:	s2_out	= 4'd4;
				4'd8:	s2_out	= 4'd9;
				4'd9:	s2_out	= 4'd7;
				4'd10:	s2_out	= 4'd2;
				4'd11:	s2_out	= 4'd13;
				4'd12:	s2_out	= 4'd12;
				4'd13:	s2_out	= 4'd0;
				4'd14:	s2_out	= 4'd5;
				default: s2_out	= 4'd10;
			endcase
		end
		2'b01: begin
			case (s2_in[4:1])
				4'd0:	s2_out	= 4'd3;
				4'd1:	s2_out	= 4'd13;
				4'd2:	s2_out	= 4'd4;
				4'd3:	s2_out	= 4'd7;
				4'd4:	s2_out	= 4'd15;
				4'd5:	s2_out	= 4'd2;
				4'd6:	s2_out	= 4'd8;
				4'd7:	s2_out	= 4'd14;
				4'd8:	s2_out	= 4'd12;
				4'd9:	s2_out	= 4'd0;
				4'd10:	s2_out	= 4'd1;
				4'd11:	s2_out	= 4'd10;
				4'd12:	s2_out	= 4'd6;
				4'd13:	s2_out	= 4'd9;
				4'd14:	s2_out	= 4'd11;
				default: s2_out	= 4'd5;
			endcase
		end
		2'b10: begin
			case (s2_in[4:1])
				4'd0:	s2_out	= 4'd0;
				4'd1:	s2_out	= 4'd14;
				4'd2:	s2_out	= 4'd7;
				4'd3:	s2_out	= 4'd11;
				4'd4:	s2_out	= 4'd10;
				4'd5:	s2_out	= 4'd4;
				4'd6:	s2_out	= 4'd13;
				4'd7:	s2_out	= 4'd1;
				4'd8:	s2_out	= 4'd5;
				4'd9:	s2_out	= 4'd8;
				4'd10:	s2_out	= 4'd12;
				4'd11:	s2_out	= 4'd6;
				4'd12:	s2_out	= 4'd9;
				4'd13:	s2_out	= 4'd3;
				4'd14:	s2_out	= 4'd2;
				default: s2_out	= 4'd15;
			endcase
		end
		default: begin
			case (s2_in[4:1])
				4'd0:	s2_out	= 4'd13;
				4'd1:	s2_out	= 4'd8;
				4'd2:	s2_out	= 4'd10;
				4'd3:	s2_out	= 4'd1;
				4'd4:	s2_out	= 4'd3;
				4'd5:	s2_out	= 4'd15;
				4'd6:	s2_out	= 4'd4;
				4'd7:	s2_out	= 4'd2;
				4'd8:	s2_out	= 4'd11;
				4'd9:	s2_out	= 4'd6;
				4'd10:	s2_out	= 4'd7;
				4'd11:	s2_out	= 4'd12;
				4'd12:	s2_out	= 4'd0;
				4'd13:	s2_out	= 4'd5;
				4'd14:	s2_out	= 4'd14;
				default: s2_out	= 4'd9;
			endcase
		end
	endcase
end
//----------------- S3 -------------------------------
always @ (*) begin
	case ({s3_in[5], s3_in[0]})
		2'b00: begin
			case (s3_in[4:1])
				4'd0:	s3_out	= 4'd10;
				4'd1:	s3_out	= 4'd0;
				4'd2:	s3_out	= 4'd9;
				4'd3:	s3_out	= 4'd14;
				4'd4:	s3_out	= 4'd6;
				4'd5:	s3_out	= 4'd3;
				4'd6:	s3_out	= 4'd15;
				4'd7:	s3_out	= 4'd5;
				4'd8:	s3_out	= 4'd1;
				4'd9:	s3_out	= 4'd13;
				4'd10:	s3_out	= 4'd12;
				4'd11:	s3_out	= 4'd7;
				4'd12:	s3_out	= 4'd11;
				4'd13:	s3_out	= 4'd4;
				4'd14:	s3_out	= 4'd2;
				default: s3_out	= 4'd8;
			endcase
		end
		2'b01: begin
			case (s3_in[4:1])
				4'd0:	s3_out	= 4'd13;
				4'd1:	s3_out	= 4'd7;
				4'd2:	s3_out	= 4'd0;
				4'd3:	s3_out	= 4'd9;
				4'd4:	s3_out	= 4'd3;
				4'd5:	s3_out	= 4'd4;
				4'd6:	s3_out	= 4'd6;
				4'd7:	s3_out	= 4'd10;
				4'd8:	s3_out	= 4'd2;
				4'd9:	s3_out	= 4'd8;
				4'd10:	s3_out	= 4'd5;
				4'd11:	s3_out	= 4'd14;
				4'd12:	s3_out	= 4'd12;
				4'd13:	s3_out	= 4'd11;
				4'd14:	s3_out	= 4'd15;
				default: s3_out	= 4'd1;
			endcase
		end
		2'b10: begin
			case (s3_in[4:1])
				4'd0:	s3_out	= 4'd13;
				4'd1:	s3_out	= 4'd6;
				4'd2:	s3_out	= 4'd4;
				4'd3:	s3_out	= 4'd9;
				4'd4:	s3_out	= 4'd8;
				4'd5:	s3_out	= 4'd15;
				4'd6:	s3_out	= 4'd3;
				4'd7:	s3_out	= 4'd0;
				4'd8:	s3_out	= 4'd11;
				4'd9:	s3_out	= 4'd1;
				4'd10:	s3_out	= 4'd2;
				4'd11:	s3_out	= 4'd12;
				4'd12:	s3_out	= 4'd5;
				4'd13:	s3_out	= 4'd10;
				4'd14:	s3_out	= 4'd14;
				default: s3_out	= 4'd7;
			endcase
		end
		default: begin
			case (s3_in[4:1])
				4'd0:	s3_out	= 4'd1;
				4'd1:	s3_out	= 4'd10;
				4'd2:	s3_out	= 4'd13;
				4'd3:	s3_out	= 4'd0;
				4'd4:	s3_out	= 4'd6;
				4'd5:	s3_out	= 4'd9;
				4'd6:	s3_out	= 4'd8;
				4'd7:	s3_out	= 4'd7;
				4'd8:	s3_out	= 4'd4;
				4'd9:	s3_out	= 4'd15;
				4'd10:	s3_out	= 4'd14;
				4'd11:	s3_out	= 4'd3;
				4'd12:	s3_out	= 4'd11;
				4'd13:	s3_out	= 4'd5;
				4'd14:	s3_out	= 4'd2;
				default: s3_out	= 4'd12;
			endcase
		end
	endcase
end
//----------------- S4 -------------------------------
always @ (*) begin
	case ({s4_in[5], s4_in[0]})
		2'b00: begin
			case (s4_in[4:1])
				4'd0:	s4_out	= 4'd7;
				4'd1:	s4_out	= 4'd13;
				4'd2:	s4_out	= 4'd14;
				4'd3:	s4_out	= 4'd3;
				4'd4:	s4_out	= 4'd0;
				4'd5:	s4_out	= 4'd6;
				4'd6:	s4_out	= 4'd9;
				4'd7:	s4_out	= 4'd10;
				4'd8:	s4_out	= 4'd1;
				4'd9:	s4_out	= 4'd2;
				4'd10:	s4_out	= 4'd8;
				4'd11:	s4_out	= 4'd5;
				4'd12:	s4_out	= 4'd11;
				4'd13:	s4_out	= 4'd12;
				4'd14:	s4_out	= 4'd4;
				default: s4_out	= 4'd15;
			endcase
		end
		2'b01: begin
			case (s4_in[4:1])
				4'd0:	s4_out	= 4'd13;
				4'd1:	s4_out	= 4'd8;
				4'd2:	s4_out	= 4'd11;
				4'd3:	s4_out	= 4'd5;
				4'd4:	s4_out	= 4'd6;
				4'd5:	s4_out	= 4'd15;
				4'd6:	s4_out	= 4'd0;
				4'd7:	s4_out	= 4'd3;
				4'd8:	s4_out	= 4'd4;
				4'd9:	s4_out	= 4'd7;
				4'd10:	s4_out	= 4'd2;
				4'd11:	s4_out	= 4'd12;
				4'd12:	s4_out	= 4'd1;
				4'd13:	s4_out	= 4'd10;
				4'd14:	s4_out	= 4'd14;
				default: s4_out	= 4'd9;
			endcase
		end
		2'b10: begin
			case (s4_in[4:1])
				4'd0:	s4_out	= 4'd10;
				4'd1:	s4_out	= 4'd6;
				4'd2:	s4_out	= 4'd9;
				4'd3:	s4_out	= 4'd0;
				4'd4:	s4_out	= 4'd12;
				4'd5:	s4_out	= 4'd11;
				4'd6:	s4_out	= 4'd7;
				4'd7:	s4_out	= 4'd13;
				4'd8:	s4_out	= 4'd15;
				4'd9:	s4_out	= 4'd1;
				4'd10:	s4_out	= 4'd3;
				4'd11:	s4_out	= 4'd14;
				4'd12:	s4_out	= 4'd5;
				4'd13:	s4_out	= 4'd2;
				4'd14:	s4_out	= 4'd8;
				default: s4_out	= 4'd4;
			endcase
		end
		default: begin
			case (s4_in[4:1])
				4'd0:	s4_out	= 4'd3;
				4'd1:	s4_out	= 4'd15;
				4'd2:	s4_out	= 4'd0;
				4'd3:	s4_out	= 4'd6;
				4'd4:	s4_out	= 4'd10;
				4'd5:	s4_out	= 4'd1;
				4'd6:	s4_out	= 4'd13;
				4'd7:	s4_out	= 4'd8;
				4'd8:	s4_out	= 4'd9;
				4'd9:	s4_out	= 4'd4;
				4'd10:	s4_out	= 4'd5;
				4'd11:	s4_out	= 4'd11;
				4'd12:	s4_out	= 4'd12;
				4'd13:	s4_out	= 4'd7;
				4'd14:	s4_out	= 4'd2;
				default: s4_out	= 4'd14;
			endcase
		end
	endcase
end
//----------------- S5 -------------------------------
always @ (*) begin
	case ({s5_in[5], s5_in[0]})
		2'b00: begin
			case (s5_in[4:1])
				4'd0:	s5_out	= 4'd2;
				4'd1:	s5_out	= 4'd12;
				4'd2:	s5_out	= 4'd4;
				4'd3:	s5_out	= 4'd1;
				4'd4:	s5_out	= 4'd7;
				4'd5:	s5_out	= 4'd10;
				4'd6:	s5_out	= 4'd11;
				4'd7:	s5_out	= 4'd6;
				4'd8:	s5_out	= 4'd8;
				4'd9:	s5_out	= 4'd5;
				4'd10:	s5_out	= 4'd3;
				4'd11:	s5_out	= 4'd15;
				4'd12:	s5_out	= 4'd13;
				4'd13:	s5_out	= 4'd0;
				4'd14:	s5_out	= 4'd14;
				default: s5_out	= 4'd9;
			endcase
		end
		2'b01: begin
			case (s5_in[4:1])
				4'd0:	s5_out	= 4'd14;
				4'd1:	s5_out	= 4'd11;
				4'd2:	s5_out	= 4'd2;
				4'd3:	s5_out	= 4'd12;
				4'd4:	s5_out	= 4'd4;
				4'd5:	s5_out	= 4'd7;
				4'd6:	s5_out	= 4'd13;
				4'd7:	s5_out	= 4'd1;
				4'd8:	s5_out	= 4'd5;
				4'd9:	s5_out	= 4'd0;
				4'd10:	s5_out	= 4'd15;
				4'd11:	s5_out	= 4'd10;
				4'd12:	s5_out	= 4'd3;
				4'd13:	s5_out	= 4'd9;
				4'd14:	s5_out	= 4'd8;
				default: s5_out	= 4'd6;
			endcase
		end
		2'b10: begin
			case (s5_in[4:1])
				4'd0:	s5_out	= 4'd4;
				4'd1:	s5_out	= 4'd2;
				4'd2:	s5_out	= 4'd1;
				4'd3:	s5_out	= 4'd11;
				4'd4:	s5_out	= 4'd10;
				4'd5:	s5_out	= 4'd13;
				4'd6:	s5_out	= 4'd7;
				4'd7:	s5_out	= 4'd8;
				4'd8:	s5_out	= 4'd15;
				4'd9:	s5_out	= 4'd9;
				4'd10:	s5_out	= 4'd12;
				4'd11:	s5_out	= 4'd5;
				4'd12:	s5_out	= 4'd6;
				4'd13:	s5_out	= 4'd3;
				4'd14:	s5_out	= 4'd0;
				default: s5_out	= 4'd14;
			endcase
		end
		default: begin
			case (s5_in[4:1])
				4'd0:	s5_out	= 4'd11;
				4'd1:	s5_out	= 4'd8;
				4'd2:	s5_out	= 4'd12;
				4'd3:	s5_out	= 4'd7;
				4'd4:	s5_out	= 4'd1;
				4'd5:	s5_out	= 4'd14;
				4'd6:	s5_out	= 4'd2;
				4'd7:	s5_out	= 4'd13;
				4'd8:	s5_out	= 4'd6;
				4'd9:	s5_out	= 4'd15;
				4'd10:	s5_out	= 4'd0;
				4'd11:	s5_out	= 4'd9;
				4'd12:	s5_out	= 4'd10;
				4'd13:	s5_out	= 4'd4;
				4'd14:	s5_out	= 4'd5;
				default: s5_out	= 4'd3;
			endcase
		end
	endcase
end
//----------------- S6 -------------------------------
always @ (*) begin
	case ({s6_in[5], s6_in[0]})
		2'b00: begin
			case (s6_in[4:1])
				4'd0:	s6_out	= 4'd12;
				4'd1:	s6_out	= 4'd1;
				4'd2:	s6_out	= 4'd10;
				4'd3:	s6_out	= 4'd15;
				4'd4:	s6_out	= 4'd9;
				4'd5:	s6_out	= 4'd2;
				4'd6:	s6_out	= 4'd6;
				4'd7:	s6_out	= 4'd8;
				4'd8:	s6_out	= 4'd0;
				4'd9:	s6_out	= 4'd13;
				4'd10:	s6_out	= 4'd3;
				4'd11:	s6_out	= 4'd4;
				4'd12:	s6_out	= 4'd14;
				4'd13:	s6_out	= 4'd7;
				4'd14:	s6_out	= 4'd5;
				default: s6_out	= 4'd11;
			endcase
		end
		2'b01: begin
			case (s6_in[4:1])
				4'd0:	s6_out	= 4'd10;
				4'd1:	s6_out	= 4'd15;
				4'd2:	s6_out	= 4'd4;
				4'd3:	s6_out	= 4'd2;
				4'd4:	s6_out	= 4'd7;
				4'd5:	s6_out	= 4'd12;
				4'd6:	s6_out	= 4'd9;
				4'd7:	s6_out	= 4'd5;
				4'd8:	s6_out	= 4'd6;
				4'd9:	s6_out	= 4'd1;
				4'd10:	s6_out	= 4'd13;
				4'd11:	s6_out	= 4'd14;
				4'd12:	s6_out	= 4'd0;
				4'd13:	s6_out	= 4'd11;
				4'd14:	s6_out	= 4'd3;
				default: s6_out	= 4'd8;
			endcase
		end
		2'b10: begin
			case (s6_in[4:1])
				4'd0:	s6_out	= 4'd9;
				4'd1:	s6_out	= 4'd14;
				4'd2:	s6_out	= 4'd15;
				4'd3:	s6_out	= 4'd5;
				4'd4:	s6_out	= 4'd2;
				4'd5:	s6_out	= 4'd8;
				4'd6:	s6_out	= 4'd12;
				4'd7:	s6_out	= 4'd3;
				4'd8:	s6_out	= 4'd7;
				4'd9:	s6_out	= 4'd0;
				4'd10:	s6_out	= 4'd4;
				4'd11:	s6_out	= 4'd10;
				4'd12:	s6_out	= 4'd1;
				4'd13:	s6_out	= 4'd13;
				4'd14:	s6_out	= 4'd11;
				default: s6_out	= 4'd6;
			endcase
		end
		default: begin
			case (s6_in[4:1])
				4'd0:	s6_out	= 4'd4;
				4'd1:	s6_out	= 4'd3;
				4'd2:	s6_out	= 4'd2;
				4'd3:	s6_out	= 4'd12;
				4'd4:	s6_out	= 4'd9;
				4'd5:	s6_out	= 4'd5;
				4'd6:	s6_out	= 4'd15;
				4'd7:	s6_out	= 4'd10;
				4'd8:	s6_out	= 4'd11;
				4'd9:	s6_out	= 4'd14;
				4'd10:	s6_out	= 4'd1;
				4'd11:	s6_out	= 4'd7;
				4'd12:	s6_out	= 4'd6;
				4'd13:	s6_out	= 4'd0;
				4'd14:	s6_out	= 4'd8;
				default: s6_out	= 4'd13;
			endcase
		end
	endcase
end
//----------------- S7 -------------------------------
always @ (*) begin
	case ({s7_in[5], s7_in[0]})
		2'b00: begin
			case (s7_in[4:1])
				4'd0:	s7_out	= 4'd4;
				4'd1:	s7_out	= 4'd11;
				4'd2:	s7_out	= 4'd2;
				4'd3:	s7_out	= 4'd14;
				4'd4:	s7_out	= 4'd15;
				4'd5:	s7_out	= 4'd0;
				4'd6:	s7_out	= 4'd8;
				4'd7:	s7_out	= 4'd13;
				4'd8:	s7_out	= 4'd3;
				4'd9:	s7_out	= 4'd12;
				4'd10:	s7_out	= 4'd9;
				4'd11:	s7_out	= 4'd7;
				4'd12:	s7_out	= 4'd5;
				4'd13:	s7_out	= 4'd10;
				4'd14:	s7_out	= 4'd6;
				default: s7_out	= 4'd1;
			endcase
		end
		2'b01: begin
			case (s7_in[4:1])
				4'd0:	s7_out	= 4'd13;
				4'd1:	s7_out	= 4'd0;
				4'd2:	s7_out	= 4'd11;
				4'd3:	s7_out	= 4'd7;
				4'd4:	s7_out	= 4'd4;
				4'd5:	s7_out	= 4'd9;
				4'd6:	s7_out	= 4'd1;
				4'd7:	s7_out	= 4'd10;
				4'd8:	s7_out	= 4'd14;
				4'd9:	s7_out	= 4'd3;
				4'd10:	s7_out	= 4'd5;
				4'd11:	s7_out	= 4'd12;
				4'd12:	s7_out	= 4'd2;
				4'd13:	s7_out	= 4'd15;
				4'd14:	s7_out	= 4'd8;
				default: s7_out	= 4'd6;
			endcase
		end
		2'b10: begin
			case (s7_in[4:1])
				4'd0:	s7_out	= 4'd1;
				4'd1:	s7_out	= 4'd4;
				4'd2:	s7_out	= 4'd11;
				4'd3:	s7_out	= 4'd13;
				4'd4:	s7_out	= 4'd12;
				4'd5:	s7_out	= 4'd3;
				4'd6:	s7_out	= 4'd7;
				4'd7:	s7_out	= 4'd14;
				4'd8:	s7_out	= 4'd10;
				4'd9:	s7_out	= 4'd15;
				4'd10:	s7_out	= 4'd6;
				4'd11:	s7_out	= 4'd8;
				4'd12:	s7_out	= 4'd0;
				4'd13:	s7_out	= 4'd5;
				4'd14:	s7_out	= 4'd9;
				default: s7_out	= 4'd2;
			endcase
		end
		default: begin
			case (s7_in[4:1])
				4'd0:	s7_out	= 4'd6;
				4'd1:	s7_out	= 4'd11;
				4'd2:	s7_out	= 4'd13;
				4'd3:	s7_out	= 4'd8;
				4'd4:	s7_out	= 4'd1;
				4'd5:	s7_out	= 4'd4;
				4'd6:	s7_out	= 4'd10;
				4'd7:	s7_out	= 4'd7;
				4'd8:	s7_out	= 4'd9;
				4'd9:	s7_out	= 4'd5;
				4'd10:	s7_out	= 4'd0;
				4'd11:	s7_out	= 4'd15;
				4'd12:	s7_out	= 4'd14;
				4'd13:	s7_out	= 4'd2;
				4'd14:	s7_out	= 4'd3;
				default: s7_out	= 4'd12;
			endcase
		end
	endcase
end
//----------------- S8 -------------------------------
always @ (*) begin
	case ({s8_in[5], s8_in[0]})
		2'b00: begin
			case (s8_in[4:1])
				4'd0:	s8_out	= 4'd13;
				4'd1:	s8_out	= 4'd2;
				4'd2:	s8_out	= 4'd8;
				4'd3:	s8_out	= 4'd4;
				4'd4:	s8_out	= 4'd6;
				4'd5:	s8_out	= 4'd15;
				4'd6:	s8_out	= 4'd11;
				4'd7:	s8_out	= 4'd1;
				4'd8:	s8_out	= 4'd10;
				4'd9:	s8_out	= 4'd9;
				4'd10:	s8_out	= 4'd3;
				4'd11:	s8_out	= 4'd14;
				4'd12:	s8_out	= 4'd5;
				4'd13:	s8_out	= 4'd0;
				4'd14:	s8_out	= 4'd12;
				default: s8_out	= 4'd7;
			endcase
		end
		2'b01: begin
			case (s8_in[4:1])
				4'd0:	s8_out	= 4'd1;
				4'd1:	s8_out	= 4'd15;
				4'd2:	s8_out	= 4'd13;
				4'd3:	s8_out	= 4'd8;
				4'd4:	s8_out	= 4'd10;
				4'd5:	s8_out	= 4'd3;
				4'd6:	s8_out	= 4'd7;
				4'd7:	s8_out	= 4'd4;
				4'd8:	s8_out	= 4'd12;
				4'd9:	s8_out	= 4'd5;
				4'd10:	s8_out	= 4'd6;
				4'd11:	s8_out	= 4'd11;
				4'd12:	s8_out	= 4'd0;
				4'd13:	s8_out	= 4'd14;
				4'd14:	s8_out	= 4'd9;
				default: s8_out	= 4'd2;
			endcase
		end
		2'b10: begin
			case (s8_in[4:1])
				4'd0:	s8_out	= 4'd7;
				4'd1:	s8_out	= 4'd11;
				4'd2:	s8_out	= 4'd4;
				4'd3:	s8_out	= 4'd1;
				4'd4:	s8_out	= 4'd9;
				4'd5:	s8_out	= 4'd12;
				4'd6:	s8_out	= 4'd14;
				4'd7:	s8_out	= 4'd2;
				4'd8:	s8_out	= 4'd0;
				4'd9:	s8_out	= 4'd6;
				4'd10:	s8_out	= 4'd10;
				4'd11:	s8_out	= 4'd13;
				4'd12:	s8_out	= 4'd15;
				4'd13:	s8_out	= 4'd3;
				4'd14:	s8_out	= 4'd5;
				default: s8_out	= 4'd8;
			endcase
		end
		default: begin
			case (s8_in[4:1])
				4'd0:	s8_out	= 4'd2;
				4'd1:	s8_out	= 4'd1;
				4'd2:	s8_out	= 4'd14;
				4'd3:	s8_out	= 4'd7;
				4'd4:	s8_out	= 4'd4;
				4'd5:	s8_out	= 4'd10;
				4'd6:	s8_out	= 4'd8;
				4'd7:	s8_out	= 4'd13;
				4'd8:	s8_out	= 4'd15;
				4'd9:	s8_out	= 4'd12;
				4'd10:	s8_out	= 4'd9;
				4'd11:	s8_out	= 4'd0;
				4'd12:	s8_out	= 4'd3;
				4'd13:	s8_out	= 4'd5;
				4'd14:	s8_out	= 4'd6;
				default: s8_out	= 4'd11;
			endcase
		end
	endcase
end
//-------- Permutation - P / the final value of f(R, K) function -----------------
assign	p_in	= {s1_out, s2_out, s3_out, s4_out, s5_out, s6_out, s7_out, s8_out};
assign	f_value	= {p_in[16], p_in[25], p_in[12], p_in[11],
		p_in[3], p_in[20], p_in[4], p_in[15],
		p_in[31], p_in[17], p_in[9], p_in[6],
		p_in[27], p_in[14], p_in[1], p_in[22],
		p_in[30], p_in[24], p_in[8], p_in[18],
		p_in[0], p_in[5], p_in[29], p_in[23],
		p_in[13], p_in[19], p_in[2], p_in[26],
		p_in[10], p_in[21], p_in[28], p_in[7]};
//-------- The ciphertext of DES --------------------------------------
always @ (posedge clk) begin
	if (decipher_process | encipher_process) begin
		ln	<= #1 r_input;
		rn	<= #1 l_input ^ f_value;
	end
end
assign	inv_p_input	= {rn, ln};
assign	desc_result	= {inv_p_input[24], inv_p_input[56], inv_p_input[16], inv_p_input[48], inv_p_input[8], inv_p_input[40], inv_p_input[0], inv_p_input[32],
			inv_p_input[25], inv_p_input[57], inv_p_input[17], inv_p_input[49], inv_p_input[9], inv_p_input[41], inv_p_input[1], inv_p_input[33],
			inv_p_input[26], inv_p_input[58], inv_p_input[18], inv_p_input[50], inv_p_input[10], inv_p_input[42], inv_p_input[2], inv_p_input[34],
			inv_p_input[27], inv_p_input[59], inv_p_input[19], inv_p_input[51], inv_p_input[11], inv_p_input[43], inv_p_input[3], inv_p_input[35],
			inv_p_input[28], inv_p_input[60], inv_p_input[20], inv_p_input[52], inv_p_input[12], inv_p_input[44], inv_p_input[4], inv_p_input[36],
			inv_p_input[29], inv_p_input[61], inv_p_input[21], inv_p_input[53], inv_p_input[13], inv_p_input[45], inv_p_input[5], inv_p_input[37],
			inv_p_input[30], inv_p_input[62], inv_p_input[22], inv_p_input[54], inv_p_input[14], inv_p_input[46], inv_p_input[6], inv_p_input[38],
			inv_p_input[31], inv_p_input[63], inv_p_input[23], inv_p_input[55], inv_p_input[15], inv_p_input[47], inv_p_input[7], inv_p_input[39]};
//------------------------------------------------------------------------
//Key Schedule Calculation
//------------------------------------------------------------------------
//------------ Permuted Choice 1 - PC1 ------------------
assign	c0	= {des_key_in[7], des_key_in[15], des_key_in[23], des_key_in[31], des_key_in[39], des_key_in[47], des_key_in[55],
		des_key_in[63], des_key_in[6], des_key_in[14], des_key_in[22], des_key_in[30], des_key_in[38], des_key_in[46],
		des_key_in[54], des_key_in[62], des_key_in[5], des_key_in[13], des_key_in[21], des_key_in[29], des_key_in[37],
		des_key_in[45], des_key_in[53], des_key_in[61], des_key_in[4], des_key_in[12], des_key_in[20], des_key_in[28]};
assign	d0	= {des_key_in[1], des_key_in[9], des_key_in[17], des_key_in[25], des_key_in[33], des_key_in[41], des_key_in[49],
		des_key_in[57], des_key_in[2], des_key_in[10], des_key_in[18], des_key_in[26], des_key_in[34], des_key_in[42],
		des_key_in[50], des_key_in[58], des_key_in[3], des_key_in[11], des_key_in[19], des_key_in[27], des_key_in[35],
		des_key_in[43], des_key_in[51], des_key_in[59], des_key_in[36], des_key_in[44], des_key_in[52], des_key_in[60]};
assign	cin	= (decipher_process | rkey_sel)? cn: c0;
assign	din	= (decipher_process | rkey_sel)? dn: d0;
//------------ Shift Left --------------------------------
always @ (posedge clk) begin
	if (decipher_process) begin
		if (shift_right_1) begin
			cn	<= #1 {cin[0], cin[27:1]};
			dn	<= #1 {din[0], din[27:1]};
		end
		else begin
			cn	<= #1 {cin[1:0], cin[27:2]};
			dn	<= #1 {din[1:0], din[27:2]};
		end
	end
	else if (key_process) begin
		if (shift_left_1) begin
			cn	<= #1 {cin[26:0], cin[27]};
			dn	<= #1 {din[26:0], din[27]};
		end
		else begin
			cn	<= #1 {cin[25:0], cin[27:26]};
			dn	<= #1 {din[25:0], din[27:26]};
		end
	end
end
assign	cn_dn	= {cn, dn};
//------------- Permuted Choice 2 - PC2 -------------------
assign	round_key	= {cn_dn[42], cn_dn[39], cn_dn[45], cn_dn[32], cn_dn[55], cn_dn[51],
			cn_dn[53], cn_dn[28], cn_dn[41], cn_dn[50], cn_dn[35], cn_dn[46],
			cn_dn[33], cn_dn[37], cn_dn[44], cn_dn[52], cn_dn[30], cn_dn[48],
			cn_dn[40], cn_dn[49], cn_dn[29], cn_dn[36], cn_dn[43], cn_dn[54],
			cn_dn[15], cn_dn[4], cn_dn[25], cn_dn[19], cn_dn[9], cn_dn[1],
			cn_dn[26], cn_dn[16], cn_dn[5], cn_dn[11], cn_dn[23], cn_dn[8],
			cn_dn[12], cn_dn[7], cn_dn[17], cn_dn[0], cn_dn[22], cn_dn[3],
			cn_dn[10], cn_dn[14], cn_dn[6], cn_dn[20], cn_dn[27], cn_dn[24]};
//
//-------------- Encryption round counter -----------------------
//
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	rcounter	<= #1 4'd0;
	else if (key_process)
		rcounter	<= #1 rcounter + 4'd1;
end
assign	k16_complete	= &rcounter;
assign	rkey_sel	= |rcounter;
assign	shift_left	= (~rkey_sel) | k16_complete;
assign	shift_left_1	= shift_left | (rcounter == 4'd1) | (rcounter == 4'd8); //0-1-8-15
assign	shift_right_1	= shift_left | (rcounter == 4'd7) | (rcounter == 4'd14); //0-7-14-15
assign	set_decipher	= (decipher_process | encipher_process) & k16_complete;
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	key_process	<= #1 1'b0;
	else if (des_decipher_en | des_encipher_en)
		key_process	<= #1 1'b1;
	else if (set_decipher)
		key_process	<= #1 1'b0;
end
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	k16_calculation	<= #1 1'b0;
	else		k16_calculation	<= #1 key_process & (~decipher_process) & (~encipher_process);
end
assign	desc_ready	= (~key_process) & (~encipher_process);
//
//Determining the encipher or decipher process
//
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	encipher_en_sync	<= #1 1'b0;
	else		encipher_en_sync	<= #1 des_encipher_en;
end
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	encipher_process	<= #1 1'b0;
	else if (encipher_en_sync)
		encipher_process	<= #1 1'b1;
	else if (~rkey_sel)
		encipher_process	<= #1 1'b0;
end
always @ (posedge clk, negedge rst_n) begin
	if (~rst_n)	decipher_process	<= #1 1'b0;
	else if (k16_complete & (~encipher_process)) begin
		if (k16_calculation)
			decipher_process	<= #1 1'b1;
		else	decipher_process	<= #1 1'b0;
	end
end
endmodule

//========================================================================
// Hex to 7-segment decoder
//========================================================================
module hex_to_7seg (
    input   [3:0]   hex,
    output  reg [6:0]   seg
);

always @(*) begin
    case (hex)
        4'h0: seg = 7'b1000000;  // 0
        4'h1: seg = 7'b1111001;  // 1
        4'h2: seg = 7'b0100100;  // 2
        4'h3: seg = 7'b0110000;  // 3
        4'h4: seg = 7'b0011001;  // 4
        4'h5: seg = 7'b0010010;  // 5
        4'h6: seg = 7'b0000010;  // 6
        4'h7: seg = 7'b1111000;  // 7
        4'h8: seg = 7'b0000000;  // 8
        4'h9: seg = 7'b0010000;  // 9
        4'hA: seg = 7'b0001000;  // A
        4'hB: seg = 7'b0000011;  // b
        4'hC: seg = 7'b1000110;  // C
        4'hD: seg = 7'b0100001;  // d
        4'hE: seg = 7'b0000110;  // E
        4'hF: seg = 7'b0001110;  // F
        default: seg = 7'b1111111;
    endcase
end

endmodule
