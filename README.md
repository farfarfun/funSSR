# funSSR

[github](https://github.com/farfarfun/funSSR)

[gitee](https://gitee.com/farfarfun/funSSR)

# 安装 SSR-服务端

通过 ssrmu.sh 脚本安装 ShadowsocksR
先明确一点，我们是要安装 shadowsocksr 这个软件，ssrmu 是一个便捷的安装配置 ShadowsocksR 的脚本。总之，通过上一步登录到我们的 vps 后我们直接复制黏贴下面的命令

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/farfarfun/funSSR/master/darkssr/server/ssrmu.sh && chmod +x ssrmu.sh && bash ssrmu.sh
```

如果提示

bash: wget: command not found
的话，就先执行下面的再执行第一步的命令

yum -y install wget
然后就进入了 ssrmu.sh 脚本了。端口必须在 `1-65535` 范围内，建议使用未占用的高位端口，例如 `10001`；密码留空时脚本会安全随机生成，不要使用公开示例密码。

最后会出现配置完成的画面，复制好提示出现的 ssr 链接复制保存在剪贴板里，之后就要安装 ssr 客户端了。

# 安装 SSR-客户端

客户端安装包不再直接提交到本仓库。请从对应上游项目的正式发布页下载并校验发布者提供的校验值；本项目只维护服务端脚本。

|  平台   |                名称                |                                                     github 下载                                                      |                                                gitee 下载                                                 |
| :-----: | :--------------------------------: | :------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------: |
| Android | ShadowsocksR Android | [上游 releases](https://github.com/shadowsocksrr/shadowsocksr-android/releases) | - |
| Mac | ShadowsocksX-NG | [上游 releases](https://github.com/shadowsocks/ShadowsocksX-NG/releases) | - |
| Windows | ShadowsocksR Windows | [上游 releases](https://github.com/shadowsocksrr/shadowsocksr-csharp/releases) | - |

# 感谢

本仓库 `darkssr/` 下的安装/管理脚本移植自以下第三方项目。本项目保留上游版权声明；修改后的代码继续以本仓库 LICENSE 发布。`doubi` 明确采用 MIT License，`ladderbackup` 当前上游仓库未提供 LICENSE 文件，因此其许可证状态为未声明，使用者应按上游项目说明核实：

[luyiming1016/ladderbackup](https://github.com/luyiming1016/ladderbackup)（许可证未声明，原始来源归 luyiming1016）

[ToyoDAdoubi/doubi](https://github.com/ToyoDAdoubi/doubi)（MIT License，原始版权归 ToyoDAdoubi）

## 运行服务

统一入口要求显式指定环境：

```bash
scripts/setup.sh run dev ssrmu       # 前台运行仓库脚本
scripts/setup.sh start prod ssrmu    # 启动已安装的生产服务
scripts/setup.sh status prod ssrmu
```

服务日志和其他运行时文件放在仓库 `.run/` 目录；可通过 `FUNSSR_RUN_DIR` 指定独立目录。

## 关于 farfarfun

[farfarfun](https://github.com/farfarfun) 是一个专注于实用工具库的开源组织，
涵盖云存储、数据处理、AI、多媒体与开发工具链等方向。

- 🏠 组织主页：<https://github.com/farfarfun>
- 📧 联系：farfarfun@qq.com

本项目基于 [MIT](LICENSE) 协议开源。
