module max_finder_unit #(
  parameter int VALUE_WIDTH = 1,
  parameter int INDEX_WIDTH = 1,
  parameter int N           = 1
)(
  input   var [N-1:0][VALUE_WIDTH-1:0]  i_value,
  input   var [N-1:0][INDEX_WIDTH-1:0]  i_index,
  output  var [INDEX_WIDTH-1:0]         o_result
);
  localparam  int NEXT_N  = (N / 2) + (N % 2);

  logic [NEXT_N-1:0][VALUE_WIDTH-1:0] value_next;
  logic [NEXT_N-1:0][INDEX_WIDTH-1:0] index_next;

  always_comb begin
    for (int i = 0;i < NEXT_N;++i) begin
      if ((i == (NEXT_N - 1) && ((N % 2) == 1))) begin
        value_next[i] = i_value[2*i+0];
        index_next[i] = i_index[2*i+0];
      end
      else if (i_value[2*i+0] >= i_value[2*i+1]) begin
        value_next[i] = i_value[2*i+0];
        index_next[i] = i_index[2*i+0];
      end
      else begin
        value_next[i] = i_value[2*i+1];
        index_next[i] = i_index[2*i+1];
      end
    end
  end

  if (NEXT_N == 1) begin : g
    always_comb begin
      o_result  = index_next[0];
    end
  end
  else begin : g
    max_finder_unit #(
      .VALUE_WIDTH  (VALUE_WIDTH  ),
      .INDEX_WIDTH  (INDEX_WIDTH  ),
      .N            (NEXT_N       )
    ) u_max_finder (
      .i_value  (value_next ),
      .i_index  (index_next ),
      .o_result (o_result   )
    );
  end
endmodule

module max_finder #(
  parameter int VALUE_WIDTH = 1,
  parameter int N           = 1,
  parameter int INDEX_WIDTH = (N == 1) ? 1 : $clog2(N)
)(
  input   var [N-1:0][VALUE_WIDTH-1:0]  i_value,
  output  var [INDEX_WIDTH-1:0]         o_result
);
  logic [N-1:0][INDEX_WIDTH-1:0]  index;

  always_comb begin
    for (int i = 0;i < N;++i) begin
      index[i]  = INDEX_WIDTH'(i);
    end
  end

  max_finder_unit #(
    .VALUE_WIDTH  (VALUE_WIDTH  ),
    .INDEX_WIDTH  (INDEX_WIDTH  ),
    .N            (N            )
  ) u_max_finder (
    .i_value  (i_value  ),
    .i_index  (index    ),
    .o_result (o_result )
  );
endmodule
