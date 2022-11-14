module tb;
  timeunit  1ns/1ps;

  bit clk;
  bit rst_n;

  always #(500ps) begin
    clk = ~clk;
  end

  initial begin
    rst_n = '1;
    @(posedge clk);
    rst_n = '0;
    @(posedge clk);
    rst_n = '1;
  end

  logic [7:0]       request;
  logic [2:0]       grant;
  logic [15:0]      request_count;
  logic [7:0][15:0] grant_count;

  for (genvar i = 0;i < 8;++i) begin : g_request
    always @(posedge clk, negedge rst_n) begin
      if (!rst_n) begin
        request[i]  <= '0;
      end
      else if (grant_count[i] < 64) begin
        if (request[i] && (grant == i)) begin
          request[i]  <= '0;
        end
        else if ((!request[i]) && ($urandom_range(0, 2) == 2)) begin
          request[i]  <= '1;
        end
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      request_count <= 0;
      grant_count   <= '{default: 0};
    end
    else if (request != '0) begin
      request_count <= request_count + 1;
      for (int i = 0;i < 8;++i) begin
        if (request[i] && (grant == i)) begin
          grant_count[i]  <= grant_count[i] + 1;
          break;
        end
      end
    end
  end

  initial begin
    @(posedge rst_n);
    while (request_count < 256) begin
      @(posedge clk);
    end
    $finish;
  end

  round_robin #(
    .REQUEST_WIDTH  (8  )
  ) duv (
    .i_clk      (clk      ),
    .i_rst_n    (rst_n    ),
    .i_request  (request  ),
    .o_grant    (grant    )
  );
endmodule
