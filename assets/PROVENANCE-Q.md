# 当前素材：简约 Q 版视觉修订

`buildings-q.png` 为本次使用 Codex 内置 imagegen 重新生成的原创 4×2 透明图集，实际尺寸 1774×887。上排为四档白灰待售房，下排为相同轮廓的橙色持有房。当前游戏只引用此文件，旧 `buildings.png` 保留但不再使用。

参考视频帧只用于识别画风：简约几何轮廓、平涂低细节、黑灰轮廓线。未从视频抠取素材、标题或标志。程序按透明度测量图集显示边界，保持宽高比显示；没有改变生成图像像素。

街道、湖面与三角形 Q 版树木由 `game.gd` 程序绘制。字体使用随游戏打包的 Noto Sans CJK SC（SIL OFL 1.1），字体原始版权信息和许可均保留；中英文可在画面内即时切换，不依赖系统中文字体。

本次完整生成提示词（内置工具模式，无 API、无密钥）：

```text
Use case: stylized-concept. Asset type: original very simple cute Q-version isometric building sprite atlas for a real-estate trading game. Input reference: supplied screenshot only for style of small geometric house shapes, flat white-gray buildings, plain gray roofs and strong simple charcoal outlines. Do NOT extract or reproduce screenshot assets or text. Generate exactly 8 separate original buildings in a precise FOUR columns by TWO rows grid on a transparent canvas, aspect ratio 2:1. Each cell fully contained, no overlap, lots of transparent padding. Top row four buildings: 1 tiny cubic one-story white cottage with simple gray gable roof; 2 slightly taller two-story white townhouse, two or three square windows; 3 broad white villa, gray gabled roof with small cubic garage, very few windows; 4 large white simple three-story mansion, plain dark-gray broad roof, simple porch and 6-8 square outlined windows. Bottom row: EXACT same four silhouettes and roof shapes aligned under their top counterparts, but ALL wall faces AND roofs filled flat vivid yellow-orange with only one slightly darker orange face, indicating player ownership. Each sprite faces front and right, same isometric view. STYLE: very low detail 2000s Flash browser cartoon game graphics, adorable squat geometric toy-house proportions, crisp black/charcoal outline, FLAT SOLID COLORS, not realistic. Max 3 flat shades per building. No gradients, no texture, no tiles, no bevel, no botanical decorations, no balconies, no brick, no reflections, no soft rendering, no landscaping, no signs, no labels, no numbers, no text, no logo, no watermarks. Transparent actual alpha background. Simple 2D cartoons readable at 60 pixels tall. This is not elaborate 3D architectural art.
```
