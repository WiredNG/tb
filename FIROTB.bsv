package FIROTB;

import FIRO::*;
import FIFO::*;
import GetPut::*;

(* synthesize *)
module mkTB();

   Reg#(int) cnt <- mkReg(0);
   Reg#(int) rcnt <- mkReg(0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 1000) $finish;
   endrule

   FIFO#(int) firo <- mkFIRO;
   Get#(int) g = toGet(firo);
   Put#(int) p = toPut(firo);
   // push
   rule push_FIRO(cnt <= 100);
      p.put(cnt);
   endrule

   // pop
   rule pop_FIRO(cnt >= 31);
      rcnt <= rcnt + 1;
      let d = g.get();
      $display("d: %d, total %d", d, rcnt);
   endrule

endmodule

endpackage : FIROTB