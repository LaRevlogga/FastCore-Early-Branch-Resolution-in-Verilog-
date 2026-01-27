module branch_predictor (
    input wire clk,
    input wire rst_n,
    input wire [31:0] pc,
    input wire predict_req,
    output reg prediction,
    output reg prediction_valid,
    input wire [31:0] update_pc,
    input wire update_valid,
    input wire update_taken,
    input wire update_correct
);

    reg [1:0] pht [0:255];
    reg [7:0] ghr;
    wire [7:0] pht_index = pc[9:2] ^ ghr;
    wire [7:0] update_index = update_pc[9:2] ^ ghr;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 256; i = i + 1) pht[i] <= 2'b01;
            ghr <= 8'h0;
            prediction_valid <= 1'b0;
        end else begin
            if (predict_req) begin
                prediction <= pht[pht_index][1];
                prediction_valid <= 1'b1;
            end else begin
                prediction_valid <= 1'b0;
            end
            
            if (update_valid) begin
                if (update_taken) begin
                    if (pht[update_index] != 2'b11)
                        pht[update_index] <= pht[update_index] + 1;
                end else begin
                    if (pht[update_index] != 2'b00)
                        pht[update_index] <= pht[update_index] - 1;
                end
                ghr <= {ghr[6:0], update_taken};
            end
        end
    end

endmodule
