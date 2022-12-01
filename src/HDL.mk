

coralmw_mkPICAMInternal.v: CAM.bsv PICAM.bsv flatten.yosys
	bsc -verilog -D BSV_POSITIVE_RESET -g mkPICAMTop PICAM.bsv
	yosys -s flatten.yosys
