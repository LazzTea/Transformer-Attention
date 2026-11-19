module softmax #(
  parameter ROW_LENGTH = 64,
  parameter DEPTH = 64,
  parameter LANES = 8,
  parameter SCORE_WIDTH = 17 + $clog2(DEPTH)
) (
  input wire clk,
  input wire rst,

  input wire [LANES * SCORE_WIDTH - 1:0] qk_scores,
  input wire [LANES-1:0] qk_lane_valid,
  input wire [$clog2(ROW_LENGTH)-1:0] qk_column_start,
  input wire qk_row_end,

  output reg [17 * ROW_LENGTH - 1:0] probabilities,
  output reg probabilities_valid
);

reg signed [SCORE_WIDTH-1:0] row_scores [0:ROW_LENGTH-1];
reg [ROW_LENGTH-1:0] score_present;
integer lane_index;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    score_present <= 0;
    probabilities_valid <= 0;
  end else begin
    // start a fresh row after the last group
    if (probabilities_valid)
      score_present <= 0;

    for (lane_index = 0; lane_index < LANES; lane_index = lane_index + 1) begin
      if (qk_lane_valid[lane_index]) begin
        row_scores[qk_column_start + lane_index] <= qk_scores[SCORE_WIDTH * lane_index +: SCORE_WIDTH];
        score_present[qk_column_start + lane_index] <= 1;
      end
    end

    probabilities_valid <= qk_row_end;
  end
end

// regenerate the table if depth changes
`include "softmax_exp.vh"

reg signed [SCORE_WIDTH:0] max_score;
reg [16:0] exp_weights [0:ROW_LENGTH-1];
reg [16 + $clog2(ROW_LENGTH):0] weight_sum;
reg [32:0] numerator;
integer column_index;

always @* begin
  probabilities = 0;
  max_score = {1'b1, {SCORE_WIDTH{1'b0}}};
  weight_sum = 0;
  numerator = 0;

  // find the largest score among the valid columns
  for (column_index = 0; column_index < ROW_LENGTH; column_index = column_index + 1)
    if (score_present[column_index] && row_scores[column_index] > max_score)
      max_score = row_scores[column_index];

  // exponentiate each score minus the max and add up the weights
  for (column_index = 0; column_index < ROW_LENGTH; column_index = column_index + 1) begin
    exp_weights[column_index] = 0;
    if (score_present[column_index])
      exp_weights[column_index] = exp_score(max_score - row_scores[column_index]);
    weight_sum = weight_sum + exp_weights[column_index];
  end

  // divide each weight by the total to get its probability
  if (probabilities_valid && weight_sum != 0) begin
    for (column_index = 0; column_index < ROW_LENGTH; column_index = column_index + 1) begin
      numerator = exp_weights[column_index] * 65536; // if you dont scale first youll just get 0 from int division
      probabilities[17 * column_index +: 17] = numerator / weight_sum;
    end
  end
end

endmodule
