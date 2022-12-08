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
module top;
import uvm_pkg::*;
`include "uvm_macros.svh"
import alu_pkg::*;

	
alu_bfm bfm();
vdic_dut_2022 DUT (.clk(bfm.clk), .rst_n(bfm.rst_n), .enable_n(bfm.enable_n), .din(bfm.din), .dout(bfm.dout), .dout_valid(bfm.dout_valid));

initial begin
    uvm_config_db #(virtual alu_bfm)::set(null, "*", "bfm", bfm);
    run_test();
end

endmodule : top



