`timescale 1ns/1ps

module tb_des_de2_top;

// Inputs
reg         CLOCK_50;
reg [3:0]   KEY;
reg [17:0]  SW;

// Outputs
wire [17:0] LEDR;
wire [8:0]  LEDG;
wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

// Test vectors
reg [63:0] test_data;
reg [63:0] test_key;
reg [63:0] expected_encrypted;

// Instantiate the Unit Under Test (UUT)
des_de2_top uut (
    .CLOCK_50   (CLOCK_50),
    .KEY        (KEY),
    .SW         (SW),
    .LEDR       (LEDR),
    .LEDG       (LEDG),
    .HEX0       (HEX0),
    .HEX1       (HEX1),
    .HEX2       (HEX2),
    .HEX3       (HEX3),
    .HEX4       (HEX4),
    .HEX5       (HEX5),
    .HEX6       (HEX6),
    .HEX7       (HEX7)
);

// Clock generation - 50MHz (20ns period)
initial begin
    CLOCK_50 = 0;
    forever #10 CLOCK_50 = ~CLOCK_50;
end

// Task to press and release a button
task press_button;
    input [1:0] button_num;
    begin
        KEY[button_num+1] = 1'b0;  // Press (active low)
        repeat(5) @(posedge CLOCK_50);
        KEY[button_num+1] = 1'b1;  // Release
        repeat(5) @(posedge CLOCK_50);
    end
endtask

// Task to wait for DES ready
task wait_ready;
    begin
        wait(LEDG[8] == 1'b1);  // Wait for ready signal
        $display("Time=%0t: DES Ready", $time);
    end
endtask

// Task to load 64-bit data in 4x16-bit chunks
task load_data;
    input [63:0] data;
    begin
        $display("Time=%0t: Loading data: %h", $time, data);
        
        // Load data[15:0]
        SW = {2'b00, data[15:0]};
        press_button(2);
        
        // Load data[31:16]
        SW = {2'b01, data[31:16]};
        press_button(2);
        
        // Load data[47:32]
        SW = {2'b10, data[47:32]};
        press_button(2);
        
        // Load data[63:48]
        SW = {2'b11, data[63:48]};
        press_button(2);
    end
endtask

// Task to perform encryption
task encrypt;
    begin
        $display("Time=%0t: Starting encryption...", $time);
        press_button(0);  // Press KEY[1] for encryption
        wait_ready();
        $display("Time=%0t: Encryption complete. Result: %h", $time, 
                 {uut.des_result[31:0], uut.des_result[63:32]});
    end
endtask

// Task to perform decryption
task decrypt;
    begin
        $display("Time=%0t: Starting decryption...", $time);
        press_button(1);  // Press KEY[2] for decryption
        wait_ready();
        $display("Time=%0t: Decryption complete. Result: %h", $time, 
                 {uut.des_result[31:0], uut.des_result[63:32]});
    end
endtask

// Main test sequence
initial begin
    $dumpfile("tb_des_de2_top.vcd");
    $dumpvars(0, tb_des_de2_top);
    
    // Initialize inputs
    KEY = 4'b1111;  // All buttons released (active low)
    SW = 18'h00000;
    
    // Test case 1: Standard DES test vector
    test_data = 64'h0123456789ABCDEF;
    test_key  = 64'h133457799BBCDFF1;
    expected_encrypted = 64'h85E813540F0AB405;
    
    $display("========================================");
    $display("DES DE2 Board Testbench");
    $display("========================================");
    $display("Test Vector:");
    $display("  Plaintext:  %h", test_data);
    $display("  Key:        %h", test_key);
    $display("  Expected:   %h", expected_encrypted);
    $display("========================================");
    
    // Reset
    $display("\nTime=%0t: Asserting reset...", $time);
    KEY[0] = 1'b0;
    repeat(20) @(posedge CLOCK_50);
    KEY[0] = 1'b1;
    repeat(10) @(posedge CLOCK_50);
    $display("Time=%0t: Reset released", $time);
    
    // The default data and key are already loaded
    // Test with default values first
    $display("\n--- Test 1: Encryption with default values ---");
    encrypt();
    
    $display("\n--- Test 2: Decryption ---");
    decrypt();
    
    // Load custom test data
    $display("\n--- Test 3: Load custom data and encrypt ---");
    load_data(test_data);
    encrypt();
    
    // Check result
    if (uut.des_result == expected_encrypted) begin
        $display("\n*** TEST PASSED! ***");
        $display("Encrypted result matches expected value!");
    end else begin
        $display("\n*** TEST FAILED! ***");
        $display("Expected: %h", expected_encrypted);
        $display("Got:      %h", uut.des_result);
    end
    
    // Decrypt the encrypted data
    $display("\n--- Test 4: Decrypt encrypted data ---");
    load_data(uut.des_result);
    decrypt();
    
    // Check if we get back original data
    if (uut.des_result == test_data) begin
        $display("\n*** DECRYPTION TEST PASSED! ***");
        $display("Decrypted result matches original plaintext!");
    end else begin
        $display("\n*** DECRYPTION TEST FAILED! ***");
        $display("Expected: %h", test_data);
        $display("Got:      %h", uut.des_result);
    end
    
    // Test case 2: All zeros
    $display("\n--- Test 5: All zeros ---");
    test_data = 64'h0000000000000000;
    load_data(test_data);
    encrypt();
    
    // Test case 3: All ones
    $display("\n--- Test 6: All ones ---");
    test_data = 64'hFFFFFFFFFFFFFFFF;
    load_data(test_data);
    encrypt();
    
    $display("\n========================================");
    $display("Testbench completed");
    $display("========================================");
    
    repeat(100) @(posedge CLOCK_50);
    $finish;
end

// Monitor for debugging
initial begin
    $monitor("Time=%0t | Ready=%b | Enc_en=%b | Dec_en=%b | Result=%h", 
             $time, LEDG[8], LEDG[7], LEDG[6], uut.des_result);
end

// Timeout watchdog
initial begin
    #50000000;  // 50ms timeout
    $display("\n*** TIMEOUT! Test took too long ***");
    $finish;
end

endmodule
