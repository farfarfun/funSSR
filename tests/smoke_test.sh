#!/usr/bin/env bash
# scripts/setup.sh 冒烟测试：覆盖参数校验、dev/prod 的 start/run/status 语义、
# 未安装服务、重复启动、陈旧 PID、失败退出码。全部使用 mock systemctl/init 脚本，
# 不依赖真实 systemd 单元或 root 权限，可在任意 Linux 开发机上运行。
#
# 用法: bash tests/smoke_test.sh
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
setup_sh="$repo_root/scripts/setup.sh"

workdir=$(mktemp -d)
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

pass=0
fail=0

assert_eq() {
	local desc=$1 expected=$2 actual=$3
	if [[ "$expected" == "$actual" ]]; then
		echo "ok   - $desc"
		pass=$((pass + 1))
	else
		echo "FAIL - $desc (期望 $expected, 实际 $actual)" >&2
		fail=$((fail + 1))
	fi
}

run_setup() {
	# 捕获退出码而不让 set -e 中断测试脚本本身
	set +e
	"$setup_sh" "$@" >"$workdir/out.log" 2>&1
	local code=$?
	set -e
	echo "$code"
}

echo "=== 1. 参数校验 ==="
code=$(run_setup); assert_eq "无参数 -> usage" 2 "$code"
code=$(run_setup start badsvc dev); assert_eq "不支持的服务" 2 "$code"
code=$(run_setup start ssr foo); assert_eq "环境必须是 dev/prod" 2 "$code"
code=$(run_setup bogus ssr dev); assert_eq "不支持的 action" 2 "$code"
code=$(run_setup start ssr dev extra); assert_eq "多余参数" 2 "$code"

echo "=== 2. status 默认汇总全部服务与环境（均未安装） ==="
export FUNSSR_RUN_DIR="$workdir/.run"
export FUNSSR_INIT_DIR="$workdir/init.d"
mkdir -p "$FUNSSR_INIT_DIR"
code=$(run_setup status)
assert_eq "全部未安装 -> status 非零退出" 1 "$code"
for svc in ssr ssrmu trojan v2ray; do
	for env in dev prod; do
		grep -q "== ${svc} (${env}) ==" "$workdir/out.log" || {
			echo "FAIL - status 输出缺少 ${svc} (${env}) 分组" >&2
			fail=$((fail + 1))
		}
	done
done

echo "=== 3. dev：未安装时 start/stop/restart 报错且非零退出 ==="
code=$(run_setup start ssr dev); assert_eq "dev 未安装 start" 1 "$code"

echo "=== 4. dev：用假 init 脚本模拟已安装，验证 start/stop/restart 透传 ==="
cat >"$FUNSSR_INIT_DIR/ssr" <<'EOF'
#!/usr/bin/env bash
echo "mock-init ssr $1"
case "$1" in
	start|restart) exit 0 ;;
	stop) exit 0 ;;
	status) exit 3 ;;  # systemd 约定：未运行时 status 返回非 0（如 3）
	*) exit 2 ;;
esac
EOF
chmod +x "$FUNSSR_INIT_DIR/ssr"
code=$(run_setup start ssr dev); assert_eq "dev 已安装 start" 0 "$code"
grep -q "mock-init ssr start" "$workdir/out.log" || { echo "FAIL - 未透传到 mock init start" >&2; fail=$((fail + 1)); }
code=$(run_setup stop ssr dev); assert_eq "dev 已安装 stop" 0 "$code"
code=$(run_setup restart ssr dev); assert_eq "dev 已安装 restart" 0 "$code"
code=$(run_setup status ssr dev); assert_eq "dev status 透传非零退出码" 3 "$code"

echo "=== 5. dev run：真正前台运行占位脚本，写入并校验 pid_file ==="
cat >"$workdir/placeholder_ssr.sh" <<'EOF'
#!/usr/bin/env bash
echo "placeholder service running pid=$$"
sleep 3
EOF
chmod +x "$workdir/placeholder_ssr.sh"
bash "$repo_root/scripts/services/service.sh" ssr ssr "$workdir/placeholder_ssr.sh" run dev \
	>"$workdir/run.log" 2>&1 &
run_pid=$!
sleep 1
pid_file="$FUNSSR_RUN_DIR/ssr.pid"
if [[ -r "$pid_file" ]]; then
	written_pid=$(cat "$pid_file")
	if kill -0 "$written_pid" 2>/dev/null; then
		echo "ok   - pid_file 写入且进程存活 (PID $written_pid)"
		pass=$((pass + 1))
	else
		echo "FAIL - pid_file 中的 PID 并未存活" >&2
		fail=$((fail + 1))
	fi
else
	echo "FAIL - run dev 未写入 pid_file" >&2
	fail=$((fail + 1))
fi

echo "--- 5b. 重复 run 应被拒绝（陈旧/活动 PID 与 flock 双重保护） ---"
dup_code=$(set +e; bash "$repo_root/scripts/services/service.sh" ssr ssr "$workdir/placeholder_ssr.sh" run dev >"$workdir/dup.log" 2>&1; echo $?; set -e)
assert_eq "占用期间重复 run dev 应非零退出" 1 "$dup_code"

wait "$run_pid"
echo "--- 5c. 进程退出后陈旧 PID 应被清理并允许重新 run ---"
timeout 2 bash "$repo_root/scripts/services/service.sh" ssr ssr "$workdir/placeholder_ssr.sh" run dev \
	>"$workdir/rerun.log" 2>&1 &
rerun_pid=$!
sleep 0.5
new_pid=$(cat "$pid_file" 2>/dev/null || echo "")
if [[ -n "$new_pid" && "$new_pid" != "$written_pid" ]]; then
	echo "ok   - 陈旧 PID 清理后重新写入新 PID"
	pass=$((pass + 1))
else
	echo "FAIL - 陈旧 PID 未被正确替换 (旧=$written_pid 新=$new_pid)" >&2
	fail=$((fail + 1))
fi
kill "$rerun_pid" 2>/dev/null || true
wait "$rerun_pid" 2>/dev/null || true

echo "=== 6. prod：用假 systemctl 模拟已安装/未安装 ==="
fake_bin="$workdir/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
	cat)
		[[ "$2" == "ssr" ]] && exit 0 || exit 1
		;;
	start|stop|restart)
		echo "mock-systemctl $1 $2"
		exit 0
		;;
	--no-pager)
		echo "mock-systemctl status $*"
		exit 0
		;;
	*) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/systemctl"
export PATH="$fake_bin:$PATH"

code=$(run_setup start ssr prod); assert_eq "prod 已安装 start" 0 "$code"
code=$(run_setup run ssr prod); assert_eq "prod run（仅已安装时执行）" 0 "$code"
code=$(run_setup start ssrmu prod); assert_eq "prod 未安装 start 报错" 1 "$code"
code=$(run_setup run ssrmu prod); assert_eq "prod 未安装 run 报错（不得回退到源码）" 1 "$code"
code=$(run_setup status ssr prod); assert_eq "prod 已安装 status 非交互透传" 0 "$code"
grep -q "mock-systemctl status" "$workdir/out.log" || { echo "FAIL - prod status 未使用 --no-pager 非交互查询" >&2; fail=$((fail + 1)); }

echo
echo "=== 汇总: $pass 通过, $fail 失败 ==="
[[ "$fail" -eq 0 ]]
