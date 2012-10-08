select 
       micA.subj_id,
       micB.subj_id 
from 
    sre12_br_calls mbc,
    sre12_io_calls micA,
    sre12_io_calls micB
where 
      micA.side_id = mbc.cra_side_id and
      micB.side_id = mbc.crb_side_id and
      mbc.hup_status = 'FULLREC'     and
      mbc.call_date >= date_sub(now(), INTERVAL 18 HOUR)
