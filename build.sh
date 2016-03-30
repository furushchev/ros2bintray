#!/bin/bash

set -e

# for pkg in `./list-all-packages.sh`; do
#     ./upload-to-bintray.sh $pkg
# done
./list-all-packages.sh | xargs -i --max-procs=10 ./upload-to-bintray.sh {}
