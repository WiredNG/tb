package TilelinkCrossBarTB;

`include "TilelinkHeader.bsv"

module mkTB();

    Reg#(int) cnt <- mkReg(0);
    rule cnt_upd;
        cnt <= cnt + 1;
        if(cnt > 100) $finish;
    endrule

    TLBurstTracker #(128, 6, 12) bt <- mkTLBurstTracker;

    rule handshake((cnt % 8) == 0);
        bt.handshake(6);
        $display("Handshaked");
    endrule

    rule display_status;
        $display(bt.valid, bt.burst, bt.first, bt.last);
    endrule

endmodule

endpackage