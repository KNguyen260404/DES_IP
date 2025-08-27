module DES_DecipherAndKey_Controller(input wire rst_n,
                                     input wire clk,
                                     input wire des_encipher_en,
                                     input wire des_decipher_en,
                                     input wire encipher_process,
                                     input wire k16_complete,
                                     output reg decipher_process,
                                     output reg key_process,
                                     output wire desc_ready);
  reg k16_calculation;
  always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      decipher_process <= 1'b0;
    end
    else if(k16_complete &(~encipher_process)) begin
      if (k16_calculation) begin
        decipher_process <= 1'b1;
      end
      else begin
        decipher_process <= 1'b0;
      end
    end
    else begin
      decipher_process <= decipher_process;
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      key_process <= 1'b0;
    end
    else if (des_encipher_en|des_decipher_en) begin
      key_process <= 1'b1;
    end
    else if ((encipher_process | decipher_process) & k16_complete) begin
      key_process <= 1'b0;
    end
    else begin
      key_process <= key_process;
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      k16_calculation <= 1'b0;
    end
    else begin
      k16_calculation <= (~encipher_process)&(~decipher_process)&(key_process);
    end
  end
  
  assign desc_ready = (~key_process) & (~encipher_process);
endmodule
