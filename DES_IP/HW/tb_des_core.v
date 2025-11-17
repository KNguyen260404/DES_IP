`timescale 1ns/1ps

module	tb_des_core;
//
//inputs
//
reg		clk;
reg		rst_n;
reg		des_encipher_en;
reg		des_decipher_en;
reg	[63:0]	des_data;
reg	[63:0]	des_key_in;
//
//outputs
//
wire	[63:0]	desc_result;
wire		desc_ready;

integer	i;

des_core tb (/*AUTOARG*/
   // Outputs
   desc_result, desc_ready, 
   // Inputs
   clk, rst_n, des_encipher_en, des_decipher_en, des_data, des_key_in
   );
 initial
 	begin
 		$dumpfile("des_core.vcd");
 		$dumpvars(0, tb_des_core);
 		main;
 		#50000;
 		$finish;
 	end
 task main;
 	fork
 		clock;
 		reset;
 		input_driver;
 	join
 endtask
 task clock;
 	begin
 		clk	= 1'b0;
 		forever	#10 clk = ~clk;
 	end
 endtask
 task reset;
 	begin
 		rst_n	= 1'b0;
 		#100
 		rst_n	= 1'b1;
 	end
 endtask
 task input_driver;
 	begin
 		des_encipher_en	= 1'b0;
 		des_decipher_en	= 1'b0;
 		des_data	= 64'h1abff69d5a93e80b;
 		des_key_in	= 64'h0133457799BBCDFF;
 		#500
 		des_decipher_en	= 1'b1;
 		#20
 		des_decipher_en	= 1'b0;
 		for (i=0; i < 9; i = i+1) begin
 		wait (tb_des_core.tb.desc_ready == 1);
 		#1000
 			des_data	= des_data >> 1;
	 		des_key_in	= des_key_in >> 1;
	 		#500
	 		des_decipher_en	= 1'b1;
	 		#20
	 		des_decipher_en	= 1'b0;
	 	end
	 	#500
	 	des_data	= 64'h0123456789abcdef;
 		des_key_in	= 64'h0133457799BBCDFF;
 		#500
 		des_encipher_en	= 1'b1;
 		#20
 		des_encipher_en	= 1'b0;
 		for (i=0; i < 9; i = i+1) begin
 		wait (tb_des_core.tb.desc_ready == 1);
 		#1000
 			des_data	= des_data >> 1;
	 		des_key_in	= des_key_in >> 1;
	 		#500
	 		des_encipher_en	= 1'b1;
	 		#20
	 		des_encipher_en	= 1'b0;
	 	end
 	end
 endtask
 
endmodule