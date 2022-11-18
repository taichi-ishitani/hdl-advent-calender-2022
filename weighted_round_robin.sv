module weighted_round_robin #(
  parameter int                                       REQUEST_WIDTH   = 1,
  parameter int                                       GRANT_WIDTH     = (REQUEST_WIDTH == 1) ? 1 : $clog2(REQUEST_WIDTH),
  parameter int                                       WEIGHT_WIDTH    = 1,
  parameter bit [REQUEST_WIDTH-1:0][WEIGHT_WIDTH-1:0] WEIGHT          = '1,
  parameter int                                       PENDING_CYCLES  = 32
)(
  input   var                     i_clk,
  input   var                     i_rst_n,
  input   var [REQUEST_WIDTH-1:0] i_request,
  output  var [GRANT_WIDTH-1:0]   o_grant
);
  localparam  int COUNT_WIDTH = $clog2(PENDING_CYCLES);

  logic [REQUEST_WIDTH-1:0][1:0]              compare_value;
  logic [GRANT_WIDTH-1:0]                     grant;
  logic [GRANT_WIDTH-1:0]                     current_grant;
  logic [REQUEST_WIDTH-1:0][WEIGHT_WIDTH-1:0] weight;
  logic [REQUEST_WIDTH-1:0]                   weight_eq_0;
  logic [COUNT_WIDTH-1:0]                     pending_cycles;
  logic [REQUEST_WIDTH-1:0]                   request_weigh_eq_0;
  logic [REQUEST_WIDTH-1:0]                   request_weigh_gt_0;

  always_comb begin
    o_grant = grant;
  end

  always_comb begin
    for (int i = 0;i < REQUEST_WIDTH;++i) begin
      compare_value[i][1] = request_weigh_gt_0[i] || (request_weigh_eq_0[i] && (pending_cycles == COUNT_WIDTH'(0)));
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

  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      pending_cycles  <= COUNT_WIDTH'(PENDING_CYCLES - 1);
    end
    else if (i_request[grant]) begin
      pending_cycles  <= COUNT_WIDTH'(PENDING_CYCLES - 1);
    end
    else if ((request_weigh_gt_0 == '0) && (request_weigh_eq_0 != '0)) begin
      pending_cycles  <= pending_cycles - COUNT_WIDTH'(1);
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

  for (genvar i = 0;i < REQUEST_WIDTH;++i) begin : g_weight
    logic update_weight;

    always_comb begin
      request_weigh_eq_0[i] = i_request[i] && (weight[i] == WEIGHT_WIDTH'(0));
      request_weigh_gt_0[i] = i_request[i] && (weight[i] >= WEIGHT_WIDTH'(1));
      update_weight         = request_weigh_gt_0[i] && (grant == GRANT_WIDTH'(i));
      weight_eq_0[i]        = weight[i] == ((update_weight) ? WEIGHT_WIDTH'(1) : WEIGHT_WIDTH'(0));
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
