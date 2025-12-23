import { router, promptAction } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Register {
  @State message: string = '用户注册';
  @State username: string = '';
  @State password: string = '';

  //构建UI
  build() {
    Column() {
      Text(this.message).fontSize(26).fontWeight(FontWeight.Bold).height(80)
      Row() {
        Text('用户名：').fontSize(20).fontColor(Color.Blue)
        TextInput({ text: this.username }).fontSize(20).width(200)
          .onChange((value) => { //赋新值
            this.username = value;
          })
      }.width('80%').height(60)

      Row() {
        Text('密').fontSize(20).fontColor(Color.Blue).margin({ right: 20 })
        Text('码：').fontSize(20).fontColor(Color.Blue)
        //密码框
        TextInput({ text: this.password }).fontSize(20).width(200).type(InputType.Password)
          .onChange((value) => { //赋新值
            this.password = value;
          })
      }.width('80%').height(60)

      ////去登录
      Row() {
        Text('去登录').margin({ right: 50 }).fontColor(Color.Brown)
          .onClick(() => { //回主页去登录
            router.pushUrl({ url: 'pages/Index' })
          })
      }.width('100%')
      .justifyContent(FlexAlign.End)

      ///////用户注册 ////////
      Row() {
        Button('注 册').onClick(() => {
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
            }).catch((err: BusinessError) => {
              console.log(err.message);
              promptAction.showToast({ message: '注册失败: ' + err.message })
            })
          } else {
            promptAction.showToast({ message: '用户名或密码不能为空' })
          }

        });
      }.width('100%').justifyContent(FlexAlign.Center)

    }
  }
}
