module prioritized_round_robin #(
  parameter int REQUEST_WIDTH   = 1,
  parameter int PRIORITY_WIDTH  = 1
)(
  input   var                                         i_clk,
  input   var                                         i_rst_n,
  input   var [REQUEST_WIDTH-1:0][PRIORITY_WIDTH-1:0] i_priority,
  input   var [REQUEST_WIDTH-1:0]                     i_request,
  output  var [REQUEST_WIDTH-1:0]                     o_grant
);
  localparam  int INDEX_WIDTH   = (REQUEST_WIDTH == 1) ? 1 : $clog2(REQUEST_WIDTH);
  localparam  int COMPARE_WIDTH = 1 + PRIORITY_WIDTH + 1;
  localparam  int VALUE_WIDTH   = INDEX_WIDTH + COMPARE_WIDTH;

  logic [REQUEST_WIDTH-1:0][VALUE_WIDTH-1:0]  compare_value;
  logic [VALUE_WIDTH-1:0]                     compare_result;
  logic [REQUEST_WIDTH-1:0]                   grant_mask;
  logic [INDEX_WIDTH-1:0]                     current_grant;

  always_comb begin
    o_grant = i_request & grant_mask;
  end

  always_comb begin
    for (int i = 0;i < REQUEST_WIDTH;++i) begin
      compare_value[i]  = {
        INDEX_WIDTH'(i), i_request[i], i_priority[i], (INDEX_WIDTH'(i) > current_grant)
      };
    end
  end

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      current_grant <= INDEX_WIDTH'(0);
    end
    else if (i_request != '0) begin
      current_grant <= compare_result[COMPARE_WIDTH+:INDEX_WIDTH];
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
endmodule
