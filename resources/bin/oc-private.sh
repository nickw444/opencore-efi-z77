#!/bin/bash

set -eu

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_PATH=$(realpath "$0");
SCRIPT_DIR=$(realpath $(dirname "$0"));

smudge() {
    source "${SCRIPT_DIR}/secrets.env.sh"

    /usr/libexec/PlistBuddy "$1" \
        -c "Set PlatformInfo:Generic:MLB ${OC_SECRET_MLB}";
    /usr/libexec/PlistBuddy "$1" \
        -c "Set PlatformInfo:Generic:SystemSerialNumber ${OC_SECRET_SYSTEM_SERIAL_NUMBER}";
    /usr/libexec/PlistBuddy "$1" \
        -c "Set PlatformInfo:Generic:SystemUUID ${OC_SECRET_SYSTEM_UUID}";
    cat "$1";
}


clean() {
    /usr/libexec/PlistBuddy "$1" \
        -c 'Set PlatformInfo:Generic:MLB Change Me!';
    /usr/libexec/PlistBuddy "$1" \
        -c 'Set PlatformInfo:Generic:SystemSerialNumber Change Me!';
    /usr/libexec/PlistBuddy "$1" \
        -c 'Set PlatformInfo:Generic:SystemUUID Change Me!';
    cat "$1";
}

install() {
    git config filter.oc-private.smudge "${SCRIPT_PATH} smudge %f";
    git config filter.oc-private.clean "${SCRIPT_PATH} clean %f";
}

main() {
    local mode=$1

    case $mode in
        "smudge")
            local file=$2;
            local tmp_file;

            tmp_file=$(mktemp);
            cat "${file}" > ${tmp_file};
            smudge "$tmp_file";
            ;;
        "clean")

            local file=$2;
            local tmp_file;

            tmp_file=$(mktemp);
            cat "${file}" > ${tmp_file};
            clean "$tmp_file";
            ;;
        "install")
            install;
            ;;
        *)
            echo "Unknown mode: $1";
            exit 1;
            ;;
    esac
}

main "$@"
