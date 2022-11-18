module max_finder_unit #(
  parameter int VALUE_WIDTH   = 1,
  parameter int COMPARE_WIDTH = VALUE_WIDTH,
  parameter int TOTAL_N       = 1,
  parameter int CURRENT_N     = TOTAL_N,
  parameter int STEP          = 1
)(
  input   var [CURRENT_N-1:0][VALUE_WIDTH-1:0]  i_value,
  input   var [TOTAL_N-1:0]                     i_location,
  output  var [VALUE_WIDTH-1:0]                 o_value,
  output  var [TOTAL_N-1:0]                     o_location
);
  localparam  int NEXT_N  = (CURRENT_N / 2) + (CURRENT_N % 2);

  logic [NEXT_N-1:0][1:0]             compare_result;
  logic [NEXT_N-1:0][VALUE_WIDTH-1:0] value_next;
  logic [TOTAL_N-1:0]                 location_next;

  always_comb begin
    for (int i = 0;i < NEXT_N;++i) begin
      if ((i == (NEXT_N - 1) && ((CURRENT_N % 2) == 1))) begin
        compare_result[i] = 2'b01;
      end
      else begin
        compare_result[i] = do_compare(i_value[2*i+0], i_value[2*i+1]);
      end

      if (compare_result[i][0]) begin
        value_next[i] = i_value[2*i+0];
      end
      else begin
        value_next[i] = i_value[2*i+1];
      end

      for (int j = 0;j < (2 * STEP);++j) begin
        if (((2 * STEP * i) + j) < TOTAL_N) begin
          location_next[2*STEP*i+j] = compare_result[i][j/STEP] && i_location[2*STEP*i+j];
        end
      end
    end
  end

  function automatic logic [1:0] do_compare(
    logic [VALUE_WIDTH-1:0] lhs,
    logic [VALUE_WIDTH-1:0] rhs
  );
    if (lhs[0+:COMPARE_WIDTH] >= rhs[0+:COMPARE_WIDTH]) begin
      return 2'b01;
    end
    else begin
      return 2'b10;
    end
  endfunction

  if (NEXT_N == 1) begin : g
    always_comb begin
      o_value     = value_next[0];
      o_location  = location_next;
    end
  end
  else begin : g
    max_finder_unit #(
      .VALUE_WIDTH    (VALUE_WIDTH    ),
      .COMPARE_WIDTH  (COMPARE_WIDTH  ),
      .TOTAL_N        (TOTAL_N        ),
      .CURRENT_N      (NEXT_N         ),
      .STEP           (2 * STEP       )
    ) u_max_finder (
      .i_value    (value_next   ),
      .i_location (location_next),
      .o_value    (o_value      ),
      .o_location (o_location   )
    );
  end
endmodule

module max_finder #(
  parameter int N             = 1,
  parameter int VALUE_WIDTH   = 1,
  parameter int COMPARE_WIDTH = VALUE_WIDTH
)(
  input   var [N-1:0][VALUE_WIDTH-1:0]  i_value,
  output  var [VALUE_WIDTH-1:0]         o_value,
  output  var [N-1:0]                   o_location
);
  max_finder_unit #(
    .VALUE_WIDTH    (VALUE_WIDTH    ),
    .COMPARE_WIDTH  (COMPARE_WIDTH  ),
    .TOTAL_N        (N              ),
    .CURRENT_N      (N              ),
    .STEP           (1              )
  ) u_max_finder (
    .i_value    (i_value    ),
    .i_location ('1         ),
    .o_value    (o_value    ),
    .o_location (o_location )
  );
endmodule
