d:
cd \
cd \vos_record\mx3
rsync -av --progress ./ walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/incoming/
cd \
cd \fisher_v0.5
perl archive_code.pl
rsync -av --progress *.tar walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform_code/
rm *.tar
d:
cd \
tar uvf proc.tar ./proc/
rsync -av --progress proc.tar walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform_logs/
d:
cd \
cd \proc
gzip -d vosarch.log.gz
cat vos1.log vos2.log vosarch.log | sort | uniq > vostmp.log
mv vostmp.log vosarch.log
gzip vosarch.log
rsync -av --progress vosarch.log.gz  walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform_logs/
