import { router, promptAction } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Register {
  @State message: string = '创建账号';
  @State username: string = '';
  @State password: string = '';

  //构建UI
  build() {
    Column() {
      // Header
      Column() {
        Text('📝')
          .fontSize(60)
          .margin({ bottom: 10 })
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Text('Join us today!')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 5 })
      }
      .margin({ top: 60, bottom: 40 })

      // 输入框区域
      Column({ space: 20 }) {
        // 用户名
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

        // 密码
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

      // 去登录
      Row() {
        Text('已有账号？')
          .fontColor('#666')
          .fontSize(14)
        Text('直接登录')
          .fontColor('#1698CE')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Index' })
          })
      }
      .width('85%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 15, bottom: 40 })

      // 注册按钮
      Button('立即注册')
        .width('85%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .backgroundColor('#1698CE')
        .shadow({ radius: 5, color: '#4F1698CE', offsetY: 3 })
        .onClick(() => {
          let data: relationalStore.ValuesBucket = {
            'username': this.username,
            'password_hash': this.password,
            'phone': '13800000000', // 默认手机号，实际项目中应由用户输入
            'full_name': 'New User',
            'created_at': new Date().toISOString()
          }
          if (this.username != '' && this.password != '') {
            DBTools.insert('users', data).then((data) => {
              promptAction.showToast({ message: '用户注册成功' })
              setTimeout(() => {
                router.back();
              }, 1000);
            }).catch((err: BusinessError) => {
              console.log(err.message);
              promptAction.showToast({ message: '注册失败: ' + err.message })
            })
          } else {
            promptAction.showToast({ message: '用户名或密码不能为空' })
          }
        });

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
