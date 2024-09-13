package SimpleBitmapTB;

import SimpleBitmap::*;
import FIFO::*;
import Vector::*;
import GetPut::*;

(* synthesize *)
module mkTB();

   Reg#(int) cnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 100) $finish;
   endrule

endmodule

endpackage : DecoderTB