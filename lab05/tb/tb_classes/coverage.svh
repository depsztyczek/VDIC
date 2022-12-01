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
class coverage extends uvm_component;
	`uvm_component_utils(coverage)
	
    virtual alu_bfm bfm;

    protected byte unsigned A;
    protected byte unsigned B;
    protected operation_t op_set;
    

	covergroup zeros_or_ones_on_ops;

		option.name = "cg_zeros_or_ones_on_ops";

		valid_ops: coverpoint bfm.op {
			bins add_op = {CMD_ADD};
			bins and_op = {CMD_AND};
			bins or_op = {CMD_OR};
			bins xor_op = {CMD_XOR};
			bins nop_op = {CMD_NOP};
			bins sub_op = {CMD_SUB};
		}

		a_leg: coverpoint bfm.A {
			bins zeros = {'h00};
			bins others= {['h01:'hFE]};
			bins ones  = {'hFF};
		}

		b_leg: coverpoint bfm.B {
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
		option.auto_bin_max = 10;

		invalid_ops: coverpoint bfm.op {
			ignore_bins valid_ops = {CMD_ADD,CMD_AND,CMD_NOP,CMD_XOR,CMD_OR,CMD_SUB};
		}

	endgroup


    function new (string name, uvm_component parent);
	    super.new(name, parent);
        zeros_or_ones_on_ops = new();
        irregular_ops 	     = new();
    endfunction : new
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
        forever begin : sampling_block
            @(posedge bfm.enable_n); //in execute i used @(posedge bfm.enable_n);
            A      = bfm.A;
            B      = bfm.B;
            op_set = bfm.op_set;
			zeros_or_ones_on_ops.sample();
			irregular_ops.sample();
        end : sampling_block
    endtask : run_phase

endclass : coverage






