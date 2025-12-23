import { router } from '@kit.ArkUI';
import relationalStore from '@ohos.data.relationalStore';
import promptAction from '@ohos.promptAction';
import DBTools from '../utils/DBTools';
import Facility from '../model/Facility'; // 导入 Facility 模型
import Reservation from '../model/Reservation';
import FacilityRating from '../model/FacilityRating';
import Activity from '../model/Activity';

@Entry
@Component
export struct FacilityDetail {
  @State facility: Facility | null = null;
  @State startTime: Date = new Date();
  @State endTime: Date = new Date(new Date().getTime() + 60 * 60 * 1000); // 默认结束时间为当前时间后一小时
  @State myReservations: Array<Reservation> = [];
  @State ratings: Array<FacilityRating> = [];
  @State activities: Array<Activity> = [];

  // 页面加载时获取传递的参数
  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['facility']) {
      this.facility = params['facility'] as Facility;
      this.loadMyReservations();
      this.loadRatings();
      this.loadActivities();
    }
  }

  onPageShow() {
    if (this.facility) {
      this.loadMyReservations();
      this.loadRatings();
      this.loadActivities();
    }
  }

  loadMyReservations() {
    const userId = AppStorage.get<number>('currentUserId');
    if (userId && this.facility && this.facility.facility_id) {
      DBTools.queryReservationsByUserAndFacility(userId, this.facility.facility_id).then((data) => {
        this.myReservations = data;
      });
    }
  }

  loadRatings() {
    if (this.facility && this.facility.facility_id) {
      DBTools.queryRatingsByFacilityId(this.facility.facility_id).then((data) => {
        this.ratings = data;
      });
    }
  }

  loadActivities() {
    if (this.facility && this.facility.facility_id) {
      DBTools.queryActivitiesByFacilityId(this.facility.facility_id).then((data) => {
        this.activities = data;
      });
    }
  }

  handleJoinActivity(activity: Activity) {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) {
      this.showToast('请先登录');
      return;
    }
    
    DBTools.checkActivityParticipation(activity.activity_id, userId).then((isJoined) => {
      if (isJoined) {
        this.showToast('您已报名参加该活动');
        return;
      }
      
      DBTools.joinActivity(activity.activity_id, userId).then((rowId) => {
        if (rowId > 0) {
          this.showToast('报名成功');
        } else {
          this.showToast('报名失败');
        }
      });
    });
  }

  getReservationStatus(item: Reservation): string {
    if (item.status === 'cancelled') {
      return '已取消';
    }
    const startTime = item.start_time;
    const endTime = item.end_time;
    const now = new Date().getTime();
    if (now < startTime) {
      return '已预约';
    } else if (now >= startTime && now <= endTime) {
      return '进行中';
    } else {
      return '已完成';
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case '已预约': return '#FAAD14'; // Orange
      case '进行中': return '#1890FF'; // Blue
      case '已完成': return '#52C41A'; // Green
      case '已取消': return '#FF4D4F'; // Red
      default: return '#999999';
    }
  }

  handleReservation() {
    if (!this.facility || !this.facility.facility_id) return;

    // 修改：从 AppStorage 获取全局存储的用户ID
    const userId = AppStorage.get<number>('currentUserId'); 
    if (userId === undefined) {
      this.showToast('用户未登录，请先登录');
      return;
    }

    const startTime = this.startTime.getTime();
    const endTime = this.endTime.getTime();

    if (startTime >= endTime) {
      this.showToast('结束时间必须晚于开始时间');
      return;
    }
    // 检查冲突
    DBTools.checkReservationConflict(this.facility!.facility_id, startTime, endTime).then((isConflict: boolean) => {
      if (isConflict) {
        this.showToast('该时间段已被预约，请选择其他时间');
        return;
      }
      // 构建预约数据
      // 注意：SQLite/RdbStore 通常存储时间戳或字符串，这里存时间戳
      const reservation: relationalStore.ValuesBucket = {
        'user_id': userId,
        'facility_id': this.facility!.facility_id,
        'start_time': startTime, // 存时间戳
        'end_time': endTime,     // 存时间戳
        'status': 'pending'
      };
      DBTools.insertReservation(reservation).then((rowId: number) => {
        if (rowId > 0) {
          promptAction.showToast({
            message: '预约成功，预约ID: ' + rowId,
            duration: 3000
          });
          this.loadMyReservations(); // 刷新预约列表
          // router.back(); // 保持在当前页面，方便查看预约记录
        } else {
          this.showToast('预约失败');
        }
      }).catch((err: Error) => {
        this.showToast('预约出错: ' + err.message);
      });
    }).catch((err: Error) => {
      this.showToast('检查冲突出错: ' + err.message);
    });
  }

  showToast(message: string) {
    promptAction.showToast({ message: message });
  }

  // 格式化日期显示
  formatDate(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  // 选择日期和时间
  selectDateTime(isStart: boolean) {
    DatePickerDialog.show({
      start: new Date(),
      end: new Date("2030-12-31"),
      selected: isStart ? this.startTime : this.endTime,
      onAccept: (value: DatePickerResult) => {
        TimePickerDialog.show({
          selected: isStart ? this.startTime : this.endTime,
          useMilitaryTime: true,
          onAccept: (timeValue: TimePickerResult) => {
            const newDate = new Date(value.year!, value.month!, value.day!, timeValue.hour, timeValue.minute);
            if (isStart) {
              this.startTime = newDate;
            } else {
              this.endTime = newDate;
            }
          }
        })
      }
    })
  }

  build() {
    Column() {
      // 1. 顶部导航栏
      Row() {
        Text('🔙')
          .fontSize(20)
          .margin({ right: 5 })
          .onClick(() => {
            router.back();
          })
        Text('设施详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

      if (this.facility) {
        Column() {
          Scroll() {
            Column() {
              // 2. 设施信息展示
              Column() {
                Text(this.facility.facility_name || '未知设施')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })
                
                Row() {
                  Text(this.facility.facility_type)
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor('#1698CE')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(4)
                  
                  Row() {
                    Text('📍')
                      .fontSize(14)
                      .margin({ right: 4 })
                    Text(this.facility.location)
                      .fontSize(14)
                      .fontColor(Color.Gray)
                  }
                  .margin({ left: 10 })
                }
                .width('100%')
                .margin({ bottom: 15 })

                Text('📝 设施描述：')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 5 })
                Text(this.facility.description || '暂无描述')
                  .fontSize(14)
                  .fontColor('#666')
                  .lineHeight(20)
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
              .margin({ top: 15, bottom: 15 })
              .alignItems(HorizontalAlign.Start)

              // 新增：设施活动展示
              Column() {
                Row() {
                  Text('📅 热门活动')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Button('+ 发起活动')
                    .fontSize(12)
                    .height(28)
                    .backgroundColor('#1698CE')
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/ActivityCreate',
                        params: {
                          facility: this.facility
                        }
                      })
                    })
                }
                .width('100%')
                .margin({ bottom: 10 })
                
                if (this.activities.length === 0) {
                  Text('暂无活动，快来发起第一个活动吧！')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .margin({ top: 10, bottom: 10 })
                    .width('100%')
                    .textAlign(TextAlign.Center)
                } else {
                  List({ space: 10 }) {
                    ForEach(this.activities, (item: Activity) => {
                      ListItem() {
                        Column() {
                          Row() {
                            Text(item.title)
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)
                            Blank()
                            if (item.status === 'open') {
                                Button('报名')
                                .fontSize(12)
                                .height(24)
                                .backgroundColor('#52C41A')
                                .onClick(() => this.handleJoinActivity(item))
                            } else {
                                Text(item.status)
                                .fontSize(12)
                                .fontColor(Color.Gray)
                            }
                          }
                          .width('100%')
                          .margin({ bottom: 5 })

                          Text(`🕒 时间: ${item.start_time}`)
                            .fontSize(14)
                            .fontColor(Color.Gray)
                            .margin({ bottom: 5 })
                            
                          Text(item.description)
                            .fontSize(14)
                            .fontColor('#333')
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('100%')
                        .padding(10)
                        .backgroundColor('#F9F9F9')
                        .borderRadius(5)
                      }
                    })
                  }
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
              .margin({ bottom: 15 })

              // 新增：我的预约记录展示
              if (this.myReservations.length > 0) {
                Column() {
                  Text('📋 我的预约记录')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 10 })
                  
                  List({ space: 10 }) {
                    ForEach(this.myReservations, (item: Reservation) => {
                      ListItem() {
                        Row() {
                          Column() {
                            Text(`${this.formatDate(new Date(item.start_time))} - ${this.formatDate(new Date(item.end_time)).split(' ')[1]}`)
                              .fontSize(14)
                          }
                          Blank()
                          Text(this.getReservationStatus(item))
                            .fontSize(14)
                            .fontColor(this.getStatusColor(this.getReservationStatus(item)))
                        }
                        .width('100%')
                        .padding(10)
                        .backgroundColor('#F9F9F9')
                        .borderRadius(5)
                      }
                    })
                  }
                  .height(this.myReservations.length > 3 ? 150 : 'auto') // 限制高度，避免占用过多空间
                }
                .width('100%')
                .padding(20)
                .backgroundColor(Color.White)
                .borderRadius(10)
                .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
                .margin({ bottom: 15 })
              }

              // 新增：用户评价展示
              Column() {
                Text('💬 用户评价')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })

                if (this.ratings.length === 0) {
                  Text('暂无评价')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .margin({ top: 10, bottom: 10 })
                } else {
                  List({ space: 10 }) {
                    ForEach(this.ratings, (item: FacilityRating) => {
                      ListItem() {
                        Column() {
                          Row() {
                            Text(item.full_name || item.username || '匿名用户')
                              .fontSize(16)
                              .fontWeight(FontWeight.Bold)
                            Blank()
                            Text(item.score + '分')
                              .fontSize(14)
                              .fontColor('#FAAD14')
                          }
                          .width('100%')
                          .margin({ bottom: 5 })

                          Text(item.comment || '无评论内容')
                            .fontSize(14)
                            .fontColor('#333')
                            .width('100%')
                        }
                        .width('100%')
                        .padding(10)
                        .backgroundColor('#F9F9F9')
                        .borderRadius(5)
                      }
                    })
                  }
                  .height(this.ratings.length > 3 ? 200 : 'auto')
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
              .margin({ bottom: 15 })

              // 3. 预约时间选择
              Column() {
                Text('⏰ 预约时间')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })

                Row() {
                  Text('开始时间')
                    .width(80)
                  Text(this.formatDate(this.startTime))
                    .fontSize(16)
                    .fontColor('#1698CE')
                    .layoutWeight(1)
                    .textAlign(TextAlign.End)
                    .onClick(() => this.selectDateTime(true))
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 1 }, color: '#EEE' })

                Row() {
                  Text('结束时间')
                    .width(80)
                  Text(this.formatDate(this.endTime))
                    .fontSize(16)
                    .fontColor('#1698CE')
                    .layoutWeight(1)
                    .textAlign(TextAlign.End)
                    .onClick(() => this.selectDateTime(false))
                }
                .width('100%')
                .padding({ top: 10, bottom: 10 })
                .border({ width: { bottom: 1 }, color: '#EEE' })
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
            }
            .width('100%')
            .padding({ left: 15, right: 15 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .align(Alignment.Top)

          // 4. 底部按钮
          Button('立即预约')
            .width('90%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#1698CE')
            .shadow({ radius: 5, color: '#4F1698CE', offsetY: 3 })
            .margin({ top: 10, bottom: 20 })
            .onClick(() => {
              this.handleReservation();
            })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
      } else {
        // 加载中或无数据状态
        Column() {
          Text('正在加载设施信息...')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ top: 50 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}