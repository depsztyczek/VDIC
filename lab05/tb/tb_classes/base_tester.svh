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
virtual class base_tester extends uvm_component;

// The macro is not there as we never instantiate/use the base_tester
//    `uvm_component_utils(base_tester)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual alu_bfm bfm;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new
    
//------------------------------------------------------------------------------
// function prototypes
//------------------------------------------------------------------------------
    pure virtual protected function operation_t get_op();
    pure virtual protected function byte get_data();

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

        phase.raise_objection(this);

        bfm.reset_alu();

        repeat (1000) begin : random_loop
            bfm.op_set = get_op();
            bfm.A     = get_data();
            bfm.B     = get_data();
			bfm.serializer(bfm.A,DATA);
			bfm.serializer(bfm.B,DATA);
			bfm.serializer(bfm.op_set,CONTROL);
			@(negedge bfm.clk);
			bfm.enable_n  = 1'b1;
        end : random_loop

//      #500;

        phase.drop_objection(this);

    endtask : run_phase


endclass : base_tester
