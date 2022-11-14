module round_robin #(
  parameter int REQUEST_WIDTH = 1,
  parameter int GRANT_WIDTH   = (REQUEST_WIDTH == 1) ? 1 : $clog2(REQUEST_WIDTH)
)(
  input   var                     i_clk,
  input   var                     i_rst_n,
  input   var [REQUEST_WIDTH-1:0] i_request,
  output  var [GRANT_WIDTH-1:0]   o_grant
);
  logic [REQUEST_WIDTH-1:0][1:0]  compare_value;
  logic [GRANT_WIDTH-1:0]         grant;
  logic [GRANT_WIDTH-1:0]         current_grant;

  always_comb begin
    o_grant = grant;
  end

  always_comb begin
    for (int i = 0;i < REQUEST_WIDTH;++i) begin
      compare_value[i][1] = i_request[i];
      compare_value[i][0] = GRANT_WIDTH'(i) > current_grant;
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
    .VALUE_WIDTH  (2              ),
    .N            (REQUEST_WIDTH  ),
    .INDEX_WIDTH  (GRANT_WIDTH    )
  ) u_max_finder (
    .i_value  (compare_value  ),
    .o_result (grant          )
  );
endmodule
