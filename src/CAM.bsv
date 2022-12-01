// A CAM is a memory, that allows object lookup by value.
import Vector :: *;

interface CAMIfc#(numeric type size, type data, type value);
  method Action insert(data d, value v);
  // should be polymorphic - currently, just uses add
  // updates a elements value in place, combining with value_old+value_new
  method Action update(data d, value v); 
  method Maybe#(value) get(data d);
  method ActionValue#(Tuple2#(data, value)) pop();
  method Action clear();
  method Bool notFull();
  method Bool notEmpty();
endinterface


module mkCAM(CAMIfc#(size, dt, vt) ifc) provisos (
  Eq#(dt),
  Bits#(dt, size_dt),
  Bits#(vt, size_vt),
  Add#(size_dt, size_vt, size_rec),
  Add#(size_rec, 1, size_mbyerec),
  Arith#(vt) // we only need this for update(); should be more polymorphic
  );
  
  Reg#(Vector#(size, Maybe#(Tuple2#(dt, vt)))) store <- mkReg(replicate(Invalid));
  
  // by keeping the first N slots full, we can also provide a FIFO interface
  Wire#(Bool) full <- mkWire();
  Wire#(Bool) empty <- mkWire();

  (* no_implicit_conditions, fire_when_enabled *)
  rule setfull;
    empty <= !any(isValid, store);
    full <= all(isValid, store);
  endrule
  
  method Action insert(dt data, vt value) if (!full);
    // shift in at 0
    store <= shiftInAt0(store, Valid(tuple2(data, value)));
  endmethod
  
  method Action update(dt data, vt value) if (!full);
    function Bool findfn (Maybe#(Tuple2#(dt, vt)) rec) = isValid(rec) ? tpl_1(fromMaybe(?, rec)) == data : False;
    Maybe#(UInt#(TLog#(size))) maybe_idx = findIndex(findfn, store);
    if (maybe_idx matches tagged Valid .idx ) begin
      // we know there is a value here
      Tuple2#(dt, vt) rec = fromMaybe(?, store[idx]);
      vt value_new = tpl_2(rec) + value;
      store[idx] <= Valid(tuple2(data, value_new));
    end else begin
      store <= shiftInAt0(store, Valid(tuple2(data, value)));
    end
  endmethod
  
  method ActionValue#(Tuple2#(dt, vt)) pop if (!empty);
    Tuple2#(dt, vt) ret = fromMaybe(?, store[0]);
    store <= shiftOutFrom0(Invalid, store, 1);
    return ret;
  endmethod
  
  method Maybe#(vt) get(dt idx);
    function Bool findfn (Maybe#(Tuple2#(dt, vt)) rec) = isValid(rec) ? tpl_1(fromMaybe(?, rec)) == idx : False;
    Maybe#(Maybe#(Tuple2#(dt, vt))) maybe_maybe_rec = find(findfn, store);
    Maybe#(vt) retval = Invalid;
    if (maybe_maybe_rec matches tagged Valid .maybe_rec ) begin
      if (maybe_rec matches tagged Valid .rec) begin
        retval = Valid(tpl_2(rec));
      end
    end
    return retval;
  endmethod
  
  method Action clear();
    store <= replicate(Invalid);
  endmethod
  
  method Bool notFull();
    return !full;
  endmethod
  
  method Bool notEmpty();
    return !empty;
  endmethod


endmodule

module mkCAM_64e_32i_16d(CAMIfc#(64, Bit#(32), Bit#(16)) ifc);
  
  CAMIfc#(64, Bit#(32), Bit#(16)) cam <- mkCAM();
  return cam;
  
endmodule
