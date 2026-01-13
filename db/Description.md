# 数据库说明

本文件夹包含项目的数据库文件。

## 数据库文件结构
SQLite (HarmonyOS ArkData relationalStore) 数据库通常由以下三个文件组成，需要同时存在才能完整读取：
- `demodb.db` (主数据文件)
- `demodb.db-shm` (共享内存文件)
- `demodb.db-wal` (预写日志文件)

## 查看方式
将文件夹中的这三个文件一起拖入 **Navicat Premium** (或其他支持 SQLite 的数据库工具) 中，即可查看数据库结构及数据。

## 获取最新数据库文件
如果需要从设备或模拟器中导出最新的数据库文件，请按照以下步骤操作 (使用 DevEco Studio):

1. **打开设备文件浏览器**:
   菜单栏点击 `View` -> `Tool Windows` -> `Device File Browser`

2. **定位文件路径**:
   在 Device File Browser 中依次展开:
   `data` > `app` > `el2` > `100` > `database` > `com.example.myapplication` > `entry` > `rdb` > `customDir` > `subCustomDir`

   > **注意**: `com.example.myapplication` 是当前项目的 Bundle Name。
   > 数据库保存路径配置位于 `entry/src/main/ets/entryability/EntryAbility.ets` 文件中。

3. **导出文件**:
   找到以下三个文件:
   - `demodb.db`
   - `demodb.db-shm`
   - `demodb.db-wal`

   选中它们，点击右键 -> `Save As...`，选择保存到本项目的 `db/` 目录下即可。
