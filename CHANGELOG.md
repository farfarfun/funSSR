# 更新日志

## 未发布

### 新增

- 增加 `scripts/setup.sh`，统一服务的 `start`、`stop`、`restart`、`run`、`status` 入口，并明确 `dev`/`prod` 环境。
- 增加 `.run/` 运行时目录约定。
- `scripts/setup.sh` 按 `action → service → environment` 的统一顺序解析参数；`scripts/services/<service>.sh` 拆分为各服务独立的分发脚本，`scripts/services/service.sh` 负责公共的 dev/prod 分发逻辑。
- `run prod` 已实现，仅对已安装的正式 systemd 服务生效，未安装时报错退出。
- `status` 不带参数时默认遍历全部服务与 `dev`/`prod` 环境，`prod` 下使用 `systemctl --no-pager --plain --full status`。

- 新增 `tests/smoke_test.sh`：覆盖参数校验、`status` 默认汇总/单目标透传退出码、dev 环境 start/stop/restart/run（PID 文件写入与陈旧 PID 清理）、prod 环境已安装/未安装分支，全部用 mock `systemctl`/`init.d` 脚本执行。
- `scripts/services/service.sh` 新增 `FUNSSR_INIT_DIR` 环境变量，可覆盖 dev 环境查找 `/etc/init.d/<unit>` 的目录（默认不变，供测试注入 mock）。

### 修复

- 直接执行 `ssr.sh` 或 `ssrmu.sh` 时，运行时 PID 和日志目录现在同样由脚本位置解析到仓库根 `.run/`；统一入口和直接调用不再使用不同目录。
- 空密码改为安全随机值，避免使用公开的固定默认密码。
- 不支持的系统和失败路径返回非零退出码。
- `ssr.sh`/`ssrmu.sh` 启停改为专属 PID 文件 + `kill -0`/`/proc/<pid>/cmdline` 校验进程身份，不再用模糊的 `ps -ef | grep` 判断重复启动。
- `Update_Shell` 更新流程中下载、读取新版本号、`chmod` 任一步失败都返回非零退出码，不再误报“脚本已更新”。
- 移除 `darkssr/client/config.json` 中硬编码的共享认证 ID 和示例邮箱，改为需要替换的占位符。
- `scripts/setup.sh status` 不带参数时环境默认值从单个字符串 `“dev prod”` 改为真正的数组展开，修复此前恒定失败（`环境必须是 dev 或 prod`）、无法汇总全部环境状态的问题。
- `scripts/services/service.sh` 的 `pid_file` 此前声明了却从未写入/读取（shellcheck SC2034）；现在 `run`（dev）会写入当前前台进程 PID，并在再次 `run` 前区分“进程仍存活”与“陈旧 PID 文件”，存活时拒绝重复前台运行。
- `scripts/setup.sh status <service> <env>`（单一明确目标）此前会把底层真实退出码统一折叠成 0/1，丢失具体状态信息；现在单目标直接透传真实退出码，仅在聚合多个目标时才归一为 0/1。
- README「感谢」区块不再笼统声称全部移植代码都按本仓库 MIT 发布：`ladderbackup` 来源的 `v2ray_ws_tls.sh` 上游许可证未声明，明确排除在本仓库 MIT 授权之外。

### 变更

- README 补充全部遗留交互式安装器的用途、支持系统、调用方式及系统修改风险，并明确它们不属于 `scripts/setup.sh` 的服务生命周期入口。
- 客户端安装包改由 GitHub Releases 或上游项目发布，仓库不再保存二进制文件。
- 安装文档中的端口范围统一为 `1-65535`。
- 仓库 description 更新为描述当前实际内容（服务端安装/管理脚本，不再提及已移除的客户端安装包）。

### 废弃

- 废弃从仓库直接下载客户端安装包的链接。
