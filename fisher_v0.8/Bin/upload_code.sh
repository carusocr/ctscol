#!/usr/bin/bash

cd /cygdrive/d/fisher_v0.8 && \
tar=`./archive_code.pl` 
gzip $tar && \
rsync -avc -e ssh --progress $tar\.gz walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform/



