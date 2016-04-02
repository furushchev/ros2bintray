#!/bin/bash
#
export LANG=C
set -e
set -o pipefail
#set -x # for debug
#
: ${MAX_PROCS:=1}
#
./list-all-packages.sh | xargs -i --max-procs=$MAX_PROCS ./upload-to-bintray.sh {}
