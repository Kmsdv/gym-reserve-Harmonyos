import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import DBTools from '../utils/DBTools';
import Reservation from '../model/Reservation';

@CustomDialog
struct RatingDialog {
  controller: CustomDialogController
  facilityName: string = ''
  onConfirm: (score: number, comment: string) => void = () => {}
  @State score: number = 5
  @State comment: string = ''

  build() {
    Column() {
      Text(`评价: ${this.facilityName}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Row() {
        Text('评分: ' + this.score.toFixed(0))
          .fontSize(16)
          .margin({ right: 10 })
        Slider({
          value: this.score,
          min: 1,
          max: 5,
          step: 1,
          style: SliderStyle.OutSet
        })
        .onChange((value: number) => {
          this.score = value
        })
        .layoutWeight(1)
      }.width('100%').margin({ bottom: 20 })

      TextArea({ placeholder: '请输入您的评价...', text: this.comment })
        .height(100)
        .onChange((value) => {
          this.comment = value
        })
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .onClick(() => {
            this.controller.close()
          })
          .backgroundColor(Color.Gray)
          .margin({ right: 20 })
        
        Button('提交')
          .onClick(() => {
            this.onConfirm(this.score, this.comment)
            this.controller.close()
          })
      }
      .justifyContent(FlexAlign.Center)
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .width('90%')
  }
}

@Entry
@Component
struct MyReservations {
  @State reservations: Array<Reservation> = [];
  @State isLoading: boolean = true;
  
  dialogController: CustomDialogController | null = null;

  aboutToAppear() {
    this.loadReservations();
  }

  loadReservations() {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) {
      return;
    }

    DBTools.queryReservationsByUserId(userId).then((data) => {
      this.reservations = data;
      this.isLoading = false;
    }).catch((err: Error) => {
      console.error('Failed to load reservations:', err.message);
      this.isLoading = false;
    });
  }

  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  getDisplayStatus(item: Reservation): string {
    if (item.status === 'cancelled') {
      return '已取消';
    }
    const now = new Date().getTime();
    if (now < item.start_time) {
      return '已预约';
    } else if (now >= item.start_time && now <= item.end_time) {
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

  openRatingDialog(item: Reservation) {
    this.dialogController = new CustomDialogController({
      builder: RatingDialog({
        facilityName: item.facility_name || '设施',
        onConfirm: (score, comment) => {
          this.submitRating(item, score, comment)
        }
      }),
      autoCancel: true,
      customStyle: true // 使用自定义样式，避免默认边距问题
    })
    this.dialogController.open()
  }

  submitRating(item: Reservation, score: number, comment: string) {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) return;

    DBTools.insertOrUpdateRating(userId, item.facility_id, score, comment).then(() => {
      promptAction.showToast({ message: '评价提交成功' })
    }).catch((err: Error) => {
      promptAction.showToast({ message: '评价失败: ' + err.message })
    })
  }

  handleItemClick(item: Reservation) {
    const status = this.getDisplayStatus(item);
    
    if (status === '已取消') {
      return;
    }
    
    if (status === '已预约') {
      promptAction.showDialog({
        title: '取消预约',
        message: '确定要取消该预约吗？',
        buttons: [
          { text: '暂不取消', color: '#000000' },
          { text: '确认取消', color: '#FF0000' }
        ]
      }).then((result) => {
        if (result.index === 1) {
          DBTools.cancelReservation(item.reservation_id).then(() => {
            promptAction.showToast({ message: '预约已取消' });
            this.loadReservations();
          })
        }
      })
    } else if (status === '进行中') {
      promptAction.showDialog({
        title: '提前结束',
        message: '确定要提前结束使用吗？结束时间将更新为当前时间。',
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '确认结束', color: '#1890FF' }
        ]
      }).then((result) => {
        if (result.index === 1) {
          const now = new Date().getTime();
          DBTools.finishReservationEarly(item.reservation_id, now).then(() => {
            promptAction.showToast({ message: '已提前结束' });
            this.loadReservations();
          })
        }
      })
    } else if (status === '已完成') {
      this.openRatingDialog(item);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('<')
          .fontSize(24)
          .padding({ right: 16 })
          .onClick(() => {
            router.back();
          })
        Text('我的预约')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 50 })
      } else if (this.reservations.length === 0) {
        Column() {
          Text('暂无预约记录')
            .fontSize(16)
            .fontColor(Color.Gray)
            .margin({ top: 50 })
        }.width('100%')
      } else {
        List({ space: 10 }) {
          ForEach(this.reservations, (item: Reservation) => {
            ListItem() {
              Column() {
                Row() {
                  Text(item.facility_name || '未知设施')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Text(this.getDisplayStatus(item))
                    .fontColor(this.getStatusColor(this.getDisplayStatus(item)))
                    .fontSize(14)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Row() {
                  Text('开始时间：')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  Text(this.formatDate(item.start_time))
                    .fontSize(14)
                }
                .width('100%')
                .margin({ bottom: 4 })

                Row() {
                  Text('结束时间：')
                    .fontSize(14)
                    .fontColor(Color.Gray)
                  Text(this.formatDate(item.end_time))
                    .fontSize(14)
                }
                .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.handleItemClick(item);
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
