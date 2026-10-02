#!/usr/bin/env bash
set -Eeuo pipefail
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
exec bash "$(dirname "${BASH_SOURCE[0]}")/service.sh" v2ray v2ray "$base_dir/darkssr/server/v2ray_ws_tls.sh" "$@"
