`timescale 1ns / 1ps

module Display( 
    input logic clk,
    input logic rst,
    input logic [15:0] value, // Register value
    
    output logic [6:0] seg, // controls the 7 LED segments
    output logic [3:0] dig, // controls which of the four digits is active
    output logic dp // decimal point control   ; won't be used, so this will be assigned 1
    );
    
    logic [17:0] refresh_counter;
    logic [1:0] digit_select; // 2'b00 = rightmost (AN0)
                              // 2'b01 = AN1
                              // 2'b10 = AN2
                              // 2'b11 = leftmost (AN3)
    logic [3:0] current_dig; 
    
    assign dp = 1'b1;
    
    assign digit_select = refresh_counter[17:16];
    
    // REMEMBER DISPLAY IS ACTIVE LOW
    
    always_ff @(posedge clk) begin
        if (rst) begin
            refresh_counter <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end
    
    always_comb begin
        case (digit_select) 
            2'b00: begin
                dig = 4'b1110; // enable AN0
                current_dig = value[3:0];
            end
            2'b01: begin
                dig = 4'b1101; // enable AN1
                current_dig = value[7:4];
            end
            2'b10: begin
                dig = 4'b1011; // enable AN2
                current_dig = value[11:8];
            end
            2'b11: begin
                dig = 4'b0111; // enable AN3
                current_dig = value[15:12];
            end
        endcase
    end
    
    always_comb begin
        case (current_dig) // Display is active low, so turning a segment to 1 turns it off
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;

            default: seg = 7'b1111111;
        endcase
    end
    
endmodule
