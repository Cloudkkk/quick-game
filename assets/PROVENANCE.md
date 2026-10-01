# 素材来源

当前游戏已采用用户要求的简约 Q 版新素材，见 `PROVENANCE-Q.md`。以下保留首版素材来源记录；旧 `buildings.png` 已不再被游戏引用。

`buildings.png` 是本次通过 Codex 内置 imagegen 生成的原创透明 2×2 建筑图集：左上小屋、右上联排、左下别墅、右下豪宅。使用内置工具模式；没有使用 API、没有提供或索取密钥。游戏直接按象限读取图集，没有把视频帧中的房屋、标志、水印提取为成品资产。

街道、湖面、树木、标签与界面由 `game.gd` 原创程序绘制。系统字体仅按可选路径读取用户机器上已经安装的字体；没有把它们复制进项目。缺少中文字体时降级到 Godot 自带字体和英文。

生成提示词：

```text
Use case: stylized-concept. Asset type: transparent sprite atlas for an original isometric real estate trading game. Create exactly FOUR separate isometric buildings in a clean 2 by 2 grid on a transparent 1024 square canvas. Each building must be fully contained inside its own 512 square quadrant with generous empty padding, no overlap. Upper left: small cream starter cottage with terracotta roof. Upper right: mint and cream three-story narrow townhouse. Lower left: larger cream modern villa with slate roof, balcony and small blue pool. Lower right: elegant ivory mansion with teal roof, columns and portico. Camera same for all, elevated 30 degree isometric view showing front and right wall, each building bottom at around 85% of its cell. Clean crisp hand-painted casual game art, soft warm afternoon colors, subtle outlines, readable silhouettes, blue windows. Standalone buildings only, transparent background, no landscape, no roads, no title, no writing, no price tags, no logos, no watermark. Original art; not replicas of any publisher's assets.
```

实际工具返回图集尺寸为 1280×1280；游戏按实际纹理尺寸动态划分四个象限。
