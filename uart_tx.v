module uart_tx 
#(
    parameter DATA_WIDTH  = 8,
    parameter CLK_FREQ    = 50_000_000,
    parameter BAUD_RATE   = 9600,
    parameter STOP_BITS   = 1
)
(
    input clk,
    input rst,
    input wr_en,
    input [DATA_WIDTH-1:0] din,
    
    output tx,
    output tx_busy 
);

localparam CYCLES_PER_BIT = CLK_FREQ/BAUD_RATE;
localparam COUNTER_LENGTH = $clog2(CYCLES_PER_BIT+1);

reg [DATA_WIDTH-1:0] data_to_send;
reg tx_reg;

reg [COUNTER_LENGTH-1:0] cycle_counter;
reg [3:0] bit_counter;

wire next_bit     = cycle_counter == CYCLES_PER_BIT-1;
wire payload_done = (bit_counter == DATA_WIDTH-1) && next_bit;
wire stop_done    = (bit_counter   == STOP_BITS-1) && current_state == STOP;

localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;

reg [1:0] current_state, next_state;

assign tx_busy = current_state != IDLE;
assign tx       = tx_reg;

// next state logic
always@(*) begin
    case(current_state)

        IDLE : begin
            if(wr_en) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end

        START : begin
            if(next_bit)  begin
                next_state = DATA;
            end else begin
                next_state = START;
            end                     
        end
        
        DATA : begin
            if(payload_done) begin
                next_state = STOP;
            end else begin
                next_state = DATA;
            end
        end
        
        STOP : begin
            if(stop_done) begin
                next_state = IDLE;
            end else begin
                next_state = STOP;
            end
        end
        
        default : begin
            next_state = IDLE;
        end

    endcase
end

// data 
always@(posedge clk) begin
    if(rst) begin
        data_to_send <= {DATA_WIDTH{1'b0}};
    end else if(current_state == IDLE && wr_en) begin
        data_to_send <= din;
    end else if(current_state == DATA && next_bit) begin
        data_to_send <= {1'b0, data_to_send[DATA_WIDTH-1:1]};
    end
end

// bit counter
always@(posedge clk) begin
    if(rst) begin
        bit_counter <= 4'b0;
    end else if(current_state != next_state) begin
        bit_counter <= 4'b0;
    end else if(next_bit && (current_state == DATA || current_state == STOP)) begin
        bit_counter <= bit_counter + 1;
    end 
end

// cycle counter
always@(posedge clk) begin
    if(rst) begin
        cycle_counter <= {COUNTER_LENGTH{1'b0}};
    end else if(next_bit) begin
        cycle_counter <= {COUNTER_LENGTH{1'b0}};        
    end else if(current_state != IDLE) begin
        cycle_counter <= cycle_counter + 1'b1;
    end
end


// progress current state
always@(posedge clk) begin
    if(rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// tx value
always@(posedge clk) begin
    if(rst) begin
        tx_reg <= 1'b1;    
    end else if(current_state == IDLE) begin
        tx_reg <= 1'b1;
    end else if(current_state == START) begin
        tx_reg <= 1'b0;
    end else if(current_state == DATA) begin
        tx_reg <= data_to_send[0];
    end else if(current_state == STOP) begin
        tx_reg <= 1'b1;
    end
end




endmodule
