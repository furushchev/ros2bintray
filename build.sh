#!/bin/bash
#
export LANG=C
set -e
set -o pipefail
#set -x # for debug
#
: ${MAX_PROCS:=1}
: ${TEMP_DEBS_DIR:=/tmp/debs}
#

if [ -e "$TEMP_DEBS_DIR" ]; then
    echo "$TEMP_DEBS_DIR already exists"
    echo "Aborting..."
    exit 1
fi
mkdir -p "$TEMP_DEBS_DIR"

./list-all-packages.sh | xargs -i --max-procs=$MAX_PROCS ./upload-to-bintray.sh {}
