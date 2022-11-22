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
 */
class scoreboard;

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    virtual alu_bfm bfm;
	test_result_t   test_result = TEST_PASSED;
	logic [15:0] predicted_result;
	logic [7:0] predicted_status;
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (virtual alu_bfm b);
        bfm = b;
    endfunction : new

//------------------------------------------------------------------------------
// local tasks & functions
//------------------------------------------------------------------------------

	function logic [15:0] get_expected(
			bit [7:0] A,
			bit [7:0] B,
			operation_t op_set
		);

		bit [15:0] ret;

		case(op_set)
			CMD_AND : ret    = A & B;
			CMD_ADD : ret    = A + B;
			CMD_XOR : ret    = A ^ B;
			CMD_NOP : ret    = 16'h0000;
			CMD_OR  : ret    = A | B;
			CMD_SUB : ret    = A - B;
			default: begin
				ret = 16'h0000;
			end
		endcase

		return(ret);

	endfunction : get_expected

	function logic [7:0] get_expected_status(
			operation_t op_set
		);

		bit [7:0] ret;

		case(op_set)
			CMD_AND : ret    = S_NO_ERROR;
			CMD_ADD : ret    = S_NO_ERROR;
			CMD_XOR : ret    = S_NO_ERROR;
			CMD_NOP : ret    = S_NO_ERROR;
			CMD_OR  : ret    = S_NO_ERROR;
			CMD_SUB : ret    = S_NO_ERROR;

			default: begin
				ret = S_INVALID_COMMAND;
			end

		endcase

		return(ret);

	endfunction : get_expected_status
	
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


    task execute();
	    
        forever begin : self_checker

        	@(negedge bfm.clk);  //copied without always 
			if(bfm.test_progress == TEST_DONE) begin:verify_result
	
				predicted_result = get_expected(bfm.A, bfm.B, bfm.op_set);
				predicted_status = get_expected_status(bfm.op_set);
	
				CHK_RESULT: assert((bfm.data_result === predicted_result) && (bfm.status === predicted_status)) begin
		   `ifdef DEBUG
					$display("%0t Test passed for A=%0d B=%0d op_set=%0d", $time, bfm.A, bfm.B, bfm.op);
		   `endif
		   		end
			end
			else begin
				test_result = TEST_FAILED;
				print_test_result(test_result);
				$error("%0t Test FAILED for A=%0d B=%0d op_set=%0d\nExpected: %d  received: %d",
					$time, bfm.A, bfm.B, bfm.op_set, predicted_result, bfm.data_result);
			end;
			bfm.test_progress = TEST_IN_PROGRESS; // Ignore the dvt warning, we know better.
		end
            
    endtask : execute

endclass : scoreboard






