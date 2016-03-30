#!/bin/bash

set -e

for pkg in `./list-all-packages.sh`; do
    ./upload-to-bintray.sh $pkg
done
