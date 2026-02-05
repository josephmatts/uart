module uart_tx 
#(
    parameter DATA_WIDTH  = 8,
    parameter CLK_FREQ    = 125_000_000,
    parameter BAUD_RATE   = 9600,
    parameter STOP_BITS   = 1
)
(
    input clk,
    input rst,
    input wr_en,
    input [DATA_WIDTH-1:0] din,
    
    output reg tx,
    output     tx_busy 
);

// Baud timing
localparam CYCLES_PER_BIT = CLK_FREQ/BAUD_RATE;
localparam COUNTER_LENGTH = $clog2(CYCLES_PER_BIT+1);

// timing
localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;
reg [1:0] state;

// registers
reg [DATA_WIDTH-1:0] data_to_send;
reg [COUNTER_LENGTH-1:0] cycle_counter;
reg [$clog2(DATA_WIDTH):0] bit_counter;
reg [1:0] stop_counter;

assign tx_busy = state != IDLE;

// uart tx fsm
always@(posedge clk) begin
    if(rst) begin
        state         <= IDLE;
        cycle_counter <= 0;
        bit_counter   <= 0;
        stop_counter  <= 0;
        data_to_send  <= 0;
        tx            <= 1'b1;
    end else begin
        case(state)
        
            IDLE : begin
                tx            <= 1'b1;
                cycle_counter <= 0;
                bit_counter   <= 0;
                stop_counter  <= 0;
                
                if(wr_en) begin
                    data_to_send  <= din;
                    state         <= START;
                end                 
            end
            
            START : begin
                tx <= 0;
                if(cycle_counter == CYCLES_PER_BIT-1) begin
                    cycle_counter <= 0;
                    state         <= DATA;
                end else begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            end
            
            DATA : begin
                tx <= data_to_send[0];
                if(cycle_counter == CYCLES_PER_BIT-1)begin
                    cycle_counter <= 0;
                    data_to_send <= data_to_send >> 1;
                    
                    if(bit_counter == DATA_WIDTH-1) begin
                        bit_counter <= 0;
                        state <= STOP;
                    end else begin
                        bit_counter <= bit_counter + 1'b1;
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            end
            
            STOP : begin
                tx <= 1'b1;
                if(cycle_counter == CYCLES_PER_BIT-1) begin
                    cycle_counter <= 0;
                    if(stop_counter == STOP_BITS-1) begin
                        stop_counter <= 0;
                        state <= IDLE;                        
                    end else begin
                        stop_counter <= stop_counter + 1'b1;
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            end
            
            default : state <= IDLE;
                     
        endcase    
    end
end





endmodule
