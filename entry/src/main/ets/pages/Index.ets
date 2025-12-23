import { router } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State message: string = '欢迎回来';
  @State username: string = 'bean';
  @State password: string = '1234';

  // 首先加载,在EntryAbility中oncreate之前
  aboutToAppear(): void {
    console.log('---------主页---------');
  }

  build() {
    Column() {
      // Logo区域
      Column() {
        Text('🏟️')
          .fontSize(80)
          .margin({ bottom: 20 })
        Text('GymLink')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text('Sports Venue Booking')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 5 })
      }
      .margin({ top: 80, bottom: 50 })

      // 输入框区域
      Column({ space: 20 }) {
        // 用户名输入框
        Row() {
          Text('👤')
            .fontSize(20)
            .margin({ right: 10 })
          TextInput({ placeholder: '请输入用户名', text: this.username })
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .onChange((value) => {
              this.username = value;
            })
        }
        .padding({ left: 15, right: 15 })
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(25)
        .shadow({ radius: 5, color: '#1F000000', offsetY: 2 })

        // 密码输入框
        Row() {
          Text('🔒')
            .fontSize(20)
            .margin({ right: 10 })
          TextInput({ placeholder: '请输入密码', text: this.password })
            .fontSize(16)
            .layoutWeight(1)
            .type(InputType.Password)
            .backgroundColor(Color.Transparent)
            .onChange((value) => {
              this.password = value;
            })
        }
        .padding({ left: 15, right: 15 })
        .height(50)
        .backgroundColor(Color.White)
        .borderRadius(25)
        .shadow({ radius: 5, color: '#1F000000', offsetY: 2 })
      }
      .width('85%')

      // 注册链接
      Row() {
        Text('还没有账号？')
          .fontColor('#666')
          .fontSize(14)
        Text('立即注册')
          .fontColor('#1698CE')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Register' })
          })
      }
      .width('85%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 15, bottom: 40 })

      // 登录按钮
      Button('登 录')
        .width('85%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1698CE')
        .shadow({ radius: 5, color: '#4F1698CE', offsetY: 3 })
        .onClick(() => {
          DBTools.queryByUser(this.username, this.password).then((data) => {
            if (data > 0) {
              AppStorage.setOrCreate('currentUserId', data);
              router.pushUrl({ url: 'pages/Success' })
            } else {
              AlertDialog.show({ message: '用户名或密码有误' })
            }
          }).catch((err: BusinessError) => {
            console.log(err.message);
          })
        });

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
