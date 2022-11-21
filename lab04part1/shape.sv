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
   protected int height=-1;
   protected int width=-1;
   protected string name = "0";

   function new(int h, int w, string n); 
	   height = h;
	   width = w;
	   name = n;
   endfunction : new
   
  	function string get_name(); 
	   return name;
  	endfunction : get_name

   pure virtual function int get_area();
  // I know instructions said it should be virtual but this made more sense to me
   function void print();
	   $display ("Shape type is %s, height = %g, width = %g, area = %g", get_name(), height, width, get_area());
   endfunction

endclass : shape


class rectangle extends shape;
	
   function new(int h, int w);
      super.new(h, w, "Rectangle");
   endfunction : new

   function int get_area();
      return height*width;
   endfunction : get_area
      
endclass : rectangle

class square extends shape;
	
   function new(int h);
      super.new(h, h, "Square");
   endfunction : new

   function int get_area();
      return height*width;
   endfunction : get_area
      
endclass : square

class triangle extends shape;
	
   function new(int h, int a);
      super.new(h, a, "Triangle");
   endfunction : new

   function int get_area();
      return (height*width)/2;
   endfunction : get_area
      
endclass : triangle


class shape_factory;

   static function shape make_shape(string shape_type, 
                                      int height, int width);
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

   static function void put_shape_in_box(T l);
      shape_storage.push_back(l);
   endfunction : put_shape_in_box

   static function void report_shapes();
      $display("Shapes in box:"); 
      foreach (shape_storage[i])
        $display(shape_storage[i].get_name());
   endfunction : report_shapes

endclass : shape_reporter


module top;


   initial begin
      shape shape_h;
      rectangle   rectangle_h;
      triangle  triangle_h;
	  square square_h;
	   
	   string line;
      int file;
	   
      file = $fopen("./lab04part1_example_factory.sv", "r");
	  while(!$feof(file))begin
		  $fgets(line, file);
		  $display("Line is %s", line);
	  end
	  
	  $fclose(file);

   end

endmodule : top




