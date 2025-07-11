// stress_test.sv
// This file is designed to stress test a SystemVerilog module hierarchy parser.
// It includes various SystemVerilog constructs that can be challenging to parse.

// =============================================================================
// Package Definition
// Demonstrates package usage and parameters/typedefs
// =============================================================================
package test_pkg;

  parameter int DEFAULT_DATA_WIDTH = 16;
  parameter int MAX_DEPTH = 8;

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_ACTIVE,
    STATE_DONE
  } fsm_state_t;

  // Function example (should be ignored by module parser)
  function automatic int add_one(input int val);
    return val + 1;
  endfunction

endpackage // test_pkg


// =============================================================================
// Leaf Module A: Simple, no parameters
// =============================================================================
module leaf_module_a (
  input logic clk,
  input logic rst_n,
  input logic [7:0] data_in,
  output logic [7:0] data_out
);
  // Internal logic (commented out for brevity, not relevant for hierarchy)
  /*
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= '0;
    end else begin
      data_out <= data_in;
    end
  end
  */
  assign data_out = data_in; // Simple pass-through for testing
endmodule // leaf_module_a


// =============================================================================
// Leaf Module B: With parameters, used in generate blocks
// =============================================================================
module leaf_module_b #(
  parameter int WIDTH = test_pkg::DEFAULT_DATA_WIDTH, // Using package parameter
  parameter string NAME = "default_b"
) (
  input logic clk,
  input logic [WIDTH-1:0] input_data,
  output logic [WIDTH-1:0] output_data
);
  // Another simple pass-through
  assign output_data = input_data;
  // This comment is inside leaf_module_b
endmodule // leaf_module_b


// =============================================================================
// Intermediate Module 1: Basic instantiations
// =============================================================================
module intermediate_module_1 (
  input logic clk,
  input logic rst_n,
  input logic [7:0] in_a,
  input logic [15:0] in_b,
  output logic [7:0] out_a,
  output logic [15:0] out_b
);

  // Instantiation of leaf_module_a
  leaf_module_a my_leaf_a_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .data_in  (in_a),
    .data_out (out_a)
  );

  // Instantiation of leaf_module_b with parameter override
  leaf_module_b #(
    .WIDTH (16),
    .NAME  ("intermediate_b_inst")
  ) my_leaf_b_inst (
    .clk        (clk),
    .input_data (in_b),
    .output_data(out_b)
  );

  // Another comment to test comment stripping
endmodule // intermediate_module_1


// =============================================================================
// Intermediate Module 2: Contains a generate-if block
// =============================================================================
module intermediate_module_2 #(
  parameter ENABLE_FEATURE = 1 // Controls generate-if
) (
  input logic clk,
  input logic [7:0] data_in,
  output logic [7:0] data_out
);

  // Instantiation of leaf_module_a inside this module
  leaf_module_a another_leaf_a_inst (
    .clk      (clk),
    .rst_n    (1'b1), // Tied high for simplicity
    .data_in  (data_in),
    .data_out (data_out)
  );

  generate
    if (ENABLE_FEATURE) begin : feature_block
      // This block should exist if ENABLE_FEATURE is 1
      leaf_module_b #(
        .WIDTH (8),
        .NAME  ("feature_leaf_b")
      ) feature_leaf_b_inst (
        .clk        (clk),
        .input_data (data_in),
        .output_data(data_out) // Simplified connection
      );
    end else begin : no_feature_block
      // This block should not exist if ENABLE_FEATURE is 1
      // It should not be parsed as an instantiation if the condition is false
      // (though a simple parser might still find it in the text)
      // The goal is to see if the parser handles the 'generate' syntax.
      // leaf_module_a dummy_inst (.clk(clk), .rst_n(1'b1), .data_in('0), .data_out(data_out));
    end
  endgenerate

endmodule // intermediate_module_2


// =============================================================================
// Complex Module: Contains generate-for loop and nested instantiations
// =============================================================================
module complex_module #(
  parameter int NUM_UNITS = 2,
  parameter int BASE_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,
  input logic [7:0] data_in_a,
  input logic [15:0] data_in_b,
  input logic [7:0] data_in_c [NUM_UNITS], // Array of inputs
  output logic [7:0] data_out_a,
  output logic [15:0] data_out_b,
  output logic [7:0] data_out_c [NUM_UNITS]
);

  // Instantiation of intermediate_module_1
  intermediate_module_1 top_level_intermediate_1 (
    .clk    (clk),
    .rst_n  (rst_n),
    .in_a   (data_in_a),
    .in_b   (data_in_b),
    .out_a  (data_out_a),
    .out_b  (data_out_b)
  );

  // Generate for loop with instantiations
  genvar i;
  generate
    for (i = 0; i < NUM_UNITS; i++) begin : gen_unit
      // Instantiation of leaf_module_b inside a generate loop
      leaf_module_b #(
        .WIDTH (BASE_WIDTH + i), // Parameter varies by loop index
        .NAME  ({NAME, "_gen_inst_", $sformatf("%0d", i)}) // String parameter concatenation
      ) gen_leaf_b_inst (
        .clk        (clk),
        .input_data (data_in_c[i]),
        .output_data(data_out_c[i])
      );

      // Another instantiation inside the same generate block
      leaf_module_a gen_leaf_a_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in_c[i]),
        .data_out (data_out_c[i]) // Simple connection for test
      );
    end
  endgenerate

  // Instantiation of intermediate_module_2
  intermediate_module_2 #(
    .ENABLE_FEATURE (1) // Enable the feature for this instance
  ) top_level_intermediate_2 (
    .clk      (clk),
    .data_in  (data_in_a),
    .data_out (data_out_a) // Connect to existing signal for test
  );

endmodule // complex_module


// =============================================================================
// Top Test Module: Integrates complex_module and others
// =============================================================================
module top_test_module (
  input logic main_clk,
  input logic main_rst_n,
  input logic [7:0] primary_data_in,
  output logic [15:0] final_output
);

  localparam int NUM_COMPLEX_LANES = 2; // For arrayed ports

  logic [7:0] complex_data_c_in [NUM_COMPLEX_LANES];
  logic [7:0] complex_data_c_out [NUM_COMPLEX_LANES];
  logic [7:0] temp_data_a;
  logic [15:0] temp_data_b;

  // Instantiate complex_module
  complex_module #(
    .NUM_UNITS (NUM_COMPLEX_LANES),
    .BASE_WIDTH (8)
  ) my_complex_inst (
    .clk          (main_clk),
    .rst_n        (main_rst_n),
    .data_in_a    (primary_data_in),
    .data_in_b    (16'hABCD), // Constant input
    .data_in_c    (complex_data_c_in),
    .data_out_a   (temp_data_a),
    .data_out_b   (temp_data_b),
    .data_out_c   (complex_data_c_out)
  );

  // Instantiate intermediate_module_1 again (testing multiple instantiations of same module)
  intermediate_module_1 another_intermediate_1 (
    .clk      (main_clk),
    .rst_n    (main_rst_n),
    .in_a     (temp_data_a),
    .in_b     (temp_data_b),
    .out_a    (), // Unconnected output
    .out_b    (final_output)
  );

  // Instantiation of an interface (should be ignored by module hierarchy)
  // This tests if the parser can skip over interface instantiations.
  /*
  serdes_interface #(.DATA_WIDTH(8)) my_serdes_intf (
    .sclk(main_clk),
    .pclk(main_clk),
    .rst_n(main_rst_n)
  );
  */

  // Using a package typedef
  test_pkg::fsm_state_t current_fsm_state;

  // This is a comment at the end of the file.
endmodule // top_test_module


// =============================================================================
// Uninstantiated Module: Should still appear as a node
// =============================================================================
module uninstantiated_module (
  input logic clk,
  output logic done
);
  // This module is defined but never instantiated by any other module in this file.
  // It should still be detected as a module declaration.
  assign done = 1'b1;
endmodule // uninstantiated_module


// =============================================================================
// Empty Module: Just a header and endmodule
// =============================================================================
module empty_module (
  input logic dummy_in,
  output logic dummy_out
);
endmodule // empty_module


// =============================================================================
// Module with no ports
// =============================================================================
module no_ports_module;
  // This module has no ports, which is valid in SystemVerilog.
  // It should still be detected as a module.
  logic internal_signal;
  assign internal_signal = 1'b0;
endmodule // no_ports_module