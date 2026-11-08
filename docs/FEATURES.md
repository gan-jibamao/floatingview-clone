# 功能清单（由设置面板文案与偏好键反推）

> 来源：`floatingViewPrefs` 的 244 条中文字面量 + 308 个偏好键。这是**作者自己写在设置里**的功能描述，可信度最高。

## 一、三屏 / 浮窗

| 功能 | 说明（原文案） |
|---|---|
| 打开三屏、浮窗 | 竖屏下打开三屏；横屏下打开浮窗 |
| 关闭三屏界面 | — |
| 侧边小窗数量 / 显示位置 | 左侧即屏幕左侧，右侧则是屏幕右侧，横屏同理，不支持整体拖动 |
| 侧边位置改变 | 临时改变，注销后恢复默认 |
| 交换主次屏位置 | 交换主屏和两个小窗的左右位置 |
| 调度主屏浮窗不自动布局 | 打开后只有新开窗/切到主屏才自动布局 |
| 调度小窗与刘海方向安全距离 | — |
| 角落区域大小 | 顶部 / 底部角落区域宽度，左右两个角同时增减 |
| 横屏浮窗键盘弹起放大浮窗 | `interfaceOrigin_3_4_isZoomFloatView` |
| 竖屏浮窗打开固定屏中心 | 转向或拖拽全屏后都不记录位置 |

## 二、主屏浮窗手势（作者原文）

> 主屏浮窗取消了灰色背景以及图钉，因此操作也有很大变更。
> **缩放**：四个角落拉伸即可缩放。
> **移动**：顶部和底部均可拖动，顶部触控高度是状态栏高度，底部触控高度是系统黑条高度。
> **其他**：横屏下浮窗较小，建议用顶部区域移动和缩放。

- 点击浮窗顶部区域 / 底部区域 → 可绑定动作
- 拖拽到屏幕底部全屏打开（拖拽区在屏幕底部中心，接近时浮窗半透明）
- 侧边小窗手势：上滑 / 下滑 / 左滑 / 右滑 各自可绑定动作

## 三、可绑定到手势的动作（工具菜单）

打开三屏浮窗、锁定屏幕转向、切换普通/暗黑模式、打开控制中心、清理后台任务栏应用、重启 SpringBoard、切换勿扰模式、打开通知中心、降半屏、切换低电量模式、开关蜂窝数据、开关铃声、开关 VPN、开关定位、开关 WiFi、开关飞行模式、开关手电筒、关机并重启、将前台应用放到侧边、打开搜索应用界面、微信扫码/收付款/我的二维码、支付宝扫码/收付款/乘车码、前台应用浮窗化。

对应 SF Symbol（可直接对照代码）：
`antenna.radiowaves.left.and.right`(飞行) `wifi` `flashlight.on.fill` `switch.2`(控制中心) `lock.iphone` `lock.rotation` `rectangle.on.rectangle`(三屏) `sidebar.squares.right` `minus.plus.batteryblock`(低电量) `hand.raised`(勿扰) `bell.badge`(通知) `light.max`(暗黑) `qrcode.viewfinder` `power.dotted`(关机) `trash.slash`(清理) `filemenu.and.selection` `arrow.left.arrow.right`(交换) `rectangle.dashed.badge.record`(录屏)

## 四、环形菜单（Arc）

- 层级数：应用环 1~4 层（`arcAppLevelCount`），工具环 1~3 层（`arcToolLevelCount`）
- 每层可独立设置：显示数量、item 大小、半径
- 内外圈显示数量（`arcAppShowCount_inner` / `_outer`）
- 菜单触发方式（`arcMenuTriggerWay`）、灵敏度（`arcContainerSensitiveness_onTouchMove`）
- 振动反馈（`arcVibrationFeedback`）、按钮底色（`arcBtn_bgColor_value`）、工具开关态/非开关态颜色
- 打开菜单时截屏隐藏自身（`arcMenuVc_onTakeScreenHideSelf`）

## 五、键盘相关

- 浮窗键盘弹出方式：竖屏 / 横屏各自独立（`wayKeyboardShowIntoFloatingView_1_2` / `_3_4`）
- 点击空白处收键盘时是否同时关闭浮窗
- 横屏时移动外置键盘（`isMoveOutsideKeyboardPosition`）
- 外置键盘收起时同时关闭浮窗（`isCloseFlotingView_onOutsideKeyboardWillHide`）
- 非系统键盘震动、与底部接触时震动反馈（`partyKeyboardFeedbackStatus`）
- 搜索面板弹出键盘时避免遮挡（`searchAppVC_keyboardWillShow_avoid_shade`）

## 六、通知横幅

- 通知横幅打开浮窗开关；打开方式可选「下拉」或「点击」（`notificationViewPrsentFloatV_gestrueWay`）
- 依赖 `BNContentViewController` / `NCNotificationShortLookViewController` 两个 Orion 钩子

## 七、主屏图标 / 桌面

- 主屏图标长按菜单注入「通过浮窗打开应用」（`SBIcon_openFloatingGesture`，即 dylib 里唯一一句中文）
- 图标拖拽越界开启浮窗（`enableSBiconEnableGesture`）
- 侧边拖动应用图标时的触感反馈（`handOnMoveSideBarApplicationIcon_feedback`）
- 重置图标位置（`resetSBIconLocation`）

## 八、外观

- 浮窗阴影：透明度 + 范围（`floatingViewHostingviewShadow_Opacity` / `Range`）
- 侧边栏阴影：`sideBarContainerShadowRange` / `_Opacity`
- 浮窗圆角大小、悬浮按钮容器阴影、按钮粘附态透明度
- 悬浮按钮显示角标、长按显示侧边工具栏、截屏时隐藏自身

## 九、搜索 / 应用面板

- 搜索界面打开方式（`searchAppView_openAppWay_1_2` / `_3_4`）
- 长按弹出快捷菜单、快捷菜单打开应用的方式
- 列表显示 bundle id 作为副标题（`showIdentifiersAsSubtitle`）
- 搜索时是否包含 bundle id（`includeIdentifiersInSearch`）
- 应用排序页 `SortAppVC`、工具排序页 `SortToolsVC`

## 十、配置管理

- 导出配置（非备份）、从文件导入配置、从备份恢复、重置为默认
- 只支持 plist 文件；重置前提示备份（原文案：「此操作不可逆，重置前请记得备份，是否继续?」）

## 十一、多屏 / 前控制台

- 前控制台（Front Console）开关 + 触发方式（`frontConsoleEnable` / `frontConsoleTriggerWay`），对应 `FVFrontConsoleWindow`（windowLevel 28）、`FVFrontConsoleVC`、`FVFrontConsoleContainer`
- 多屏渲染位置（`multipleScreenRenderPosition`）
- 岛位（Dynamic Island）动画状态（`islandPositionAnimatedStatus`）
