// serdes_pkg.sv
// Package for common SERDES configurations
package serdes_pkg;

  parameter int DATA_WIDTH = 8;     // Width of the parallel data
  parameter int SER_RATIO = 8;      // Serialization ratio (e.g., 8:1)
  parameter int NUM_LANES = 1;      // Number of SERDES lanes

  // Derived parameter
  parameter int SER_DATA_WIDTH = DATA_WIDTH * SER_RATIO; // Total serialized data width per cycle

  // Enum for state machines (example for a simple FSM in serializer/deserializer)
  typedef enum logic [1:0] {
    IDLE_STATE,
    TRANSMIT_STATE,
    RECEIVE_STATE
  } serdes_state_e;

endpackage

// serdes_serializer.sv
// Module for serializing parallel data into a high-speed serial stream
module serdes_serializer #(
  parameter int DATA_WIDTH = serdes_pkg::DATA_WIDTH,
  parameter int SER_RATIO = serdes_pkg::SER_RATIO
) (
  input  logic              pclk,        // Parallel clock (low speed)
  input  logic              sclk,        // Serial clock (high speed)
  input  logic              rst_n,       // Asynchronous active-low reset

  input  logic [DATA_WIDTH-1:0]  pdata_in,    // Parallel data input
  input  logic              pdata_valid, // Parallel data valid signal

  output logic              sdata_out,   // Serial data output
  output logic              sdata_ready  // Serial data output ready/valid
);

  // Internal registers for serialization
  logic [SER_RATIO-1:0][DATA_WIDTH-1:0] shift_reg;
  logic [SER_RATIO-1:0]               bit_cnt;
  logic                             serialize_en;

  // FSM for serialization control (simplified)
  serdes_pkg::serdes_state_e current_state, next_state;

  always_ff @(posedge pclk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= serdes_pkg::IDLE_STATE;
    end else begin
      current_state <= next_state;
    end
  end

  always_comb begin
    next_state = current_state;
    serialize_en = 1'b0;
    case (current_state)
      serdes_pkg::IDLE_STATE: begin
        if (pdata_valid) begin
          next_state = serdes_pkg::TRANSMIT_STATE;
          serialize_en = 1'b1;
        end
      end
      serdes_pkg::TRANSMIT_STATE: begin
        // For simplicity, assume one parallel data pushes all bits out.
        // In reality, this would involve a counter to cycle through SER_RATIO bits.
        if (bit_cnt == SER_RATIO - 1) begin
          next_state = serdes_pkg::IDLE_STATE;
        end
        serialize_en = 1'b1; // Keep shifting as long as we are transmitting
      end
    endcase
  end

  // Data shifting and output logic (simplified)
  always_ff @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= '0;
      bit_cnt   <= '0;
      sdata_out <= 1'b0;
      sdata_ready <= 1'b0;
    end else begin
      if (serialize_en) begin
        // Load new parallel data into the shift register
        if (current_state == serdes_pkg::IDLE_STATE && pdata_valid) begin
          for (int i = 0; i < SER_RATIO; i++) begin
            // This is a simplified way. In a real design, you'd populate the shift_reg
            // more intelligently based on the parallel input and its width.
            // For example, if DATA_WIDTH=8, SER_RATIO=8, pdata_in is 8 bits.
            // This loop would effectively take one 'pdata_in' and spread its bits
            // across 'SER_RATIO' stages of the shift_reg for serial output.
            shift_reg[i] <= pdata_in; // Simplified: assuming 1-bit per shift stage
          end
          bit_cnt <= '0;
        end else if (current_state == serdes_pkg::TRANSMIT_STATE) begin
          // Shift out one bit per high-speed clock cycle
          sdata_out <= shift_reg[bit_cnt][0]; // Assuming 1-bit serial
          bit_cnt <= bit_cnt + 1;
        end
      end
      sdata_ready <= serialize_en; // Indicate when serial data is valid
    end
  end

endmodule

// serdes_deserializer.sv
// Module for deserializing a high-speed serial stream into parallel data
module serdes_deserializer #(
  parameter int DATA_WIDTH = serdes_pkg::DATA_WIDTH,
  parameter int SER_RATIO = serdes_pkg::SER_RATIO
) (
  input  logic              pclk,        // Parallel clock (low speed)
  input  logic              sclk,        // Serial clock (high speed)
  input  logic              rst_n,       // Asynchronous active-low reset

  input  logic              sdata_in,    // Serial data input
  input  logic              sdata_valid, // Serial data input valid signal

  output logic [DATA_WIDTH-1:0]  pdata_out,   // Parallel data output
  output logic              pdata_valid  // Parallel data output valid signal
);

  // Internal registers for deserialization
  logic [SER_RATIO-1:0][DATA_WIDTH-1:0] shift_reg; // For accumulating serial bits
  logic [SER_RATIO-1:0]               bit_cnt;
  logic                             deserialize_en;

  // FSM for deserialization control (simplified)
  serdes_pkg::serdes_state_e current_state, next_state;

  always_ff @(posedge sclk or negedge rst_n) begin // FSM clocked by sclk for input sampling
    if (!rst_n) begin
      current_state <= serdes_pkg::IDLE_STATE;
    end else begin
      current_state <= next_state;
    end
  end

  always_comb begin
    next_state = current_state;
    deserialize_en = 1'b0;
    case (current_state)
      serdes_pkg::IDLE_STATE: begin
        if (sdata_valid) begin
          next_state = serdes_pkg::RECEIVE_STATE;
          deserialize_en = 1'b1;
        end
      end
      serdes_pkg::RECEIVE_STATE: begin
        if (bit_cnt == SER_RATIO - 1) begin
          next_state = serdes_pkg::IDLE_STATE;
        end
        deserialize_en = 1'b1; // Keep shifting as long as we are receiving
      end
    endcase
  end

  // Data shifting and output logic (simplified)
  always_ff @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg   <= '0;
      bit_cnt     <= '0;
    end else begin
      if (deserialize_en && sdata_valid) begin
        // Shift in one bit per high-speed clock cycle
        shift_reg[bit_cnt] <= sdata_in; // Assuming 1-bit serial input
        bit_cnt <= bit_cnt + 1;
      end
    end
  end

  // Latch parallel data out on parallel clock
  always_ff @(posedge pclk or negedge rst_n) begin
    if (!rst_n) begin
      pdata_out   <= '0;
      pdata_valid <= 1'b0;
    end else begin
      if (current_state == serdes_pkg::RECEIVE_STATE && bit_cnt == SER_RATIO - 1) begin
        // Once all bits are received, assemble into parallel data
        // This assembly logic needs to match the serialization.
        // For simplicity, assuming the first DATA_WIDTH bits of the shift_reg are the parallel data.
        pdata_out <= shift_reg[0]; // Simplified: assuming shift_reg[0] has the full parallel word
        pdata_valid <= 1'b1;
      end else begin
        pdata_valid <= 1'b0;
      end
    end
  end

endmodule

// serdes_interface.sv (Optional but good for connecting and UVM)
// Interface for connecting the serializer and deserializer
interface serdes_interface #(
  parameter int DATA_WIDTH = serdes_pkg::DATA_WIDTH
) (
  input logic sclk,
  input logic pclk,
  input logic rst_n
);

  // Serializer outputs / Deserializer inputs
  logic sdata;
  logic sdata_ready_valid; // Naming this more descriptive

  // Deserializer outputs / Serializer inputs (not directly for this example)
  // But generally, an interface might carry both directions.

  // Modports for clarity and directional control (optional but good practice)
  modport ser_mp (
    input  pclk,
    input  rst_n,
    output sdata,
    output sdata_ready_valid
  );

  modport des_mp (
    input  sclk,
    input  rst_n,
    input  sdata,
    input  sdata_ready_valid
  );

endinterface

// serdes_top.sv
// Top-level SERDES module integrating serializer and deserializer
module serdes_top #(
  parameter int DATA_WIDTH = serdes_pkg::DATA_WIDTH,
  parameter int SER_RATIO = serdes_pkg::SER_RATIO,
  parameter int NUM_LANES = serdes_pkg::NUM_LANES
) (
  input  logic               pclk_in,      // Parallel clock for input
  input  logic               pclk_out,     // Parallel clock for output
  input  logic               sclk,         // Serial clock (high speed)
  input  logic               rst_n,        // Asynchronous active-low reset

  input  logic [DATA_WIDTH-1:0]  pdata_in [NUM_LANES], // Array of parallel data inputs
  input  logic               pdata_in_valid [NUM_LANES], // Array of valid signals

  output logic [DATA_WIDTH-1:0]  pdata_out [NUM_LANES], // Array of parallel data outputs
  output logic               pdata_out_valid [NUM_LANES]  // Array of valid signals
);

  // Internal signals for connecting serializer and deserializer for each lane
  // For simplicity, this example assumes direct connection for simulation/loopback.
  // In a real system, these would go through physical layer (PMA) and interconnects.
  logic sdata_internal [NUM_LANES];
  logic sdata_ready_internal [NUM_LANES];

  genvar i;
  generate
    for (i = 0; i < NUM_LANES; i++) begin : gen_serdes_lane

      // Instantiate Serializer
      serdes_serializer #(
        .DATA_WIDTH (DATA_WIDTH),
        .SER_RATIO  (SER_RATIO)
      ) serializer_i (
        .pclk        (pclk_in),
        .sclk        (sclk),
        .rst_n       (rst_n),
        .pdata_in    (pdata_in[i]),
        .pdata_valid (pdata_in_valid[i]),
        .sdata_out   (sdata_internal[i]),
        .sdata_ready (sdata_ready_internal[i])
      );

      // Instantiate Deserializer
      serdes_deserializer #(
        .DATA_WIDTH (DATA_WIDTH),
        .SER_RATIO  (SER_RATIO)
      ) deserializer_i (
        .pclk        (pclk_out),
        .sclk        (sclk),
        .rst_n       (rst_n),
        .sdata_in    (sdata_internal[i]),
        .sdata_valid (sdata_ready_internal[i]), // Using serializer's ready as deserializer's valid for loopback
        .pdata_out   (pdata_out[i]),
        .pdata_valid (pdata_out_valid[i])
      );

      // Optional: Using an interface for connection (more common in testbenches)
      // serdes_interface #(.DATA_WIDTH(DATA_WIDTH)) serdes_intf (.*);
      //
      // assign serdes_intf.sdata = sdata_internal[i];
      // assign serdes_intf.sdata_ready_valid = sdata_ready_internal[i];
      //
      // serdes_serializer #(
      //   .DATA_WIDTH (DATA_WIDTH),
      //   .SER_RATIO  (SER_RATIO)
      // ) serializer_i (
      //   .pclk        (serdes_intf.pclk),
      //   .sclk        (serdes_intf.sclk),
      //   .rst_n       (serdes_intf.rst_n),
      //   .pdata_in    (pdata_in[i]),
      //   .pdata_valid (pdata_in_valid[i]),
      //   .sdata_out   (serdes_intf.sdata),
      //   .sdata_ready (serdes_intf.sdata_ready_valid)
      // );
      //
      // serdes_deserializer #(
      //   .DATA_WIDTH (DATA_WIDTH),
      //   .SER_RATIO  (SER_RATIO)
      // ) deserializer_i (
      //   .pclk        (serdes_intf.pclk),
      //   .sclk        (serdes_intf.sclk),
      //   .rst_n       (serdes_intf.rst_n),
      //   .sdata_in    (serdes_intf.sdata),
      //   .sdata_valid (serdes_intf.sdata_ready_valid),
      //   .pdata_out   (pdata_out[i]),
      //   .pdata_valid (pdata_out_valid[i])
      // );
    end
  endgenerate

endmodule
