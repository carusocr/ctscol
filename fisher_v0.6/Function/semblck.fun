func semblock(_fsy_sem)
	for(;;)
        	if(sem_test(_fsy_sem) eq 1)
               		sem_clear(_fsy_sem);
        	else
               		break;
        	endif
	endfor	
endfunc