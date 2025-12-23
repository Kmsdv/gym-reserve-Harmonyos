import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import DBTools from '../utils/DBTools';
import FacilityRating from '../model/FacilityRating';

@CustomDialog
struct EditRatingDialog {
  controller: CustomDialogController
  facilityName: string = ''
  @State score: number = 5
  @State comment: string = ''
  onConfirm: (score: number, comment: string) => void = () => {}

  build() {
    Column() {
      Text(`修改评价: ${this.facilityName}`)
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
        
        Button('保存')
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
struct MyRatings {
  @State ratings: Array<FacilityRating> = [];
  @State isLoading: boolean = true;
  
  dialogController: CustomDialogController | null = null;

  aboutToAppear() {
    this.loadRatings();
  }

  loadRatings() {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) {
      return;
    }

    DBTools.queryRatingsByUserId(userId).then((data) => {
      this.ratings = data;
      this.isLoading = false;
    }).catch((err: Error) => {
      console.error('Failed to load ratings:', err.message);
      this.isLoading = false;
    });
  }

  handleItemClick(item: FacilityRating) {
    promptAction.showActionMenu({
      title: '操作评价',
      buttons: [
        { text: '修改评价', color: '#1890FF' },
        { text: '删除评价', color: '#FF4D4F' }
      ]
    }).then((response) => {
      if (response.index === 0) {
        // 修改
        this.openEditDialog(item);
      } else if (response.index === 1) {
        // 删除
        this.confirmDelete(item);
      }
    })
  }

  openEditDialog(item: FacilityRating) {
    this.dialogController = new CustomDialogController({
      builder: EditRatingDialog({
        facilityName: item.facility_name || '设施',
        score: item.score,
        comment: item.comment,
        onConfirm: (score, comment) => {
          this.updateRating(item, score, comment)
        }
      }),
      autoCancel: true,
      customStyle: true
    })
    this.dialogController.open()
  }

  updateRating(item: FacilityRating, score: number, comment: string) {
    DBTools.updateRating(item.rating_id, score, comment).then(() => {
      promptAction.showToast({ message: '评价已更新' });
      this.loadRatings();
    }).catch((err: Error) => {
      promptAction.showToast({ message: '更新失败: ' + err.message });
    })
  }

  confirmDelete(item: FacilityRating) {
    promptAction.showDialog({
      title: '删除评价',
      message: '确定要删除这条评价吗？',
      buttons: [
        { text: '取消', color: '#000000' },
        { text: '确认删除', color: '#FF0000' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        DBTools.deleteRating(item.rating_id).then(() => {
          promptAction.showToast({ message: '评价已删除' });
          this.loadRatings();
        })
      }
    })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('🔙')
          .fontSize(20)
          .margin({ right: 5 })
          .onClick(() => {
            router.back();
          })
        Text('我的评价')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).margin({ top: 50 })
      } else if (this.ratings.length === 0) {
        Column() {
          Text('📭')
            .fontSize(50)
            .margin({ bottom: 10 })
          Text('暂无评价记录')
            .fontSize(16)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .margin({ top: 100 })
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.ratings, (item: FacilityRating) => {
            ListItem() {
              Column() {
                Row() {
                  Text('🏟️ ' + (item.facility_name || '未知设施'))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                  Blank()
                  Text(item.score + '分')
                    .fontColor('#FAAD14')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .margin({ bottom: 8 })

                Text(item.comment)
                  .fontSize(14)
                  .fontColor('#333')
                  .width('100%')
                  .margin({ bottom: 8 })

                Text(item.created_at)
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .width('100%')
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(10)
              .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
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
    .backgroundColor('#F5F7FA')
  }
}
