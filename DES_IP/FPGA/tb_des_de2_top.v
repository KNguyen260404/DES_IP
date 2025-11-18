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
reg [63:0] expected_result;
integer test_count;
integer pass_count;
integer fail_count;

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
        repeat(10) @(posedge CLOCK_50);
        KEY[button_num+1] = 1'b1;  // Release
        repeat(10) @(posedge CLOCK_50);
    end
endtask

// Task to wait for DES ready
task wait_ready;
    integer timeout;
    begin
        timeout = 0;
        while (LEDG[8] != 1'b1 && timeout < 10000) begin
            @(posedge CLOCK_50);
            timeout = timeout + 1;
        end
        if (timeout >= 10000) begin
            $display("ERROR: Timeout waiting for DES ready signal!");
        end
    end
endtask

// Task to wait for DES busy (processing)
task wait_busy;
    integer timeout;
    begin
        timeout = 0;
        while (LEDG[8] == 1'b1 && timeout < 10000) begin
            @(posedge CLOCK_50);
            timeout = timeout + 1;
        end
        if (timeout >= 10000) begin
            $display("ERROR: Timeout waiting for DES to start processing!");
        end
    end
endtask

// Task to load 64-bit data in 4x16-bit chunks
task load_data;
    input [63:0] data;
    begin
        $display("[INFO] Loading data: 0x%h", data);
        
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
        
        repeat(20) @(posedge CLOCK_50);
    end
endtask

// Task to perform encryption
task encrypt;
    begin
        $display("[INFO] Starting encryption...");
        wait_ready();
        press_button(0);  // Press KEY[1] for encryption
        wait_busy();      // Wait for processing to start
        wait_ready();     // Wait for completion
        $display("[INFO] Encryption complete. Result: 0x%h", uut.des_result);
    end
endtask

// Task to perform decryption
task decrypt;
    begin
        $display("[INFO] Starting decryption...");
        wait_ready();
        press_button(1);  // Press KEY[2] for decryption
        wait_busy();      // Wait for processing to start
        wait_ready();     // Wait for completion
        $display("[INFO] Decryption complete. Result: 0x%h", uut.des_result);
    end
endtask

// Task to verify result
task verify_result;
    input [63:0] expected;
    input [255:0] test_name;
    begin
        test_count = test_count + 1;
        if (uut.des_result === expected) begin
            $display("[PASS] Test %0d: %s", test_count, test_name);
            $display("       Expected: 0x%h", expected);
            $display("       Got:      0x%h", uut.des_result);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test %0d: %s", test_count, test_name);
            $display("       Expected: 0x%h", expected);
            $display("       Got:      0x%h", uut.des_result);
            fail_count = fail_count + 1;
        end
        $display("");
    end
endtask

// Main test sequence
initial begin
    $dumpfile("tb_des_de2_top.vcd");
    $dumpvars(0, tb_des_de2_top);
    
    // Initialize counters
    test_count = 0;
    pass_count = 0;
    fail_count = 0;
    
    // Initialize inputs
    KEY = 4'b1111;  // All buttons released (active low)
    SW = 18'h00000;
    
    $display("");
    $display("================================================================================");
    $display("                    DES DE2 Board Testbench");
    $display("================================================================================");
    $display("");
    
    // Reset sequence
    $display("[INFO] Applying reset...");
    KEY[0] = 1'b0;
    repeat(50) @(posedge CLOCK_50);
    KEY[0] = 1'b1;
    repeat(30) @(posedge CLOCK_50);
    $display("[INFO] Reset complete");
    $display("");
    
    //==========================================================================
    // Test 1: Standard DES Test Vector
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 1: Standard DES Test Vector");
    $display("--------------------------------------------------------------------------------");
    test_data = 64'h0123456789ABCDEF;
    test_key  = 64'h133457799BBCDFF1;
    expected_result = 64'h85E813540F0AB405;
    
    $display("[INFO] Plaintext: 0x%h", test_data);
    $display("[INFO] Key:       0x%h", test_key);
    $display("[INFO] Expected:  0x%h", expected_result);
    
    load_data(test_data);
    encrypt();
    verify_result(expected_result, "Standard DES Encryption");
    
    //==========================================================================
    // Test 2: Decrypt back to original
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 2: Decrypt Ciphertext Back to Plaintext");
    $display("--------------------------------------------------------------------------------");
    expected_result = test_data;
    load_data(64'h85E813540F0AB405);
    decrypt();
    verify_result(expected_result, "DES Decryption to Original");
    
    //==========================================================================
    // Test 3: All Zeros
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 3: All Zeros Plaintext");
    $display("--------------------------------------------------------------------------------");
    test_data = 64'h0000000000000000;
    test_key  = 64'h133457799BBCDFF1;
    expected_result = 64'h8CA64DE9C1B123A7;  // Known result for this key
    
    $display("[INFO] Plaintext: 0x%h", test_data);
    $display("[INFO] Key:       0x%h", test_key);
    
    load_data(test_data);
    encrypt();
    $display("[INFO] Result stored for verification");
    $display("");
    
    //==========================================================================
    // Test 4: All Ones
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 4: All Ones Plaintext");
    $display("--------------------------------------------------------------------------------");
    test_data = 64'hFFFFFFFFFFFFFFFF;
    test_key  = 64'h133457799BBCDFF1;
    
    $display("[INFO] Plaintext: 0x%h", test_data);
    $display("[INFO] Key:       0x%h", test_key);
    
    load_data(test_data);
    encrypt();
    $display("[INFO] Result stored for verification");
    $display("");
    
    //==========================================================================
    // Test 5: Known Test Vector 2
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 5: NIST Test Vector");
    $display("--------------------------------------------------------------------------------");
    test_data = 64'h0000000000000000;
    test_key  = 64'h0000000000000000;
    expected_result = 64'h8CA64DE9C1B123A7;
    
    $display("[INFO] Plaintext: 0x%h", test_data);
    $display("[INFO] Key:       0x%h", test_key);
    
    load_data(test_data);
    encrypt();
    verify_result(expected_result, "NIST Test Vector");
    
    //==========================================================================
    // Test 6: Encrypt-Decrypt Round Trip
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 6: Encrypt-Decrypt Round Trip Test");
    $display("--------------------------------------------------------------------------------");
    test_data = 64'hDEADBEEFCAFEBABE;
    test_key  = 64'h0123456789ABCDEF;
    
    $display("[INFO] Original:  0x%h", test_data);
    
    load_data(test_data);
    encrypt();
    $display("[INFO] Encrypted: 0x%h", uut.des_result);
    
    // Store encrypted result
    expected_result = uut.des_result;
    
    // Decrypt it back
    load_data(expected_result);
    decrypt();
    verify_result(test_data, "Round Trip Encrypt-Decrypt");
    
    //==========================================================================
    // Test 7: Multiple Sequential Operations
    //==========================================================================
    $display("--------------------------------------------------------------------------------");
    $display("Test 7: Sequential Operations Test");
    $display("--------------------------------------------------------------------------------");
    
    test_data = 64'h0011223344556677;
    load_data(test_data);
    encrypt();
    $display("[INFO] Encrypt #1: 0x%h", uut.des_result);
    
    test_data = 64'h8899AABBCCDDEEFF;
    load_data(test_data);
    encrypt();
    $display("[INFO] Encrypt #2: 0x%h", uut.des_result);
    
    test_data = 64'hFEDCBA9876543210;
    load_data(test_data);
    encrypt();
    $display("[INFO] Encrypt #3: 0x%h", uut.des_result);
    $display("[INFO] Sequential operations completed");
    $display("");
    
    //==========================================================================
    // Test Summary
    //==========================================================================
    repeat(50) @(posedge CLOCK_50);
    
    $display("================================================================================");
    $display("                         TEST SUMMARY");
    $display("================================================================================");
    $display("Total Tests:  %0d", test_count);
    $display("Passed:       %0d", pass_count);
    $display("Failed:       %0d", fail_count);
    $display("Success Rate: %0d%%", (pass_count * 100) / test_count);
    $display("================================================================================");
    
    if (fail_count == 0) begin
        $display("");
        $display("   ██████╗  █████╗ ███████╗███████╗");
        $display("   ██╔══██╗██╔══██╗██╔════╝██╔════╝");
        $display("   ██████╔╝███████║███████╗███████╗");
        $display("   ██╔═══╝ ██╔══██║╚════██║╚════██║");
        $display("   ██║     ██║  ██║███████║███████║");
        $display("   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝");
        $display("");
        $display("         ALL TESTS PASSED!");
        $display("");
    end else begin
        $display("");
        $display("   ███████╗ █████╗ ██╗██╗     ");
        $display("   ██╔════╝██╔══██╗██║██║     ");
        $display("   █████╗  ███████║██║██║     ");
        $display("   ██╔══╝  ██╔══██║██║██║     ");
        $display("   ██║     ██║  ██║██║███████╗");
        $display("   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝");
        $display("");
        $display("    SOME TESTS FAILED!");
        $display("");
    end
    $display("================================================================================");
    
    repeat(100) @(posedge CLOCK_50);
    $finish;
end

// Timeout watchdog
initial begin
    #100000000;  // 100ms timeout
    $display("");
    $display("================================================================================");
    $display("ERROR: SIMULATION TIMEOUT!");
    $display("Test took longer than expected. Possible issues:");
    $display("  - DES core stuck in processing");
    $display("  - Ready signal not asserting");
    $display("  - Clock or reset issues");
    $display("================================================================================");
    $finish;
end

endmodule
