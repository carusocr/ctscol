#!/usr/bin/bash

cd /cygdrive/d/vos_record/mx4 && \
rsync -av -e ssh --progress ./ walkerk@thing4.ldc.upenn.edu:/mixer-4/tel-audio/incoming/


