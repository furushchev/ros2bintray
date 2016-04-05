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

if [ "$LOG_FILE" != "" ]; then
    LOG_SUFFIX=" 1>> $LOG_FILE 2>&1"
fi

./list-all-packages.sh | xargs -i -t -r --max-procs=$MAX_PROCS bash -c "./upload-to-bintray.sh {} $LOG_SUFFIX"
