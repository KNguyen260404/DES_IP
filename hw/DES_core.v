// Code your design here
`include "PC1.v"
`include "PC2.v"
`include "IP.v"
`include "E_Permutation.v"
`include "S_Box.v"
`include "P_Permutation.v"
`include "Inverse_IP.v"
`include "DES_Counter.v"
`include "DES_DecipherAndKey_Controller.v"
`include "DES_Encipher_Controller.v"
module DES_core(
  input wire clk,
  input wire rst_n,
  input wire des_encipher_en,
  input wire des_decipher_en,
  input wire [63:0] des_data,
  input wire [63:0] des_key_in,
  
  output wire desc_ready,
  output wire [63:0] desc_result 

);
  wire [31:0]l0;
  wire [31:0]r0;
  reg [31:0]ln;
  reg [31:0]rn;
  wire lr_sel;
  wire encipher_process;
  wire [3:0] rcounter;
  wire rkey_sel;
  wire [31:0]l_input;
  wire [31:0]r_input;
  wire [47:0]round_key;
  wire [47:0]re;
  wire [47:0]re_xor_key;
  wire [31:0]p_in;
  wire [31:0]f_value;
  wire decipher_process;
  wire [63:0]inv_ip_input;
  wire [27:0]c0;
  wire [27:0]d0;
  reg [27:0]cn;
  reg [27:0]dn;
  wire [27:0]cin;
  wire [27:0]din;
  wire shift_left1;
  wire shift_right1;
  wire key_process;
  wire [55:0]cn_dn;
  wire k16_complete;
  //-------------------------------------------------------------------------
  //|                              DES_DataEncryption                       |
  //-------------------------------------------------------------------------
  
  //1.---------Initial_Permutation----------
  IP dut_ip(.des_data(des_data), .l0(l0), .r0(r0));
  assign lr_sel=(encipher_process)?(rcounter==4'd1):(~rkey_sel);
  assign l_input = (lr_sel)? l0: ln;
  assign r_input = (lr_sel)? r0: rn;
  //2.---------E-Permutation----------------
  E_Permutation dut_etable(.r_input(r_input), .re(re));
  //*After E-Table, we XOR re with Round Key
  assign re_xor_key = re^round_key;
  //3.-------------S-Box--------------------
  S_Box dut_sbox(.re_xor_key(re_xor_key), .p_in(p_in));
  //4.---------P-Permutation----------------
  P_Permutation dut_ptable(.p_in(p_in), .f_value(f_value));
  always@(posedge clk) begin
    if (encipher_process | decipher_process) begin
      ln <=  r_input;
      rn <= (l_input^f_value);
    end
    else begin
      ln <= ln;
      rn <= rn;
    end
  end
  assign inv_ip_input = {rn,ln};
  Inverse_IP dut_inv_ip(.inv_ip_input(inv_ip_input), .desc_result(desc_result));
  //-------------------------------------------------------------------------------
  //|                            Key Schedule Calculation                         |
  //-------------------------------------------------------------------------------
  
  //1.---------Permutation Choice 1---------
  PC1 dut_pc1(.des_key_in(des_key_in), .c0(c0), .d0(d0));
  assign cin=(rkey_sel|decipher_process)?cn:c0;
  assign din=(rkey_sel|decipher_process)?dn:d0;
  always@(posedge clk)	begin: shift
    if(decipher_process)	begin
      if(shift_right1)	begin
        cn	<= {cin[0], cin[27:1]};
		dn	<= {din[0], din[27:1]};
      end
      else	begin
        cn	<= {cin[1:0], cin[27:2]};
		dn	<= {din[1:0], din[27:2]};
      end
    end
      else	begin
        if(key_process)	begin
          if(shift_left1)	begin
            cn	<= {cin[26:0], cin[27]};
			dn	<= {din[26:0], din[27]};
          end
          else	begin
            cn	<= {cin[25:0], cin[27:26]};
			dn	<= {din[25:0], din[27:26]};
          end
        end
        else begin
          cn<=cn;
          dn<=dn;
        end
      end
  end
  assign	cn_dn	= {cn, dn};
  //3.---------Permutation Choice 2----------
  PC2 dut_pc2(.cn_dn(cn_dn), .round_key(round_key));
  //----------------------------------------------------------------------
  //|                              DES Controller                        |
  //----------------------------------------------------------------------
  
  //1.----------DES Counter-----------
  DES_Counter dut_counter(.rst_n(rst_n), .clk(clk), .key_process(key_process), .rcounter(rcounter), .rkey_sel(rkey_sel), .shift_left1(shift_left1), .shift_right1(shift_right1), .k16_complete(k16_complete));
  //2.----------DES_DecipherAndKey_Controller---------
  DES_DecipherAndKey_Controller dut_decipherkey(.rst_n(rst_n), .clk(clk), .des_encipher_en(des_encipher_en), .des_decipher_en(des_decipher_en), .encipher_process(encipher_process), .k16_complete(k16_complete), .decipher_process(decipher_process), .key_process(key_process), .desc_ready(desc_ready));
  //3.---------DES_Encipher_controller----------
  DES_Encipher_Controller dut_enciphercontroll(.rst_n(rst_n), .clk(clk), .rkey_sel(rkey_sel), .des_encipher_en(des_encipher_en), .encipher_process(encipher_process));
endmodule
