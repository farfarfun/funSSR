#!/usr/bin/env bash
set -Eeuo pipefail
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
exec bash "$(dirname "${BASH_SOURCE[0]}")/service.sh" trojan trojan "$base_dir/darkssr/server/trojan_centos7.sh" "$@"
