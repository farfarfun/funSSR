#!/usr/bin/env bash
set -Eeuo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
run_dir="${FUNSSR_RUN_DIR:-${root_dir}/.run}"

usage() {
	cat <<'EOF'
用法: scripts/setup.sh {start|stop|restart|run|status} {dev|prod} [ssr|ssrmu|trojan|v2ray]
dev 使用仓库脚本直接运行，prod 使用已安装的 systemd/init 服务。
EOF
}

[[ $# -ge 2 && $# -le 3 ]] || { usage >&2; exit 2; }
action=$1
mode=$2
service=${3:-ssrmu}
[[ "$mode" == dev || "$mode" == prod ]] || { echo "环境必须是 dev 或 prod" >&2; exit 2; }
case "$service" in
	ssr) script="$root_dir/darkssr/server/ssr.sh"; unit=ssr ;;
	ssrmu) script="$root_dir/darkssr/server/ssrmu.sh"; unit=ssrmu ;;
	trojan) script="$root_dir/darkssr/server/trojan_centos7.sh"; unit=trojan ;;
	v2ray) script="$root_dir/darkssr/server/v2ray_ws_tls.sh"; unit=v2ray ;;
	*) echo "不支持的服务: $service" >&2; exit 2 ;;
esac

mkdir -p "$run_dir"
export FUNSSR_RUN_DIR="$run_dir"

case "$action" in
	run)
		[[ "$mode" == dev ]] || { echo "run 仅用于 dev；prod 请使用 start" >&2; exit 2; }
		exec bash "$script"
		;;
	start|stop|restart|status)
		if [[ "$mode" == prod ]]; then
			command -v systemctl >/dev/null 2>&1 || { echo "prod 需要 systemctl" >&2; exit 1; }
			exec systemctl "$action" "$unit"
		fi
		init="/etc/init.d/$unit"
		[[ -x "$init" ]] || { echo "dev 服务尚未安装: $init" >&2; exit 1; }
		exec "$init" "$action"
		;;
	*) usage >&2; exit 2 ;;
esac
