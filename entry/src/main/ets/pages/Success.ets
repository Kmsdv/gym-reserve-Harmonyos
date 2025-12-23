import { router } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import Facility from '../model/Facility';
import User from '../model/User';

@Entry
@Component
struct Success {
  @State currentIndex: number = 0;
  @State facilities: Array<Facility> = [];
  @State currentUser: User | null = null;
  @State recommendations: Array<Facility> = [];
  @State recommendationTitle: string = '今日推荐';

  private controller: TabsController = new TabsController();

  aboutToAppear() {
    // 加载设施数据
    this.loadFacilities();
    // 加载用户信息
    this.loadUserInfo();
    // 加载推荐
    this.loadRecommendations();
  }

  onPageShow() {
    this.loadUserInfo();
    this.loadRecommendations();
  }

  async loadRecommendations() {
    const userId = AppStorage.get<number>('currentUserId');
    if (!userId) {
      this.loadDefaultRecommendations();
      return;
    }

    try {
      // 1. 获取用户最近预约
      const reservations = await DBTools.queryReservationsByUserId(userId);
      
      if (reservations.length === 0) {
        this.recommendationTitle = '热门推荐';
        this.loadDefaultRecommendations();
        return;
      }

      const lastReservation = reservations[0];
      const lastFacilityId = lastReservation.facility_id;

      // 2. 获取所有设施
      const allFacilities = await DBTools.queryFacilities();
      
      // 3. 找到最近预约的设施类型
      const lastFacility = allFacilities.find(f => f.facility_id === lastFacilityId);
      
      if (!lastFacility) {
        this.loadDefaultRecommendations();
        return;
      }

      const targetType = lastFacility.facility_type;
      this.recommendationTitle = `猜你喜欢 (${targetType})`;

      // 4. 筛选同类型设施优先显示
      let recs = allFacilities.filter(f => f.facility_type === targetType);
      
      // 如果同类型不足3个，补全其他类型的设施
      if (recs.length < 3) {
        const others = allFacilities.filter(f => f.facility_type !== targetType);
        recs = recs.concat(others);
      }

      this.recommendations = recs;

    } catch (err) {
      console.error('Load recommendations failed', err);
      this.loadDefaultRecommendations();
    }
  }

  loadDefaultRecommendations() {
    this.recommendationTitle = '今日推荐';
    DBTools.queryFacilities().then((data) => {
      this.recommendations = data;
    }).catch((err: Error) => {
      console.error('Failed to load default recommendations:', err.message);
    });
  }

  loadUserInfo() {
    const userId = AppStorage.get<number>('currentUserId');
    if (userId) {
      DBTools.queryUserById(userId).then((user) => {
        this.currentUser = user;
      });
    }
  }

  loadFacilities() {
    DBTools.queryFacilities().then((data) => {
      this.facilities = data;
    }).catch((err: Error) => {
      console.error('Failed to load facilities:', err.message);
    });
  }

  @Builder TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .size({ width: 25, height: 25 })
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.controller.changeIndex(this.currentIndex);
    })
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        // 1. 推荐页面
        TabContent() {
          Column() {
            Text(this.recommendationTitle)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 20 })
            
            List({ space: 15 }) {
              ForEach(this.recommendations, (item: Facility) => {
                ListItem() {
                  Column() {
                    Image($r('app.media.background')) // 使用默认背景图
                      .width('100%')
                      .height(150)
                      .borderRadius({ topLeft: 10, topRight: 10 })
                      .backgroundColor(Color.Gray)
                      .objectFit(ImageFit.Cover)
                    
                    Column() {
                      Row() {
                        Text(item.facility_name)
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
                        Blank()
                        Text(item.facility_type)
                          .fontSize(12)
                          .fontColor(Color.White)
                          .backgroundColor('#1698CE')
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .borderRadius(10)
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                      .margin({ bottom: 8 })

                      Text(item.description)
                        .fontSize(14)
                        .fontColor(Color.Gray)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                    }
                    .padding(12)
                    .width('100%')
                    .backgroundColor(Color.White)
                    .borderRadius({ bottomLeft: 10, bottomRight: 10 })
                  }
                  .width('90%')
                  .margin({ left: '5%', right: '5%' }) // 居中
                  .shadow({ radius: 5, color: '#1F000000', offsetY: 2 })
                  .borderRadius(10)
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/FacilityDetail',
                      params: {
                        facility: item
                      }
                    })
                  })
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F1F3F5')
        }
        .tabBar(this.TabBuilder('推荐', 0, $r('app.media.startIcon'), $r('app.media.startIcon'))) // 使用默认图标占位

        // 2. 设施页面
        TabContent() {
          Column() {
            Text('设施列表')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 10 })

            List({ space: 10 }) {
              ForEach(this.facilities, (item: Facility) => {
                ListItem() {
                  Row() {
                    Column() {
                      Text(item.facility_name)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                      Text(item.location)
                        .fontSize(14)
                        .fontColor(Color.Gray)
                        .margin({ top: 5 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Text(item.facility_type)
                      .fontSize(14)
                      .fontColor(Color.Blue)
                      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                      .backgroundColor('#E6F7FF')
                      .borderRadius(15)
                  }
                  .width('90%')
                  .padding(15)
                  .backgroundColor(Color.White)
                  .borderRadius(10)
                  .shadow({ radius: 5, color: '#1F000000', offsetX: 2, offsetY: 2 })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/FacilityDetail',
                      params: {
                        facility: item
                      }
                    })
                  })
                }
                .width('100%')
              })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F1F3F5')
        }
        .tabBar(this.TabBuilder('设施', 1, $r('app.media.startIcon'), $r('app.media.startIcon')))

        // 3. 我的页面
        TabContent() {
          Column() {
            Row() {
              Image($r('app.media.startIcon'))
                .width(60)
                .height(60)
                .borderRadius(30)
                .margin({ right: 15 })
              Column() {
                Text(this.currentUser ? (this.currentUser.full_name || this.currentUser.username) : '未登录')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Text(this.currentUser ? `ID: ${this.currentUser.user_id}` : '')
                  .fontSize(14)
                  .fontColor(Color.Gray)
                  .margin({ top: 5 })
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
            .onClick(() => {
              if (this.currentUser) {
                router.pushUrl({ url: 'pages/UserInfoEdit' });
              }
            })

            List() {
              ListItem() {
                Row() {
                  Text('我的预约')
                  Blank()
                  Text('>')
                }
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/MyReservations' });
                })
              }
              
              ListItem() {
                Row() {
                  Text('评价记录')
                  Blank()
                  Text('>')
                }
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .margin({ top: 1 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/MyRatings' });
                })
              }

              ListItem() {
                Row() {
                  Text('退出登录')
                    .fontColor(Color.Red)
                }
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .justifyContent(FlexAlign.Center)
                .margin({ top: 20 })
                .onClick(() => {
                  router.back();
                })
              }
            }
            .width('100%')
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F1F3F5')
        }
        .tabBar(this.TabBuilder('我的', 2, $r('app.media.startIcon'), $r('app.media.startIcon')))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
  }
}
