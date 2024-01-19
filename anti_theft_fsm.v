`timescale 1ns / 1ps

module debouncer(input clk, input [4:0]btn, input reset, output [4:0]debounced_btn);
	wire hidden, brake, driver, passenger, reprogram;
	
	synchronize s1(.clk(clk), .in(btn[1]), .out(hidden));
	synchronize s2 (.clk(clk), .in(btn[3]), .out(brake));
	synchronize s3 (.clk(clk), .in(btn[2]), .out(driver));
	synchronize s4 (.clk(clk), .in(btn[4]), .out(passenger));
	synchronize s5 (.clk(clk), .in(btn[0]), .out(reprogram));
	
	debounce d1 (.clock_in(clk), .noisy_in(hidden), .clean_out(debounced_btn[1]), .reset_in(reset));
	debounce d2 (.clock_in(clk), .noisy_in(brake), .clean_out(debounced_btn[3]), .reset_in(reset));
	debounce d3 (.clock_in(clk), .noisy_in(driver), .clean_out(debounced_btn[2]), .reset_in(reset));
	debounce d4 (.clock_in(clk), .noisy_in(passenger), .clean_out(debounced_btn[4]), .reset_in(reset));
	debounce d5 (.clock_in(clk), .noisy_in(reprogram), .clean_out(debounced_btn[0]), .reset_in(reset));
endmodule


module synchronize 
#(parameter NSYNC = 3)  // number of sync flops.  must be >= 2
(input clk,in, output reg out);

  reg [NSYNC-2:0] sync;

  always @ (posedge clk)
  begin
    {out,sync} <= {sync[NSYNC-2:0],in};
  end
endmodule

module debounce (input reset_in, clock_in, noisy_in,output reg clean_out);
   reg [19:0] count;
   reg new_input;

   always @(posedge clock_in)
     if (reset_in) begin 
        new_input <= noisy_in; 
        clean_out <= noisy_in; 
        count <= 0; end
     else if (noisy_in != new_input) begin new_input<=noisy_in; count <= 0; end
     else if (count == 1000000) clean_out <= new_input;
     else count <= count+1;
endmodule


module time_parameters(input [1:0]interval_signal, input reprogram, 
input [1:0]time_parameter_selector, input [3:0]time_value, 
output reg[3:0]delay);

reg [3:0] time_values [0:3];

initial begin
    time_values[0] = 4'd6;   // T_ARM_DELAY
    time_values[1] = 4'd8;   // T_DRIVER_DELAY
    time_values[2] = 4'd15;  // T_PASSENGER_DELAY
    time_values[3] = 4'd10;  // T_ALARM_ON
end

always @(interval_signal) begin
	delay = time_values[interval_signal];
end

always @(posedge reprogram) begin
	time_values[time_parameter_selector] = time_value;
end
endmodule


module timer(input clk, input start_timer, input [3:0]countdown_amount, input reset,
output reg expired_signal, output reg one_hz_enable, output reg [3:0]internal_counter);

reg [26:0]clk_counter = 0;
reg timer_on;

initial begin
	internal_counter = 4'b0000;
end

always @ (posedge clk) begin
	if (reset) begin
		internal_counter <= 0;
		clk_counter <= 0;
		timer_on <= 1;
	end
	
	if (start_timer) begin
		internal_counter <= countdown_amount;
		clk_counter <= 0;
		timer_on <= 1;
	end

	expired_signal <= 0;
	
	if (timer_on && internal_counter == 4'b0000) begin
		expired_signal <= 1;
		timer_on <= 0;
	end
	
	clk_counter <= clk_counter + 1'b1;
	one_hz_enable = 0;
	
	if (clk_counter == 5 - 1) begin
		clk_counter <= 0;
		one_hz_enable = 1;
		
		if (internal_counter != 4'b0000) begin
			internal_counter <= internal_counter - 4'b0001;
		end
	end
end
endmodule


module anti_theft_fsm(input clk, input [4:0]btn, input [3:0]time_value, 
input [1:0]time_parameter_selector, input ignition, input reset, output reg[1:0]led, output power, output [6:0]seg, output [3:0]an);
// Led 0: Status
// Led 1: Siren

reg [2:0] state = 3'b000; // Initially armed
// State 000: Armed
// State 001: Triggered
// State 010: Sound Alarm
// State 011: Sound Alarm + Doors Closed
// State 100: Disarmed
// State 101: Disarmed + Ignition OFF
// State 110: Disarmed + Ignition OFF + Driver ON
// State 111: Disarmed + Ignition OFF + Driver ON + Driver OFF

wire one_hz_enable;
reg start_timer, timer_reset;
wire [3:0]countdown_amount, internal_counter;
timer t(.clk(clk), .start_timer(start_timer), .countdown_amount(countdown_amount), .reset(timer_reset), 
.expired_signal(expired_signal), .one_hz_enable(one_hz_enable), .internal_counter(internal_counter));

wire hidden, brake, driver, passenger, reprogram;
debouncer d(.clk(clk), .btn(btn), .reset(reset), .debounced_btn({passenger, brake, driver, hidden, reprogram}));

reg [1:0]countdown_type;
time_parameters tp(.interval_signal(countdown_type), .reprogram(reprogram), 
.time_parameter_selector(time_parameter_selector), .time_value(time_value),
.delay(countdown_amount));

seven_segment_display ssd(.clk(clk), .number({internal_counter, 1'b0, state}), .reset(reset), .anode(an), .seg(seg));
			
fuel_pump fp(.clk(clk), .ignition(ignition), .brake(brake), .hidden(hidden), .power(power));

initial begin
		led = 3'b000;
		start_timer = 0;
end

always @(posedge clk) begin
	start_timer <= 1'b0;
	timer_reset = 1'b0;
	
	if (reprogram || reset) begin
		timer_reset = 1'b1;
		state <= 3'b000;
	end
	if (state == 3'b000) begin	// Armed
		if (one_hz_enable) begin
			led[0] = !led[0];
		end
		led[1] = 0;
		
		if (ignition) begin
			state <= 3'b100;
		end
		
		if (driver || passenger) begin 
			countdown_type = driver ? 2'd1:2'd2;
			start_timer <= 1'b1;
			state <= 3'b001;
		end
	end

	if (state == 3'b001) begin	// Triggered
		led[0] = 1;
		led[1] = 0;
		
		if (ignition) begin
			state <= 3'b100;
			timer_reset = 1'b1;
		end
		
		if (expired_signal && !ignition) begin
			state <= 3'b010;
		end
	end

	if (state == 3'b010) begin	// Sound Alarm
		led[0] = 1;
		led[1] = 1;
		
		if (!driver && !passenger) begin
			start_timer <= 1'b1;
			countdown_type = 2'd3;
			state <= 3'b011;
		end
		
		if (ignition) begin 
			led[1] = 0;
			state <= 3'b100;
		end
	end
	
	if (state == 3'b011) begin	// Sound alarm + Doors Closed
		if (expired_signal) begin
			led[1] = 0;
			state <= 3'b000;
		end
	end
		
	if (state == 3'b100) begin	// Disarmed
		led[0] = 0;
		led[1] = 0;
		
		if (!ignition) begin
			state <= 3'b101;
		end
	end
	
	if (state == 3'b101) begin	// Disarmed + Ignition OFF
		if (driver) begin
			state <= 3'b110;
		end
	end
	
	if (state == 3'b110) begin	// Disarmed + Ignition OFF + Driver ON
		if (!driver) begin
			countdown_type = 2'd0;
			start_timer <= 1'b1;
			state <= 3'b111;
		end
	end
	
	if (state == 3'b111) begin	// Disarmed + Ignition OFF + Driver ON + Driver OFF
		if (driver) begin
			state <= 3'b110;
		end
		
		if (expired_signal) begin
			state <= 3'b000;
		end
	end
end
endmodule


module fuel_pump (input clk, input ignition, input brake, input hidden, output reg power);
reg [1:0]state = 2'b00;
// State 00: Power OFF
// State 01: Ignition ON
// State 10: Power ON

always @ (posedge clk) begin
	if (state == 2'b00) begin
		power = 1'b0;

		if (ignition) begin
			state <= 2'b01;
		end
	end

	if (state == 2'b01) begin
		if (hidden && brake) begin
			state <= 2'b10;
		end
	end

	if (state == 2'b10) begin
		power = 1'b1;
		if (!ignition) begin
			state <= 2'b00;
		end
	end
end
endmodule


module seven_segment_display(input clk, input [7:0] number, input reset,
output reg [3:0] anode, output reg [6:0] seg);
	 
reg [3:0] LED_BCD;
reg [19:0] refresh_counter;
wire [1:0] LED_activating_counter;

always @(posedge clk or posedge reset)
begin 
  if(reset==1)
		refresh_counter <= 0;
  else
		refresh_counter <= refresh_counter + 1;
end 

assign LED_activating_counter = refresh_counter[19:18];
always @(*)
begin
  case(LED_activating_counter)
  2'b00: begin
		anode = 4'b1110; 
		LED_BCD = number[3:0];
  end
  2'b10: begin
		anode = 4'b1101; 
		LED_BCD = number[7:4];
  end
  default: begin
		anode = 4'b1111; 
		LED_BCD = 4'b0000;
  end
  endcase
end

always @(*)
begin
  case(LED_BCD)
	  4'b0000: seg = 7'b1000000; // "0"  
	  4'b0001: seg = 7'b1111001; // "1" 
	  4'b0010: seg = 7'b0100100; // "2" 
	  4'b0011: seg = 7'b0110000; // "3" 
	  4'b0100: seg = 7'b0011001; // "4" 
	  4'b0101: seg = 7'b0010010; // "5" 
	  4'b0110: seg = 7'b0000010; // "6" 
	  4'b0111: seg = 7'b1111000; // "7" 
	  4'b1000: seg = 7'b0000000; // "8"  
	  4'b1001: seg = 7'b0010000; // "9" 
	  4'b1010: seg = 7'b0001000; // "A" 
	  4'b1011: seg = 7'b0000000; // "B" 
	  4'b1100: seg = 7'b1000110; // "C" 
	  4'b1101: seg = 7'b1000000; // "D" 
	  4'b1110: seg = 7'b0000110; // "E" 
	  4'b1111: seg = 7'b0001110; // "F" 
	  default: seg = 7'b1000000; // "0"
  endcase
end
endmodule
