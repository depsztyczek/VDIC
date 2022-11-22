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
	
	typedef enum bit[7:0] {
		S_NO_ERROR = 8'b00000000,
		S_MISSING_DATA = 8'b00000001,
		S_DATA_STACK_OVERFLOW = 8'b00000010,
		S_OUTPUT_FIFO_OVERFLOW = 8'b00000100,
		S_DATA_PARITY_ERROR = 8'b00100000,
		S_COMMAND_PARITY_ERROR = 8'b01000000,
		S_INVALID_COMMAND = 8'b10000000
	} status_t;

	typedef enum bit[7:0] {
		CMD_NOP = 8'b00000000,
		CMD_AND = 8'b00000001,
		CMD_OR = 8'b00000010,
		CMD_XOR = 8'b00000011,
		CMD_ADD = 8'b00010000,
		CMD_SUB = 8'b00100000
	} operation_t;

	typedef enum bit {
		TEST_DONE,
		TEST_IN_PROGRESS
	} test_progress_t;

	typedef enum bit {
		CONTROL = 1'b1,
		DATA = 1'b0
	} payload_type_t;
	
	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result_t;
	
	typedef enum {
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT
	} print_color_t;

`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"
`include "testbench.svh"

endpackage : alu_pkg
   
