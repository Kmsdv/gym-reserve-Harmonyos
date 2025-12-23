import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import User from '../model/User';
import Facility from '../model/Facility';
import Reservation from '../model/Reservation';
import FacilityRating from '../model/FacilityRating';
import Activity from '../model/Activity';

/**
 * 数据库管理工具，从缓存中读出store/pstm,完成CURD
 */
export default class DBTools {
  //数据库对象
  private static rdbstore: relationalStore.RdbStore;

  //设置数据库对象
  static setStore(store: relationalStore.RdbStore) {
    DBTools.rdbstore = store;
  }

  //获取数据库对象
  static getStore(): relationalStore.RdbStore {
    return DBTools.rdbstore;
  }

  //执行sql用于建表等
  static executeSql(sql: string): Promise<void> { //返加异步对象
    return DBTools.getStore().executeSql(sql);
  }

  //1.添加记录
  static insert(tableName: string, data: relationalStore.ValuesBucket): Promise<number> { //返回id号
    return DBTools.getStore().insert(tableName, data);
  }

  //2.1查询数据：通过用户名与密码
  static queryByUser(username: string, password: string): Promise<number> {
    let pd = new relationalStore.RdbPredicates('users');
    pd.equalTo('username', username).and().equalTo('password_hash', password);
    return new Promise<number>((resolve, reject) => {
      let temp = -1;
      DBTools.getStore().query(pd).then((rs) => {
        if (rs.goToNextRow()) {
          temp = rs.getLong(rs.getColumnIndex('user_id'));
        }
        //解析正确的数据
        resolve(temp);
      }).catch((err: BusinessError) => {
        reject(err);
      });
    })
  }

  //2.2查询所有数据
  static queryAll(): Promise<Array<User>> {
    let pd = new relationalStore.RdbPredicates('users');
    return new Promise<Array<User>>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        let users = Array<User>();
        while (rs.goToNextRow()) {
          let user = new User(
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getString(rs.getColumnIndex('username')),
            rs.getString(rs.getColumnIndex('password_hash')),
            rs.getString(rs.getColumnIndex('full_name')),
            rs.getString(rs.getColumnIndex('phone')),
            rs.getString(rs.getColumnIndex('email')),
            rs.getString(rs.getColumnIndex('created_at'))
          )
          users.push(user);
        }
        //解析正确的数据
        resolve(users);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  //3.删除记录:通过id
  static deleteById(id: number) { //:Promise<number>
    let pd = new relationalStore.RdbPredicates('users');
    pd.equalTo('user_id', id);
    //传入删除条件
    return DBTools.getStore().delete(pd);
  }

  //4.更新数据:通过id
  static updateById(id: number, data: relationalStore.ValuesBucket) {
    let pd = new relationalStore.RdbPredicates('users');
    pd.equalTo('user_id', id);
    ////传入数据、条件
    return DBTools.getStore().update(data, pd);
  }

  // 5. 查询所有设施
  static queryFacilities(): Promise<Array<Facility>> {
    let pd = new relationalStore.RdbPredicates('facilities');
    return new Promise<Array<Facility>>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        let facilities = Array<Facility>();
        while (rs.goToNextRow()) {
          let facility = new Facility(
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getString(rs.getColumnIndex('facility_name')),
            rs.getString(rs.getColumnIndex('facility_type')),
            rs.getString(rs.getColumnIndex('description')),
            rs.getString(rs.getColumnIndex('location')),
            rs.getLong(rs.getColumnIndex('capacity')),
            rs.getString(rs.getColumnIndex('created_at'))
          )
          facilities.push(facility);
        }
        resolve(facilities);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 6. 查询设施评分
  static queryAverageRating(facilityId: number): Promise<number> {
    let pd = new relationalStore.RdbPredicates('ratings');
    pd.equalTo('facility_id', facilityId);
    return new Promise<number>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        let totalScore = 0;
        let count = 0;
        while (rs.goToNextRow()) {
          totalScore += rs.getLong(rs.getColumnIndex('score'));
          count++;
        }
        rs.close();
        resolve(count > 0 ? totalScore / count : 0);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 7. 添加预约
  static insertReservation(data: relationalStore.ValuesBucket): Promise<number> {
    return DBTools.getStore().insert('reservations', data);
  }

  // 8. 检查预约冲突
  static checkReservationConflict(facilityId: number, startTime: number, endTime: number): Promise<boolean> {
    let pd = new relationalStore.RdbPredicates('reservations');
    // 冲突条件：同一设施，且 (新开始时间 < 旧结束时间) 且 (新结束时间 > 旧开始时间)
    // 状态不为 'cancelled'
    pd.equalTo('facility_id', facilityId)
      .and()
      .notEqualTo('status', 'cancelled')
      .and()
      .lessThan('start_time', endTime)
      .and()
      .greaterThan('end_time', startTime);

    return new Promise<boolean>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        let count = rs.rowCount;
        rs.close();
        resolve(count > 0); // 如果数量大于0，说明有冲突
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 9. 查询用户预约记录（包含设施名称）
  static queryReservationsByUserId(userId: number): Promise<Array<Reservation>> {
    const sql = `
      SELECT r.*, f.facility_name 
      FROM reservations r 
      LEFT JOIN facilities f ON r.facility_id = f.facility_id 
      WHERE r.user_id = ? 
      ORDER BY r.start_time DESC
    `;
    
    return new Promise<Array<Reservation>>((resolve, reject) => {
      DBTools.getStore().querySql(sql, [userId]).then((rs) => {
        let reservations = Array<Reservation>();
        while (rs.goToNextRow()) {
          let reservation = new Reservation(
            rs.getLong(rs.getColumnIndex('reservation_id')),
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('start_time')),
            rs.getLong(rs.getColumnIndex('end_time')),
            rs.getString(rs.getColumnIndex('status')),
            rs.getString(rs.getColumnIndex('created_at')),
            rs.getString(rs.getColumnIndex('facility_name')) // 关联查询出的字段
          )
          reservations.push(reservation);
        }
        rs.close();
        resolve(reservations);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 10. 根据ID查询用户
  static queryUserById(userId: number): Promise<User | null> {
    let pd = new relationalStore.RdbPredicates('users');
    pd.equalTo('user_id', userId);
    return new Promise<User | null>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        if (rs.goToNextRow()) {
          let user = new User(
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getString(rs.getColumnIndex('username')),
            rs.getString(rs.getColumnIndex('password_hash')),
            rs.getString(rs.getColumnIndex('full_name')),
            rs.getString(rs.getColumnIndex('phone')),
            rs.getString(rs.getColumnIndex('email')),
            rs.getString(rs.getColumnIndex('created_at'))
          )
          rs.close();
          resolve(user);
        } else {
          rs.close();
          resolve(null);
        }
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 11. 查询用户对特定设施的预约
  static queryReservationsByUserAndFacility(userId: number, facilityId: number): Promise<Array<Reservation>> {
    const sql = `
      SELECT * FROM reservations 
      WHERE user_id = ? AND facility_id = ? 
      ORDER BY start_time DESC
    `;
    
    return new Promise<Array<Reservation>>((resolve, reject) => {
      DBTools.getStore().querySql(sql, [userId, facilityId]).then((rs) => {
        let reservations = Array<Reservation>();
        while (rs.goToNextRow()) {
          let reservation = new Reservation(
            rs.getLong(rs.getColumnIndex('reservation_id')),
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('start_time')),
            rs.getLong(rs.getColumnIndex('end_time')),
            rs.getString(rs.getColumnIndex('status')),
            rs.getString(rs.getColumnIndex('created_at'))
          )
          reservations.push(reservation);
        }
        rs.close();
        resolve(reservations);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 12. 取消预约
  static cancelReservation(reservationId: number): Promise<number> {
    let pd = new relationalStore.RdbPredicates('reservations');
    pd.equalTo('reservation_id', reservationId);
    let data: relationalStore.ValuesBucket = {
      'status': 'cancelled'
    };
    return DBTools.getStore().update(data, pd);
  }

  // 13. 提前结束预约
  static finishReservationEarly(reservationId: number, endTime: number): Promise<number> {
    let pd = new relationalStore.RdbPredicates('reservations');
    pd.equalTo('reservation_id', reservationId);
    let data: relationalStore.ValuesBucket = {
      'end_time': endTime,
      // 可选：同时更新状态为 completed，虽然显示逻辑主要依赖时间，但保持数据语义一致更好
      // 'status': 'completed' 
    };
    return DBTools.getStore().update(data, pd);
  }

  // 14. 添加或更新评分
  static insertOrUpdateRating(userId: number, facilityId: number, score: number, comment: string): Promise<number> {
    // 先检查是否已存在
    let pd = new relationalStore.RdbPredicates('ratings');
    pd.equalTo('user_id', userId).and().equalTo('facility_id', facilityId);
    
    return new Promise<number>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        const data: relationalStore.ValuesBucket = {
          'user_id': userId,
          'facility_id': facilityId,
          'score': score,
          'comment': comment
        };

        if (rs.rowCount > 0) {
          // 更新
          rs.close();
          DBTools.getStore().update(data, pd).then((rows) => resolve(rows)).catch((err: BusinessError) => reject(err));
        } else {
          // 插入
          rs.close();
          DBTools.getStore().insert('ratings', data).then((rowId) => resolve(rowId)).catch((err: BusinessError) => reject(err));
        }
      }).catch((err: BusinessError) => {
        reject(err);
      })
    });
  }

  // 15. 查询设施的所有评价
  static queryRatingsByFacilityId(facilityId: number): Promise<Array<FacilityRating>> {
    const sql = `
      SELECT r.*, u.username, u.full_name 
      FROM ratings r 
      LEFT JOIN users u ON r.user_id = u.user_id 
      WHERE r.facility_id = ? 
      ORDER BY r.created_at DESC
    `;
    
    return new Promise<Array<FacilityRating>>((resolve, reject) => {
      DBTools.getStore().querySql(sql, [facilityId]).then((rs) => {
        let ratings = Array<FacilityRating>();
        while (rs.goToNextRow()) {
          let rating = new FacilityRating(
            rs.getLong(rs.getColumnIndex('rating_id')),
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('score')),
            rs.getString(rs.getColumnIndex('comment')),
            rs.getString(rs.getColumnIndex('created_at')),
            rs.getString(rs.getColumnIndex('username')),
            rs.getString(rs.getColumnIndex('full_name'))
          )
          ratings.push(rating);
        }
        rs.close();
        resolve(ratings);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 16. 查询用户的所有评价
  static queryRatingsByUserId(userId: number): Promise<Array<FacilityRating>> {
    const sql = `
      SELECT r.*, f.facility_name 
      FROM ratings r 
      LEFT JOIN facilities f ON r.facility_id = f.facility_id 
      WHERE r.user_id = ? 
      ORDER BY r.created_at DESC
    `;
    
    return new Promise<Array<FacilityRating>>((resolve, reject) => {
      DBTools.getStore().querySql(sql, [userId]).then((rs) => {
        let ratings = Array<FacilityRating>();
        while (rs.goToNextRow()) {
          let rating = new FacilityRating(
            rs.getLong(rs.getColumnIndex('rating_id')),
            rs.getLong(rs.getColumnIndex('user_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('score')),
            rs.getString(rs.getColumnIndex('comment')),
            rs.getString(rs.getColumnIndex('created_at')),
            undefined, // username
            undefined, // full_name
            rs.getString(rs.getColumnIndex('facility_name')) // facility_name
          )
          ratings.push(rating);
        }
        rs.close();
        resolve(ratings);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 17. 删除评价
  static deleteRating(ratingId: number): Promise<number> {
    let pd = new relationalStore.RdbPredicates('ratings');
    pd.equalTo('rating_id', ratingId);
    return DBTools.getStore().delete(pd);
  }

  // 18. 更新评价
  static updateRating(ratingId: number, score: number, comment: string): Promise<number> {
    let pd = new relationalStore.RdbPredicates('ratings');
    pd.equalTo('rating_id', ratingId);
    let data: relationalStore.ValuesBucket = {
      'score': score,
      'comment': comment
    };
    return DBTools.getStore().update(data, pd);
  }

  // 19. 创建活动
  static insertActivity(data: relationalStore.ValuesBucket): Promise<number> {
    return DBTools.getStore().insert('activities', data);
  }

  // 20. 查询所有活动 (with facility name and organizer name)
  static queryActivities(): Promise<Array<Activity>> {
    const sql = `
      SELECT a.*, f.facility_name, u.full_name as organizer_name,
      (SELECT COUNT(*) FROM activity_participants ap WHERE ap.activity_id = a.activity_id) as participant_count
      FROM activities a
      LEFT JOIN facilities f ON a.facility_id = f.facility_id
      LEFT JOIN users u ON a.organizer_id = u.user_id
      ORDER BY a.start_time ASC
    `;
    return new Promise<Array<Activity>>((resolve, reject) => {
      DBTools.getStore().querySql(sql).then((rs) => {
        let activities = Array<Activity>();
        while (rs.goToNextRow()) {
          let activity = new Activity(
            rs.getLong(rs.getColumnIndex('activity_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('organizer_id')),
            rs.getString(rs.getColumnIndex('title')),
            rs.getString(rs.getColumnIndex('description')),
            rs.getString(rs.getColumnIndex('start_time')),
            rs.getString(rs.getColumnIndex('end_time')),
            rs.getString(rs.getColumnIndex('status')),
            rs.getString(rs.getColumnIndex('created_at')),
            rs.getString(rs.getColumnIndex('facility_name')),
            rs.getString(rs.getColumnIndex('organizer_name')),
            rs.getLong(rs.getColumnIndex('participant_count'))
          )
          activities.push(activity);
        }
        rs.close();
        resolve(activities);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 21. 查询特定设施的活动
  static queryActivitiesByFacilityId(facilityId: number): Promise<Array<Activity>> {
     const sql = `
      SELECT a.*, f.facility_name, u.full_name as organizer_name,
      (SELECT COUNT(*) FROM activity_participants ap WHERE ap.activity_id = a.activity_id) as participant_count
      FROM activities a
      LEFT JOIN facilities f ON a.facility_id = f.facility_id
      LEFT JOIN users u ON a.organizer_id = u.user_id
      WHERE a.facility_id = ?
      ORDER BY a.start_time ASC
    `;
    return new Promise<Array<Activity>>((resolve, reject) => {
      DBTools.getStore().querySql(sql, [facilityId]).then((rs) => {
        let activities = Array<Activity>();
        while (rs.goToNextRow()) {
           let activity = new Activity(
            rs.getLong(rs.getColumnIndex('activity_id')),
            rs.getLong(rs.getColumnIndex('facility_id')),
            rs.getLong(rs.getColumnIndex('organizer_id')),
            rs.getString(rs.getColumnIndex('title')),
            rs.getString(rs.getColumnIndex('description')),
            rs.getString(rs.getColumnIndex('start_time')),
            rs.getString(rs.getColumnIndex('end_time')),
            rs.getString(rs.getColumnIndex('status')),
            rs.getString(rs.getColumnIndex('created_at')),
            rs.getString(rs.getColumnIndex('facility_name')),
            rs.getString(rs.getColumnIndex('organizer_name')),
            rs.getLong(rs.getColumnIndex('participant_count'))
          )
          activities.push(activity);
        }
        rs.close();
        resolve(activities);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }

  // 22. 加入活动
  static joinActivity(activityId: number, userId: number): Promise<number> {
    const data: relationalStore.ValuesBucket = {
      'activity_id': activityId,
      'user_id': userId
    };
    return DBTools.getStore().insert('activity_participants', data);
  }

  // 23. 检查是否已加入
  static checkActivityParticipation(activityId: number, userId: number): Promise<boolean> {
    let pd = new relationalStore.RdbPredicates('activity_participants');
    pd.equalTo('activity_id', activityId).and().equalTo('user_id', userId);
    return new Promise<boolean>((resolve, reject) => {
      DBTools.getStore().query(pd).then((rs) => {
        let count = rs.rowCount;
        rs.close();
        resolve(count > 0);
      }).catch((err: BusinessError) => {
        reject(err);
      })
    })
  }
}
