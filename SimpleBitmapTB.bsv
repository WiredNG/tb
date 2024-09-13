package SimpleBitmapTB;

import SimpleBitmap::*;
import FIRO::*;
import Vector::*;
import GetPut::*;
import LCGR::*;

typedef 3 BITCOUNT;
typedef Bit#(BITCOUNT) ID_T;
typedef Bit#(TExp#(BITCOUNT)) MAP_T;

(* synthesize *)
module mkTB();

   Reg#(int) cnt <- mkReg(0);
   Reg#(MAP_T) busy[2] <- mkCReg(2, 0);

   rule up_counter;
      cnt <= cnt + 1;
      if(cnt > 2000) $finish;
   endrule

   Reg#(Bit#(32)) rnd <- mkReg(87897);
   rule rnd_gen;
      rnd <= pack(lcg(unpack(rnd)));
   endrule

   GetPut#(ID_T) intf <- mkSimpleBitmap;

   match {.gintf, .pintf} = intf;
   let gen_get = gintf.get;
   let gen_put = pintf.put;

   FIRO#(ID_T, 64) buffer <- mkFIRO;

   let buf_get = toGet(buffer).get;
   let buf_put = toPut(buffer).put;

   rule get_id(cnt < 70 || (unpack(rnd[31:16]) >= 16'd20000));
      let id <- gen_get;
      MAP_T map = 0;
      map[id] = 1;
      buf_put(id);
      if(busy[1][id] == 1) begin
          $display("REPEAT ALLOC!");
          $finish;
      end
      busy[1][id] <= 1;
      $display("%03d-Alloca: %b", cnt, map);
   endrule

   rule retire_id(cnt >= 70 && (unpack(rnd[15:0]) >= 16'd21000));
      let id <- buf_get;
      MAP_T map = 0;
      map[id] = 1;
      gen_put(id);
      if(busy[0][id] == 0) begin
          $display("REPEAT RETIRE!");
          $finish;
      end
      busy[0][id] <= 0;
      $display("%03d-Retire: %b", cnt, map);
   endrule

endmodule

endpackage : SimpleBitmapTB