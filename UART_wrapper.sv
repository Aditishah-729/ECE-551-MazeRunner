module UART_wrapper(clk, rst_n, RX, cmd_rdy, cmd, clr_cmd_rdy, trmt, resp, tx_done, TX);

input clk, rst_n;	
input RX; //Receive line from Bluetooth module
input trmt;
input clr_cmd_rdy;
input logic [7:0] resp; //resp is sent to Bluetooth module upon a pulse on trmt
output logic cmd_rdy; 
output logic [15:0] cmd; //When cmd_rdy is asserted cmd is 16-bit command received 
output logic tx_done, TX; //when resp sent is done.

//other internal nodes
logic rx_rdy;
logic [7:0] rx_data;
logic is_first_byte;
logic set_cmd_rdy;
logic clr_rdy;
logic [7:0] first_byte;

// Instantiation of the UART
UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .rx_rdy(rx_rdy), 
          .rx_data(rx_data), .trmt(trmt), .tx_data(resp), .tx_done(tx_done), .clr_rx_rdy(clr_rdy));


//logic for SM
typedef enum reg {IDLE, WRAPPING} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else 
		state <= nxt_state;

//SM control
always_comb begin

is_first_byte = 0;
clr_rdy = 0;
nxt_state = state;
set_cmd_rdy = 0;

case(state)

	IDLE: begin 
		is_first_byte = 1; // we begin processing the first byte.
		if (rx_rdy) begin
			clr_rdy = 1;
			nxt_state = WRAPPING;
		end

	end

	WRAPPING: begin
		if (rx_rdy) begin
			set_cmd_rdy = 1; // after both responses have been processed, we assert set_cmd_rdy
			clr_rdy = 1;
			nxt_state = IDLE;
		end 
	end
endcase

end


// flop for command ready 

always_ff @(posedge clk)
	if (is_first_byte | clr_cmd_rdy)
		cmd_rdy <= 0;
	else if (set_cmd_rdy)
		cmd_rdy <= 1;
	else 
		cmd_rdy <= cmd_rdy;

// flop for first_byte
  
always_ff @(posedge clk)
	if (is_first_byte)
		first_byte <= rx_data;
else 
	first_byte <= first_byte;

assign cmd = {first_byte, rx_data}; // output cmd to be sent combination of the both bytes.

	  
endmodule
