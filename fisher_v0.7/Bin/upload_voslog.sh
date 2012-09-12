#!/usr/bin/bash

cd /cygdrive/p/proc && \
gzip -d vosarch.log.gz && \
cat vos1.log vos2.log vosarch.log | sort | uniq > vostmp.log && \
mv vostmp.log vosarch.log && \
gzip vosarch.log && \
rsync -avc -e ssh --progress vosarch.log.gz walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform/





