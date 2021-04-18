`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:44:27 04/11/2021
// Design Name:   SDRAM_Controller
// Module Name:   /home/ise/Xilinx_Projects/SDRAM_Controller/SDRAM_Controller_tb_1.v
// Project Name:  SDRAM_Controller
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: SDRAM_Controller
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module SDRAM_Controller_tb_1;

	// Inputs
	reg [240:1] Command;
	reg [21:0] Address;
	reg [8:1] Burst_length;
	reg [8:1] Accessing_mode;
	reg [8:1] CAS_latency;
	reg [40:1] Single_write_mode;
	reg clk_crontroller;
	reg [15:0] DQ_SDRAM_CONT;
	reg [15:0] DQ_USER_CONT;

	// Outputs
	wire [11:0] A;
	wire [1:0] BS;
	wire clk_sdram;
	wire CKE;
	wire CS;
	wire RAS;
	wire CAS;
	wire WE;
	wire LDQM;
	wire UDQM;
	wire Vcc;
	wire VccQ;
	wire Vss;
	wire VssQ;
	wire [15:0] DQ_CONT_SDRAM;
	wire [15:0] DQ_CONT_USER;

	/* // Bidirs
	// wire [15:0] DQ_SDRAM;
	// wire [15:0] DQ_USER;
	
	// reg write_mem, read_mem;
	// reg [15:0] dq; */

	// Instantiate the Unit Under Test (UUT)
	SDRAM_Controller uut (
		.Command(Command), 
		.Address(Address), 
		.Burst_length(Burst_length), 
		.Accessing_mode(Accessing_mode), 
		.CAS_latency(CAS_latency), 
		.Single_write_mode(Single_write_mode), 
		.A(A), 
		.BS(BS), 
		.clk_crontroller(clk_crontroller), 
		.clk_sdram(clk_sdram), 
		.CKE(CKE), 
		.CS(CS), 
		.RAS(RAS), 
		.CAS(CAS), 
		.WE(WE), 
		.DQ_SDRAM_CONT(DQ_SDRAM_CONT), 
		.DQ_USER_CONT(DQ_USER_CONT), 
		.DQ_CONT_SDRAM(DQ_CONT_SDRAM), 
		.DQ_CONT_USER(DQ_CONT_USER),
		.LDQM(LDQM), 
		.UDQM(UDQM), 
		.Vcc(Vcc), 
		.VccQ(VccQ), 
		.Vss(Vss), 
		.VssQ(VssQ)
	);

	initial begin
		// Initialize Inputs
		Command = "power_up";
		Address = 22'bx;
		Burst_length = "4";
		Accessing_mode = "s";
		CAS_latency = "2";
		Single_write_mode = "br&bw";
		clk_crontroller = 0;
		#400 Command = "no_operation";
		#40 Address = {2'b00, 3'haf4, 2'h5d};
		Command = "bank_activate";
		#40 Command = "bank_precharge";
		#40 Command = "read";
		#40 Command = "no_operation";
		#40 Command = "bank_activate";
		#40 Command = "write";
		#100 Command = "read";
		#100 Command = "bank_precharge";
		#40 Command = "end_task";
		// Wait 100 ns for global reset to finish
		#100;
		$finish;
        
		// Add stimulus here

	end
	
	always #5 clk_crontroller = ~clk_crontroller;
	
	always begin
		wait((Command == "write"))
		@(posedge clk_crontroller)
		DQ_USER_CONT = $random %16;
	end
	always begin
		wait((Command == "read"))
		@(posedge clk_crontroller)
		DQ_SDRAM_CONT = $random %16;
	end
   // assign DQ_USER = (write_mem) ? dq : 16'b0;
		
endmodule

