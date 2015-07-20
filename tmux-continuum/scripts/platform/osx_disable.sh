#!/bin/sh

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"

. "${CURRENT_DIR}/../vars.sh"

rm -rf "${osx_boot_start_file_path}"

# vim: set ts=8 sw=4 tw=0 ft=sh :
