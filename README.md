ctscol
======

LDC Telephone Speech Collection Software
Fisher v0.5     (used for LRE11)
Fisher v0.6     (used briefly for SRE12)
Fisher v0.7     (used for the bulk of SRE12, and for RATS)

The codebase addresses two collection protocols:
Fisher (non-deterministic pairing of strangers based on platform activity)
Callfriend (caller/claque initiated, often between familiars)

The running system includes one dispatch thread, n threads polling
for inbound calls, and n threads polling for a new participant to
contact. Application selection is based on DNIS.

Inbound threads are fixed in number - the number is defined by
the number of inbound timeslots purchased from the T-1 provider.

The number of outbound threads can be varied at runtime - there
is a default number that are spawned when the system
starts. 

Each version directory contains four subdirectories:
  Bin
  Function
  Include
  Perl
Software for starting the system is found in Bin.
Currently all three LDC collection platforms are configured
so that their instance of the collection app should start 
automatically when the host computer starts.

\---fisher_v0.7
    +---Bin
    |       answer.vs
    |       blacklist.txt
    |       client.vs
    |       clock.vs
    |       dialer.vs
    |       dialernp.vs
    |       frustatus.log
    |       init.yml
    |       linemgr.vs
    |       log
    |       outbound.vs
    |       recorder.vs
    |       runmoh.vs
    |       runrsync.bat
    |       runspawn.bat
    |       runspawn.pl
    |       runvlc.bat
    |       runvlc.pl
    |       run_one.vs
    |       spawn.vs
    |       spawnrec.vs
    |       tspawn.vs
    |       upload_audio.sh
    |       upload_code.sh
    |       upload_proc.sh
    |       upload_voslog.sh
    |
    +---Function
    |       cfib.fun
    |       cfibexit.fun
    |       cfibsurv.fun
    |       clrproc.fun
    |       clrsig.fun
    |       cr_query.fun
    |       delproc.fun
    |       fshib.fun
    |       fsh_exit.fun
    |       fsplog.fun
    |       getdtmf.fun
    |       getpin.fun
    |       gettod.fun
    |       ibtest.fun
    |       logbrdg.fun
    |       logterm.fun
    |       logval.fun
    |       metaib.fun
    |       namelook.fun
    |       newside.fun
    |       notify.fun
    |       procexst.fun
    |       procread.fun
    |       procsend.fun
    |       procwrit.fun
    |       pr_look.fun
    |       recaccpt.fun
    |       recname.fun
    |       rectest.fun
    |       rlseline.fun
    |       runperl.fun
    |       semblck.fun
    |       semblock.fun
    |       stoprec.fun
    |       timesup.fun
    |       tpc_look.fun
    |       udioc.fun
    |       validate.fun
    |
    +---Include
    |       cfib_perl.inc
    |       cfib_prompts.inc
    |       cfib_recparm.inc
    |       dnis_opts.inc
    |       dnis_opts_atlas.inc
    |       dnis_opts_atlas1.inc
    |       dnis_opts_toku.inc
    |       final_rpt_fields.inc
    |       fisher_common.inc
    |       fisher_core.inc
    |       fisher_perl.inc
    |       fisher_prompts.inc
    |       linemgr_disp.inc
    |       lpos.cfg
    |       nactive.ul
    |       tone_prompts.inc
    |
    \---Perl
        |   archive_code.pl
        |   FshPerl.pm
        |   FshPerl.yml
        |   newdialin.pl
        |   plot_vos.pl
        |   Semfile.pm
        |   telco_lvd_queries.platform.sql
        |   telco_master.schema.sql
        |
        +---cfib
        |       clrproc.pl
        |       insert_topics.pl
        |       logbridge.pl
        |       logsurvey.pl
        |       logterm.pl
        |       logterm_save.pl
        |       logval.pl
        |       newside.pl
        |       validpin.pl
        |
        \---fisher
                24hrrecs.sql
                callct.sql
                clrcip.pl
                clrproc.pl
                delproc.pl
                getcallee.pl
                getcallee.sql
                getcleldc.sql
                getpinfname.pl
                gettod.pl
                logbridge.pl
                logterm.pl
                logval.pl
                newside.pl
                tdyrecs.sql
                testgetcallee.sql
                testloadtdtbl.pl
                test_getcallee.pl
                test_get_phid.pl
                udcmade.pl
                udreorder.pl
                udstat.pl
                udtod.pl
                update_io_calls.pl
                validpin.pl


