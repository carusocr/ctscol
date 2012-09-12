select 
       micA.subj_id,
       micB.subj_id 
from 
     mx7spa_br_calls mbc,
     mx7spa_io_calls micA,
     mx7spa_io_calls micB
where 
      micA.side_id = mbc.cra_side_id and
      micB.side_id = mbc.crb_side_id and
      mbc.hup_status = 'FULLREC'     and
      mbc.call_date >= date_sub(now(), INTERVAL 24 HOUR)
