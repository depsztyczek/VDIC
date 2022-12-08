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
import alu_pkg::*;

//------------------------------------------------------------------------------
// the interface
//------------------------------------------------------------------------------

interface alu_bfm;

//------------------------------------------------------------------------------
// dut connections
//------------------------------------------------------------------------------

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
bit           [23:0] result;
wire          [7:0]  op;

operation_t          op_set;

assign op = op_set;
assign data_result = {data_msb, data_lsb};
assign result = {status, data_result};

command_monitor command_monitor_h;
result_monitor result_monitor_h;
    
//------------------------------------------------------------------------------
// DUT reset task
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
// send transaction to DUT
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

function bit calculate_parity(bit [9:0] word);
	automatic bit parity_bit = 0;
	for (int i = 1 ; i < 10 ; i++)
	begin
		if (word[i] == 1)
			parity_bit = !parity_bit;
	end

	return parity_bit;

endfunction : calculate_parity
	
task send_op(input byte iA, input byte iB, input operation_t iop, shortint result);

    op_set = iop;
    A      = iA;
    B      = iB;

	serializer(A,DATA);
	serializer(B,DATA);
	serializer(op_set,CONTROL);
	@(negedge clk);
	enable_n  = 1'b1;

endtask : send_op

//------------------------------------------------------------------------------
// write command monitor
//------------------------------------------------------------------------------

always @(posedge clk) begin : op_monitor
    static bit in_command = 0;
    command_s command;
    if (!enable_n) begin : enable_n_low
        if (!in_command) begin : new_command
            command.A  = A;
            command.B  = B;
            command.op = op_set;
            command_monitor_h.write_to_monitor(command);
        end : new_command
    end : enable_n_low
    else // enable_n high
        in_command = 0;
end : op_monitor

always @(negedge rst_n) begin : rst_monitor
    command_s command;
    command.op = CMD_NOP;
    if (command_monitor_h != null) //guard against VCS time 0 negedge
        command_monitor_h.write_to_monitor(command);
end : rst_monitor


//------------------------------------------------------------------------------
// write result monitor
//------------------------------------------------------------------------------

initial begin : result_monitor_thread
    forever begin
        @(posedge clk) ;
        if (done)
            result_monitor_h.write_to_monitor(result);
    end
end : result_monitor_thread

//------------------------------------------------------------------------------
// clock generator
//------------------------------------------------------------------------------

initial begin
    clk = 0;
    forever begin
        #10;
        clk = ~clk;
    end
end



endinterface : alu_bfm
