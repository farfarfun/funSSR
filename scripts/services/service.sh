#!/usr/bin/env bash
set -Eeuo pipefail

service=$1
unit=$2
action=$3
environment=$4
base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
run_dir=${FUNSSR_RUN_DIR:-"${base_dir}/.run"}
lock_file="${run_dir}/${service}.lock"

mkdir -p "$run_dir"
if [[ "$action" == start || "$action" == restart || "$action" == run ]]; then
	exec 9>"$lock_file"
	flock -n 9 || { echo "服务操作正在进行: $service" >&2; exit 1; }
fi

installed_unit() {
	command -v systemctl >/dev/null 2>&1 && systemctl cat "$unit" >/dev/null 2>&1
}

init_script() {
	local init_dir="${FUNSSR_INIT_DIR:-/etc/init.d}"
	printf '%s\n' "$init_dir/$unit"
}

installed_init() {
	local init
	init=$(init_script)
	[[ -x "$init" ]] || { echo "服务尚未安装: $init" >&2; return 1; }
	printf '%s\n' "$init"
}

require_file() {
	local path=$1 description=$2
	[[ -f "$path" ]] || { echo "run 不可用: 未找到已安装的${description}: $path" >&2; exit 1; }
}

run_foreground() {
	local ssr_dir ssr_config binary config
	case "$service" in
	ssr)
		ssr_dir=${FUNSSR_SSR_DIR:-/usr/local/shadowsocksr}
		if [[ -n ${FUNSSR_SSR_CONFIG:-} ]]; then
			ssr_config=$FUNSSR_SSR_CONFIG
		elif [[ -f "${ssr_dir}/user-config.json" ]]; then
			ssr_config="${ssr_dir}/user-config.json"
		else
			ssr_config=/etc/shadowsocksr/user-config.json
		fi
		require_file "${ssr_dir}/shadowsocks/server.py" "ShadowsocksR 服务"
		require_file "$ssr_config" "ShadowsocksR 配置"
		command -v python >/dev/null 2>&1 || { echo "run 不可用: 未找到 python" >&2; exit 1; }
		cd "${ssr_dir}/shadowsocks"
		exec python "${ssr_dir}/shadowsocks/server.py" -c "$ssr_config" a
		;;
	ssrmu)
		ssr_dir=${FUNSSR_SSRMU_DIR:-/usr/local/shadowsocksr}
		require_file "${ssr_dir}/server.py" "ShadowsocksR MuJSON 服务"
		command -v python >/dev/null 2>&1 || { echo "run 不可用: 未找到 python" >&2; exit 1; }
		cd "$ssr_dir"
		exec python "${ssr_dir}/server.py" a
		;;
	trojan)
		binary=${FUNSSR_TROJAN_BIN:-/usr/src/trojan/trojan}
		config=${FUNSSR_TROJAN_CONFIG:-/usr/src/trojan/server.conf}
		require_file "$binary" "Trojan 服务"
		require_file "$config" "Trojan 配置"
		[[ -x "$binary" ]] || { echo "run 不可用: Trojan 服务不可执行: $binary" >&2; exit 1; }
		exec "$binary" -c "$config"
		;;
	v2ray)
		binary=${FUNSSR_V2RAY_BIN:-/usr/local/bin/v2ray}
		config=${FUNSSR_V2RAY_CONFIG:-/usr/local/etc/v2ray/config.json}
		require_file "$binary" "V2Ray 服务"
		require_file "$config" "V2Ray 配置"
		[[ -x "$binary" ]] || { echo "run 不可用: V2Ray 服务不可执行: $binary" >&2; exit 1; }
		exec "$binary" run -config "$config"
		;;
	*) echo "不支持的服务: $service" >&2; exit 2 ;;
	esac
}

case "$environment" in
	prod)
		[[ "$action" != run ]] || run_foreground
		if init=$(installed_init 2>/dev/null); then
			case "$action" in
				status) exec "$init" status ;;
				start|stop|restart) exec "$init" "$action" ;;
				*) exit 2 ;;
			esac
		fi
		installed_unit || { echo "prod 服务尚未安装: $unit" >&2; exit 1; }
		case "$action" in
			status) exec systemctl --no-pager --plain --full status "$unit" ;;
			start|stop|restart) exec systemctl "$action" "$unit" ;;
			*) exit 2 ;;
		esac
		;;
	dev)
		case "$action" in
			run) run_foreground ;;
			status) init=$(installed_init); exec "$init" status ;;
			start|stop|restart) init=$(installed_init); exec "$init" "$action" ;;
			*) exit 2 ;;
		esac
		;;
	*) echo "环境必须是 dev 或 prod" >&2; exit 2 ;;
esac
