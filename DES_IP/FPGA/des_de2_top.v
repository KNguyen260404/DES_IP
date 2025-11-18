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
        case (SW[17:16])
            2'b00: des_data[15:0]  <= SW[15:0];   // Load data low 16 bits
            2'b01: des_data[31:16] <= SW[15:0];   // Load data bits 31:16
            2'b10: des_data[47:32] <= SW[15:0];   // Load data bits 47:32
            2'b11: des_data[63:48] <= SW[15:0];   // Load data high 16 bits
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        des_key <= 64'h133457799BBCDFF1;  // Default test key
    end else if (key2_pressed && SW[17]) begin
        case (SW[16])
            1'b0: des_key[31:0]  <= {des_key[31:16], SW[15:0]};   // Load key low
            1'b1: des_key[63:32] <= {des_key[63:48], SW[15:0]};   // Load key high
        endcase
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

// Hex to 7-segment decoder
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
