# DDE二维码识别

专为 DDE 桌面环境打造的屏幕二维码识别工具，使用 Flutter 构建。

说明：
1. 由于是基于Zbar识别，可能存在部分二维码识别不到的问题
2. 由于是基于Zbar识别，某些条形码也会被识别到(这不是bug而是feature😂)
3. 目前不支持Wayland，问题太多了……

虽说是为 DDE 开发的，不过简单测试了下，其他桌面环境大概率也能用，毕竟功能太简单了

> 小技巧：可以绑定为快捷键触发，命令是 /opt/apps/com.debuggerx.dde-qrcode-detector/files/dde_qrcode_detector
