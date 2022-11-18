module weighted_round_robin #(
  parameter int                                       REQUEST_WIDTH   = 1,
  parameter int                                       WEIGHT_WIDTH    = 1,
  parameter bit [REQUEST_WIDTH-1:0][WEIGHT_WIDTH-1:0] WEIGHT          = '1
)(
  input   var                     i_clk,
  input   var                     i_rst_n,
  input   var [REQUEST_WIDTH-1:0] i_request,
  output  var [REQUEST_WIDTH-1:0] o_grant
);
  localparam  int INDEX_WIDTH   = (REQUEST_WIDTH == 1) ? 1 : $clog2(REQUEST_WIDTH);
  localparam  int COMPARE_WIDTH = 3;
  localparam  int VALUE_WIDTH   = INDEX_WIDTH + COMPARE_WIDTH;

  logic [REQUEST_WIDTH-1:0][VALUE_WIDTH-1:0]  compare_value;
  logic [VALUE_WIDTH-1:0]                     compare_result;
  logic [REQUEST_WIDTH-1:0]                   grant_mask;
  logic [INDEX_WIDTH-1:0]                     current_grant;
  logic [REQUEST_WIDTH-1:0][WEIGHT_WIDTH-1:0] weight;
  logic [REQUEST_WIDTH-1:0]                   weight_eq_0;

  always_comb begin
    o_grant = i_request & grant_mask;
  end

  always_comb begin
    for (int i = 0;i < REQUEST_WIDTH;++i) begin
      compare_value[i][VALUE_WIDTH-1-:INDEX_WIDTH]  = INDEX_WIDTH'(i);
      compare_value[i][2]                           = i_request[i];
      compare_value[i][1]                           = weight[i] > WEIGHT_WIDTH'(0);
      compare_value[i][0]                           = INDEX_WIDTH'(i) > current_grant;
    end
  end

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      current_grant <= INDEX_WIDTH'(0);
    end
    else if (i_request != '0) begin
      current_grant <= compare_value[VALUE_WIDTH-1-:INDEX_WIDTH];
    end
  end

  max_finder #(
    .N              (REQUEST_WIDTH  ),
    .VALUE_WIDTH    (VALUE_WIDTH    ),
    .COMPARE_WIDTH  (COMPARE_WIDTH  )
  ) u_max_finder (
    .i_value    (compare_value  ),
    .o_value    (compare_result ),
    .o_location (grant_mask     )
  );

  for (genvar i = 0;i < REQUEST_WIDTH;++i) begin : g_weight
    logic update_weight;

    always_comb begin
      update_weight = i_request[i] && grant_mask[i] && (weight[i] > WEIGHT_WIDTH'(0));
      if (update_weight) begin
        weight_eq_0[i]  = weight[i] == WEIGHT_WIDTH'(1);
      end
      else begin
        weight_eq_0[i]  = weight[i] == WEIGHT_WIDTH'(0);
      end
    end

    always_ff @(posedge i_clk, negedge i_rst_n) begin
      if (!i_rst_n) begin
        weight[i] <= WEIGHT[i];
      end
      else if (weight_eq_0 == '1) begin
        weight[i] <= WEIGHT[i];
      end
      else if (update_weight) begin
        weight[i] <= weight[i] - WEIGHT_WIDTH'(1);
      end
    end
  end
endmodule
