`include "TilelinkHeader.bsv"

import FIFO::*;
import GetPut::*;
import SimpleBitmap::*;
import Connectable::*;

//                             4 Beats Burst when Cache is 128 x 128B = 16K/Way with 256b BUS.
//                             8 Beats Burst when Cache is 128 x 128B = 16K/Way with 128b BUS.
//                             Since Our CPU Can handle 2R or 2W Request per cycle at most,
//                             That's means 128b/cycle 's data rate.
//                             Consider the cost lead by Coherence Protocol, I think 256b BUS fit most.

//                 addr_width, data_width, size_width, source_width, sink_width, max_size
//                             == 32 B     Max 2^15 B  Max 32 Mst    Max 16 Slv  Max 256B
`define CURTLPARMS 48,         256,        4,          5,            4,          8

module mkTB();

    Reg#(int) cnt <- mkReg(0);
    rule cnt_upd;
        cnt <= cnt + 1;
        if(cnt > 300) $finish;
    endrule

    FIFO#(TLA#(`CURTLPARMS)) tla_src <- mkFIFO;
    FIFO#(Bit#(5)) id_dst <- mkFIFO;
    GetPut#(Bit#(5)) id_bitmap <- mkSimpleBitmap;
    match {.id_alloc, .id_free} = id_bitmap;

    rule gen_burstify_tla;
        Bit#(5) id <- id_alloc.get();
        let request = TLA {
                opcode  : Get,
                param   : '0,
                size    : 4'd7, // 4Beats of burst, 128B = 2^7B
                source  : id,
                address : {31'd0,id,12'd0},
                mask    : '0,
                corrupt : False,
                data    : '0
        };
        tla_src.enq(request);
        $display("Allocate %x", id);
    endrule

    rule retire;
        let p = id_dst.first;
        id_dst.deq();
        id_free.put(p);
        $display("Free %x", p);
    endrule


    TilelinkMST#(`CURTLPARMS) mst <- mkTilelinkPingPongMst(TLINFO {sink: '0, source: '0}, tla_src, id_dst, False);
    TilelinkSLV#(`CURTLPARMS) slv <- mkTilelinkPingPongSlv(TLINFO {sink: '0, source: '0}, False);
    mkConnection(mst, slv);

endmodule
