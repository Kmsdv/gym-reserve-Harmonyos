import { router } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import relationalStore from '@ohos.data.relationalStore';
import DBTools from '../utils/DBTools';
import User from '../model/User';

@Entry
@Component
struct UserInfoEdit {
  @State user: User | null = null;
  @State username: string = '';
  @State fullName: string = '';
  @State phone: string = '';
  @State email: string = '';

  aboutToAppear() {
    this.loadUserInfo();
  }

  loadUserInfo() {
    const userId = AppStorage.get<number>('currentUserId');
    if (userId) {
      DBTools.queryUserById(userId).then((user) => {
        if (user) {
          this.user = user;
          this.username = user.username || '';
          this.fullName = user.full_name || '';
          this.phone = user.phone || '';
          this.email = user.email || '';
        }
      });
    }
  }

  saveUserInfo() {
    if (!this.user || !this.user.user_id) return;

    const updateData: relationalStore.ValuesBucket = {
      // 'username': this.username, // 用户名不可修改
      'full_name': this.fullName,
      'phone': this.phone,
      'email': this.email
    };

    DBTools.updateById(this.user.user_id, updateData).then((rows) => {
      if (rows > 0) {
        promptAction.showToast({ message: '保存成功' });
        // 稍微延迟后返回，让用户看到提示
        setTimeout(() => {
          router.back();
        }, 500);
      } else {
        promptAction.showToast({ message: '保存失败或未做修改' });
      }
    }).catch((err: Error) => {
      promptAction.showToast({ message: '保存出错: ' + err.message });
    });
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
        Text('编辑个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(15)
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })

      if (this.user) {
        Column() {
          // 表单区域
          Column({ space: 20 }) {
            
            // 用户名
            Column() {
              Text('👤 用户名')
                .fontSize(14)
                .fontColor(Color.Gray)
                .margin({ bottom: 8 })
              TextInput({ text: this.username, placeholder: '请输入用户名' })
                .height(45)
                .enabled(false) // 设置为不可编辑
                .backgroundColor('#F5F5F5') // 设置背景色表示只读
                .borderRadius(10)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 昵称
            Column() {
              Text('🏷️ 昵称')
                .fontSize(14)
                .fontColor(Color.Gray)
                .margin({ bottom: 8 })
              TextInput({ text: this.fullName, placeholder: '请输入昵称' })
                .height(45)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EEE' })
                .onChange((value) => {
                  this.fullName = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 电话号码
            Column() {
              Text('📱 电话号码')
                .fontSize(14)
                .fontColor(Color.Gray)
                .margin({ bottom: 8 })
              TextInput({ text: this.phone, placeholder: '请输入电话号码' })
                .height(45)
                .type(InputType.PhoneNumber)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EEE' })
                .onChange((value) => {
                  this.phone = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            // 邮箱
            Column() {
              Text('📧 电子邮箱')
                .fontSize(14)
                .fontColor(Color.Gray)
                .margin({ bottom: 8 })
              TextInput({ text: this.email, placeholder: '请输入电子邮箱' })
                .height(45)
                .type(InputType.Email)
                .borderRadius(10)
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EEE' })
                .onChange((value) => {
                  this.email = value;
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .shadow({ radius: 2, color: '#1F000000', offsetY: 1 })
          .margin({ top: 20 })

          // 保存按钮
          Button('💾 保存修改')
            .width('90%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#1698CE')
            .shadow({ radius: 5, color: '#4F1698CE', offsetY: 3 })
            .margin({ top: 40 })
            .onClick(() => {
              this.saveUserInfo();
            })

        }
        .width('100%')
        .padding({ left: 15, right: 15 })
      } else {
        LoadingProgress().width(50).height(50).margin({ top: 50 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
