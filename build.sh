#!/bin/bash

set -e

: ${UPLOAD_CONCURRENCY:=4}

# for pkg in `./list-all-packages.sh`; do
#     ./upload-to-bintray.sh $pkg
# done
./list-all-packages.sh | xargs -i --max-procs=$UPLOAD_CONCURRENCY ./upload-to-bintray.sh {}
