#!/bin/sh

set -e
set -u

find scripts -type f -print0 | xargs -0 -r -P"$(nproc)" -I{} bash -c 'shellcheck -Calways -x -e SC1117,SC2034,SC2059,SC2153 {}'
find functions -type f -print0 | xargs -0 -r -P"$(nproc)" -I{} bash -c 'shellcheck -Calways -x -e SC1117,SC2034,SC2059,SC2153 {}'

