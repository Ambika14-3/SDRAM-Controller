`timescale 1ns / 1ps
// Controller of SDRAM 54S416T-5 to 54S416T-7
// 1M x 4 BANKS x 16 BITS SDRAM

// Address = 22 bits of Address ({Bank_Select [21:20], Row_Address [19:8], Column_Address [7:0]}) -> Input
// A = 12 bits for Address (A[11:0] = for Row Address & next time A[7:0] = for Column Address) -> Output
// BS = 2 bits for Bank Select -> Output
// A10 = AP
// CS = Chip Select -> output, Active low
// RAS = Row Address Enable or Row Address Select -> output, Active low
// CAS = Column Address Enable or Column Address Select -> output, Active low
// WE = Write Enable -> Output, Active low (WE = 1 for write & WE = 0 for read)
// clk_crontroller = Clock signal used inside controller -> input
// clk_sdram = Clock signal passed to SDRAM -> output
// CKE = Clock Enable -> output, Active high
// DQ_USER = 16 bits for Data Transfer between USER & controller -> Input & Output both
// DQ_SDRAM = 16 bits for Data Transfer between SDRAM & controller -> Input & Output both
// Vcc & Vss = Power Supply for SDRAM (Vcc = always high & Vss = always low)
// LDQM = only read lower byte of data -> Output, Active high 
// UDQM = only read upper byte of data -> Output, Active high
// Operation = Which operation to perform on SDRAM
// Command = Which operation to perform on SDRAM -> input, datatype -> string
// Operation = perform that perticular Command only if Current State of SDRAM allows that Command
// Brust_length = no. of locations to read or write in one chance -> input, datatype -> string, possible_values = {1 or 2 or 4 or 8 or f} ("f" for full page)
// Accessing_mode = which type of Brust_length -> input, datatype -> string, possible_values = {s or i} ("s" for sequential & "i" for interleave)
// CAS_latency = Column Address Strobe latency, delay in clock cycles between the READ command and the moment data is available -> input, datatype -> string, possible_values = {2 or 3}
// Single_write_mode = (Burst read and Burst write) or (Burst read and single write) -> input, datatype -> string, possible_values = {br&bw or br&sw}
// PREV = previous state of SDRAM before execution of current command
// STATE = current state of SDRAM after execution of current command
// NEXT = what will be the future state of SDRAM after execution of future command
// bur_len = Burst_length in integer form
// cas_lat = CAS_latency in integer form
// write_mem = a type of data write enable signal when write command is accessed
// read_mem = a type of data read enable signal when read command is accessed
// select = direction of dataflow between DQ_USER & DQ_SDRAM pins of controller 

module SDRAM_Controller #(parameter clk_period = 10) (Command, Address, Burst_length, Accessing_mode, CAS_latency, Single_write_mode, A, BS, clk_crontroller, clk_sdram, CKE, CS, RAS, CAS, WE, DQ_SDRAM_CONT, DQ_USER_CONT, DQ_CONT_SDRAM, DQ_CONT_USER, LDQM, UDQM, Vcc, VccQ, Vss, VssQ);
parameter tRSC = 20;		// delay after a new command may be issued after the mode register set command 
parameter tRCD = 20;		// delay from Bank Activate command to first read or write operation can begin
parameter tRC = 20;		// the minimum time interval between successive Bank Activate commands to the same bank
parameter tRRD = 20;		// the minimum time interval between interleaved Bank Activate commands
parameter tRAS = 300;	// the maximum time that each bank can be held active
parameter tRP = 20;		// the delay between the Bank Precharge Command and the Bank Activate Command
parameter tAC = 20;		// delay time after Self Refresh Operation and before the next command can be issued

parameter POWER_UP = 4'b1111, POWER_DOWN = 4'b0000, IDLE = 4'b1000, MODE_REG = 4'b1001, ACTIVE_POWER_DOWN = 4'b0001, ROW_ACTIVE = 4'b0111, READ = 4'b0110, WRITE = 0011, PRECHARGE = 4'b0100, SELF_REFRESH = 4'b0101, DEVICE_DESELECT = 4'b1001;

input [30*8:1] Command;			// 30 characters string variable
input [8:1] Burst_length, Accessing_mode, CAS_latency;
input [5*8:1] Single_write_mode;
input [21:0] Address;
input clk_crontroller;
output reg [11:0] A;
output reg [1:0] BS;
output reg CKE, CS, RAS, CAS, WE, LDQM, UDQM, VccQ, VssQ, Vcc, Vss;
output clk_sdram;
output reg [15:0] DQ_CONT_SDRAM, DQ_CONT_USER;
input [15:0] DQ_SDRAM_CONT, DQ_USER_CONT;
reg [15:0] DQ;
reg [30*8:1] Operation;			// 30 characters string variable
integer bur_len, cas_lat;			// burst length in integer form
reg write_mem, read_mem, select;
reg [3:0] STATE, NEXT, PREV;

assign clk_sdram = clk_crontroller;

always @(Operation)
begin
	case (Operation)
		"power_up": begin
			STATE = POWER_UP;
			$display("time = %0t\tExecuting 'power_up' command\nCurrent State = %b\n", $time, STATE);
			{Vcc, VccQ, Vss, VssQ} = 4'b1100;
			{UDQM, LDQM, CKE} = 3'b111;	// to prevent data contention on the DQ bus during power up
			// precharge_all;
			#200;	// 200uS delay is required during power_up
			Auto_refresh_cycles(3'b111);
			mode_reg(CS, RAS, CAS, WE, BS, A, Address, Burst_length, Accessing_mode, CAS_latency, Single_write_mode);
			Auto_refresh_cycles(3'b111);
		end
		
		"mode_reg_set": begin
			STATE = MODE_REG;
			$display("time = %0t\tExecuting 'mode_reg_set' command\nCurrent State = %b\n", $time, STATE);
			CKE = 1;
			#clk_period;
			mode_reg(CS, RAS, CAS, WE, BS, A, Address, Burst_length, Accessing_mode, CAS_latency, Single_write_mode);
		end
		
		"no_operation": begin
			STATE = IDLE;
			$display("time = %0t\tExecuting 'no_operation' command\nCurrent State = %b\n", $time, STATE);
			{CKE, CS, RAS, CAS, WE} = 5'b10111;	// go to idle state
		end
		
		"clock_suspend": begin			// clk disabled
			STATE = ACTIVE_POWER_DOWN;
			$display("time = %0t\tExecuting 'clock_suspend' command\nCurrent State = %b\n", $time, STATE);
			CKE = 0;
			#clk_period;
		end
		
		"clock_enable": begin			// clk enabled
			STATE = NEXT;
			$display("time = %0t\tExecuting 'clock_enable' command\nCurrent State = %b\n", $time, STATE);
			CKE = 1;
			#clk_period;
		end
		
		"bank_activate": begin
			STATE = ROW_ACTIVE;
			$display("time = %0t\tExecuting 'bank_activate' command\nCurrent State = %b\n", $time, STATE);
			BS = Address[21:20];
			// precharge(BS);
			A = Address[19:8];
			{CKE, CS, RAS, CAS, WE} = 5'b10011;
			#tRCD;
		end
		
		"read": begin		// burst_read command
			STATE = READ;
			$display("time = %0t\tExecuting 'read' command\nCurrent State = %b\n", $time, STATE);
			A = {1'bx, 1'b0, 2'bxx, Address[7:0]};
			{CKE, CS, RAS, CAS, WE} = 5'b10101;
			#1;
			read_mem = 1;
			// for(j=0 ; j<(bur_len+cas_lat) ; j=j+1)
			#(clk_period*(bur_len+cas_lat));	// hold read_mem = 1 till no. of (Burst_length+CAS_latency) clock cycles delay
			read_mem = 0;
		end
		
		"write": begin
			STATE = WRITE;
			$display("time = %0t\tExecuting 'write' command\nCurrent State = %b\n", $time, STATE);
			A = {1'bx, 1'b0, 2'bxx, Address[7:0]};
			{CKE, CS, RAS, CAS, WE} = 5'b10100;
			#1;
			write_mem = 1;
			// for(j=0 ; j<8 ; j=j+1)
			#(clk_period*bur_len);				// hold write_mem = 1 till no. of Burst_length clock cycles delay
			write_mem = 0;
		end
		
		"bank_precharge": begin
			STATE = PRECHARGE;
			$display("time = %0t\tExecuting 'bank_precharge' command\nCurrent State = %b\n", $time, STATE);
			{BS, A[10]} = {Address[21:20], 1'b0};
			{CKE, CS, RAS, CAS, WE} = 5'b10010;
			#tRP;
		end
		
		"selt_refresh": begin
			STATE = SELF_REFRESH;
			$display("time = %0t\tExecuting 'selt_refresh' command\nCurrent State = %b\n", $time, STATE);
			{CKE, CS, RAS, CAS, WE} = 5'b00001;
			{BS, A, UDQM, LDQM} = 16'bx;
			#20;
			{CKE, CS, RAS, CAS, WE} = 5'b10111;		// return to idle state
			#tAC;
		end
		
		"power_down": begin								// Sleep mode
			STATE = POWER_DOWN;
			$display("time = %0t\tExecuting 'power_down' command\nCurrent State = %b\n", $time, STATE);
			CKE = 1;
			#clk_period {CKE, CS, RAS, CAS, WE} = 5'b01xxx;
		end
		
		"power_down_end": begin
			STATE = IDLE;
			$display("time = %0t\tExecuting 'power_down_end' command\nCurrent State = %b\n", $time, STATE);
			#clk_period {CKE, CS, RAS, CAS, WE} = 5'b10111;		// return to idle state
		end
		
		default: begin
			STATE = DEVICE_DESELECT;
			$display("time = %0t\tExecuting 'device_deselect' command\nCurrent State = %b\n", $time, STATE);
			CKE = 1;
			#1 {CKE, CS, RAS, CAS, WE} = 5'b01xxx;			// device deselect mode
		end
	endcase
end

initial begin
	PREV = DEVICE_DESELECT;
	STATE = DEVICE_DESELECT;
	NEXT = DEVICE_DESELECT;
end

always @(Burst_length)
begin
	case (Burst_length)
		"1": bur_len = 1;
		"2": bur_len = 2;
		"4": bur_len = 4;
		"8": bur_len = 8;
		default: bur_len = 0;
	endcase
end

always @(CAS_latency)
begin
	case (CAS_latency)
		"2": cas_lat = 2;
		"3": cas_lat = 3;
		default: cas_lat = 0;
	endcase
end

always @(posedge write_mem or posedge read_mem)		// 2x1 decoder
begin
	if(write_mem)
		select = 1;
	if(read_mem)
		select = 0;
end

//assign DQ_SDRAM = (select == 1)?DQ:DQ_SDRAM;
//assign DQ_USER = (select == 0)?DQ:DQ_USER;

always begin
	wait(write_mem | read_mem);		// first check for write_mem == 1 or read_mem == 1
	@(posedge clk_crontroller);		// than at every posedge clk always statement will execute
	if(select)
		DQ_CONT_SDRAM = DQ_USER_CONT;
	else
		DQ_CONT_USER = DQ_SDRAM_CONT;
	#1 $display("time = %0t\tDQ_USER_CONT = %h\t\tDQ_SDRAM_CONT = %h\tDQ_CONT_USER = %h\t\tDQ_CONT_SDRAM = %h\n", $time, DQ_USER_CONT, DQ_SDRAM_CONT, DQ_CONT_USER, DQ_CONT_SDRAM);
end

task mode_reg;		/* inside SDRAM mode_reg_content[7:0] = {A[9], A[6:0]} */
	output cs, ras, cas, we;
	output [1:0] bs;
	output [11:0] a;
	input [21:0] address;
	input [8:1] bl, am, cl;
	input [5*8:1] swm;
	begin
		{bs, a[11:10], a[8:7]} = 6'b0;
		case (bl)
			"1": a[2:0] = 3'b000;
			"2": a[2:0] = 3'b001;
			"4": a[2:0] = 3'b010;
			"8": a[2:0] = 3'b011;
			"f": a[2:0] = 3'b111;
			default: a[2:0] = 3'bxxx;
		endcase
		a[3] = (am == "s")?0:((am == "i")?1:1'bx);
		case (cl)
			"2": a[6:4] = 3'b010;
			"3": a[6:4] = 3'b011;
			default: a[6:4] = 3'bxxx;
		endcase
		a[9] = (swm == "br&bw")?0:((swm == "br&sw")?1:1'bx);
		{cs, ras, cas, we} = 4'b0000;
		#tRSC;
	end
endtask

task Auto_refresh_cycles;
	input [2:0] n;	// no. of auto_refresh_cycles
	integer num;
	begin
		num = n;
		#(clk_period*num);
	end
endtask

always @(Command)
begin
	case (STATE)
		DEVICE_DESELECT: begin
			if(Command == "power_up")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = DEVICE_DESELECT, next command can only be 'power_up'!!!\n");
		end
		
		POWER_UP: begin
			if(Command == "no_operation")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = POWER_UP, next command can only be 'no_operation'!!!\n");
		end
		
		POWER_DOWN: begin
			if(Command == "power_down_end")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = POWER_DOWN, next command can only be 'power_down_end'!!!\n");
		end
		
		IDLE: begin
			if((Command == "power_down") | (Command == "mode_reg_set") | (Command == "self_refresh") | (Command == "bank_activate") | (Command == "no_operation"))
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = IDLE, next command can only be {'power_up', 'mode_reg_set', 'self_refresh', 'bank_activate', 'no_operation'}!!!\n");
		end
		
		MODE_REG: begin
			if(Command == "no_operation")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = MODE_REG, next command can only be 'no_operation'!!!\n");
		end
		
		ROW_ACTIVE: begin
			if((Command == "read") | (Command == "write") | (Command == "bank_precharge") | (Command == "clock_suspend"))
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = ROW_ACTIVE, next command can only be {'read', 'write', 'bank_precharge', 'clock_suspend'}!!!\n");
		end
		
		READ: begin
			if((Command == "read") | (Command == "write") | (Command == "bank_precharge") | (Command == "clock_suspend"))
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = READ, next command can only be {'read', 'write', 'bank_precharge', 'clock_suspend'}!!!\n");
		end
		
		WRITE: begin
			if((Command == "read") | (Command == "write") | (Command == "bank_precharge") | (Command == "clock_suspend"))
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = WRITE, next command can only be {'read', 'write', 'bank_precharge', 'clock_suspend'}!!!\n");
		end
		
		PRECHARGE: begin
			if(Command == "no_operation")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = PRECHARGE, next command can only be 'no_operation'!!!\n");
		end
		
		SELF_REFRESH: begin
			if(Command == "no_operation")
			begin
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = SELF_REFRESH, next command can only be 'no_operation'!!!\n");
		end
		
		ACTIVE_POWER_DOWN: begin
			if(Command == "clock_enable")
			begin
				NEXT = PREV;
				PREV = STATE;
				Operation = Command;
			end
			else
				$display("Error: Current_State = ACTIVE_POWER_DOWN, next command can only be 'clock_enable'!!!\n");
		end
		
		default: Operation = "no_operation";
	endcase
end

endmodule
