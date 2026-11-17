module QK_matmul #(parameter DEPTH = 64, parameter QUERY_FILE = "", parameter KEY_FILE = "")
(
  input wire clk,
  // Ignore Reset for now
  input wire rst,

  input wire ready,

  output reg signed [22:0] s,
  output reg valid,

  output reg [$clog2(DEPTH)-1:0] j_out,
  output reg valid_row,
  output reg done
);

reg [$clog2(DEPTH)-1:0] i = 0;
reg [$clog2(DEPTH)-1:0] j = 0;
reg [$clog2(DEPTH)-1:0] k = 0;

// $readmemh("file_name", memory_array [, start_address [, end_address]]);
reg signed [7:0] Q [0:DEPTH*DEPTH-1];
reg signed [7:0] KT [0:DEPTH*DEPTH-1];

// Entries
reg signed [7:0] q;
reg signed [7:0] kt;

initial begin
  $readmemh(QUERY_FILE, Q);
  $readmemh(KEY_FILE, KT);
end

reg signed [22:0] sum;

reg running = 0;

reg first_d = 0;
reg last_d  = 0;
reg vld_d   = 0;

reg [$clog2(DEPTH)-1:0] j_out_d = 0;
reg valid_row_d = 0;

wire signed [22:0] acc = first_d ? q * kt : sum + q * kt;

always @(posedge clk or posedge rst) begin
  if (rst) begin
    i <= 0;
    j <= 0;
    k <= 0;

    vld_d   <= 0;

    running <= 0;
    done <= 0;

    valid <= 0;
    valid_row <= 0;
  end 

  else begin
    valid <= 0;
    valid_row <= 0;

    if (ready && !done) begin
      running <= 1;
    end

    if (running) begin
      // Calculate the Indexes
      if (k == DEPTH - 1) begin
        k <= 0;
        if (j == i) begin
          j <= 0;
          if (i == DEPTH - 1) begin
            // Calculations Finished
            i <= 0;

            running <= 0;
            done <= 1;
          end else begin
            i <= i + 1;
          end
        end else begin
          j <= j + 1;
        end
      end else begin
        k <= k + 1;
      end
    end


    // Step 2: Load Data
    q <= Q[i*DEPTH + k];
    kt <= KT[k*DEPTH + j];

    first_d <= (k == 0);
    last_d  <= (k == DEPTH - 1);
    vld_d   <= running;

    j_out_d     <= j;
    valid_row_d <= (j == i);

    // Step 3: Multiply & Store S
    if (vld_d) begin
      sum <= acc;
      if (last_d) begin
        s <= acc;
        valid <= 1;
        j_out <= j_out_d;
        valid_row <= valid_row_d;
      end
    end
  end
end

endmodule