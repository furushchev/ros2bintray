#!/bin/bash
#
export LANG=C
set -e
#set -x # for debug
#
: ${UPLOAD_CONCURRENCY:=4}
#
./list-all-packages.sh | xargs -i --max-procs=$UPLOAD_CONCURRENCY ./upload-to-bintray.sh {}
