import { router } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import Activity from '../model/Activity';
import User from '../model/User';

@CustomDialog
struct ParticipantsDialog {
  controller: CustomDialogController
  activityId: number = 0
  @State participants: Array<User> = []
  @State isLoading: boolean = true

  aboutToAppear() {
    if (this.activityId) {
      DBTools.queryActivityParticipants(this.activityId).then(users => {
        this.participants = users;
        this.isLoading = false;
      })
    }
  }

  build() {
    Column() {
      Text('👥 参与人员名单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      if (this.isLoading) {
        LoadingProgress().width(40).height(40)
      } else if (this.participants.length === 0) {
        Text('暂无人员报名')
          .fontColor(Color.Gray)
          .margin({ top: 20, bottom: 20 })
      } else {
        List() {
          ForEach(this.participants, (user: User) => {
            ListItem() {
              Row() {
                Column() {
                  Text(user.full_name || user.username || '未知用户')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text(user.phone || '无联系方式')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
              .border({ width: { bottom: 1 }, color: '#F0F0F0' })
            }
          })
        }
        .height(300) // Limit height
        .width('100%')
      }

      Button('关闭')
        .onClick(() => {
          this.controller.close()
        })
        .backgroundColor('#1698CE')
        .width('100%')
        .margin({ top: 15 })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .width('90%')
  }
}

@Entry
@Component
struct MyActivities {
  @State currentFilter: number = 0; // 0: 我发起的, 1: 我参与的
  @State createdActivities: Array<Activity> = [];
  @State joinedActivities: Array<Activity> = [];
  @State isLoading: boolean = true;

  participantsDialogController: CustomDialogController | null = null;

  aboutToAppear() {
    this.loadData();
  }

  loadData() {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) return;

    this.isLoading = true;
    // Load both for simplicity, or load based on filter
    Promise.all([
      DBTools.queryActivitiesByOrganizer(userId),
      DBTools.queryJoinedActivities(userId)
    ]).then((results) => {
      const created = results[0];
      const joined = results[1];
      this.createdActivities = created;
      this.joinedActivities = joined;
      this.isLoading = false;
    }).catch((err: Error) => {
      console.error('Load activities failed:', err);
      this.isLoading = false;
    });
  }

  openParticipantsDialog(activityId: number) {
    this.participantsDialogController = new CustomDialogController({
      builder: ParticipantsDialog({
        activityId: activityId
      }),
      autoCancel: true,
      customStyle: true
    })
    this.participantsDialogController.open()
  }

  @Builder FilterButton(index: number, text: string) {
    Column() {
      Text(text)
        .fontSize(16)
        .fontWeight(this.currentFilter === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentFilter === index ? '#1698CE' : '#666')
        .padding({ bottom: 8 })
      
      if (this.currentFilter === index) {
        Divider()
          .strokeWidth(2)
          .color('#1698CE')
          .width(40)
      } else {
        Divider()
          .strokeWidth(2)
          .color(Color.Transparent)
          .width(40)
      }
    }
    .layoutWeight(1)
    .onClick(() => {
      this.currentFilter = index;
    })
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('🔙')
          .fontSize(20)
          .margin({ right: 5 })
          .onClick(() => {
            router.back();
          })
        Text('我的活动')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

      // Filter Tabs
      Row() {
        this.FilterButton(0, '我发起的')
        this.FilterButton(1, '我参与的')
      }
      .width('100%')
      .padding({ top: 15 })
      .backgroundColor(Color.White)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 50 })
      } else {
        List({ space: 10 }) {
          ForEach(this.currentFilter === 0 ? this.createdActivities : this.joinedActivities, (item: Activity) => {
            ListItem() {
              Column() {
                Row() {
                  Text(item.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Text(item.status === 'open' ? '报名中' : item.status)
                    .fontSize(12)
                    .fontColor(Color.White)
                    .backgroundColor(item.status === 'open' ? '#52C41A' : '#999')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(10)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row() {
                  Text('📍 ' + (item.facility_name || '未知地点'))
                    .fontSize(14)
                    .fontColor(Color.Gray)
                    .margin({ right: 15 })
                  
                  Text('🕒 ' + item.start_time)
                    .fontSize(14)
                    .fontColor(Color.Gray)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(item.description)
                  .fontSize(14)
                  .fontColor('#666')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .margin({ bottom: 10 })

                Row() {
                  Text(`👥 已报名: ${item.participant_count || 0}人`)
                    .fontSize(14)
                    .fontColor('#1698CE')
                  
                  Blank()

                  if (this.currentFilter === 0) {
                    Button('查看报名人员')
                      .fontSize(12)
                      .height(28)
                      .backgroundColor('#1698CE')
                      .onClick(() => {
                        this.openParticipantsDialog(item.activity_id)
                      })
                  } else {
                     Text(`发起人: ${item.organizer_name || '未知'}`)
                      .fontSize(14)
                      .fontColor(Color.Gray)
                  }
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding(15)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding(15)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}