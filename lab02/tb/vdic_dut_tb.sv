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

module top;

//------------------------------------------------------------------------------
// Type definitions
//------------------------------------------------------------------------------
	typedef enum bit[7:0] {
		S_NO_ERROR = 8'b00000000,
		S_MISSING_DATA = 8'b00000001,
		S_DATA_STACK_OVERFLOW = 8'b00000010,
		S_OUTPUT_FIFO_OVERFLOW = 8'b00000100,
		S_DATA_PARITY_ERROR = 8'b00100000,
		S_COMMAND_PARITY_ERROR = 8'b01000000,
		S_INVALID_COMMAND = 8'b10000000	
	} status_t;

	typedef enum bit {
		CONTROL = 1'b1,
		DATA = 1'b0
	} payload_type_t;

	typedef enum bit[7:0] {
		CMD_NOP = 8'b00000000,
		CMD_AND = 8'b00000001,
		CMD_OR = 8'b00000010,
		CMD_XOR = 8'b00000011,
		CMD_ADD = 8'b00010000,
		CMD_SUB = 8'b00100000
	} operation_t;

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;

	typedef enum bit {
		TEST_DONE,
		TEST_IN_PROGRESS
	} test_progress_t;

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
	bit           [7:0] data_msb;
	bit           [7:0] data_lsb;
	bit           [15:0] data_result;
	wire          [7:0]  op;

// Add all of the required arguments here

	operation_t          op_set;
	assign op = op_set;
	assign data_result = {data_msb, data_lsb};

	test_result_t        test_result = TEST_PASSED;
	test_progress_t      test_progress = TEST_IN_PROGRESS;

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
		bit [2:0] op_choice;
		op_choice = 3'($random);
		case (op_choice)
			3'b000 : return CMD_NOP;
			3'b001 : return CMD_AND;
			3'b010 : return CMD_OR;
			3'b011 : return CMD_XOR;
			3'b100 : return CMD_ADD;
			3'b101 : return CMD_SUB;
			3'b110 : return 8'($random);
			3'b111 : return 8'($random);
		endcase // case (op_choice)
	endfunction : get_op
//---------------------------------
	function byte get_data();

		bit [1:0] data_choice;

		data_choice = 2'($random);

		if (data_choice == 2'b00)
			return 8'h00;
		else if (data_choice == 2'b11)
			return 8'hFF;
		else
			return 8'($random);
	endfunction : get_data

//------------------------
// Tester main

	initial begin : tester
		reset_alu();
		repeat (1000) begin : tester_main_blk
			@(negedge clk);
			test_progress = TEST_IN_PROGRESS;
			op_set = get_op();
			A      = get_data();
			B      = get_data();
			serializer(A,DATA);
			serializer(B,DATA);
			serializer(op_set,CONTROL);
			@(negedge clk);
			enable_n  = 1'b1;
			case (op_set)
				default: begin : case_default_blk

					deserializer();
					test_progress = TEST_DONE;

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
// serializer task
//------------------------------------------------------------------------------

	task serializer(input bit [7:0] data, payload_type_t payload_bit);

		bit [9:0] word;
		static bit parity_bit = 0;

		assign word = {payload_bit, data, parity_bit};

		parity_bit = calculate_parity(word);

		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			din = word[9-i];
			enable_n  = 1'b0;
		end

	endtask

//------------------------------------------------------------------------------
// deserializer task
//------------------------------------------------------------------------------

	task deserializer();

		bit [9:0] status_word, data_msb_word, data_lsb_word;

		assign status = status_word[8:1];
		assign data_msb = data_msb_word[8:1];
		assign data_lsb = data_lsb_word[8:1];

		wait(dout_valid);

		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			status_word[9-i] = dout;
		end
		assert(calculate_parity(status_word) == status_word[0]);


		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			data_msb_word[9-i] = dout;
		end
		assert(calculate_parity(data_msb_word) == data_msb_word[0]);

		for (int i = 0 ; i < 10 ; i++)
		begin
			@(negedge clk);
			data_lsb_word[9-i] = dout;
		end
		assert(calculate_parity(data_lsb_word) == data_lsb_word[0]);


		begin
			`ifdef DEBUG
			$display("Deserializer received:");
			$display("Status: %b", status_word);
			$display("Data MSB: %b", data_msb_word);
			$display("Data LSB: %b", data_lsb_word);
			$display("Data is %h", data_result);
			`endif
		end

	endtask

	function bit calculate_parity(bit [9:0] word);
		automatic bit parity_bit = 0;
		for (int i = 1 ; i < 10 ; i++)
		begin
			if (word[i] == 1)
				parity_bit = !parity_bit;
		end

		return parity_bit;

	endfunction : calculate_parity

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
			CMD_XOR : ret    = A ^ B;
			CMD_NOP : ret    = 16'h0000;
			CMD_OR  : ret    = A | B;
			CMD_SUB : ret    = A - B;
			default: begin
				`ifdef DEBUG
				$display("Randomized operation was %d",op_set);
				`endif
				ret = 16'h0000;
			end
		endcase
		`ifdef DEBUG
		$display("Get expected says we should have data result = %d",ret);
		`endif
		return(ret);
	endfunction : get_expected

	function logic [7:0] get_expected_status(
			operation_t op_set
		);
		bit [7:0] ret;
	`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, A, B, op_set);
	`endif
		case(op_set)
			CMD_AND : ret    = S_NO_ERROR;
			CMD_ADD : ret    = S_NO_ERROR;
			CMD_XOR : ret    = S_NO_ERROR;
			CMD_NOP : ret    = S_NO_ERROR;
			CMD_OR  : ret    = S_NO_ERROR;
			CMD_SUB : ret    = S_NO_ERROR;
			default: begin
				`ifdef DEBUG
				$display("Randomized operation was %d", op_set);
				`endif
				ret = S_INVALID_COMMAND;
			end
		endcase
		`ifdef DEBUG
		$display("Get expected says we should have data result = %d",ret);
		`endif
		return(ret);
	endfunction : get_expected_status

//------------------------------------------------------------------------------
// Coverage block
//------------------------------------------------------------------------------

// Covergroup checking for min and max arguments of the ALU
	covergroup zeros_or_ones_on_ops;

		option.name = "cg_zeros_or_ones_on_ops";

		valid_ops: coverpoint op {
			bins add_op = {CMD_ADD};
			bins and_op = {CMD_AND};
			bins or_op = {CMD_OR};
			bins xor_op = {CMD_XOR};
			bins nop_op = {CMD_NOP};
			bins sub_op = {CMD_SUB};
		}

		a_leg: coverpoint A {
			bins zeros = {'h00};
			bins others= {['h01:'hFE]};
			bins ones  = {'hFF};
		}

		b_leg: coverpoint B {
			bins zeros = {'h00};
			bins others= {['h01:'hFE]};
			bins ones  = {'hFF};
		}

		B_op_00_FF: cross a_leg, b_leg, valid_ops {

			// Simulate all zero/ones input for all the valid operations.

			bins B1_add_op_00          = binsof (valid_ops) intersect {CMD_ADD} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
			bins B2_and_op_00          = binsof (valid_ops) intersect {CMD_AND} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
			bins B3_xor_op_00          = binsof (valid_ops) intersect {CMD_XOR} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
			bins B4_or_op_00          = binsof (valid_ops) intersect {CMD_OR} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
			bins B5_sub_op_00          = binsof (valid_ops) intersect {CMD_SUB} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
			bins B6_nop_op_00          = binsof (valid_ops) intersect {CMD_NOP} && (binsof (a_leg.zeros) || binsof (b_leg.zeros));
		
			
			bins B7_add_op_FF          = binsof (valid_ops) intersect {CMD_ADD} && (binsof (a_leg.ones) || binsof (b_leg.ones));
			bins B8_and_op_FF          = binsof (valid_ops) intersect {CMD_AND} && (binsof (a_leg.ones) || binsof (b_leg.ones));
			bins B9_xor_op_FF           = binsof (valid_ops) intersect {CMD_XOR} && (binsof (a_leg.ones) || binsof (b_leg.ones));
			bins B10_or_op_FF           = binsof (valid_ops) intersect {CMD_OR} && (binsof (a_leg.ones) || binsof (b_leg.ones));
			bins B11_sub_op_FF           = binsof (valid_ops) intersect {CMD_SUB} && (binsof (a_leg.ones) || binsof (b_leg.ones));
			bins B12_nop_op_FF           = binsof (valid_ops) intersect {CMD_NOP} && (binsof (a_leg.ones) || binsof (b_leg.ones));

			ignore_bins others_only = binsof(a_leg.others) && binsof(b_leg.others);
		}

		B_op_regular: cross a_leg, b_leg, valid_ops {

			// Simulate regular input on operations

			bins B1_add_op_regular          = binsof (valid_ops) intersect {CMD_ADD} && (binsof (a_leg.others) || binsof (b_leg.others));
			bins B2_and_op_regular          = binsof (valid_ops) intersect {CMD_AND} && (binsof (a_leg.others) || binsof (b_leg.others));
			bins B3_xor_op_regular          = binsof (valid_ops) intersect {CMD_XOR} && (binsof (a_leg.others) || binsof (b_leg.others));
			bins B4_or_op_regular          = binsof (valid_ops) intersect {CMD_OR} && (binsof (a_leg.others) || binsof (b_leg.others));
			bins B5_sub_op_regular          = binsof (valid_ops) intersect {CMD_SUB} && (binsof (a_leg.others) || binsof (b_leg.others));
			bins B6_nop_op_regular          = binsof (valid_ops) intersect {CMD_NOP} && (binsof (a_leg.others) || binsof (b_leg.others));
		
		}

	endgroup

// Covergroup checking for irregular operations.
	covergroup irregular_ops;

		option.name = "cg_irregular_ops";

		invalid_ops: coverpoint op {
			ignore_bins valid_ops = {CMD_ADD,CMD_AND,CMD_NOP,CMD_XOR,CMD_OR,CMD_SUB};
		}

	endgroup

	zeros_or_ones_on_ops        c_00_FF;
	irregular_ops       c_irregular_ops;

	initial begin : coverage
		c_00_FF = new();
		c_irregular_ops = new();
		forever begin : sample_cov
			@(posedge enable_n);
			begin
				c_00_FF.sample();
				c_irregular_ops.sample();
			end
		end
	end : coverage

//------------------------------------------------------------------------------
// Scoreboard - demo
//------------------------------------------------------------------------------
	always @(negedge clk) begin : scoreboard
		if(test_progress == TEST_DONE) begin:verify_result

			automatic bit [15:0] predicted_result = get_expected(A, B, op_set);
			automatic bit [7:0] predicted_status = get_expected_status(op_set);

			CHK_RESULT: assert((data_result === predicted_result) && (status === predicted_status)) begin
		   `ifdef DEBUG
				$display("%0t Test passed for A=%0d B=%0d op_set=%0d", $time, A, B, op);
		   `endif
			end
			else begin
				test_result <= TEST_FAILED;
				print_test_result(test_result);
				$error("%0t Test FAILED for A=%0d B=%0d op_set=%0d\nExpected: %d  received: %d",
					$time, A, B, op_set , predicted_result, data_result);
			end;
			test_progress = TEST_IN_PROGRESS; // Ignore the dvt warning, we know better.
		end
	end : scoreboard

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
