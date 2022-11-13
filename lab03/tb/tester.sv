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
module tester(tinyalu_bfm bfm);
    
import tinyalu_pkg::*;


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


initial begin : tester
	
	bfm.reset_alu();
	repeat (1000) begin : tester_main_blk
		@(negedge bfm.clk);
		bfm.test_progress = TEST_IN_PROGRESS;
		bfm.op_set = get_op();
		bfm.A      = get_data();
		bfm.B      = get_data();
		bfm.serializer(bfm.A,DATA);
		bfm.serializer(bfm.B,DATA);
		bfm.serializer(bfm.op_set,CONTROL);
		@(negedge bfm.clk);
		bfm.enable_n  = 1'b1;
		case (bfm.op_set)
			default: begin : case_default_blk
				bfm.deserializer();
				bfm.test_progress = TEST_DONE;
			end : case_default_blk
		endcase // case (op_set)
	end : tester_main_blk
	$finish;
end : tester


endmodule : tester
