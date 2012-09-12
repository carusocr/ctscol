select 
    micA.subj_id,
    micB.subj_id,
    sec_to_time(unix_timestamp(now()) - unix_timestamp(mbc.call_date)),
    mbc.call_date,
    msA.active,
    msB.active
from 
    sre12_br_calls mbc, 
    sre12_io_calls micA, 
    sre12_io_calls micB,
    sre12_subj msA,
    sre12_subj msB
where 
    mbc.hup_status  = 'FULLREC'    and 
    mbc.cra_side_id = micA.side_id and 
    mbc.crb_side_id = micB.side_id and
    msA.subj_id = micA.subj_id     and
    msB.subj_id = micB.subj_id     and 
    unix_timestamp(now()) - unix_timestamp(mbc.call_date) < 57600
