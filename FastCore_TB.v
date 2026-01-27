module tb_fast_core_system;

    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10;

    reg clk, rst_n;
    reg [31:0] instr_in;
    reg instr_valid;
    reg [5:0] src1_index, src2_index, dest_index;
    reg src1_valid, src2_valid;
    reg is_branch, is_load;
    wire [31:0] result_out;
    wire result_valid;
    wire [5:0] result_index;
    wire branch_resolved;
    wire branch_taken;
    reg recovery_trigger;
    
    reg [31:0] pc;
    reg predict_req;
    wire prediction;
    wire prediction_valid;
    reg [31:0] update_pc;
    reg update_valid;
    reg update_taken;
    reg update_correct;
    
    integer total_branches;
    integer fast_core_resolved;
    integer correct_predictions;
    integer cycle_count;
	 integer i;
    
    fast_core dut_fast_core (
        .clk(clk), .rst_n(rst_n),
        .instr_in(instr_in), .instr_valid(instr_valid),
        .src1_index(src1_index), .src2_index(src2_index), .dest_index(dest_index),
        .src1_valid(src1_valid), .src2_valid(src2_valid),
        .is_branch(is_branch), .is_load(is_load),
        .result_out(result_out), .result_valid(result_valid), .result_index(result_index),
        .branch_resolved(branch_resolved), .branch_taken(branch_taken),
        .recovery_trigger(recovery_trigger)
    );
    
    branch_predictor dut_predictor (
        .clk(clk), .rst_n(rst_n),
        .pc(pc), .predict_req(predict_req),
        .prediction(prediction), .prediction_valid(prediction_valid),
        .update_pc(update_pc), .update_valid(update_valid),
        .update_taken(update_taken), .update_correct(update_correct)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    task send_instruction;
        input [5:0] opcode;
        input [4:0] rs, rt, rd;
        input [5:0] funct;
        input [15:0] imm;
        input is_br;
        begin
            instr_in = {opcode, rs, rt, rd, 5'b0, funct};
            if (opcode == 6'h08) instr_in = {opcode, rs, rt, imm};
            else if (opcode == 6'h04 || opcode == 6'h05) instr_in = {opcode, rs, rt, imm};
            instr_valid = 1'b1;
            src1_index = {1'b0, rs};
            src2_index = {1'b0, rt};
            dest_index = {1'b0, rd};
            src1_valid = 1'b1;
            src2_valid = 1'b1;
            is_branch = is_br;
            is_load = 1'b0;
            @(posedge clk);
            instr_valid = 1'b0;
        end
    endtask
    
    initial begin
        rst_n = 0;
        instr_valid = 0;
        recovery_trigger = 0;
        pc = 32'h1000;
        predict_req = 0;
        update_valid = 0;
        total_branches = 0;
        fast_core_resolved = 0;
        correct_predictions = 0;
        cycle_count = 0;
        
        $dumpfile("fast_core_tb.vcd");
        $dumpvars(0, tb_fast_core_system);
        
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        $display("\nStarting Fast Core Tests");
        $display("------------------------\n");
        
        // Test 1: Arithmetic
        $display("Test 1: Arithmetic operations");
        send_instruction(6'h00, 5'd0, 5'd0, 5'd1, 6'h20, 16'h0, 1'b0);
        #(CLK_PERIOD * 2);
        send_instruction(6'h08, 5'd1, 5'd2, 5'd0, 6'h0, 16'd10, 1'b0);
        #(CLK_PERIOD * 2);
        send_instruction(6'h00, 5'd1, 5'd2, 5'd3, 6'h20, 16'h0, 1'b0);
        #(CLK_PERIOD * 3);
        
        // Test 2: Branch
        $display("Test 2: Branch resolution");
        send_instruction(6'h08, 5'd0, 5'd4, 5'd0, 6'h0, 16'd5, 1'b0);
        #(CLK_PERIOD * 2);
        send_instruction(6'h08, 5'd0, 5'd5, 5'd0, 6'h0, 16'd5, 1'b0);
        #(CLK_PERIOD * 2);
        send_instruction(6'h04, 5'd4, 5'd5, 5'd0, 6'h0, 16'd4, 1'b1);
        total_branches = total_branches + 1;
        #(CLK_PERIOD * 3);
        if (branch_resolved) begin
            fast_core_resolved = fast_core_resolved + 1;
            $display("  Branch resolved! Taken: %b", branch_taken);
        end
        #(CLK_PERIOD * 3);
        
        // Test 3: Recovery
        $display("Test 3: Recovery");
        recovery_trigger = 1;
        #(CLK_PERIOD);
        recovery_trigger = 0;
        #(CLK_PERIOD * 2);
        
        // Test 4: Prediction
        $display("Test 4: Branch prediction");
        for (i = 0; i < 5; i = i + 1) begin
            pc = 32'h2000 + (i * 4);
            predict_req = 1;
            #(CLK_PERIOD);
            predict_req = 0;
            
            send_instruction(6'h08, 5'd0, 5'd11, 5'd0, 6'h0, i, 1'b0);
            #(CLK_PERIOD);
            send_instruction(6'h08, 5'd0, 5'd12, 5'd0, 6'h0, i+1, 1'b0);
            #(CLK_PERIOD);
            send_instruction(6'h04, 5'd11, 5'd12, 5'd0, 6'h0, 16'd4, 1'b1);
            total_branches = total_branches + 1;
            #(CLK_PERIOD * 2);
            
            update_pc = 32'h2000 + (i * 4);
            update_valid = 1;
            update_taken = (i % 2 == 0);
            update_correct = (prediction == update_taken) && prediction_valid;
            if (update_correct) correct_predictions = correct_predictions + 1;
            #(CLK_PERIOD);
            update_valid = 0;
            
            if (branch_resolved) fast_core_resolved = fast_core_resolved + 1;
            #(CLK_PERIOD * 2);
        end
        
        #(CLK_PERIOD * 10);
        $display("\nResults:");
        $display("Total branches: %0d", total_branches);
        $display("Fast core resolved: %0d (%0d%%)", fast_core_resolved, (fast_core_resolved * 100) / total_branches);
        $display("Prediction accuracy: %0d%%", (correct_predictions * 100) / total_branches);
        
        #(CLK_PERIOD * 5);
        $finish;
    end
    
    always @(posedge clk) begin
        if (branch_resolved) $display("[%0d] Branch resolved - taken=%b", cycle_count, branch_taken);
        if (result_valid) $display("[%0d] Result: idx=%0d, val=%h", cycle_count, result_index, result_out);
        if (rst_n) cycle_count = cycle_count + 1;
    end
    
    initial begin
        #(CLK_PERIOD * 5000);
        $display("TIMEOUT");
        $finish;
    end

endmodule
