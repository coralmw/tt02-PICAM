import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

CAM_SLOTS = 32

READ_CMD = int("000001", 2)
WRITE_CMD = int("000010", 2)

@cocotb.test()
async def test_7seg(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut._log.info("reset")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0
    
    dut.in_in_.value = 0

    dut._log.info("check all empty")
    for slot_i in range(CAM_SLOTS):
        dut.in_in_.value = READ_CMD
        await RisingEdge(clock)
        dut.in_in_.value = slot_i
        await RisingEdge(clock)
        dut.in_in_.value = 0
        retval = dut.out.value.binstr
        # bit 7 is "ret val this cycle"
        assert retval[7] == '1', "Expected a Invalid return value from a read to addr {slot_i=} got {retval=}"
        # bit 6 is maybe
        assert retval[5] == '0', "Expected a Invalid return value from a read to addr {slot_i=} got {retval=}"
    
    # write to all slots
    for slot_i in range(CAM_SLOTS):
        dut.in_in_.value = WRITE_CMD
        await RisingEdge(clock)
        dut.in_in_.value = slot_i # address
        await RisingEdge(clock)
        dut.in_in_.value = slot_i + 32
        await RisingEdge(clock)
        dut.in_in_.value = 0
        await RisingEdge(clock)
    
    for slot_i in range(CAM_SLOTS):
        # read back
        dut.in_in_.value = READ_CMD
        await RisingEdge(clock)
        dut.in_in_.value = slot_i
        await RisingEdge(clock)
        dut.in_in_.value = 0
        retval = dut.out.value.binstr
        # bit 7 is "ret val this cycle"
        assert retval[7] == '1', "Expected a Valid return value from a read to addr {slot_i=} got {retval=}"
        # bit 6 is maybe
        assert retval[5] == '1', "Expected a Valid return value from a read to addr {slot_i=} got {retval=}"
        assert int(retval[0:5], "2") == slot_i+32, "Expected a Valid return value from a read to addr {slot_i=} got {retval=}"
        
        