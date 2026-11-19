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

reg [8*LANES-1:0] V [0:D*GROUPS-1];

reg [8*LANES-1:0] v;

reg [31:0] p_sum = 0;

initial begin
  $readmemh(VALUE_FILE, V);
end

reg running = 0;

reg first_d = 0;
reg last_d = 0;
reg vld_d = 0;

integer b;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    i <= 0;
    g <= 0;
    k <= 0;

    vld_d <= 0;
    running <= 0;
    done <= 0;
  end else begin
    if (ready) begin
      // Step 2: Load Data
      v <= V[k*GROUPS + g];

      // Step 3: Multiply & Store PV
    end
  end
end

genvar l;
generate
  for (l = 0; l < LANES; l = l + 1) begin : lane
    pv_lane #(.SW(SW)) u_lane (
      .clk(clk),
      .rst(rst),

      .p(p),
      .v(v[8*l +: 8]),

      .pv(o_acc[SW*l +: SW]),
      .valid(p_valid[l])
    );
  end
endgenerate

endmodule