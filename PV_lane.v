module pv_lane #(
  parameter SW = 24,
  parameter D  = 64
) (
  input  wire              clk,
  input  wire              ready,

  input  wire [16:0]       p,
  input  wire [D*8-1:0]    v,

  output reg  [D*SW-1:0]   pv
);

integer i;

always @(posedge clk) begin
  if (ready) begin
    for (i = 0; i < D; i = i + 1)
      pv[SW*i +: SW] <= $signed({1'b0, p}) * $signed(v[8*i +: 8]);
  end
end

endmodule