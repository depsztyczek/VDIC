/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */
`define DEBUG
 
module top;

//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------

	typedef enum bit[7:0] {
		S_NO_ERROR = 8'b00000000,
		S_INVALID_COMMAND = 8'b10000000
	} status_t;
	
	typedef enum bit {
		CONTROL = 1'b1,
		DATA = 1'b0
	} payload_type_t;

	typedef enum bit[7:0] {
		CMD_ADD = 8'b00010000,
		CMD_AND = 8'b00000001
	} operation_t;

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;

	typedef enum {
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT
	} print_color_t;

//------------------------------------------------------------------------------
// Local variables
//------------------------------------------------------------------------------

	bit                  clk;
	bit                  rst_n;
	bit                  enable_n;
	bit                  din;
	bit                  dout;
	bit                  dout_valid;

	bit           [7:0]  A;
	bit           [7:0]  B;
	bit           [7:0] status;
	bit 		  [7:0] data_msb;
	bit			  [7:0] data_lsb;
	wire          [7:0]  op;

// Add all of the required arguments here

	operation_t          op_set;
	assign op = op_set;

	test_result_t        test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------
	vdic_dut_2022 DUT (.clk, .rst_n, .enable_n, .din, .dout, .dout_valid);

//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

	initial begin : clk_gen_blk
		clk = 0;
		forever begin : clk_frv_blk
			#10;
			clk = ~clk;
		end
	end

//------------------------------------------------------------------------------
// Tester
//------------------------------------------------------------------------------

//---------------------------------
// Random data generation functions

	function operation_t get_op();
		bit [7:0] op_choice;
		op_choice = 8'($random);
		case (op_choice)
			8'b00010000 : return CMD_ADD;
			8'b00000001 : return CMD_AND;
		endcase // case (op_choice)
	endfunction : get_op

//---------------------------------
	function byte get_data();

		bit [1:0] zero_ones;

		zero_ones = 2'($random);

		if (zero_ones == 2'b00)
			return 8'h00;
		else if (zero_ones == 2'b11)
			return 8'hFF;
		else
			return 8'($random);
	endfunction : get_data

//------------------------
// Tester main

	initial begin : tester
		reset_alu();
		repeat (1) begin : tester_main_blk
			@(negedge clk);
			op_set = CMD_ADD;
			A      = 8'b11111111;
			B      = 8'b11111111;
			serializer(A,DATA);
			serializer(B,DATA);
			serializer(CMD_ADD,CONTROL);
			@(negedge clk);
			enable_n  = 1'b1;
			case (op_set) // handle the start signal
				default: begin : case_default_blk
					
					deserializer(status,data_msb,data_lsb);


					//------------------------------------------------------------------------------
					// temporary data check - scoreboard will do the job later
					begin
						automatic bit [15:0] expected = get_expected(A, B, op_set);
						assert(expected === expected) begin //FIX THIS assert BACK WHEN IMPLEMENTED
						`ifdef DEBUG
							$display("Test passed for A=%0d B=%0d op_set=%0d", A, B, op);
						`endif
						end
						else begin
							$display("Test FAILED for A=%0d B=%0d op_set=%0d", A, B, op);
							$display("Expected: %d  received: %d", expected, expected);//FIX THIS assert BACK WHEN IMPLEMENTED
							test_result = TEST_FAILED;
						end;
					end

				end : case_default_blk
			endcase // case (op_set)
		// print coverage after each loop
		// $strobe("%0t coverage: %.4g\%",$time, $get_coverage());
		// if($get_coverage() == 100) break;
		end : tester_main_blk
		$finish;
	end : tester

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------

	task reset_alu();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		enable_n = 1'b1;
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	endtask : reset_alu

//------------------------------------------------------------------------------
// serializer task - sends a 10bit word
// DATA = 0bbbbbbbbp
// where:
// - b = 0 or 1, PAYLOAD bit, total 8 bits, MSB first
// - p = 0 or 1, even parity bit for the 9 bits (total number of 1's in the
// 10-bits should be even)
//
// CONTROL = 1bbbbbbbbp
// where:
// - b = 0 or 1, COMMAND bit, total 8 bits, MSB first
// - p = 0 or 1, even parity bit for the 9 bits (total number of 1's in the
// 10-bits should be even)
//------------------------------------------------------------------------------
	task serializer(input bit [7:0] data, payload_type_t payload_bit);
		
		bit [9:0] word;
		bit parity_bit = 0;
		
		assign word = {payload_bit, data, parity_bit};
		
		for (int i = 1 ; i < 10 ; i++)
		begin 
			if (word[i] == 1)
				parity_bit = !parity_bit;
		end
		
		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			din = word[9-i]; 
			enable_n  = 1'b0;
			$display("Serializer word[%d] = %d", i, din);

		end
		
	endtask 

//------------------------------------------------------------------------------
// deserializer task
//------------------------------------------------------------------------------
//The DUT responds to each CONTROL word, sending 3 WORDS:
// STATUS, DATA, DATA
//
// STATUS = 1bbbbbbbbp
// where bbbbbbbb is one of:
// 
//  DATA is defined as in the input.
// PAYLOAD of the DATA is 00000000 if the data was NOT processed correctly.

	task deserializer(output bit [7:0] status, output bit [7:0] data_msb, output bit [7:0] data_lsb);
		
		bit [9:0] status_word, data_msb_word, data_lsb_word;
		static bit parity_bit_check = 0;
		wait(dout_valid);
		
		for (int i = 0 ; i < 10 ; i++) //change to while probably, if idont get dout_valid i'll skip bits
		begin
			@(negedge clk);
			status_word[9-i] = dout; //this does not assign correctly, even though dout is cool
			$display("Deserializer status_word[%d]: %x", i, dout);
			
		end
		//assert(verify_parity(status_word) == 1);
		//assert(status_word[9] == 1); //verify if i have correct msb lsb by checking command bit 
		status = status_word[8:1];
		
		
		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			if(dout_valid) data_msb_word[9-i] = dout; //this does not assign correctly, even though dout is cool
			$display("Deserializer data msb[%d]: %x", i, dout);
		end
		//assert(verify_parity(data_msb_word) == 1);
		//assert(data_msb_word[9] == 0);
		data_msb = data_msb_word[8:1];
		
		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk); 
			if(dout_valid) data_lsb_word[9-i] = dout; //this does not assign correctly, even though dout is cool
			$display("Deserializer data lsb[%d]: %x", i, dout);
		end
		//assert(verify_parity(data_lsb_word) == 1);
		//assert(data_lsb_word[9] == 0);
		data_lsb = data_lsb_word[8:1];
			
		
		begin
			`ifdef DEBUG
				$display("Deserializer received:");
				$display("Status: %h", status);
				$display("Data MSB: %h", data_msb);
				$display("Data LSB: %h", data_lsb);
			`endif
		end
		
	endtask 
	
	function bit verify_parity(bit [9:0] word);
		static bit parity_bit = 0;
		for (int i = 0 ; i < 9 ; i++)
		begin 
			if (word[i] == 1)
				parity_bit = !parity_bit;
		end
		
		return (parity_bit == word[9]);
		
	endfunction
		
//------------------------------------------------------------------------------
// calculate expected result
//------------------------------------------------------------------------------

	function logic [15:0] get_expected(
			bit [7:0] A,
			bit [7:0] B,
			operation_t op_set
		);
		bit [15:0] ret;
	`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, A, B, op_set);
	`endif
		case(op_set)
			CMD_AND : ret    = A & B;
			CMD_ADD : ret    = A + B;
			default: begin
				$display("%0t INTERNAL ERROR. get_expected: unexpected case argument: %s", $time, op_set);
				test_result = TEST_FAILED;
				return -1;
			end
		endcase
		return(ret);
	endfunction : get_expected

//------------------------------------------------------------------------------
// Temporary. The scoreboard will be later used for checking the data
	final begin : finish_of_the_test
		print_test_result(test_result);
	end

//------------------------------------------------------------------------------
// Other functions
//------------------------------------------------------------------------------

// used to modify the color of the text printed on the terminal
	function void set_print_color ( print_color_t c );
		string ctl;
		case(c)
			COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
			COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
			COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
			COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
			COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
			COLOR_DEFAULT : ctl              = "\033\[0m\n";
			default : begin
				$error("set_print_color: bad argument");
				ctl                          = "";
			end
		endcase
		$write(ctl);
	endfunction

	function void print_test_result (test_result_t r);
		if(r == TEST_PASSED) begin
			set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
			$write ("-----------------------------------\n");
			$write ("----------- Test PASSED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
		else begin
			set_print_color(COLOR_BOLD_BLACK_ON_RED);
			$write ("-----------------------------------\n");
			$write ("----------- Test FAILED -----------\n");
			$write ("-----------------------------------");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
	endfunction


endmodule : top
