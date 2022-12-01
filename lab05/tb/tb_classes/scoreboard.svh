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
class scoreboard extends uvm_component;
	`uvm_component_utils(scoreboard)
	
//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual alu_bfm bfm;
	protected test_result_t test_result = TEST_PASSED;
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
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

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
	    
		logic [15:0] predicted_result;
		logic [7:0] predicted_status;
	    
        forever begin : self_checker
            @(negedge bfm.clk)
                if(bfm.done) begin : check_data
	                bfm.deserializer();
					predicted_result = get_expected(bfm.A, bfm.B, bfm.op_set);
					predicted_status = get_expected_status(bfm.op_set);
					// deleted if from here, maybe begin end will break
                        SCOREBOARD_CHECK:
                        assert((bfm.data_result === predicted_result) && (bfm.status === predicted_status)) begin
                            `ifdef DEBUG
                            $display("%0t Test passed for A=%0d B=%0d op_set=%0d", $time, bfm.A, bfm.B, bfm.op);
                            `endif
                        end
                        else begin
                            $error ("FAILED: A: %0h  B: %0h  op: %s result: %0h",
                                bfm.A, bfm.B, bfm.op_set.name(), bfm.data_result);
                            test_result = TEST_FAILED;
                        end
                end : check_data
        end : self_checker
    endtask : run_phase

//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        print_test_result(test_result);
    endfunction : report_phase

endclass : scoreboard







