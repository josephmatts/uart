module uart_tx 
#(
    parameter DATA_WIDTH = 8,
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 9600,
    parameter STOP_BIT   = 1,
    parameter PARITY     = 0
)
(
    input clk,
    input rst,
    input wr_en,
    input s_tick,
    input [DATA_WIDTH-1:0] din,
    
    output tx,
    output tx_done 
);

localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;

reg [1:0] current_state, next_state;
reg tx_next;

// next state logic
always@(*) begin
    next_state = current_state;
    case(current_state)

        IDLE:begin
            tx_next = 1'b1;
            if(wr_en) begin
                next_state = START;
            end 
        end

        START:begin
            tx_next = 1'b0;

        end

    
    endcase
end








endmodule