select count(*)
from 
     sre12_br_calls sbc,
     sre12_io_calls sca,
     sre12_io_calls scb
where
     sbc.cra_side_id = sca.side_id and
     sbc.crb_side_id = scb.side_id and
     sbc.hup_status  = 'FULLREC'   and
     ( sca.subj_id = ? or scb.subj_id = ?)




