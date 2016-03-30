#!/bin/bash

: ${APT_URL:="packages.ros.org"}
: ${APT_REPO:="ros-shadow-fixed"}
: ${DEB_DISTRIBUTION:="trusty"}
: ${DEB_ARCH:="amd64"}

LST="/var/lib/apt/lists/${APT_URL}_${APT_REPO}_ubuntu_dists_${DEB_DISTRIBUTION}_main_binary-${DEB_ARCH}_Packages"
grep ^Package:  $LST |sed -e 's@Package: @@g'
