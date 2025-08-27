module DES_Encipher_Controller(input wire rst_n,
                               input wire clk,
                               input wire rkey_sel,
                               input wire des_encipher_en,
                               output reg encipher_process);
  reg encipher_en_sync;
  always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      encipher_en_sync <= 1'b0;
    end
    else begin
      encipher_en_sync <= des_encipher_en;
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      encipher_process <= 1'b0;
    end
    else if (encipher_en_sync) begin
      encipher_process <= 1'b1;
    end
    else if (~rkey_sel) begin
      encipher_process <= 1'b0;
    end
    else begin
      encipher_process <= encipher_process;
    end
  end
endmodule