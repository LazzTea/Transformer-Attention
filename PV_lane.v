module pv_lane #(parameter SW = 23)
(
  input wire clk,
  input wire rst,

  input wire signed [7:0] p,
  input wire signed [7:0] v,

  input reg signed [SW-1:0] pv,
  output reg valid
);

reg signed [SW-1:0] sum;

wire signed [SW-1] 

always @(posedge clk or posedge rst) begin
  if (rst) begin
  end

  else begin
    // Step 3: Multiply & Store PV
    pv <= p*v;
  end
end