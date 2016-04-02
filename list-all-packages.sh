#!/bin/bash
#
export LANG=C
#set -x
#
: ${DEB_ARCH:="amd64"}
APT_PATH=${APT_REPO#http://}
APT_PATH=${APT_PATH//\//_}
LST="/var/lib/apt/lists/${APT_PATH}_dists_${DEB_DISTRIBUTION}_main_binary-${DEB_ARCH}_Packages"
grep ^Package:  $LST |sed -e 's@Package: @@g'
