#!/usr/bin/env bash
set -Eeuo pipefail
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
exec bash "$(dirname "${BASH_SOURCE[0]}")/service.sh" ssr ssr "$base_dir/darkssr/server/ssr.sh" "$@"
