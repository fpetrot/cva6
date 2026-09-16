// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Rohan Arshid, 10xEngineers
// Date: 22.01.2024
// Description: Contains the logic for decoding cm.push, cm.pop, cm.popret,
//              cm.popretz, cm.mvsa01, and cm.mva01s instructions of the
//              Zcmp Extension

module macro_decoder #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty
) (
    input  logic [31:0] instr_i,
    input  logic        clk_i,                      // Clock
    input  logic        rst_ni,                     // Synchronous reset
    input  logic        is_macro_instr_i,           // Instruction is of macro extension
    input  logic        illegal_instr_i,            // From compressed decoder
    input  logic        is_compressed_i,
    input  logic        issue_ack_i,                // Check if the instruction is acknowledged
    output logic [31:0] instr_o,
    output logic        illegal_instr_o,
    output logic        is_compressed_o,
    output logic        fetch_stall_o,              // Wait while push/pop/move instructions expand
    output logic        is_last_macro_instr_o,
    output logic        is_double_rd_macro_instr_o
);

  // FSM States
  enum logic [2:0] {
    IDLE,
    INIT,
    PUSH_ADDI,
    MOVE,
    ZERO,
    RET
  }
      state_d, state_q;

  // Instruction Types
  enum logic [2:0] {
    PUSH,
    POP,
    POPRETZ,
    POPRET,
    MVA01S,
    MVSA01
  } macro_instr_type;

  // Temporary registers
  logic [3:0] reg_numbers, reg_numbers_q, reg_numbers_d;
  logic [11:0] stack_adj, stack_imm;
  logic [4:0] xreg1, xreg2, store_reg, store_reg_q, store_reg_d;
  logic [11:0] offset, offset_q, offset_d;
  localparam [11:0] xlen_bytes = CVA6Cfg.XLEN / 8;
  localparam [2:0] funct3 = CVA6Cfg.IS_XLEN32 ? 3'b10 : 3'b11;

  always_comb begin
    illegal_instr_o            = 1'b0;
    fetch_stall_o              = 1'b0;
    is_last_macro_instr_o      = 1'b0;
    is_double_rd_macro_instr_o = 1'b0;
    is_compressed_o            = is_macro_instr_i ? 1'b1 : is_compressed_i;
    reg_numbers                = '0;
    stack_adj                  = '0;
    state_d                    = state_q;
    offset_d                   = offset_q;
    reg_numbers_d              = reg_numbers_q;
    store_reg_d                = store_reg_q;

    if (is_macro_instr_i) begin

      unique case (instr_i[12:10])
        // push or pop
        3'b110: begin
          if (instr_i[7:4] < 4'b0100) begin
            illegal_instr_o = 1'b1;
            instr_o     = instr_i;
          end

          unique case (instr_i[9:8])
            2'b00: begin
              macro_instr_type = PUSH;
            end
            2'b10: begin
              macro_instr_type = POP;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o     = instr_i;
            end
          endcase
        end
        // popret or popretz
        3'b111: begin
          if (instr_i[7:4] < 4'b0100) begin
            illegal_instr_o = 1'b1;
            instr_o     = instr_i;
          end

          unique case (instr_i[9:8])
            2'b00: begin
              macro_instr_type = POPRETZ;
            end
            2'b10: begin
              macro_instr_type = POPRET;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o     = instr_i;
            end
          endcase
        end
        // mvq01s or mvsa01
        3'b011: begin
          unique case (instr_i[6:5])
            2'b01: begin
              macro_instr_type = MVSA01;
            end
            2'b11: begin
              macro_instr_type = MVA01S;
            end
            default: begin
              illegal_instr_o = 1'b1;
              instr_o     = instr_i;
            end
          endcase
        end
        default: begin
          illegal_instr_o = 1'b1;
          instr_o     = instr_i;
        end
      endcase

      // Calculate xreg1 & xreg2 for move instructions
      if (macro_instr_type == MVSA01 || macro_instr_type == MVA01S) begin
        if (macro_instr_type == MVA01S || instr_i[9:7] != instr_i[4:2]) begin
          xreg1 = {instr_i[9:8] > 0, instr_i[9:8] == 0, instr_i[9:7]};
          xreg2 = {instr_i[4:3] > 0, instr_i[4:3] == 0, instr_i[4:2]};
        end else begin
          illegal_instr_o = 1'b1;
          instr_o     = instr_i;
        end
      end else begin
        xreg1 = '0;
        xreg2 = '0;
      end

      // push/pop/popret/popretz instructions
      unique case (instr_i[7:4])
        4'b0100: reg_numbers = 4'd1;
        4'b0101: reg_numbers = 4'd2;
        4'b0110: reg_numbers = 4'd3;
        4'b0111: reg_numbers = 4'd4;
        4'b1000: reg_numbers = 4'd5;
        4'b1001: reg_numbers = 4'd6;
        4'b1010: reg_numbers = 4'd7;
        4'b1011: reg_numbers = 4'd8;
        4'b1100: reg_numbers = 4'd9;
        4'b1101: reg_numbers = 4'd10;
        4'b1110: reg_numbers = 4'd11;
        4'b1111: reg_numbers = 4'd13;
        default: begin
          reg_numbers = '0;
          illegal_instr_o = 1'b1;
        end
      endcase

      stack_adj = (((reg_numbers * xlen_bytes) + 12'd15) & ~12'd15) + {6'b0, instr_i[3:2], 4'b0000};

    end else begin
      illegal_instr_o = illegal_instr_i;
      instr_o     = instr_i;
    end

    unique case (state_q)
      IDLE: begin
        if (is_macro_instr_i && !illegal_instr_o) begin
          fetch_stall_o = 1;
          reg_numbers_d = reg_numbers - 1'b1;
          state_d = issue_ack_i ? INIT : IDLE;
          case (macro_instr_type)
            PUSH: begin
              stack_imm = -stack_adj;
              offset   = -xlen_bytes;
              offset_d = -(2 * xlen_bytes);
            end
            POP, POPRETZ, POPRET: begin
              stack_imm = stack_adj - xlen_bytes;
              offset_d   = stack_adj - (2 * xlen_bytes);
            end
            default: ;
          endcase
          // when rlist is 4, max reg is x18 i.e. 14(const) + 4
          // when rlist is 12, max reg is x27 i.e. 15(const) + 12
          store_reg_d = 4'd13 + reg_numbers;
          store_reg   = 4'd14 + reg_numbers;

          if (macro_instr_type == MVSA01) begin
            is_double_rd_macro_instr_o = 1;
            // addi xreg1, a0, 0
            instr_o = {12'h0, 5'hA, 3'h0, xreg1, riscv::OpcodeOpImm};
            if (issue_ack_i) begin
              state_d = MOVE;
            end
          end else if (macro_instr_type == MVA01S) begin
            is_double_rd_macro_instr_o = 1;
            // addi a0, xreg1, 0
            instr_o = {12'h0, xreg1, 3'h0, 5'hA, riscv::OpcodeOpImm};
            if (issue_ack_i) begin
              state_d = MOVE;
            end
          end else begin // Stack related insns then
            if (reg_numbers == 4'd1) begin
              store_reg = 5'h1;  // ra
            end else if (reg_numbers == 4'd2) begin
              store_reg = 5'h8;  // s0
            end else if (reg_numbers == 4'd3) begin
              store_reg = 5'h9;  // s1
            end

            if (macro_instr_type == PUSH) begin
              instr_o = {offset[11:5], store_reg, 5'h2, funct3, offset[4:0], riscv::OpcodeStore};
            end else begin // POP/POPRET/POPRETZ
              instr_o = {stack_imm, 5'h2, funct3, store_reg, riscv::OpcodeLoad};
            end

            if (reg_numbers == 4'd1) begin
              if (issue_ack_i) begin
                state_d = PUSH_ADDI;
              end
            end
          end
        end
      end

      INIT: begin // We enter INIT only on stack related insns
        fetch_stall_o = 1;  // stall inst fetch
        store_reg = store_reg_q;
        if (reg_numbers_q == 4'd1) begin
          store_reg = 5'h1;
          state_d = PUSH_ADDI;
        end else if (reg_numbers_q == 4'd2) begin
          store_reg = 5'h8;
        end else if (reg_numbers_q == 4'd3) begin
          store_reg = 5'h9;
        end

        if (issue_ack_i) begin
          if (macro_instr_type == PUSH) begin
            instr_o = {offset_d[11:5], store_reg, 5'h2, funct3, offset_d[4:0], riscv::OpcodeStore};
          end else begin // POP/POPRET/POPRETZ
            instr_o = {offset_q, 5'h2, funct3, store_reg, riscv::OpcodeLoad};
          end

          reg_numbers_d = reg_numbers_q - 1;
          store_reg_d = store_reg_q - 1;
          offset_d = offset_q - xlen_bytes;
        end
      end

      MOVE: begin
        if (issue_ack_i) begin
          if (macro_instr_type == MVSA01) begin
            // addi xreg2, a1, 0
            instr_o = {12'h0, 5'hB, 3'h0, xreg2, riscv::OpcodeOpImm};
          end else begin // MVA01S
            // addi a1, xreg2, 0
            instr_o = {12'h0, xreg2, 3'h0, 5'hB, riscv::OpcodeOpImm};
          end
          fetch_stall_o = 0;
          is_last_macro_instr_o = 1;
          is_double_rd_macro_instr_o = 1;
          state_d = IDLE;
        end else begin
          illegal_instr_o = 1'b1;
          instr_o     = instr_i;
        end
      end

      PUSH_ADDI: begin
        if (issue_ack_i) begin
          if (macro_instr_type == PUSH) begin
            // addi sp, sp, stack_adj
            instr_o = {stack_imm, 5'h2, 3'h0, 5'h2, riscv::OpcodeOpImm};
          end else begin
            instr_o = {stack_adj, 5'h2, 3'h0, 5'h2, riscv::OpcodeOpImm};
          end
          if (macro_instr_type == POPRETZ) begin
            state_d = ZERO;
            fetch_stall_o = 1;
          end else if (macro_instr_type == POPRET) begin
            state_d = RET;
            fetch_stall_o = 1;
          end else begin
            state_d = IDLE;
            fetch_stall_o = 0;
            is_last_macro_instr_o = 1;
          end
        end else begin
          fetch_stall_o = 1;
        end
      end

      ZERO: begin
        if (issue_ack_i) begin
          instr_o = {12'h0, 5'h0, 3'h0, 5'hA, riscv::OpcodeOpImm}; //addi a0, zero, 0x0
          state_d = RET;
        end
        fetch_stall_o = 1;
      end

      RET: begin
        if (issue_ack_i) begin
          instr_o = {12'h0, 5'h1, 3'h0, 5'h0, riscv::OpcodeJalr}; //ret - jalr x0, x1, 0
          state_d = IDLE;
          fetch_stall_o = 0;
          is_last_macro_instr_o = 1;
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      state_q <= IDLE;
      offset_q <= '0;
      reg_numbers_q <= '0;
      store_reg_q <= '0;
    end else begin
      state_q <= state_d;
      offset_q <= offset_d;
      reg_numbers_q <= reg_numbers_d;
      store_reg_q <= store_reg_d;
    end
  end
endmodule
