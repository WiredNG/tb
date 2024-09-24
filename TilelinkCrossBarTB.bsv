`include "TilelinkHeader.bsv"

import Arbiter::*;
import FIFO::*;
import GetPut::*;
import SimpleBitmap::*;
import Connectable::*;
import LCGR::*;
import Vector::*;

//                             4 Beats Burst when Cache is 128 x 128B = 16K/Way with 256b BUS.
//                             8 Beats Burst when Cache is 128 x 128B = 16K/Way with 128b BUS.
//                             Since Our CPU Can handle 2R or 2W Request per cycle at most,
//                             That's means 128b/cycle 's data rate.
//                             Consider the cost lead by Coherence Protocol, I think 256b BUS fit most.

//                 addr_width, data_width, size_width, source_width, sink_width, max_size
//                             == 32 B     Max 2^15 B  Max 32 Mst    Max 16 Slv  Max 256B
`define CURTLPARMS 48,         256,        4,          8,            4,          8
typedef 2 MST_NUM;
typedef 1 SLV_NUM;
// Source has 8bits, high 4 is for Mst route, low 4 is bitmap gen.

module mkHelper_Create_TLA#(
    Bit#(4) id,
    UInt#(32) rnd_seed,
    FIFO#(TLA#(`CURTLPARMS)) tla_src, // A Request queue
    FIFO#(Bit#(8)) id_dst // ID Release queue
)(Empty);
    GetPut#(Bit#(4)) id_bitmap <- mkSimpleBitmap;
    match {.id_alloc, .id_free} = id_bitmap;

    Reg#(UInt#(32)) random_number <- mkReg(rnd_seed);
    Wire#(Bit#(32)) rnd_bit <- mkWire;
    rule upd_random_number;
        random_number <= lcg(random_number);
        rnd_bit <= pack(random_number);
    endrule
    rule gen_burstify_tla;
        let map_id <- id_alloc.get();
        let request = TLA {
                opcode  : Get,
                param   : '0,
                size    : 7, // 8Beats of burst, 256B = 2^8B
                source  : {id, map_id},
                address : {30'd0, rnd_bit[5:0], 12'd0},
                mask    : '0,
                corrupt : False,
                data    : '0
        };
        tla_src.enq(request);
        $display("ID %X Allocate %x", id, map_id);
    endrule
    rule retire;
        let p = id_dst.first;
        id_dst.deq();
        id_free.put(p[3:0]);
        $display("ID %X Free %x", id, p);
    endrule
endmodule

module mkTB() provisos(
    Alias#(mst_index_t, Bit#(TLog#(MST_NUM))),
    Alias#(slv_index_t, Bit#(TLog#(SLV_NUM)))
);

    Reg#(int) cnt <- mkReg(0);
    rule cnt_upd;
        cnt <= cnt + 1;
        if(cnt > 100) $finish;
    endrule

    Vector#(MST_NUM,FIFO#(TLA#(`CURTLPARMS))) tla_src <- replicateM(mkFIFO);
    Vector#(MST_NUM,FIFO#(Bit#(8))) id_dst <- replicateM(mkFIFO);
    Vector#(MST_NUM,TilelinkMST#(`CURTLPARMS)) mst = ?;
    Vector#(SLV_NUM,TilelinkSLV#(`CURTLPARMS)) slv = ?;

    mst[0] <- mkTilelinkPingPongMst(TLINFO {sink: '0, source: '0}, tla_src[0], id_dst[0], True);
    mst[1] <- mkTilelinkPingPongMst(TLINFO {sink: '0, source: 8'h10}, tla_src[1], id_dst[1], True);
    slv[0] <- mkTilelinkPingPongSlv(TLINFO {sink: '0, source: '0}, True);
    mkHelper_Create_TLA (0,123,  tla_src[0],id_dst[0]);
    mkHelper_Create_TLA (1,12345,tla_src[1],id_dst[1]);

    function Bit#(SLV_NUM) routeAddress(mst_index_t m, Bit#(48) addr);
        return 1;
    endfunction
    function Bit#(MST_NUM) routeSource(slv_index_t s, Bit#(8) source);
        if(source[7:4] == 0) return 2'b01;
        else return 2'b10;
    endfunction
    function Bit#(SLV_NUM) routeSink(mst_index_t m, Bit#(4) sink);
        return 1;
    endfunction
    mkTilelinkCrossBar(routeAddress,routeSource,routeSink,mkArbiter(False),mkArbiter(False), mst, slv);

endmodule
