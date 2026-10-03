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

# 校验 pid_file：陈旧文件直接清理返回 0；进程仍存活则返回 1 并报告 PID。
stale_pid_check() {
	[[ -r "$pid_file" ]] || return 0
	local pid
	read -r pid <"$pid_file" || { rm -f "$pid_file"; return 0; }
	if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
		echo "dev 前台会话仍在运行: $service (PID $pid)" >&2
		return 1
	fi
	rm -f "$pid_file"
	return 0
}

dev_init() {
	local init_dir="${FUNSSR_INIT_DIR:-/etc/init.d}"
	local init="$init_dir/$unit"
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
				stale_pid_check || exit 1
				printf '%s\n' "$$" >"$pid_file"
				exec bash "$source_script"
				;;
			status) init=$(dev_init); exec "$init" status ;;
			start|stop|restart) init=$(dev_init); exec "$init" "$action" ;;
			*) exit 2 ;;
		esac
		;;
	*) echo "环境必须是 dev 或 prod" >&2; exit 2 ;;
esac
