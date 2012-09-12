#!/usr/bin/bash

cd /cygdrive/p/ && \
gzip -d proc.tar.gz && \
tar uvf proc.tar ./proc/ && \
gzip proc.tar && \
rsync -avc -e ssh --progress proc.tar.gz walkerk@kronus.ldc.upenn.edu:/v20/mixer3_audio/platform/



