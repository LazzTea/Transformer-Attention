module qk_lane #(parameter SW = 23)
(
  input wire clk,
  input wire rst,

  input wire signed [7:0] q,
  input wire signed [7:0] kt,

  input wire first,
  input wire last,
  input wire vld,
  input wire mask,

  output reg signed [SW-1:0] s,
  output reg valid
);

reg signed [SW-1:0] sum;

wire signed [SW-1:0] acc = first ? q * kt : sum + q * kt;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    valid <= 0;
  end

  else begin
    valid <= 0;

    // Step 3: Multiply & Store S
    if (vld) begin
      sum <= acc;
      if (last) begin
        s <= acc;
        valid <= mask;
      end
    end
  end
end

endmodule