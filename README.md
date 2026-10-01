# quick-game

Estate Rise（街区大亨）是一个 Godot 4.5.1 房地产交易小游戏：低买高卖，从 100 K 启动资金积累现金，购买梦想豪宅。

## 启动

使用 Godot 4.5.1 打开仓库根目录的 `project.godot`，按 F5 运行。macOS 安装 Godot 后也可双击 `Launch.command`。

```sh
godot --path .
```

## 玩法

- 点击白色挂牌房屋买入，点击橙色持有房卖出；价格箭头表示涨跌。
- 房价周期波动，未购买的挂牌会下架，持有房产不会消失。
- 现金达到右上角豪宅现价后，点击豪宅完成挑战。
- 1 秒 = 1 个月；空格暂停，R 重开，H / Esc 打开帮助，右下角切换速度。
- 支持直接触摸；一次主手指按下只触发一次交易。

## 音效与记录

包含买入 pop、盈利金币音、亏损短音、资金不足 boop、按钮轻点和胜利庆祝六种原创合成 WAV。右下角“声音 / 静音”开关会保存本地偏好；最多两路播放，普通音效间隔至少 80 毫秒。Web 音效等待首次点击、触摸或操作键输入后解锁，没有自动播放或背景音乐。

最佳通关时间与静音偏好分别保存在 Godot 的 `user://` 目录，不保存进行中的局面。游戏内可点击顶部“EN / 中文”即时切换，语言选择单独保存在本地，重开和刷新后保留。初次根据浏览器语言选择，中文使用随游戏打包的 Noto Sans CJK SC（OFL 1.1），不依赖系统字体。

## 验证

本机已通过核心玩法 19/19、音效专项 23/23，以及三种窗口尺寸的触摸和静音测试 40/40。音效版在 Mac Chrome 的手机尺寸模拟下已通过独立 QA 21/21、正式无探针构建 9/9：首次触摸启动音频、买卖播放、静音、重开及刷新保留静音均覆盖。Android 真机与实际扬声器听感尚未验证。

```sh
mkdir -p evidence
godot --headless --path . --log-file evidence/core.log --script res://tests/core_test.gd
godot --headless --path . --log-file evidence/audio.log --script res://tests/audio_test.gd
godot --headless --path . --log-file evidence/touch.log --script res://tests/touch_test.gd
godot --headless --path . --log-file evidence/language.log --script res://tests/language_test.gd
```

双语专项原生测试 38/38、实际 Mac Chrome 横竖屏 QA 40/40、正式无探针双语构建 15/15 已通过，覆盖动态交易文案、帮助与胜利、字形与文字边界、切换时状态不重置和刷新持久化。

## Web 导出

见 [WEB-EXPORT.md](WEB-EXPORT.md)。仓库保留单线程 Web 导出配置和 gzip WASM 加载修复源码，导出模板与构建产物不提交。

## 素材

当前 Q 版房屋图集为原创生成素材，来源记录见 [assets/PROVENANCE-Q.md](assets/PROVENANCE-Q.md)。音效没有使用第三方音频样本；合成源码是 `tools/make_sounds.py`，使用说明见 `assets/sounds/LICENSE.txt`。街道、树木、界面由程序绘制。
