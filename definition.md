## 1. 文件头注释（1-43行）

```c
/* See LICENSE file ... 
 * dynamic window manager ...
 */
```
- dwm 的设计思想：通过处理 X 事件驱动，使用 `SubstructureRedirectMask` 管理窗口。
- 事件处理器存放在数组中，O(1) 分发。
- 客户端按标签（tag）组织。

## 2. 包含头文件（44-70行）

- 标准 C 库：`errno.h`, `locale.h`, `signal.h`, `stdio.h`, `stdlib.h`, `string.h`, `unistd.h`, `sys/wait.h`
- X11 相关：`Xlib.h`, `Xutil.h`, `Xatom.h`, `cursorfont.h`, `keysym.h`, `Xproto.h`
- Xinerama（多显示器支持）：条件包含
- Xft 字体渲染
- 自定义头文件：`drw.h`（绘图）, `util.h`（工具函数）

## 3. 宏定义（72-93行）

| 宏 | 含义 |
|----|------|
| `BUTTONMASK` | 鼠标按下+释放 |
| `CLEANMASK(mask)` | 去除 numlock 和 CapsLock 修饰符 |
| `INTERSECT` | 计算两个矩形交集面积 |
| `ISVISIBLE(C)` | 客户端是否在当前可见标签上 |
| `MOUSEMASK` | 鼠标事件 + 指针移动 |
| `WIDTH/HEIGHT` | 实际窗口宽高（含边框+gappx） |
| `TAGMASK` | 标签掩码（最大31个标签） |
| `TEXTW(X)` | 文本宽度 + 左右内边距 |
| `SYSTEM_TRAY_REQUEST_DOCK` | 系统托盘请求码 |
| `XEMBED_*` | XEMBED 协议常量 |

## 4. 枚举类型（94-112行）

- `CurNormal, CurResize, CurMove`：光标形状
- `SchemeNorm, SchemeSel`：颜色方案
- `Net*`：EWMH 原子索引
- `Xembed*`：XEMBED 原子
- `WM*`：传统 WM 协议原子
- `Clk*`：点击区域（标签栏、布局符号、状态文本等）

## 5. 联合体 `Arg`（113-118行）

用于向函数传递不同类型的参数（整数、无符号整数、浮点、指针）。

## 6. 结构体定义

### `Button`（120-126行）
- 鼠标按键绑定：点击区域、修饰键、按键号、回调函数、参数。

### `Client`（127-144行）
- 窗口客户端的完整信息：窗口名、浮动比例、几何参数、标签位、各种标志（固定、浮动、紧急、全屏）、链表指针、所属 monitor、X Window ID。

### `Key`（146-150行）
- 键盘绑定：修饰键、键符号、回调函数、参数。

### `Layout`（152-154行）
- 布局：符号（如 `[]=`）、布局函数指针（tile/monocle 等）。

### `Monitor`（156-178行）
- 显示器/工作区结构：布局符号、mfact（主区比例）、nmaster（主区窗口数）、编号、bar 几何、窗口区域、标签集、当前布局索引、显示栏标志、栏位置、客户端链表、选中客户端、栈、下一个 monitor、bar 窗口、两个布局指针。

### `Rule`（180-187行）
- 窗口规则：匹配类、实例、标题，设置标签、是否浮动、所在 monitor。

### `Systray`（189-191行）
- 系统托盘：窗口 ID、图标客户端链表。

## 7. 全局变量（192-219行）

- `systray`：系统托盘结构指针
- `stext`：状态栏文本
- `screen`, `sw`, `sh`：屏幕编号、宽高
- `bh`：栏高度
- `lrpad`：文本左右填充总和
- `numlockmask`：NumLock 掩码
- `handler[LASTEvent]`：事件处理函数指针数组
- 各种 `Atom` 数组：`wmatom`, `netatom`, `xatom`
- `running`：主循环标志
- `cursor[CurLast]`：光标对象
- `scheme`：颜色方案
- `dpy`, `drw`：X 显示和绘图上下文
- `mons`, `selmon`：monitor 链表和当前选中
- `root`, `wmcheckwin`：根窗口和 EWMH 检查窗口

## 8. 函数声明（220-281行）

声明了所有静态函数，包括事件处理、客户端管理、布局、绘图、系统托盘等。其中 `OH016` 注释掉了多显示器切换相关函数（`dirtomon`, `focusmon`, `tagmon`）。

## 9. 函数实现

### `applyrules(Client *c)`（283-322行）
- 获取窗口的类、实例名
- 遍历 `rules[]` 匹配规则，设置 `isfloating` 和 `tags`
- 如果规则指定 monitor，切换到对应 monitor
- 最后确保 `tags` 非空，否则使用当前 monitor 的选中标签

### `applysizehints(Client *c, int *x, ...)`（324-388行）
- 应用窗口大小提示（ICCCM 4.1.2.3）
- 处理最小/最大尺寸、增量、宽高比
- 返回是否需要调整几何

### `arrange(Monitor *m)` 和 `arrangemon(Monitor *m)`（390-408行）
- `arrange`: 对所有 monitor 或指定 monitor 调用 `showhide` 隐藏非可见窗口，然后调用 `arrangemon`
- `arrangemon`: 更新 monitor 的布局符号，调用布局函数

### `attach(Client *c)` / `detach(Client *c)`（410-416, 565-571）
- 将客户端加入 monitor 的 `clients` 链表头 / 移除

### `attachstack(Client *c)` / `detachstack(Client *c)`（418-422, 573-588）
- 操作栈链表（焦点顺序），用于 `focus` 和 `zoom`

### `buttonpress(XEvent *e)`（424-476行）
- 处理鼠标点击
- 根据点击窗口识别点击区域（标签栏、布局符号、状态文本、窗口标题、客户端区域）
- 找到对应的 `Button` 绑定并执行函数

### `checkotherwm(void)`（478-486行）
- 尝试选择 `SubstructureRedirectMask`，若失败说明已有 WM 运行
- 设置临时错误处理器

### `cleanup(void)` 和 `cleanupmon(Monitor *mon)`（488-526行）
- 退出时清理：取消所有客户端管理，销毁栏窗口、光标、颜色、系统托盘，关闭显示

### `clientmessage(XEvent *e)`（528-588行）
- 处理 `ClientMessage` 事件
- 系统托盘图标添加请求（`SYSTEM_TRAY_REQUEST_DOCK`）
- 处理全屏状态切换（`NetWMState`）
- 处理激活窗口（`NetActiveWindow`）

### `configure(Client *c)`（590-604行）
- 发送 `ConfigureNotify` 事件，告知客户端其新几何

### `configurenotify(XEvent *e)`（606-628行）
- 根窗口大小改变时更新 `sw, sh`
- 调用 `updategeom()` 更新 monitor 布局
- 调整全屏客户端和栏窗口

### `configurerequest(XEvent *e)`（630-672行）
- 客户端请求改变大小/位置
- 若客户端是浮动或当前布局无布局函数，直接应用请求
- 否则仅更新内部坐标，不移动窗口（由布局管理）

### `createmon(void)`（674-686行）
- 创建并初始化一个新 `Monitor` 结构

### `destroynotify(XEvent *e)`（688-698行）
- 窗口销毁时，从客户端链表移除或从系统托盘移除

### `drawbar(Monitor *m)`（718-778行）
- 绘制状态栏
- 先计算状态文本宽度，留出系统托盘空间
- 绘制标签：只绘制有窗口或当前选中的标签（`hide_vacant_tags` 补丁）
- 绘制布局符号、窗口标题、浮动指示器
- 调用 `drw_map` 显示

### `drawbars(void)`（780-784行）
- 遍历所有 monitor 调用 `drawbar`

### `enternotify(XEvent *e)`（786-800行）
- 鼠标进入窗口时切换焦点和 monitor

### `expose(XEvent *e)`（802-810行）
- 栏窗口暴露事件时重绘

### `focus(Client *c)`（812-834行）
- 将焦点切换到客户端 `c`
- 更新栈顺序、边框颜色、输入焦点
- 处理紧急标志

### `focusin(XEvent *e)`（836-841行）
- 某些客户端获取焦点时，确保 dwm 重新设置焦点（避免焦点丢失）

### `focusstack(const Arg *arg)`（860-885行）
- 切换焦点到下一个/上一个可见客户端

### `getatomprop`（887-906行）
- 获取窗口的指定 Atom 属性

### `getsystraywidth()`（908-915行）
- 计算系统托盘总宽度（含间距）

### `getrootptr`（917-923行）
- 获取鼠标指针在根窗口上的坐标

### `getstate`（925-939行）
- 获取窗口的 `WM_STATE`

### `gettextprop`（941-964行）
- 获取窗口文本属性（支持 UTF-8 转换）

### `grabbuttons`（966-985行）
- 根据焦点状态为窗口抓取鼠标按键事件
- 用于点击窗口时切换焦点

### `grabkeys`（987-1007行）
- 抓取所有配置的键盘快捷键，支持 NumLock/CapsLock 修饰

### `incnmaster`（1009-1013行）
- 增加/减少主区域窗口数

### `keypress(XEvent *e)`（1030-1040行）
- 处理按键事件，查找匹配的 `keys[]` 并调用函数

### `killclient(const Arg *arg)`（1042-1056行）
- 发送 `WM_DELETE_WINDOW`，若失败则强制 `XKillClient`

### `manage(Window w, XWindowAttributes *wa)`（1058-1106行）
- 管理一个新窗口：创建 `Client`，应用规则，设置几何，处理瞬时窗口，映射窗口

### `mappingnotify`（1108-1114行）
- 键盘映射改变时重新抓取按键

### `maprequest(XEvent *e)`（1116-1128行）
- 映射请求：系统托盘图标激活或普通窗口调用 `manage`

### `monocle(Monitor *m)`（1130-1140行）
- 单窗口布局：所有窗口全屏显示，并在符号中显示窗口数量

### `motionnotify(XEvent *e)`（1142-1153行）
- 鼠标在根窗口移动时，根据指针位置切换 monitor（用于跟随鼠标焦点）

### `movemouse(const Arg *arg)`（1155-1206行）
- 鼠标拖动移动窗口
- 支持吸附边缘（snap）
- 若窗口非浮动则自动切换为浮动模式

### `nexttiled(Client *c)`（1208-1210行）
- 返回下一个非浮动的可见客户端

### `pop(Client *c)`（1212-1216行）
- 将客户端移动到链表头部并聚焦

### `propertynotify(XEvent *e)`（1218-1259行）
- 处理属性改变：标题、大小提示、WM_HINTS、窗口类型、瞬时窗口等
- 更新系统托盘图标几何

### `quit(const Arg *arg)`（1261-1263行）
- 设置 `running = 0` 退出主循环

### `recttomon`（1265-1275行）
- 根据矩形区域（窗口占据区域）找出最佳 monitor（重叠面积最大）

### `removesystrayicon`（1277-1288行）
- 从系统托盘链表中移除图标

### `resize`（1290-1294行）
- 调用 `applysizehints` 后调用 `resizeclient`

### `resizebarwin`（1296-1300行）
- 调整栏窗口大小和位置

### `resizeclient`（1302-1344行）
- 实际执行 `XConfigureWindow` 改变客户端几何
- 处理无用间隙（uselessgap）补丁：注释掉当只有一个窗口或 monocle 时去除间隙，使得始终有间隙

### `resizerequest`（1346-1355行）
- 处理系统托盘图标的 resize 请求

### `resizemouse`（1357-1406行）
- 鼠标拖动调整窗口大小

### `restack`（1408-1425行）
- 重新排列窗口堆叠顺序：浮动窗口在上，平铺窗口在栏下方

### `run`（1427-1433行）
- 主事件循环：获取 X 事件，调用对应 `handler`

### `scan`（1435-1458行）
- 扫描已存在的窗口（dwm 启动时）并管理它们（先普通窗口，后瞬时窗口）

### `sendmon`（1460-1472行）
- 将客户端移动到另一个 monitor

### `setclientstate`（1474-1478行）
- 设置 `WM_STATE` 属性

### `sendevent`（1480-1505行）
- 发送 ClientMessage 事件，检查协议支持

### `setfocus`（1507-1513行）
- 设置 X 输入焦点并更新 `_NET_ACTIVE_WINDOW`

### `setfullscreen`（1515-1542行）
- 切换全屏状态：保存原状态，去除边框，调整到 monitor 大小

### `setlayout`（1544-1554行）
- 切换布局（主/备）或设置指定布局

### `setmfact`（1556-1566行）
- 调整主区域比例因子 `mfact`

### `setup`（1568-1650行）
- 初始化：信号处理、屏幕尺寸、绘图上下文、字体、原子、光标、颜色方案、系统托盘、状态栏、EWMH 支持、选择事件、抓取按键

### `seturgent`（1652-1660行）
- 设置/清除窗口紧急提示

### `showhide`（1662-1678行）
- 递归显示/隐藏客户端：可见则移动到正确位置，不可见则移出屏幕

### `spawn`（1680-1696行）
- 启动外部程序（fork+exec）

### `tag`（1698-1705行）
- 设置当前窗口的标签

### `tile(Monitor *m)`（1720-1743行）
- 平铺布局算法：主区域（master）和堆叠区域（stack），使用 mfact 比例

### `togglebar`（1745-1759行）
- 切换状态栏显示/隐藏，调整系统托盘位置

### `togglefloating`（1761-1770行）
- 切换当前窗口浮动状态

### `toggletag`（1772-1782行）
- 切换当前窗口的标签（异或）

### `toggleview`（1784-1792行）
- 切换当前视图的标签（异或）

### `unfocus`（1794-1804行）
- 失去焦点：恢复边框颜色，移除键盘焦点

### `unmanage`（1806-1826行）
- 移除客户端：恢复边框，设置 WithdrawnState，释放内存

### `unmapnotify`（1828-1842行）
- 窗口取消映射：若为客户端则取消管理，若为系统托盘图标则重新映射（解决某些图标消失问题）

### `updatebars`（1844-1866行）
- 为每个 monitor 创建栏窗口

### `updatebarpos`（1868-1877行）
- 根据 `showbar` 和 `topbar` 更新 monitor 的窗口区域和栏位置

### `updateclientlist`（1879-1890行）
- 更新 `_NET_CLIENT_LIST` 属性

### `updategeom`（1892-1974行）
- 使用 Xinerama 获取显示器布局，创建/销毁 monitor 结构，更新几何

### `updatenumlockmask`（1976-1989行）
- 获取 NumLock 键的修饰掩码

### `updatesizehints`（1991-2025行）
- 读取并解析 `WM_NORMAL_HINTS`

### `updatestatus`（2027-2032行）
- 从根窗口 `_NET_WM_NAME` 或 `WM_NAME` 获取状态文本（通常由外部脚本写入）

### `updatesystrayicongeom`（2034-2055行）
- 调整系统托盘图标大小，使其适应栏高度

### `updatesystrayiconstate`（2057-2080行）
- 根据 `_XEMBED_INFO` 属性映射/取消映射图标

### `updatesystray`（2082-2154行）
- 初始化或更新系统托盘窗口：创建托盘窗口、设置 selection owner、布局所有图标

### `updatetitle`（2156-2164行）
- 获取窗口标题（优先 `_NET_WM_NAME`）

### `updatewindowtype`（2166-2174行）
- 根据 `_NET_WM_WINDOW_TYPE` 设置浮动（如对话框）

### `updatewmhints`（2176-2190行）
- 更新紧急提示和输入焦点提示

### `view`（2192-2201行）
- 切换视图到指定标签，同时切换到备选标签集

### `wintoclient`（2203-2214行）
- 根据窗口 ID 查找 `Client`

### `wintosystrayicon`（2216-2222行）
- 根据窗口 ID 查找系统托盘图标

### `wintomon`（2224-2236行）
- 根据窗口 ID 查找所属 monitor（支持根窗口坐标、栏窗口、客户端）

### `xerror` / `xerrordummy` / `xerrorstart`（2238-2270行）
- X 错误处理：忽略可恢复错误，否则调用原错误处理器

### `systraytomon`（2272-2284行）
- 决定系统托盘显示在哪个 monitor（支持 `systraypinning`）

### `zoom`（2286-2294行）
- 将当前窗口提升为主区域第一个（类似于 `pop`）

### `main`（2296-2309行）
- 初始化 locale，打开 X 显示，检查其他 WM，调用 `setup()`, `scan()`, `run()`, `cleanup()`，关闭显示

---

## 10. 用户自定义修改

代码中通过注释 `// OH016:` 标记了修改处：

- **去掉了多显示器快捷键**：`dirtomon`, `focusmon`, `tagmon` 等函数被注释掉。
- **无用间隙补丁**：在 `resizeclient` 中原本有判断当只有单个窗口或 monocle 时去掉间隙，被修改为始终保留间隙（注释掉那段 if）。
- **标签栏绘制**：在 `drawbar` 中增加了 `if (occ & 1 << i)` 判断，用于在有窗口的标签上绘制指示方块（原补丁 `hide_vacant_tags` 可能移除了方块，这里恢复）。

此外，`Monitor` 结构中的 `ltsymbol` 大小从 3 改为 4 以支持更长的符号。

