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
class scoreboard extends uvm_subscriber #(result_transaction);
    `uvm_component_utils(scoreboard)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    uvm_tlm_analysis_fifo #(command_transaction) cmd_f;
    protected test_result_t test_result = TEST_PASSED;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// function to calculate the expected ALU result
//------------------------------------------------------------------------------
	function logic [15:0] get_expected_data(
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

	endfunction : get_expected_data

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
	
	function result_transaction get_expected_result(command_transaction cmd);
		result_transaction ret;
		bit [7:0] status;
		bit [15:0] data;
		
		status = get_expected_status(cmd.op);
		data = get_expected_data(cmd.A, cmd.B, cmd.op);
		ret.result = {status, data};
		
		return(ret);

	endfunction : get_expected_result
	
	protected function void print_test_result (test_result_t r);
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
        cmd_f = new ("cmd_f", this);
    endfunction : build_phase


//------------------------------------------------------------------------------
// subscriber write function
//------------------------------------------------------------------------------
    function void write(result_transaction t);
	    
	    string data_str;
		result_transaction predicted_result;
        command_transaction cmd;
	    
        cmd.A            = 0;
        cmd.B            = 0;
        cmd.op           = CMD_NOP;

        do
            if (!cmd_f.try_get(cmd))
                $fatal(1, "Missing command in self checker");
        while (cmd.op == CMD_NOP);
        predicted_result = get_expected_result(cmd);

        data_str  = { cmd.convert2string(),
            " ==>  Actual " , t.convert2string(),
            "/Predicted ",predicted_result.convert2string()};

        if (!predicted_result.compare(t)) begin
            `uvm_error("SELF CHECKER", {"FAIL: ",data_str})
            test_result = TEST_FAILED;
        end
        else
            `uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)
            
    endfunction : write

//------------------------------------------------------------------------------
// report phase
//------------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        print_test_result(test_result);
    endfunction : report_phase

endclass : scoreboard






