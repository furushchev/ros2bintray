#!/bin/bash

export LANG=C
#set -x
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
defvar()
{
    local val secret
    val=$(eval echo '$'"$1")
    if [ "$val" = "" ]; then
        if [ $# -lt 2 ]; then
            panic variable $(echo $1) is not defined
        else
            eval $(echo $1)="\"${@:2:($#-1)}\""
        fi
    else
        if [ "$2" = "-s" ]; then
            secret="true"
        fi
    fi
    if [ "$secret" != "true" ]; then
        declare -p $(echo $1)
    fi
}

setq()
{
    eval $(echo $1)="\"${@:2:($#-1)}\""
    declare -p $(echo $1)
}

validate_args()
{
    if [ $# -ne 1 ]; then
        panic "Usage: $0 <package name>"
    fi
    pkg_name=$1

    info checking arguments...
    # Environment
    defvar DEB_DISTRIBUTION `lsb_release -cs`
    defvar DEB_COMPONENT main
    # Downloading
    defvar TEMP_DEBS_DIR /tmp/debs
    defvar APT_MIRRORS "http://packages.ros.org/ros-shadow-fixed/ubuntu"
    defvar DL_CONCURRENT_NUM 5
    # Uploading
    defvar BINTRAY_BASE_URL "https://api.bintray.com"
    defvar BINTRAY_REPOSITORY
    defvar BINTRAY_USER
    defvar BINTRAY_API_KEY -s

    if [ -e $TEMP_DEBS_DIR ]; then
        rm -rf $TEMP_DEBS_DIR
    fi
    mkdir $TEMP_DEBS_DIR
}

create_package()
{
    info creating package to bintray...
    RET=$(curl -H 'Accept: application/json' -H 'Content-type: application/json' -X POST -d "{
  \"name\": \"$pkg_name\",
  \"desc\": \"$pkg_desc\",
  \"licenses\": [\"Unlicense\"],
  \"vcs_url\": \"$vcs_url\",
  \"public_download_numbers\": true
}" -u$BINTRAY_USER:$BINTRAY_API_KEY "$BINTRAY_BASE_URL/packages/$BINTRAY_REPOSITORY")
    if echo $RET | jq '.message' | grep exists; then
        warn "`echo $RET | jq '.message'`"
    elif [ "`echo $RET | jq '.name'`" != "" ]; then
        panic "failed to create package: $RET"
    else
        info "created package: `echo $RET | jq '.name'`"
    fi
}

urldecode()
{
    printf '%b' "${1//%/\\x}"
}

get_deb_uri()
{
    local pkg_info
    info getting information of $pkg_name ...
    while read -a pkg_info; do
        case $pkg_info in
            Package:)
                setq pkg_name ${pkg_info[1]}
                ;;
            Version:)
                setq pkg_ver $(urldecode ${pkg_info[1]})
                ;;
            Architecture:)
                setq pkg_arch ${pkg_info[1]}
                ;;
            Homepage:)
                setq vcs_url ${pkg_info[1]}
                ;;
            Filename:)
                setq pkg_path ${pkg_info[1]}
                ;;
            MD5sum:)
                setq pkg_md5 ${pkg_info[1]}
                ;;
            Description:)
                setq pkg_desc ${pkg_info[@]:1}
                ;;
        esac
    done < <(apt-cache show -q $pkg_name)
    defvar vcs_url "https://github.com/" # dummy
}

download_deb()
{
    local mirrors mirror uri uris
    mirrors=${APT_MIRRORS//,/ }
    for mirror in `echo $mirrors`; do
        uris="$uris \"$mirror/$pkg_path\" "
    done
    info downloading debian package...
    aria2c \
        --continue=true \
        --max-concurrent-downloads=$DL_CONCURRENT_NUM \
        --max-connection-per-server=$DL_CONCURRENT_NUM \
        --split=5 \
        --min-split-size=1M \
        --dir=$TEMP_DEBS_DIR \
        --out=$(basename "$pkg_path") \
        --checksum=md5=$pkg_md5 \
        --quiet=true \
        $uris
}

upload_content()
{
    local deb_name deb_path
    deb_name=$(basename "$pkg_path")
    deb_path=$(echo $TEMP_DEBS_DIR/$deb_name)
    info uploading debian package to bintray...
    RET=`curl -T $deb_path -u$BINTRAY_USER:$BINTRAY_API_KEY "$BINTRAY_BASE_URL/content/$BINTRAY_REPOSITORY/$pkg_name/$pkg_ver/$deb_name;deb_distribution=$DEB_DISTRIBUTION;deb_component=$DEB_COMPONENT;deb_architecture=$pkg_arch;publish=1;override=0"`
    if echo $RET | jq '.message' | grep "already exists"; then
        warn "failed to upload: `echo $RET | jq '.message'`"
    elif echo $RET | jq '.message' | grep "Entity Too Large"; then
        error "skip uploading $1: `echo $RET | jq '.message'`"
    elif [ "`echo $RET | jq '.message'`" != "\"success\"" ]; then
        panic "failed to upload: `echo $RET | jq '.'`"
    else
        info "uploaded: $pkg_name"
    fi
}


validate_args $@
info uploading package $pkg_name
get_deb_uri
download_deb
create_package
upload_content
info finished uploading $pkg_name successfly!
