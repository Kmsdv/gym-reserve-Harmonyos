import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import relationalStore from '@ohos.data.relationalStore';
import DBTools from '../utils/DBTools';
import Facility from '../model/Facility';

@Entry
@Component
struct ActivityCreate {
  @State facility: Facility | null = null;
  @State title: string = '';
  @State description: string = '';
  @State startTime: Date = new Date();
  @State endTime: Date = new Date(new Date().getTime() + 2 * 60 * 60 * 1000);

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['facility']) {
      this.facility = params['facility'] as Facility;
    }
  }

  formatDate(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

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

  createActivity() {
    if (!this.title) {
      promptAction.showToast({ message: '请输入活动标题' });
      return;
    }
    if (!this.facility) {
      promptAction.showToast({ message: '设施信息缺失' });
      return;
    }
    
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    if (this.startTime >= this.endTime) {
      promptAction.showToast({ message: '结束时间必须晚于开始时间' });
      return;
    }

    const activityData: relationalStore.ValuesBucket = {
      'facility_id': this.facility.facility_id,
      'organizer_id': userId,
      'title': this.title,
      'description': this.description,
      'start_time': this.formatDate(this.startTime),
      'end_time': this.formatDate(this.endTime),
      'status': 'open',
      'created_at': new Date().toISOString()
    };

    DBTools.insertActivity(activityData).then((rowId) => {
      if (rowId > 0) {
        promptAction.showToast({ message: '活动创建成功' });
        router.back();
      } else {
        promptAction.showToast({ message: '创建失败' });
      }
    }).catch((err: Error) => {
      promptAction.showToast({ message: '创建出错: ' + err.message });
    });
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('🔙')
          .fontSize(20)
          .margin({ right: 5 })
          .onClick(() => router.back())
        Text('发起活动')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

      Scroll() {
        Column() {
          if (this.facility) {
            Row() {
              Text('🏟️')
                .fontSize(18)
                .margin({ right: 8 })
              Text('设施: ' + this.facility.facility_name)
                .fontSize(16)
                .fontColor(Color.Gray)
            }
            .margin({ bottom: 20, top: 20 })
            .width('100%')
          }

          Text('📝 活动标题')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 10 })
          
          TextInput({ placeholder: '请输入活动标题', text: this.title })
            .onChange((value) => this.title = value)
            .width('100%')
            .height(50)
            .margin({ bottom: 20 })
            .backgroundColor(Color.White)
            .borderRadius(10)
            .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

          Text('📄 活动描述')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 10 })

          TextArea({ placeholder: '请输入活动描述', text: this.description })
            .onChange((value) => this.description = value)
            .width('100%')
            .height(100)
            .margin({ bottom: 20 })
            .backgroundColor(Color.White)
            .borderRadius(10)
            .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

          Text('⏰ 时间安排')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ bottom: 10 })

          Row() {
            Text('开始时间')
            Blank()
            Text(this.formatDate(this.startTime))
              .fontColor('#1698CE')
              .onClick(() => this.selectDateTime(true))
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
          .margin({ bottom: 10 })

          Row() {
            Text('结束时间')
            Blank()
            Text(this.formatDate(this.endTime))
              .fontColor('#1698CE')
              .onClick(() => this.selectDateTime(false))
          }
          .width('100%')
          .padding(15)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
          .margin({ bottom: 30 })

          Button('✨ 创建活动')
            .width('100%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#1698CE')
            .shadow({ radius: 5, color: '#4F1698CE', offsetY: 3 })
            .onClick(() => this.createActivity())
        }
        .padding(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}