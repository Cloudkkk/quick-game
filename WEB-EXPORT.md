# Web 导出与托管

项目使用 Godot 4.5.1、Compatibility 渲染、单线程 Web 模板，不依赖 SharedArrayBuffer、跨源隔离头或 PWA。

## 模板与构建

使用匹配的官方 Godot 4.5.1 导出模板。当前预设使用项目内 `.web-export/web_nothreads_release.zip`；此目录不提交。可以将官方单线程 release 模板放到该位置，或在编辑器的 Web 导出预设中清空“自定义模板 / Release”并使用已安装的官方模板。

官方版本来源：https://godotengine.org/download/archive/4.5.1-stable/

导出预设默认输出到相邻 `estate-rise-web/dist/index.html`；也可指定独立构建目录：

```sh
mkdir -p dist
godot --headless --path . --export-release Web dist/index.html
python3 tools/compress-web.py dist
```

第二步压缩 WASM，同时复制 `tools/wasm-loader.js` 到产物目录。HTML 预设已在引擎脚本之前引用 `wasm-loader.js?v=2`。

## 必须保留的加载修复

部分静态托管会忽略 `_headers`，把 gzip WASM 当普通字节返回，导致 Godot 加载停住。不得仅依赖 `Content-Encoding: gzip`：必须保留 `wasm-loader.js` 及 HTML 中的引用。

加载器仅处理同源 `index.wasm`：检测 gzip magic 时使用浏览器 `DecompressionStream('gzip')` 解压，已经由服务器解压的数据直接使用。校验 WASM magic 后返回 `application/wasm` Response。压缩 WASM 约 9.2 MB，未压缩约 38 MB。

使用 HTTPS 托管整个导出目录，包含 HTML、JS、WASM、PCK、音频 worklet 及 Godot 许可文件。WASM 的 MIME 为 `application/wasm`，PCK 为 `application/octet-stream`。保留并更新导出 HTML 内的资源大小配置，不把测试构建混入正式产物。

## 移动端与覆盖范围

画布随浏览器尺寸调整，直接处理触摸且关闭触摸转鼠标。没有可用中文字体时显示英文。音效采用预渲染 WAV 和 Web Sample 播放，等待首次用户输入。最佳成绩和静音偏好存储于浏览器 IndexedDB；隐私模式可能不保留。

音效版已在 Mac Chrome 的手机尺寸模拟下通过独立 QA 21/21、正式无探针构建 9/9。首次触摸后 AudioContext 为 running，实际播放 WAV 样本；静音、重开与刷新保留静音通过。测试服务器故意未设置 Content-Encoding，压缩加载兼容补丁已验证。浏览器录音有有效信号且无削波，尚未做主观听感和 Android 真机确认。
