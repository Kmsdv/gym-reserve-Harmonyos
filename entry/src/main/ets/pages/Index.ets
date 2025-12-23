import { router } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State message: string = '用户登录';
  @State username: string = 'bean';
  @State password: string = '1234';

  // 首先加载,在EntryAbility中oncreate之前
  aboutToAppear(): void {
    console.log('---------主页---------');
  }

  build() {
    Column() { //自动为Flex
      Text(this.message).fontSize(26).fontWeight(FontWeight.Bold)
      Row() {
        Text('用户名：').fontSize(20).fontColor(Color.Blue)
        TextInput({ text: this.username }).fontSize(20).width(200)
          .onChange((value)=>{//赋新值
            this.username=value;
          })
      }.width('80%').height(60)

      Row() {
        Text('密').fontSize(20).fontColor(Color.Blue).margin({ right: 20 })
        Text('码：').fontSize(20).fontColor(Color.Blue)
        //密码框
        TextInput({ text: this.password }).fontSize(20).width(200).type(InputType.Password)
          .onChange((value)=>{//赋新值
            this.password=value;
          })
      }.width('80%').height(60)

      Row() {
        Text('去注册').margin({ right: 50 }).fontColor(Color.Brown)
          .onClick(()=>{
            router.pushUrl({url:'pages/Register'})
          })
      }.width('100%')
      .justifyContent(FlexAlign.End)

      // 用户登录
      Row() {
        Button('登 录').onClick(() => {
          DBTools.queryByUser(this.username,this.password).then((data)=>{
            if(data>0){
              // 修改点：登录成功，将返回的用户ID (data) 存储到 AppStorage
              // 这样在 FacilityDetail.ets 中就可以通过 AppStorage.get('currentUserId') 获取了
              AppStorage.setOrCreate('currentUserId', data);

              //AlertDialog.show({message:'正常登录：'+data})
              router.pushUrl({url:'pages/Success'})
            }else{
              AlertDialog.show({message:'用户名或密码有误'})
            }
          }).catch((err:BusinessError)=>{
            console.log(err.message);
          })
        });
      }

    }.width('100%')
    .height('100%')
    .backgroundColor('#eee')
    .justifyContent(FlexAlign.Center)
  }
}
