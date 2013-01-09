select fs.subj_id,
       fs.pin, 
       tp.phone_id, 
       tp.phone_number,
       fs.group_id
from   telco_subjects ts,
       telco_available ta,
       telco_phones tp,
      sre12_subj fs
where
       ts.subj_id  = ta.subj_id and
       ts.subj_id  = fs.subj_id and
       ts.subj_id  = tp.subj_id and
       ta.phone_id = tp.phone_id and 
       ta.avstring like 'XXX' and
       ts.cip = 'N' and
       ts.ldcpool = 'Y'









