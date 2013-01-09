
dec

	const SCB_VOX = 1;
	const SCB_FULL_DUPLEX = 0;
	const SCB_HALF_DUPLEX = 1;
 	const SCB_DTI = 3;    ## i.e. digital
	var dtib : 1;
	var dtic : 2;
	var voxc : 2;	

enddec

program
	
	dtib = 1;
	dtic = 1;
	voxc = 1;
	scb_route(dtib*256 + dtic, SCB_DTI, 
	      voxc, SCB_VOX, 
	      SCB_FULL_DUPLEX);

    	DTI_clrsig(dtib, dtic, 3);
    	DTI_clrtrans(dtib, dtic);
    	DTI_watch(dtib, dtic, "w");
    	DTI_clrtrans(dtib, dtic);
    	DTI_setsig(dtib, dtic, 3); 
	DTI_waittrans(dtib,dtic,"w",5);
	vid_print(DTI_getsig(dtib,dtic));	
	sc_call(voxc,12158202206);
	vid_print(sc_getcar(voxc));
	vid_print(sc_cardata(voxc,7));
	sc_play(voxc,"0012TON.au",768);
	DTI_clrsig(dtib,dtic,3);

endprogram

onsignal
	DTI_clrsig(dtib,dtic,3);
	restart;
end