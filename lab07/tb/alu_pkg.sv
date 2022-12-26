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
`timescale 1ns/1ps
package alu_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

//------------------------------------------------------------------------------
// package typedefs
//------------------------------------------------------------------------------

    // ALU op codes
	typedef enum bit[7:0] {
		CMD_NOP = 8'b00000000,
		CMD_AND = 8'b00000001,
		CMD_OR = 8'b00000010,
		CMD_XOR = 8'b00000011,
		CMD_ADD = 8'b00010000,
		CMD_SUB = 8'b00100000
	} operation_t;

	//ALU status codes
	typedef enum bit[7:0] {
		S_NO_ERROR = 8'b00000000,
		S_MISSING_DATA = 8'b00000001,
		S_DATA_STACK_OVERFLOW = 8'b00000010,
		S_OUTPUT_FIFO_OVERFLOW = 8'b00000100,
		S_DATA_PARITY_ERROR = 8'b00100000,
		S_COMMAND_PARITY_ERROR = 8'b01000000,
		S_INVALID_COMMAND = 8'b10000000
	} status_t;

	//Payload data type
	typedef enum bit {
		CONTROL = 1'b1,
		DATA = 1'b0
	} payload_type_t;
	
    // ALU data packet
    typedef struct packed {
        byte unsigned A;
        byte unsigned B;
        operation_t op;
    } command_s;
	
	typedef struct packed{
		bit [23:0] result;
	} result_s;

    // terminal print colors
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color;

	// Test results
	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;

//------------------------------------------------------------------------------
// package functions
//------------------------------------------------------------------------------

    // used to modify the color of the text printed on the terminal

    function void set_print_color ( print_color c );
        string ctl;
        case(c) 
            COLOR_BOLD_BLACK_ON_GREEN : ctl = "\033\[1;30m\033\[102m";
            COLOR_BOLD_BLACK_ON_RED : ctl       = "\033\[1;30m\033\[101m";
            COLOR_BOLD_BLACK_ON_YELLOW : ctl    = "\033\[1;30m\033\[103m";
            COLOR_BOLD_BLUE_ON_WHITE : ctl      = "\033\[1;34m\033\[107m";
            COLOR_BLUE_ON_WHITE : ctl           = "\033\[0;34m\033\[107m";
            COLOR_DEFAULT : ctl                 = "\033\[0m\n";
            default : begin
                $error("set_print_color: bad argument");
                ctl                             = "";
            end
        endcase
        $write(ctl);
    endfunction

//------------------------------------------------------------------------------
// testbench classes
//------------------------------------------------------------------------------
`include "command_transaction.svh"
`include "add_transaction.svh"
`include "result_transaction.svh"
`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "command_monitor.svh"
`include "result_monitor.svh"
`include "env.svh"

//------------------------------------------------------------------------------
// test classes
//------------------------------------------------------------------------------

`include "random_test.svh"
`include "add_test.svh"

endpackage : alu_pkg

