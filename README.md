# GymLink（HarmonyOS/ArkTS）

一个基于 HarmonyOS（ArkTS）的体育场馆预约与活动管理应用。提供场馆浏览、活动创建/报名、预约管理、评分评价、用户信息维护等核心能力，适合校园/社区场景的示例或起步项目。

## 功能特性
- 场馆与活动
  - 场馆列表与详情（支持资源展示、评分等）
  - 活动创建、报名与我的活动管理
- 预约与评分
  - 我的预约/我的评分视图，便于快速查看与维护
- 用户管理
  - 注册/登录流程（示例），个人信息编辑
- 数据与工具
  - 本地数据工具封装（`DBTools.ets`）
  - 可选 Mock 数据能力（`entry/mock/mock-config.json5`）
- 测试能力
  - 集成 Hypium 单元测试与 Hamock Mock（`ohosTest` 模块）

## 技术栈
- 框架与语言：HarmonyOS ArkTS
- 构建：Hvigor（`hvigorfile.ts`、`build-profile.json5`）
- 包管理：ohpm（`oh-package.json5` / `oh-package-lock.json5`）
- 测试：Hypium（`@ohos/hypium`）、Hamock（`@ohos/hamock`）

## 目录结构
```
.
├─ AppScope/
│  └─ app.json5                      # 应用级配置（bundleName、label 等）
├─ entry/
│  ├─ src/main/
│  │  ├─ module.json5                # 模块配置（moduleName、abilities 等）
│  │  ├─ ets/
│  │  │  ├─ entryability/EntryAbility.ets
│  │  │  ├─ entrybackupability/EntryBackupAbility.ets
│  │  │  ├─ model/                   # 数据模型（Activity/Facility/Reservation/User 等）
│  │  │  ├─ pages/                   # 页面（Index、FacilityDetail、MyReservations 等）
│  │  │  └─ utils/DBTools.ets
│  │  └─ resources/                  # 资源（element/media/profile 等）
│  ├─ ohosTest/                       # Hypium 测试模块
│  ├─ mock/mock-config.json5          # Mock 配置
│  └─ build/                          # 构建产物与中间件（.hap 输出等）
├─ hvigor/                            # Hvigor 全局配置
├─ oh_modules/                        # ohpm 依赖安装目录
├─ build-profile.json5                # 根构建配置
├─ hvigorfile.ts                      # 根构建脚本
└─ code-linter.json5                  # 代码规范/静态检查配置
```

## 环境准备
- DevEco Studio（推荐，包含 HarmonyOS SDK 与构建链）
- 真机或模拟器环境（HarmonyOS NEXT/支持 ArkTS 的版本）
- 可选：命令行构建所需的 Hvigor/ohpm（通常随 DevEco 安装）

> 说明：若使用 DevEco Studio，通常无需单独安装 Node 或手动配置 Hvigor，直接在 IDE 内构建与运行即可。

## 快速开始
### 方式一：使用 DevEco Studio（推荐）
1. 打开 DevEco Studio，选择“Open Project”，导入本项目根目录。
2. 在右上角选择目标设备（模拟器或真机）。
3. 直接点击运行（Run）或调试（Debug）按钮，DevEco 会自动安装依赖、构建并部署。

### 方式二：命令行（可选，视环境而定）
> 以下命令仅在已正确安装/配置 Hvigor 与 ohpm 的前提下可用。

安装依赖（根与 entry 模块按需执行）：
```bash
# 根目录（如存在依赖）
ohpm install

# entry 模块
cd entry
ohpm install
```

构建 HAP（默认 product 示例为 `default`）：
```bash
# 在 entry 目录
hvigorw assembleHap -p product=default
# 若没有 hvigorw，可尝试（取决于环境）
hvigor assembleHap -p product=default
```

构建产物：
- `entry/build/outputs/default/entry-default-unsigned.hap`

## 运行与调试
- DevEco Studio 中选择 `entry` 模块作为主模块运行。
- 若使用命令行构建，建议仍通过 IDE 进行部署与调试，以获得更好的日志与断点体验。

## 测试
- Hypium 测试位于：
  - `entry/ohosTest/ets/test/Ability.test.ets`
  - `entry/ohosTest/ets/test/List.test.ets`
- 在 DevEco Studio 中：将运行目标切换为 `ohosTest` 模块，使用“Run/Debug Tests”执行。

## 配置说明
- 应用配置：`AppScope/app.json5`
- 模块配置：`entry/src/main/module.json5`
- 构建配置：
  - 根：`build-profile.json5`、`hvigorfile.ts`
  - 模块：`entry/build-profile.json5`、`entry/hvigorfile.ts`
- 代码规范：`code-linter.json5`
- 混淆规则：`entry/obfuscation-rules.txt`
- Mock 数据：`entry/mock/mock-config.json5`（根据内部注释开关/调整）

## 主要页面与模型
- 页面（`entry/src/main/ets/pages/`）
  - `Index.ets`：应用首页/导航
  - `FacilityDetail.ets`：场馆详情
  - `ActivityCreate.ets`：创建活动
  - `MyReservations.ets`、`MyActivities.ets`、`MyRatings.ets`：我的预约/活动/评分
  - `Register.ets`、`UserInfoEdit.ets`、`Success.ets`：用户流程相关
- 模型（`entry/src/main/ets/model/`）
  - `Activity.ets`、`Facility.ets`、`FacilityRating.ets`、`Reservation.ets`、`User.ets`
- 工具（`entry/src/main/ets/utils/DBTools.ets`）

## 常见问题（FAQ）
- Q：命令行 `hvigorw`/`hvigor` 不可用？
  - A：优先使用 DevEco Studio 运行；命令行需确保 DevEco 构建工具链已正确安装并加入环境变量。
- Q：`.hap` 构建成功但无法安装？
  - A：确认目标设备系统版本与目标 API Level 匹配，必要时在 DevEco 里直接部署。

## 贡献
欢迎提交 Issue 与 Pull Request：
1. Fork 本仓库，创建特性分支
2. 提交变更并确保通过测试
3. 发起 Pull Request 并说明变更内容

## 许可证
本项目尚未声明许可证（All rights reserved）。如需开源分发，请添加适当的 `LICENSE` 文件并在此处声明。

## 致谢
- HarmonyOS/ArkTS 社区与相关工具链
- 测试框架：Hypium、Hamock
