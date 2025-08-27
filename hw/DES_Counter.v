module DES_Counter (input wire rst_n,
                    input wire clk,
                    input wire key_process,
                    output reg [3:0]rcounter,
                    output wire rkey_sel,
                    output wire shift_left1,
                    output wire shift_right1,
                    output wire k16_complete);
  wire shift_left;
  always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rcounter <= 4'd0;
    end
    else if (key_process) begin
      rcounter <= rcounter + 1;
    end
    else begin
      rcounter <= rcounter;
    end
  end
  assign k16_complete = (&rcounter);
  assign rkey_sel = (|rcounter);
  assign shift_left =  k16_complete | (~rkey_sel);
  assign shift_left1 = shift_left | (rcounter == 4'd1) | (rcounter == 4'd8);
  assign shift_right1 = shift_left | (rcounter == 4'd7) | (rcounter == 4'd14);
endmodule
