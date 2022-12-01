// A CAM is a memory, that allows object lookup by value.
import CAM :: *;
import Vector :: *;

`define CAM_SLOTS 32

typedef Bit#(1) SBit;

interface TopIfc;
  method Action in(Vector#(6, SBit) in_);
  method Vector#(8, SBit) out();
endinterface

typedef UInt#(6) DType; // 1 bit for Maybe(invalid)
typedef UInt#(6) AType;

typedef enum {
  IDLE,
  READ_STORE_ADDR,
  READ_RETURN,
  WRITE_STORE_ADDR,
  WRITE_STORE_DATA
} State deriving (Eq, FShow, Bits);

(* synthesize,
   reset_prefix = "reset",
   clock_prefix = "clock",
   always_ready, always_enabled *)
module mkPICAMTop(TopIfc);
  
  CAMIfc#(`CAM_SLOTS, AType, DType) cam <- mkCAM();
  Reg#(Vector#(6, Bit#(1))) input_r <- mkReg(replicate(0));
  Wire#(Vector#(8, Bit#(1))) output_w <- mkDWire(replicate(0));
  
  // req format
  // cycle 1: metadata. bit 0: read, bit 1: write. exclusive with write priority
  // cycle 2: address
  // cycle 3: data (if read)
  
  Reg#(State) state <- mkReg(IDLE);
  Reg#(AType) addr_r <- mkReg(0);
  Reg#(Maybe#(DType)) ret_r <- mkReg(Invalid);
  
  rule read_cmd if (state == IDLE);
    if (input_r[0] == 1) state <= READ_STORE_ADDR;
    else if (input_r[1] == 1) state <= WRITE_STORE_ADDR;
    else state <= IDLE;
  endrule
  
  rule read_store_addr if (state == READ_STORE_ADDR);
    AType addr = unpack(pack(input_r));
    ret_r <= cam.get(addr);
    state <= READ_RETURN;
  endrule
  
  rule read_return if (state == READ_RETURN);
    Vector#(8, Bit#(1)) out_ = unpack({1'b1, pack(ret_r)});
    output_w <= out_;
  endrule

  rule write_addr if (state == WRITE_STORE_ADDR);
    addr_r <= unpack(pack(input_r));
    state <= WRITE_STORE_DATA;
  endrule
  
  rule write_commit if (state == WRITE_STORE_DATA);
    DType data = unpack(pack(input_r));
    cam.update(addr_r, data);
    state <= IDLE;
  endrule
  
  method Action in(Vector#(6, Bit#(1)) in_);
    input_r <= in_;
  endmethod
  method Vector#(8, Bit#(1)) out = output_w._read;
  
endmodule
