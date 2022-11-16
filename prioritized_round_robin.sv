module prioritized_round_robin #(
  parameter int REQUEST_WIDTH   = 1,
  parameter int GRANT_WIDTH     = (REQUEST_WIDTH == 1) ? 1 : $clog2(REQUEST_WIDTH),
  parameter int PRIORITY_WIDTH  = 1
)(
  input   var                                         i_clk,
  input   var                                         i_rst_n,
  input   var [REQUEST_WIDTH-1:0][PRIORITY_WIDTH-1:0] i_priority,
  input   var [REQUEST_WIDTH-1:0]                     i_request,
  output  var [GRANT_WIDTH-1:0]                       o_grant
);
  localparam  int COMPARE_VALUE_WIDTH = 1 + PRIORITY_WIDTH + 1;

  logic [REQUEST_WIDTH-1:0][COMPARE_VALUE_WIDTH-1:0]  compare_value;
  logic [GRANT_WIDTH-1:0]                             grant;
  logic [GRANT_WIDTH-1:0]                             current_grant;

  always_comb begin
    o_grant = grant;
  end

  always_comb begin
    for (int i = 0;i < REQUEST_WIDTH;++i) begin
      compare_value[i]  = {i_request[i], i_priority[i], (GRANT_WIDTH'(i) > current_grant)};
    end
  end

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      current_grant <= GRANT_WIDTH'(0);
    end
    else if (i_request != '0) begin
      current_grant <= grant;
    end
  end

  max_finder #(
    .VALUE_WIDTH  (COMPARE_VALUE_WIDTH  ),
    .N            (REQUEST_WIDTH        ),
    .INDEX_WIDTH  (GRANT_WIDTH          )
  ) u_max_finder (
    .i_value  (compare_value  ),
    .o_result (grant          )
  );
endmodule
