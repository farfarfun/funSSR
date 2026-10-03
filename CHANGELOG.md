# 更新日志

## 未发布

### 新增

- 增加 `scripts/setup.sh`，统一服务的 `start`、`stop`、`restart`、`run`、`status` 入口，并明确 `dev`/`prod` 环境。
- 增加 `.run/` 运行时目录约定。
- `scripts/setup.sh` 按 `action → service → environment` 的统一顺序解析参数；`scripts/services/<service>.sh` 拆分为各服务独立的分发脚本，`scripts/services/service.sh` 负责公共的 dev/prod 分发逻辑。
- `run prod` 已实现，仅对已安装的正式 systemd 服务生效，未安装时报错退出。
- `status` 不带参数时默认遍历全部服务与 `dev`/`prod` 环境，`prod` 下使用 `systemctl --no-pager --plain --full status`。

### 修复

- 空密码改为安全随机值，避免使用公开的固定默认密码。
- 不支持的系统和失败路径返回非零退出码。
- `ssr.sh`/`ssrmu.sh` 启停改为专属 PID 文件 + `kill -0`/`/proc/<pid>/cmdline` 校验进程身份，不再用模糊的 `ps -ef | grep` 判断重复启动。
- `Update_Shell` 更新流程中下载、读取新版本号、`chmod` 任一步失败都返回非零退出码，不再误报“脚本已更新”。
- 移除 `darkssr/client/config.json` 中硬编码的共享认证 ID 和示例邮箱，改为需要替换的占位符。
- `scripts/setup.sh status` 不带参数时环境默认值从单个字符串 `"dev prod"` 改为真正的数组展开，修复此前恒定失败（`环境必须是 dev 或 prod`）、无法汇总全部环境状态的问题。

### 变更

- 客户端安装包改由 GitHub Releases 或上游项目发布，仓库不再保存二进制文件。
- 安装文档中的端口范围统一为 `1-65535`。

### 废弃

- 废弃从仓库直接下载客户端安装包的链接。
