# MT.VS
#
# Multi-Threaded RLL function test program
#
#-------------------------------------------------------------------------------

dec
	var handle : 10;
enddec

program
	# Trace RLL function calls
	trace(8);
	
	# Stamp the log file prior to calling the multi-threaded function
	voslog("Prior to calling TestMt() in MT.VS");
	
	# Pass some arbitrary arguments to TestMT to check that they are
	# correctly passed to the actual multi-threaded function.
	handle = TestMt(5, 4, 3, 2, 1);
	
	# Stamp the log file when this task is woken up after TestMT()
	# completes
	voslog("After calling TestMt() in MT.VS, thread handle = ", handle);
	
	# Exit VOS
	exit(0);
endprogram
