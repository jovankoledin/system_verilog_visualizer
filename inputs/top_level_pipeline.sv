// Define an interface for data transfer
interface data_transfer_if (input bit clk, input bit rst);
  logic [7:0] data_in;
  logic       data_in_valid;
  logic [7:0] data_out;
  logic       data_out_valid;
  logic       ready_to_receive; // Backpressure signal

  modport master (output data_in, output data_in_valid, input ready_to_receive, input data_out, input data_out_valid);
  modport slave  (input data_in, input data_in_valid, output ready_to_receive, output data_out, output data_out_valid);
endinterface

// --- Module 1: Data Source ---
module data_source (
  input  bit            clk,
  input  bit            rst,
  data_transfer_if.master source_if
);

  int counter;

  initial begin
    counter = 0;
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      source_if.data_in <= '0;
      source_if.data_in_valid <= 1'b0;
      counter <= 0;
    end else begin
      if (source_if.ready_to_receive) begin
        source_if.data_in <= counter;
        source_if.data_in_valid <= 1'b1;
        counter <= counter + 1;
      end else begin
        source_if.data_in_valid <= 1'b0; // De-assert if not ready
      end
    end
  end

  // A simple function within the module
  function automatic int get_next_data(int current_val);
    return current_val + 1;
  endfunction

endmodule

// --- Module 2: Data Processor (Parameterized) ---
module data_processor #(parameter int ID = 0, parameter int DELAY = 1) (
  input  bit              clk,
  input  bit              rst,
  data_transfer_if.slave  proc_if
);

  logic [7:0] internal_data;
  logic       internal_data_valid;
  int         delay_counter;

  enum {IDLE, PROCESSING, OUTPUTTING} fsm_state;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      fsm_state <= IDLE;
      proc_if.ready_to_receive <= 1'b1;
      internal_data <= '0;
      internal_data_valid <= 1'b0;
      proc_if.data_out <= '0;
      proc_if.data_out_valid <= 1'b0;
      delay_counter <= 0;
    end else begin
      proc_if.ready_to_receive <= 1'b0; // Default to not ready unless in IDLE

      case (fsm_state)
        IDLE: begin
          proc_if.data_out_valid <= 1'b0; // Ensure output is not valid
          if (proc_if.data_in_valid) begin
            internal_data <= process_data_func(proc_if.data_in, ID);
            internal_data_valid <= 1'b1;
            fsm_state <= PROCESSING;
            delay_counter <= 0;
            proc_if.ready_to_receive <= 1'b0; // Not ready while processing
          end else begin
            proc_if.ready_to_receive <= 1'b1; // Ready to receive next data
          end
        end
        PROCESSING: begin
          if (delay_counter < DELAY - 1) begin
            delay_counter <= delay_counter + 1;
            fsm_state <= PROCESSING;
          end else begin
            fsm_state <= OUTPUTTING;
          end
        end
        OUTPUTTING: begin
          proc_if.data_out <= internal_data;
          proc_if.data_out_valid <= internal_data_valid;
          if (internal_data_valid && proc_if.data_out_valid) begin // Check if downstream accepted
            fsm_state <= IDLE;
            internal_data_valid <= 1'b0; // Consume internal data
          end
        end
      endcase
    end
  end

  // A combinational function for data processing
  function automatic logic [7:0] process_data_func(logic [7:0] data, int proc_id);
    return data + proc_id; // Simple processing: add ID
  endfunction

  // A task for more complex, multi-cycle operations (though here it's simple)
  task automatic do_complex_task(input logic [7:0] in_data, output logic [7:0] out_data);
    #1; // Simulate some delay
    out_data = in_data * 2;
  endtask

endmodule

// --- Module 3: Data Sink ---
module data_sink (
  input  bit            clk,
  input  bit            rst,
  data_transfer_if.slave sink_if
);

  int received_count;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      received_count <= 0;
      sink_if.ready_to_receive <= 1'b1;
    end else begin
      sink_if.ready_to_receive <= 1'b1; // Always ready to receive
      if (sink_if.data_out_valid) begin
        $display("Time %0t: Sink received data: %0d", $time, sink_if.data_out);
        received_count <= received_count + 1;
      end
    end
  end

endmodule

// --- Top-Level Module (Interleaving) ---
module top_level_pipeline;
  bit clk;
  bit rst;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  // Reset generation
  initial begin
    rst = 1;
    #100;
    rst = 0;
    #5000; // Run simulation for a while
    $finish;
  end

  // Instantiate interfaces
  data_transfer_if source_to_proc_if (.clk(clk), .rst(rst));
  data_transfer_if proc1_to_proc2_if (.clk(clk), .rst(rst));
  data_transfer_if proc2_to_sink_if  (.clk(clk), .rst(rst));

  // Interleaved Module Instantiation
  data_source source_inst (
    .clk(clk),
    .rst(rst),
    .source_if(source_to_proc_if.master)
  );

  data_processor #(.ID(10), .DELAY(2)) proc1_inst ( // Processor 1 with ID 10, 2-cycle delay
    .clk(clk),
    .rst(rst),
    .proc_if(source_to_proc_if.slave)
  );

  // Here's the "interleaving" - proc2 is connected to proc1's output
  data_processor #(.ID(20), .DELAY(3)) proc2_inst ( // Processor 2 with ID 20, 3-cycle delay
    .clk(clk),
    .rst(rst),
    .proc_if(proc1_to_proc2_if.slave)
  );

  data_sink sink_inst (
    .clk(clk),
    .rst(rst),
    .sink_if(proc2_to_sink_if.slave)
  );

  // Connect processor 1 output to processor 2 input
  assign proc1_to_proc2_if.data_in         = source_to_proc_if.data_out;
  assign proc1_to_proc2_if.data_in_valid   = source_to_proc_if.data_out_valid;
  assign source_to_proc_if.ready_to_receive = proc1_to_proc2_if.ready_to_receive; // Backpressure

  // Connect processor 2 output to sink input
  assign proc2_to_sink_if.data_in          = proc1_to_proc2_if.data_out;
  assign proc2_to_sink_if.data_in_valid    = proc1_to_proc2_if.data_out_valid;
  assign proc1_to_proc2_if.ready_to_receive = proc2_to_sink_if.ready_to_receive; // Backpressure

endmodule