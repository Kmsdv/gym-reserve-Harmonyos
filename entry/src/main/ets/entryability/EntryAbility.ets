import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { relationalStore } from '@kit.ArkData';//导入数据库包
import DBTools from '../utils/DBTools';//导入自编数据库操作工具类

export default class EntryAbility extends UIAbility {
  static pstm: relationalStore.RdbStore | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    //数据库初始化配置信息 start__________________
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'demodb.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S3, // 数据库安全级别
      encrypt: false, // 可选参数，指定数据库是否加密，默认不加密
      customDir: 'customDir/subCustomDir', // 可选参数，数据库自定义路径。数据库将在如下的目录结构中被创建：context.databaseDir + '/rdb/' + customDir，其中context.databaseDir是应用沙箱对应的路径，'/rdb/'表示创建的是关系型数据库，customDir表示自定义的路径。当此参数不填时，默认在本应用沙箱目录下创建RdbStore实例。
      isReadOnly: false // 可选参数，指定数据库是否以只读方式打开。该参数默认为false，表示数据库可读可写。该参数为true时，只允许从数据库读取数据，不允许对数据库进行写操作，否则会返回错误码801。
    };
    // 判断数据库版本，如果不匹配则需进行升降级操作,假设当前数据库版本为3，表结构：EMPLOYEE (NAME, AGE, SALARY, CODES, IDENTITY)
    // 建表Sql语句, IDENTITY为bigint类型，sql中指定类型为UNLIMITED INT,可以在此处创建好所有表
    
    // 5.1 users表
    const SQL_CREATE_USERS = `
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        phone TEXT,
        email TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 5.2 facilities表
    const SQL_CREATE_FACILITIES = `
      CREATE TABLE IF NOT EXISTS facilities (
        facility_id INTEGER PRIMARY KEY AUTOINCREMENT,
        facility_name TEXT NOT NULL,
        facility_type TEXT,
        description TEXT,
        location TEXT,
        capacity INTEGER DEFAULT 1,
        image TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 5.3 ratings表（适配SQLite：CHECK约束+移除外键（可通过业务逻辑保证关联））
    const SQL_CREATE_RATINGS = `
      CREATE TABLE IF NOT EXISTS ratings (
        rating_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        facility_id INTEGER NOT NULL,
        score INTEGER CHECK(score BETWEEN 1 AND 5),
        comment TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, facility_id)
      )
    `;

    // 5.4 reservations表（适配SQLite：enum→TEXT，CHECK约束）
    const SQL_CREATE_RESERVATIONS = `
      CREATE TABLE IF NOT EXISTS reservations (
        reservation_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        facility_id INTEGER NOT NULL,
        start_time DATETIME NOT NULL,
        end_time DATETIME NOT NULL,
        status TEXT DEFAULT 'pending', -- SQLite无enum，用TEXT模拟（pending/confirmed/cancelled/completed）
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        CHECK(end_time > start_time)
      )
    `;

    // 5.5 usage_logs表（适配SQLite：enum→TEXT）
    const SQL_CREATE_USAGE_LOGS = `
      CREATE TABLE IF NOT EXISTS usage_logs (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        facility_id INTEGER NOT NULL,
        action TEXT NOT NULL, -- reserve/cancel/checkin/checkout
        action_time DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 5.6 activities表
    const SQL_CREATE_ACTIVITIES = `
      CREATE TABLE IF NOT EXISTS activities (
        activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
        facility_id INTEGER NOT NULL,
        organizer_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        start_time DATETIME NOT NULL,
        end_time DATETIME NOT NULL,
        status TEXT DEFAULT 'open', -- open/full/cancelled/completed
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 5.7 activity_participants表
    const SQL_CREATE_ACTIVITY_PARTICIPANTS = `
      CREATE TABLE IF NOT EXISTS activity_participants (
        participant_id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(activity_id, user_id)
      )
    `;

    relationalStore.getRdbStore(this.context, STORE_CONFIG, (err, store) => {
      if (err) {
        console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }
      
      // 创建所有表
      store.executeSql(SQL_CREATE_USERS);
      store.executeSql(SQL_CREATE_FACILITIES);
      // 尝试为旧数据库添加 image 字段 (如果字段已存在会报错，忽略即可)
      store.executeSql("ALTER TABLE facilities ADD COLUMN image TEXT").catch((err: Error) => {});

      // 强制更新现有数据的图片字段，确保旧数据也能显示图片
      store.executeSql("UPDATE facilities SET image = 'gym' WHERE facility_name = '综合体育馆'").catch((err: Error) => {});
      store.executeSql("UPDATE facilities SET image = 'soccer' WHERE facility_name = '露天足球场'").catch((err: Error) => {});
      store.executeSql("UPDATE facilities SET image = 'pool' WHERE facility_name = '游泳馆'").catch((err: Error) => {});

      store.executeSql(SQL_CREATE_RATINGS);
      store.executeSql(SQL_CREATE_RESERVATIONS);
      store.executeSql(SQL_CREATE_USAGE_LOGS);
      store.executeSql(SQL_CREATE_ACTIVITIES);
      store.executeSql(SQL_CREATE_ACTIVITY_PARTICIPANTS);

      //正常则建表
      DBTools.setStore(store);
      console.info('-------------建库建表成功------------');
      
      //初始化两条记录
      // 检查是否已经有数据，避免重复插入
      let pd = new relationalStore.RdbPredicates('users');
      store.query(pd, (err, resultSet) => {
        if (resultSet.rowCount === 0) {
          let user1: relationalStore.ValuesBucket = {
            'username': 'bean',
            'password_hash': '1234',
            'full_name': 'Mr. Bean',
            'phone': '13601234567',
            'email': 'bean@example.com'
          }
          let user2: relationalStore.ValuesBucket = {
            'username': 'tom',
            'password_hash': '1234',
            'full_name': 'Tom Cat',
            'phone': '13901234567',
            'email': 'tom@example.com'
          }
          let us: relationalStore.ValuesBucket[] = [user1, user2];
          store.batchInsert('users', us, (err, rowId) => {
            if (err) {
              return;
            }
            console.log("=======初始化记录:" + rowId)
          });
        }
        resultSet.close();
      })

      // 初始化设施数据
      let pdFacilities = new relationalStore.RdbPredicates('facilities');
      store.query(pdFacilities, (err, resultSet) => {
        if (resultSet.rowCount === 0) {
          let f1: relationalStore.ValuesBucket = {
            'facility_name': '综合体育馆',
            'facility_type': '室内',
            'description': '多功能室内体育馆，可进行篮球、羽毛球比赛',
            'location': 'A区 101',
            'capacity': 50,
            'image': 'gym'
          }
          let f2: relationalStore.ValuesBucket = {
            'facility_name': '露天足球场',
            'facility_type': '室外',
            'description': '标准11人制足球场，草皮良好',
            'location': 'B区 201',
            'capacity': 22,
            'image': 'soccer'
          }
          let f3: relationalStore.ValuesBucket = {
            'facility_name': '游泳馆',
            'facility_type': '室内',
            'description': '恒温泳池，50米标准赛道',
            'location': 'C区 301',
            'capacity': 30,
            'image': 'pool'
          }
          let facilities: relationalStore.ValuesBucket[] = [f1, f2, f3];
          store.batchInsert('facilities', facilities, (err, rowId) => {
            if (!err) {
              console.log("=======初始化设施记录成功:" + rowId);
            }
          });
        }
        resultSet.close();
      })
    });
    //数据库配置信息 end

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}