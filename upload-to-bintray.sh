#!/bin/bash

export LANG=C
set -x
#
info()
{
    echo "[Info] $@"
}
warn()
{
    echo -e "\e[33m [Warn] $@ \e[m"
}
error()
{
    echo -e "\e[1;31m [Error] $@ \e[m"
}
panic()
{
    error "$@"
    echo "Aborting..."
    exit 1
}
#
if [ $# -ne 1 ]; then
    panic "Usage: $0 <package name>"
fi
DEB_DISTRIBUTION=`lsb_release -cs`
: ${DEB_COMPONENT:="main"}
: ${TEMP_DEBS_DIR:="/tmp/debs"}
: ${BINTRAY_BASE_URL:="https://api.bintray.com"}
if [ ${BINTRAY_REPOSITORY:="undefined"} = "undefined" ]; then
    panic "BINTRAY_REPOSITORY is undefined (e.g. ros/ros)"
fi
if [ ${BINTRAY_USER:="undefined"} = "undefined" ]; then
    panic "BINTRAY_USER is undefined"
fi
if [ ${BINTRAY_API_KEY:="undefined"} = "undefined" ]; then
    panic "BINTRAY_API_KEY is undefined"
fi
#
if [ -e $TEMP_DEBS_DIR ]; then
    rm -rf $TEMP_DEBS_DIR
fi
mkdir $TEMP_DEBS_DIR
#
create_package()
{
    pkg_name=$1
    ros_distro=`echo $pkg_name | cut -d '-' -f2`
    ros_pkg_name=`echo $pkg_name | sed -e "s@ros-$ros_distro-@@g" -e "s@-@_@g"`
    vcs_url=`rosinstall_generator --rosdistro $ros_distro $ros_pkg_name | grep 'uri:' | awk '{print $2}'`
    vcs_url=${vcs_url:-"https://github.com/"}
    desc=`aptitude show $pkg_name | grep '^Description: ' | sed -e 's@Description: @@g'`
    RET=`curl -H 'Accept: application/json' -H 'Content-type: application/json' -X POST -d "{
  \"name\": \"$pkg_name\",
  \"desc\": \"$desc\",
  \"licenses\": [\"Unlicense\"],
  \"vcs_url\": \"$vcs_url\",
  \"public_download_numbers\": true
}" -u$BINTRAY_USER:$BINTRAY_API_KEY "$BINTRAY_BASE_URL/packages/$BINTRAY_REPOSITORY"`
    if echo $RET | jq '.message' | grep exists; then
        warn "`echo $RET | jq '.message'`"
    elif [ "`echo $RET | jq '.name'`" != "" ]; then
        panic "failed to create package: $RET"
    else
        info "created package: `echo $RET | jq '.name'`"
    fi
}

upload_content()
{
    pkg_name=$1
    version=`aptitude show $pkg_name | grep '^Version: ' |cut -f 2 -d ' '`
    arch=`aptitude show $pkg_name | grep 'Architecture: ' | cut -f 2 -d ' '`
    (cd $TEMP_DEBS_DIR; aptitude download $pkg_name)
    deb_path=$TEMP_DEBS_DIR/`ls $TEMP_DEBS_DIR | grep "^$pkg_name"`
    deb_name=`basename $deb_path`
    RET=`curl -T $deb_path -u$BINTRAY_USER:$BINTRAY_API_KEY "$BINTRAY_BASE_URL/content/$BINTRAY_REPOSITORY/$pkg_name/$version/$deb_name;deb_distribution=$DEB_DISTRIBUTION;deb_component=$DEB_COMPONENT;deb_architecture=$arch;publish=1;override=0"`
    if echo $RET | jq '.message' | grep "already exists"; then
        warn "failed to upload: `echo $RET | jq '.message'`"
    elif echo $RET | jq '.message' | grep "Entity Too Large"; then
        error "skip uploading $1: `echo $RET | jq '.message'`"
    elif [ "`echo $RET | jq '.message'`" != "\"success\"" ]; then
        panic "failed to upload: `echo $RET | jq '.message'`"
    else
        info "uploaded: $pkg_name"
    fi
}

info "uploading package $1"
create_package $1
upload_content $1
