select fs.subj_id,
       fs.pin, 
       ts.fname,
       ts.lname,
       tp.phone_id, 
       tp.phone_number,
       fs.group_id
from   telco_subjects ts,
       telco_available ta,
       telco_phones tp,
      sre12_subj fs
       left joinsre12_exclude fe on fs.subj_id = fe.spoke_to
where
       ts.subj_id = ta.subj_id and
       ts.subj_id = fs.subj_id and
       ts.subj_id = tp.subj_id and
       ta.phone_id = tp.phone_id and
       ts.cip = 'N' and
       fs.active in ('T','Y') and  	
       ta.avstring like '%Tu%18%' and
       IFNULL(ts.sut,now()) <= now() and
       ts.subj_id not in ('120337') and
       IFNULL(fs.calls_done,0) < fs.max_allowed and
   #    fe.spoke_to is null and
       IFNULL(fs.reorder,1) > 0
order by IFNULL(fs.reorder,1)







