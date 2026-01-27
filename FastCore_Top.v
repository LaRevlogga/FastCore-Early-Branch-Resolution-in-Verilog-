module fast_core (
    input wire clk,
    input wire rst_n,
    
    // Instruction input
    input wire [31:0] instr_in,
    input wire instr_valid,
    input wire [5:0] src1_index,
    input wire [5:0] src2_index,
    input wire [5:0] dest_index,
    input wire src1_valid,
    input wire src2_valid,
    input wire is_branch,
    input wire is_load,
    
    // Outputs
    output reg [31:0] result_out,
    output reg result_valid,
    output reg [5:0] result_index,
    
    // Branch resolution
    output reg branch_resolved,
    output reg branch_taken,
    
    // Recovery
    input wire recovery_trigger
);

    // Simplified SRF - only 16 entries for Verilog compatibility
    reg [31:0] srf [0:15];
    reg srf_valid [0:15];
    reg [2:0] sojourn_counter [0:15];
    
    // ERF
    reg [31:0] erf [0:31];
    reg erf_valid [0:31];
    
    // Pipeline registers
    reg [31:0] pipe_instr;
    reg [5:0] pipe_src1_idx, pipe_src2_idx, pipe_dest_idx;
    reg pipe_valid;
    reg pipe_is_branch;
    reg [31:0] pipe_src1_val, pipe_src2_val;
    
    // Reservation stations (4 ALUs)
    reg [31:0] rs_instr [0:3];
    reg rs_valid [0:3];
    reg [31:0] rs_src1 [0:3];
    reg [31:0] rs_src2 [0:3];
    reg [5:0] rs_dest_idx [0:3];
    reg rs_is_branch [0:3];
    
    // ALU outputs
    reg [31:0] alu_result [0:3];
    reg alu_result_valid [0:3];
    reg [5:0] alu_dest_idx [0:3];
    reg alu_branch_resolved [0:3];
    reg alu_branch_taken [0:3];
    
    reg [1:0] rs_select;
    integer i;
    
    wire [5:0] opcode = instr_in[31:26];
    wire is_candidate = instr_valid && src1_valid && src2_valid && !is_load && 
                       (opcode == 6'h00 || opcode == 6'h04 || opcode == 6'h05 || opcode == 6'h08);
    
    // Stage 1: Operand Fetch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid <= 1'b0;
        end else if (recovery_trigger) begin
            pipe_valid <= 1'b0;
        end else if (is_candidate) begin
            pipe_instr <= instr_in;
            pipe_src1_idx <= src1_index;
            pipe_src2_idx <= src2_index;
            pipe_dest_idx <= dest_index;
            pipe_is_branch <= is_branch;
            pipe_valid <= 1'b1;
            
            if (src1_index < 16 && srf_valid[src1_index[3:0]])
                pipe_src1_val <= srf[src1_index[3:0]];
            else if (src1_index < 32 && erf_valid[src1_index[4:0]])
                pipe_src1_val <= erf[src1_index[4:0]];
            else
                pipe_valid <= 1'b0;
            
            if (src2_index < 16 && srf_valid[src2_index[3:0]])
                pipe_src2_val <= srf[src2_index[3:0]];
            else if (src2_index < 32 && erf_valid[src2_index[4:0]])
                pipe_src2_val <= erf[src2_index[4:0]];
            else
                pipe_valid <= 1'b0;
        end else begin
            pipe_valid <= 1'b0;
        end
    end
    
    // Stage 2: Issue & Stage 3: Execute (Combined to avoid multiple drivers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                rs_valid[i] <= 1'b0;
                alu_result_valid[i] <= 1'b0;
                alu_branch_resolved[i] <= 1'b0;
            end
            rs_select <= 2'b00;
        end else if (recovery_trigger) begin
            for (i = 0; i < 4; i = i + 1) begin
                rs_valid[i] <= 1'b0;
                alu_result_valid[i] <= 1'b0;
                alu_branch_resolved[i] <= 1'b0;
            end
        end else begin
            // Issue stage
            if (pipe_valid) begin
                rs_instr[rs_select] <= pipe_instr;
                rs_src1[rs_select] <= pipe_src1_val;
                rs_src2[rs_select] <= pipe_src2_val;
                rs_dest_idx[rs_select] <= pipe_dest_idx;
                rs_is_branch[rs_select] <= pipe_is_branch;
                rs_valid[rs_select] <= 1'b1;
                rs_select <= rs_select + 1;
            end
            
            // Execute stage (all ALUs)
            for (i = 0; i < 4; i = i + 1) begin
                if (rs_valid[i]) begin
                    case (rs_instr[i][31:26])
                        6'h00: begin
                            case (rs_instr[i][5:0])
                                6'h20: alu_result[i] <= rs_src1[i] + rs_src2[i];
                                6'h22: alu_result[i] <= rs_src1[i] - rs_src2[i];
                                6'h24: alu_result[i] <= rs_src1[i] & rs_src2[i];
                                6'h25: alu_result[i] <= rs_src1[i] | rs_src2[i];
                                6'h2A: alu_result[i] <= ($signed(rs_src1[i]) < $signed(rs_src2[i])) ? 32'd1 : 32'd0;
                                default: alu_result[i] <= 32'h0;
                            endcase
                            alu_result_valid[i] <= 1'b1;
                            alu_branch_resolved[i] <= 1'b0;
                        end
                        6'h08: begin
                            alu_result[i] <= rs_src1[i] + {{16{rs_instr[i][15]}}, rs_instr[i][15:0]};
                            alu_result_valid[i] <= 1'b1;
                            alu_branch_resolved[i] <= 1'b0;
                        end
                        6'h04: begin
                            alu_branch_resolved[i] <= 1'b1;
                            alu_branch_taken[i] <= (rs_src1[i] == rs_src2[i]);
                            alu_result_valid[i] <= 1'b0;
                            alu_result[i] <= 32'h0;
                        end
                        6'h05: begin
                            alu_branch_resolved[i] <= 1'b1;
                            alu_branch_taken[i] <= (rs_src1[i] != rs_src2[i]);
                            alu_result_valid[i] <= 1'b0;
                            alu_result[i] <= 32'h0;
                        end
                        default: begin
                            alu_result_valid[i] <= 1'b0;
                            alu_branch_resolved[i] <= 1'b0;
                        end
                    endcase
                    alu_dest_idx[i] <= rs_dest_idx[i];
                    rs_valid[i] <= 1'b0;
                end else begin
                    alu_result_valid[i] <= 1'b0;
                    alu_branch_resolved[i] <= 1'b0;
                end
            end
        end
    end
    
    // Stage 4: Writeback
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                srf_valid[i] <= 1'b0;
                sojourn_counter[i] <= 3'b0;
            end
            for (i = 0; i < 32; i = i + 1) erf_valid[i] <= 1'b0;
            result_valid <= 1'b0;
            branch_resolved <= 1'b0;
        end else if (recovery_trigger) begin
            for (i = 0; i < 32; i = i + 1) begin
                erf[i] <= 32'h0;
                erf_valid[i] <= 1'b1;
            end
            result_valid <= 1'b0;
            branch_resolved <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            branch_resolved <= 1'b0;
            
            for (i = 0; i < 4; i = i + 1) begin
                if (alu_result_valid[i]) begin
                    srf[alu_dest_idx[i][3:0]] <= alu_result[i];
                    srf_valid[alu_dest_idx[i][3:0]] <= 1'b1;
                    sojourn_counter[alu_dest_idx[i][3:0]] <= 3'b0;
                    result_out <= alu_result[i];
                    result_index <= alu_dest_idx[i];
                    result_valid <= 1'b1;
                end
                if (alu_branch_resolved[i]) begin
                    branch_resolved <= 1'b1;
                    branch_taken <= alu_branch_taken[i];
                end
            end
            
            for (i = 0; i < 16; i = i + 1) begin
                if (srf_valid[i]) begin
                    if (sojourn_counter[i] < 3'd4) begin
                        sojourn_counter[i] <= sojourn_counter[i] + 1;
                    end else begin
                        if (i < 32) begin
                            erf[i] <= srf[i];
                            erf_valid[i] <= 1'b1;
                        end
                        srf_valid[i] <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
