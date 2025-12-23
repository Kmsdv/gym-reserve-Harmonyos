import { router } from '@kit.ArkUI';
import DBTools from '../utils/DBTools';
import Facility from '../model/Facility';
import User from '../model/User';
import Activity from '../model/Activity';

@Entry
@Component
struct Success {
  @State currentIndex: number = 0;
  @State facilities: Array<Facility> = [];
  @State currentUser: User | null = null;
  @State recommendations: Array<Facility> = [];
  @State recommendedActivities: Array<Activity> = [];
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
    // 加载活动推荐
    DBTools.queryActivities().then((data) => {
      this.recommendedActivities = data.slice(0, 5); // 推荐前5个活动
    }).catch((err: Error) => {
      console.error('Failed to load activity recommendations:', err.message);
    });

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

getFacilityImage(imageName: string | null): Resource {
  if (imageName === 'gym') {
    return $r('app.media.gym'); // 确保 media 目录下有 gym.png
  }
  if (imageName === 'soccer') {
    return $r('app.media.soccer'); // 确保 media 目录下有 soccer.png
  }
  if (imageName === 'pool') {
    return $r('app.media.pool'); // 确保 media 目录下有 pool.png
  }
  return $r('app.media.background'); // 默认图片
}

  @Builder TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Text(targetIndex === 0 ? '🔥' : (targetIndex === 1 ? '🏟️' : '👤'))
        .fontSize(24)
        .margin({ bottom: 4 })
      Text(title)
        .fontSize(10)
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
            List({ space: 15 }) {
              // 推荐设施标题
              ListItem() {
                Row() {
                  Text('✨')
                    .fontSize(24)
                    .margin({ right: 10 })
                  Text(this.recommendationTitle)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                }
                .margin({ top: 20, bottom: 5, left: 20 })
              }

              // 推荐设施列表
              ForEach(this.recommendations, (item: Facility) => {
                ListItem() {
                  Column() {
                    Stack({ alignContent: Alignment.TopEnd }) {
                      Image(this.getFacilityImage(item.image)) // 使用动态图片
                        .width('100%')
                        .height(150)
                        .borderRadius({ topLeft: 10, topRight: 10 })
                        .backgroundColor(Color.Gray)
                        .objectFit(ImageFit.Cover)
                      
                      Text(item.facility_type)
                        .fontSize(12)
                        .fontColor(Color.White)
                        .backgroundColor('#1698CE')
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .borderRadius({ topLeft: 0, topRight: 10, bottomLeft: 10, bottomRight: 0 })
                        .margin({ top: 0, right: 0 })
                    }
                    
                    Column() {
                      Row() {
                        Text(item.facility_name)
                          .fontSize(18)
                          .fontWeight(FontWeight.Bold)
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

              // 推荐活动标题
              if (this.recommendedActivities.length > 0) {
                ListItem() {
                  Row() {
                    Text('📅')
                      .fontSize(24)
                      .margin({ right: 10 })
                    Text('热门活动')
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                  }
                  .margin({ top: 20, bottom: 5, left: 20 })
                }

                // 推荐活动列表
                ForEach(this.recommendedActivities, (item: Activity) => {
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
                        Text('📍')
                          .fontSize(14)
                          .margin({ right: 5 })
                        Text((item.facility_name || '未知地点'))
                          .fontSize(14)
                          .fontColor(Color.Gray)
                      }
                      .width('100%')
                      .margin({ bottom: 5 })

                      Row() {
                        Text('🕒')
                          .fontSize(14)
                          .margin({ right: 5 })
                        Text(item.start_time)
                          .fontSize(14)
                          .fontColor(Color.Gray)
                      }
                      .width('100%')
                      .margin({ bottom: 5 })

                      Row() {
                        Text('👥')
                          .fontSize(14)
                          .margin({ right: 5 })
                        Text(`已报名: ${item.participant_count || 0}人`)
                          .fontSize(14)
                          .fontColor(Color.Gray)
                      }
                      .width('100%')
                      .margin({ bottom: 5 })

                      Text(item.description)
                        .fontSize(14)
                        .fontColor('#666')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                    }
                    .width('90%')
                    .margin({ left: '5%', right: '5%' })
                    .padding(15)
                    .backgroundColor(Color.White)
                    .borderRadius(10)
                    .shadow({ radius: 5, color: '#1F000000', offsetY: 2 })
                    .onClick(() => {
                      // 尝试跳转到对应设施详情
                      const facility = this.facilities.find(f => f.facility_id === item.facility_id);
                      if (facility) {
                        router.pushUrl({
                          url: 'pages/FacilityDetail',
                          params: {
                            facility: facility
                          }
                        })
                      }
                    })
                  }
                })
              }
              
              // 底部留白
              ListItem() {
                Row().height(20)
              }
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
            Row() {
              Text('🏟️')
                .fontSize(24)
                .margin({ right: 10 })
              Text('设施列表')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding({ left: 20, top: 20, bottom: 10 })

            List({ space: 10 }) {
              ForEach(this.facilities, (item: Facility) => {
                ListItem() {
                  Row() {
                    Image(this.getFacilityImage(item.image)) // 使用动态图片
                      .width(60)
                      .height(60)
                      .borderRadius(8)
                      .backgroundColor('#EEE')
                      .margin({ right: 15 })

                    Column() {
                      Text(item.facility_name)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                      
                      Row() {
                        Text('📍')
                          .fontSize(12)
                          .margin({ right: 4 })
                        Text(item.location)
                          .fontSize(14)
                          .fontColor(Color.Gray)
                      }
                      .margin({ top: 5 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Text(item.facility_type)
                      .fontSize(12)
                      .fontColor('#1698CE')
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
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
              Text('👤') // 头像占位
                .fontSize(40)
                .width(60)
                .height(60)
                .textAlign(TextAlign.Center)
                .backgroundColor('#EEE')
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
                  Text('📅')
                    .fontSize(20)
                    .margin({ right: 10 })
                  Text('我的预约')
                    .fontSize(16)
                  Blank()
                  Text('>')
                    .fontColor(Color.Gray)
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
                  Text('🏃')
                    .fontSize(20)
                    .margin({ right: 10 })
                  Text('我的活动')
                    .fontSize(16)
                  Blank()
                  Text('>')
                    .fontColor(Color.Gray)
                }
                .width('100%')
                .padding(15)
                .backgroundColor(Color.White)
                .margin({ top: 1 })
                .onClick(() => {
                  router.pushUrl({ url: 'pages/MyActivities' });
                })
              }
              
              ListItem() {
                Row() {
                  Text('⭐')
                    .fontSize(20)
                    .margin({ right: 10 })
                  Text('评价记录')
                    .fontSize(16)
                  Blank()
                  Text('>')
                    .fontColor(Color.Gray)
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
                  Text('🚪')
                    .fontSize(20)
                    .margin({ right: 10 })
                  Text('退出登录')
                    .fontSize(16)
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
