# funSSR

[github](https://github.com/fundata/funSSR)

[gitee](https://gitee.com/notechats/funSSR)

# 安装 SSR-服务端

通过 ssrmu.sh 脚本安装 ShadowsocksR
先明确一点，我们是要安装 shadowsocksr 这个软件，ssrmu 是一个便捷的安装配置 ShadowsocksR 的脚本。总之，通过上一步登录到我们的 vps 后我们直接复制黏贴下面的命令

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/fundata/funSSR/master/funSSR/server/ssrmu.sh && chmod +x ssrmu.sh && bash ssrmu.sh
```

如果提示

bash: wget: command not found
的话，就先执行下面的再执行第一步的命令

yum -y install wget
然后就进入了 ssrmu.sh 脚本了，脚本有很多功能，小白的我们就一路回车就好了 注意这里，其他可以一路回车，选端口强烈建议换一个端口，建议将默认的 2333 换为 1000065535 间的 1000011000 之间的一个随机端口，最近 2333 端口被封的厉害

最后会出现配置完成的画面，复制好提示出现的 ssr 链接复制保存在剪贴板里，之后就要安装 ssr 客户端了。

# 安装 SSR-客户端

|  平台   |                名称                |                                                     github 下载                                                      |                                                gitee 下载                                                 |
| :-----: | :--------------------------------: | :------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------------------: |
| Android |   shadowsocksr-android-3.5.4.apk   |   [github](https://raw.githubusercontent.com/fundata/funSSR/master/funSSR/client/shadowsocksr-android-3.5.4.apk)   |   [gitee](https://gitee.com/notechats/funSSR/raw/master/funSSR/client/shadowsocksr-android-3.5.4.apk)   |
|   Mac   |       ShadowsocksX-NG-R8.dmg       |       [github](https://raw.githubusercontent.com/fundata/funSSR/master/funSSR/client/ShadowsocksX-NG-R8.dmg)       |       [gitee](https://gitee.com/notechats/funSSR/raw/master/funSSR/client/ShadowsocksX-NG-R8.dmg)       |
| Windows | ShadowsocksR-win-4.9.2-tlanyan.zip | [github](https://raw.githubusercontent.com/fundata/funSSR/master/funSSR/client/ShadowsocksR-win-4.9.2-tlanyan.zip) | [gitee](https://gitee.com/notechats/funSSR/raw/master/funSSR/client/ShadowsocksR-win-4.9.2-tlanyan.zip) |

# 感谢

[luyiming1016/ladderbackup](https://github.com/luyiming1016/ladderbackup)

[ToyoDAdoubi/doubi](https://github.com/ToyoDAdoubi/doubi)
