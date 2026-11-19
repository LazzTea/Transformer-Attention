module PV_matmul (
  parameter N = 64,
  parameter D = 64,
  parameter LANES = 8,
  parameter VALUE_FILE = ""
)
(
  input wire clk,
  input wire rst,

  input wire ready,

  input wire [$clog2(N)-1:0] p_row,
  input wire [$clog2(N)-1:0] p_col [0:7],
  input wire [15:0] p[7:0],
  input wire p_valid [7:0],


  output wire [LANES*(17+$clog2(D))-1:0] o,
  output wire [LANES-1:0] valid,

  output reg done
);

localparam SW = 17 + $clog2(D);
localparam GROUPS = N / LANES;

reg [$clog2(N)-1:0] i = 0;
reg [$clog2(N)-1:0] g = 0;
reg [$clog2(D)-1:0] k = 0;

reg [D-1:0]   V [0:N-1];
reg [D*8-1:0] v [0:LANES-1];

reg [D*SW-1:0] pv [0:LANES-1];

reg [31:0] p_sum [0:7]= 0;

reg [SW:0]

initial begin
  $readmemh(VALUE_FILE, V);
end

reg running = 0;

integer i;
integer b;

always @(posedge clk or posedge rst) begin
  if (rst) begin
  end 
  
  else begin
    if (ready) begin
      // Load Data
      for (i = 0; i < 8; i = i + 1) begin
        v[i] <= V[p_col[i]];
      end

      if (!first) begin
        for (i = 0; i < 64; i = i + 1) begin
          o_acc[i] <= pv[0][SW:0] + 
        end
      end
    end
  end
end

genvar l;
generate
  for (l = 0; l < LANES; l = l + 1) begin : lane
    pv_lane #(.SW(SW)) u_lane (
      .clk(clk),

      .p(p[l]),
      .v(v[l]),

      .pv(pv[l])
    );
  end
endgenerate

endmodule