package FIROTB;

import FIRO::*;
import GetPut::*;

(* synthesize *)
module mkTB();

   Reg#(int) cnt <- mkReg(0);
   Reg#(int) rcnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 1000) $finish;
   endrule

   FIRO#(int, 100) firo <- mkFIRO;
   let g = toGet(firo).get;
   let p = toPut(firo).put;
   // push
   rule push_FIRO(cnt <= 500);
      p(cnt);
   endrule

   // pop
   rule pop_FIRO(cnt >= 64);
      rcnt <= rcnt + 1;
      let d <- g();
      $display("d: %d, total %d", d, rcnt);
   endrule

endmodule

endpackage : FIROTB