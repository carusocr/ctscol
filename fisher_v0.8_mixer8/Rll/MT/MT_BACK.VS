# MT_BACK.VS
#
# This is a background task that runs while the multi-threaded function call
# in MT.VS is active
#
#-------------------------------------------------------------------------------

program
	while(1)
		voslog("MT_BACK is alive and well");
		sleep(10);
	endwhile
endprogram
