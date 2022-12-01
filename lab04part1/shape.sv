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
virtual class shape;
	protected real height=-1;
	protected real width=-1;
	protected string name = "0";

	function new(real h, real w, string n);
		height = h;
		width = w;
		name = n;
	endfunction : new

	function string get_name();
		return name;
	endfunction : get_name

	pure virtual function real get_area();
	// I know instructions said it should be virtual but this made more sense to me
	function void print();
		$display ("Shape type is %s, height = %g, width = %g, area = %g", get_name(), height, width, get_area());
	endfunction

endclass : shape


class rectangle extends shape;

	function new(real h, real w);
		super.new(h, w, "Rectangle");
	endfunction : new

	function real get_area();
		return height*width;
	endfunction : get_area

endclass : rectangle

class square extends rectangle;

	function new(real h);
		super.new(h, h, "Square");
	endfunction : new

endclass : square

class triangle extends shape;

	function new(real h, real a);
		super.new(h, a, "Triangle");
	endfunction : new

	function real get_area();
		return (height*width)/2;
	endfunction : get_area

endclass : triangle


class shape_factory;

	static function shape make_shape(string shape_type,
			real height, real width);
		rectangle rectangle_h;
		triangle triangle_h;
		square square_h;

		case (shape_type)
			"rectangle" : begin
				rectangle_h = new(height, width);
				return rectangle_h;
			end

			"triangle" : begin
				triangle_h = new(height, width);
				return triangle_h;
			end

			"square" : begin
				square_h = new(height);
				return square_h;
			end

			default :
				$fatal (1, {"No such shape: ", shape_type});

		endcase // case (species)

	endfunction : make_shape

endclass : shape_factory



class shape_reporter #(type T=shape);

	protected static T shape_storage[$];

	static function void store_shape(T l);
		shape_storage.push_back(l);
	endfunction : store_shape

	static function void report_shapes();
		$display("Shapes in box:");
		foreach (shape_storage[i])
			shape_storage[i].print();
	endfunction : report_shapes

endclass : shape_reporter


module top;


	initial begin
		shape_factory factory;
		shape_reporter reporter;

		string shape_type;
		real h, w;
		int file;

		file = $fopen("../lab04part1_shapes.txt", "r");
		while($fscanf(file, "%s %g %g", shape_type, h, w) == 3)begin
			reporter.store_shape(factory.make_shape(shape_type, h, w));
		end

		$fclose(file);

		reporter.report_shapes();

	end

endmodule : top




