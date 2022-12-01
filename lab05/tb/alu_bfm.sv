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
interface alu_bfm;
import alu_pkg::*;


	bit                  clk;
	bit                  rst_n;
	bit                  enable_n;
	bit                  din;
	logic                dout;
	bit                  dout_valid;
	bit 				 done;


	bit           [7:0] A, B;
	bit           [7:0] status;
	bit           [7:0] data_msb;
	bit           [7:0] data_lsb;
	bit           [15:0] data_result;
	wire          [7:0]  op;

	operation_t          op_set;

	assign op = op_set;
	assign data_result = {data_msb, data_lsb};

//------------------------------------------------------------------------------
// clock generator
//------------------------------------------------------------------------------
	initial begin : clk_gen_blk
		clk = 0;
		forever begin : clk_frv_blk
			#10;
			clk = ~clk;
		end
	end

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

		@(negedge clk);
		done = 1;
		@(negedge clk);
		done = 0;
		
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



endinterface : alu_bfm


