#!/usr/bin/env bash
set -Eeuo pipefail

service=$1
unit=$2
source_script=$3
action=$4
environment=$5
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
run_dir=${FUNSSR_RUN_DIR:-"${base_dir}/.run"}
pid_file="${run_dir}/${service}.pid"
lock_file="${run_dir}/${service}.lock"

mkdir -p "$run_dir"
if [[ "$action" == start || "$action" == restart || "$action" == run ]]; then
	exec 9>"$lock_file"
	flock -n 9 || { echo "服务操作正在进行: $service" >&2; exit 1; }
fi

installed_unit() {
	command -v systemctl >/dev/null 2>&1 && systemctl cat "$unit" >/dev/null 2>&1
}

dev_init() {
	local init="/etc/init.d/$unit"
	[[ -x "$init" ]] || { echo "dev 服务尚未安装: $init" >&2; return 1; }
	printf '%s\n' "$init"
}

case "$environment" in
	prod)
		installed_unit || { echo "prod 服务尚未安装: $unit" >&2; exit 1; }
		case "$action" in
			status) exec systemctl --no-pager --plain --full status "$unit" ;;
			start|stop|restart) exec systemctl "$action" "$unit" ;;
			run) exec systemctl start "$unit" ;;
			*) exit 2 ;;
		esac
		;;
	dev)
		case "$action" in
			run)
				[[ -f "$source_script" ]] || { echo "未找到服务脚本: $source_script" >&2; exit 1; }
				exec bash "$source_script"
				;;
			status) init=$(dev_init); exec "$init" status ;;
			start|stop|restart) init=$(dev_init); exec "$init" "$action" ;;
			*) exit 2 ;;
		esac
		;;
	*) echo "环境必须是 dev 或 prod" >&2; exit 2 ;;
esac
