module QK_matmul #(
  parameter N = 64,
  parameter D = 64,
  parameter LANES = 8,
  parameter QUERY_FILE = "",
  parameter KEY_FILE = ""
)
(
  input wire clk,
  input wire rst,

  input wire ready,

  output wire [LANES*(17+$clog2(D))-1:0] s,
  output wire [LANES-1:0] valid,

  output reg [$clog2(N)-1:0] j_out,
  output reg valid_row,
  output reg done
);

localparam SW = 17 + $clog2(D);
localparam GROUPS = N / LANES;

reg [$clog2(N)-1:0] i = 0;
reg [$clog2(N)-1:0] g = 0;
reg [$clog2(D)-1:0] k = 0;

// Q:  N x D, one INT8 per entry, address i*D + k
// KT: D x GROUPS words, LANES INT8 per word, address k*GROUPS + g
//     byte b of the word is K[g*LANES + b][k]
reg signed [7:0] Q [0:N*D-1];
reg [8*LANES-1:0] KT [0:D*GROUPS-1];

// Entries
reg signed [7:0] q;
reg [8*LANES-1:0] kt;

initial begin
  $readmemh(QUERY_FILE, Q);
  $readmemh(KEY_FILE, KT);
end

reg running = 0;

reg first_d = 0;
reg last_d  = 0;
reg vld_d   = 0;
reg [LANES-1:0] mask_d = 0;

reg [$clog2(N)-1:0] j_out_d = 0;
reg valid_row_d = 0;

integer b;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    i <= 0;
    g <= 0;
    k <= 0;

    vld_d   <= 0;

    running <= 0;
    done <= 0;

    valid_row <= 0;
  end

  else begin
    valid_row <= 0;

    if (ready && !done) begin
      running <= 1;
    end

    if (running) begin
      // Calculate the Indexes
      if (k == D - 1) begin
        k <= 0;
        if (g == i / LANES) begin
          g <= 0;
          if (i == N - 1) begin
            // Calculations Finished
            i <= 0;

            running <= 0;
            done <= 1;
          end else begin
            i <= i + 1;
          end
        end else begin
          g <= g + 1;
        end
      end else begin
        k <= k + 1;
      end
    end


    // Step 2: Load Data
    q  <= Q[i*D + k];
    kt <= KT[k*GROUPS + g];

    first_d <= (k == 0);
    last_d  <= (k == D - 1);
    vld_d   <= running;

    for (b = 0; b < LANES; b = b + 1)
      mask_d[b] <= (g*LANES + b <= i);

    j_out_d     <= g * LANES;
    valid_row_d <= (g == i / LANES);

    // Step 3 is in the lanes; these outputs line up with them
    if (vld_d && last_d) begin
      j_out <= j_out_d;
      valid_row <= valid_row_d;
    end
  end
end

genvar l;
generate
  for (l = 0; l < LANES; l = l + 1) begin : lane
    qk_lane #(.SW(SW)) u_lane (
      .clk(clk),
      .rst(rst),

      .q(q),
      .kt(kt[8*l +: 8]),

      .first(first_d),
      .last(last_d),
      .vld(vld_d),
      .mask(mask_d[l]),

      .s(s[SW*l +: SW]),
      .valid(valid[l])
    );
  end
endgenerate

endmodule