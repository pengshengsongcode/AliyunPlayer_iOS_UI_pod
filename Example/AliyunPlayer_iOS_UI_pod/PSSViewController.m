//
//  ViewController1.m
//  CCPlayer
//
//  Created by 彭盛凇 on 2019/6/13.
//  Copyright © 2019 彭盛凇. All rights reserved.
//

#import "PSSViewController.h"
#import "AliyunVodPlayerView.h"
#import "AliyunReachability.h"
#import "MBProgressHUD+AlivcHelper.h"
#import <sys/utsname.h>

#import "AVCVideoConfig.h"

//#import "AVCVideoConfig.h"

#define ScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ScreenHeight  [UIScreen mainScreen].bounds.size.height
#define SizeWidth(W) (W *CGRectGetWidth([[UIScreen mainScreen] bounds])/320)
#define SizeHeight(H) (H *(ScreenHeight)/568)
#define RGBToColor(R,G,B)  [UIColor colorWithRed:(R * 1.0) / 255.0 green:(G * 1.0) / 255.0 blue:(B * 1.0) / 255.0 alpha:1.0]
#define rgba(R,G,B,A)  [UIColor colorWithRed:(R * 1.0) / 255.0 green:(G * 1.0) / 255.0 blue:(B * 1.0) / 255.0 alpha:A]
#define VIEWSAFEAREAINSETS(view) ({UIEdgeInsets i; if(@available(iOS 11.0, *)) {i = view.safeAreaInsets;} else {i = UIEdgeInsetsZero;} i;})


@interface PSSViewController ()<AliyunVodPlayerViewDelegate>

//播放器
@property (nonatomic,strong, nullable)AliyunVodPlayerView *playerView;

//网络监听
@property (nonatomic, strong) AliyunReachability *reachability;

/**
 是否在展示模态视图
 */
@property (nonatomic, assign) BOOL isPresent;

//进入前后台时，对界面旋转控制
@property (nonatomic, assign)BOOL isBecome;

//控制锁屏
@property (nonatomic, assign)BOOL isLock;

//是否隐藏navigationbar
@property (nonatomic,assign)BOOL isStatusHidden;

/**
 播放视频的配置
 */
@property (nonatomic, strong) AVCVideoConfig *config;

@end

@implementation PSSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
    [self.view addSubview:self.playerView];
    
    
    /**************************************/
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    //网络状态判定
    _reachability = [AliyunReachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged)
                                                 name:AliyunPVReachabilityChangedNotification
                                               object:nil];
    
    NSLog(@"%@",[self.playerView getSDKVersion]);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //        self.playerView.coverUrl = [NSURL URLWithString:@"https://fr-hd.huangbaoche.com/Db97xyP_Zg0?"];
        [self.playerView setTitle:@"啦啦啦啦啦啦啦啦啦阿里"];
        self.config.isLocal = false;
        //        if (listModel.videoUrl) {
        self.config.playMethod = AliyunPlayMedthodURL;
        self.config.videoUrl = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
        [self startPlayVideo];
        
    });
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (NSString*)iphoneType {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString*platform = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    return platform;
}

- (void)changeDownloadViewFrameWhenFullScreen:(BOOL)isFullScreen{
    //    if (!isFullScreen) {
    //        //竖屏
    //        CGFloat y = self.playerView.frame.size.height + 20 + self.exchangeContainView.frame.size.height;
    //        if (IPHONEX) {
    //            y += 16;
    //        }
    //        _downloadContainView.frame = CGRectMake(0, y, ScreenWidth, ScreenHeight - y);
    //        [self.downloadGestureView removeFromSuperview];
    //    }else{
    //        //全屏
    //        CGRect frame = self.downloadContainView.frame;
    //        frame.size.height = ScreenHeight;
    //        frame.origin.x = ScreenWidth - frame.size.width;
    //        frame.origin.y = 0;
    //        self.downloadContainView.frame = frame;
    //        //        self.downloadContainView.backgroundColor = [UIColor redColor];
    //        self.downloadGestureView.frame = CGRectMake(0, 0, ScreenWidth - frame.size.width, ScreenHeight);
    //    }
    //    _downloadTableView.frame = CGRectMake(0, 0, self.downloadContainView.frame.size.width, _downloadContainView.frame.size.height - 50);
    //    _downloadEditContainView.frame = CGRectMake(0, self.downloadTableView.frame.size.height, self.downloadContainView.frame.size.width, 50);
    //    //    [self configDownloadEditView:self.isEdit]; //防止iPhone 5s下
}


//适配iphone x 界面问题，没有在 viewSafeAreaInsetsDidChange 这里做处理 ，主要 旋转监听在 它之后获取。
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    NSString *platform =  [self iphoneType];
    CGFloat width = 0;
    CGFloat height = 0;
    CGFloat topHeight = 0;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ) {
        width = ScreenWidth;
        height = ScreenWidth * 9 / 16.0;
        topHeight = 20;
        [self changeDownloadViewFrameWhenFullScreen:false];
        [self refreshUIWhenScreenChanged:false];
    }else{
        width = ScreenWidth;
        height = ScreenHeight;
        topHeight = 0;
        [self changeDownloadViewFrameWhenFullScreen:true];
        [self refreshUIWhenScreenChanged:true];
    }
    CGRect tempFrame = CGRectMake(0,topHeight, width, height);
    //    UIDevice *device = [UIDevice currentDevice] ;
    //iphone x
    if (![platform isEqualToString:@"iPhone10,3"] && ![platform isEqualToString:@"iPhone10,6"]) {
        switch (orientation) {
            case UIInterfaceOrientationUnknown:
            case UIInterfaceOrientationPortraitUpsideDown:
            {
                
            }
                break;
            case UIInterfaceOrientationPortrait:
            {
                self.playerView.frame = tempFrame;
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
            {
                //                self.playerView.frame = CGRectMake(0,0,ScreenWidth,ScreenHeight);
                self.playerView.frame = tempFrame;
            }
                break;
                
            default:
                break;
        }
        //        [self.selectView layoutSubviews];
        
        return;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            if (self.isStatusHidden) {
                CGRect frame = self.playerView.frame;
                frame.origin.x = VIEWSAFEAREAINSETS(self.view).left;
                frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
                frame.size.width = ScreenWidth-VIEWSAFEAREAINSETS(self.view).left*2;
                frame.size.height = ScreenHeight-VIEWSAFEAREAINSETS(self.view).bottom-VIEWSAFEAREAINSETS(self.view).top;
                self.playerView.frame = frame;
            }else{
                CGRect frame = self.playerView.frame;
                frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
                //竖屏全屏时 isStatusHidden 来自是否 旋转回调。
                if (self.playerView.fixedPortrait&&self.isStatusHidden) {
                    frame.size.height = ScreenHeight- VIEWSAFEAREAINSETS(self.view).top- VIEWSAFEAREAINSETS(self.view).bottom;
                }
                self.playerView.frame = frame;
            }
        }
            break;
        case UIInterfaceOrientationPortrait:
        {
            width = ScreenWidth;
            height = ScreenWidth * 9 / 16.0;
            topHeight = 20;
            [self changeDownloadViewFrameWhenFullScreen:false];
            [self refreshUIWhenScreenChanged:false];
            
            CGRect frame = CGRectMake(0, topHeight, width, height);
            frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
            //竖屏全屏时 isStatusHidden 来自是否 旋转回调。
            if (self.playerView.fixedPortrait&&self.isStatusHidden) {
                frame.size.height = ScreenHeight- VIEWSAFEAREAINSETS(self.view).top- VIEWSAFEAREAINSETS(self.view).bottom;
            }
            self.playerView.frame = frame;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            CGRect frame = self.playerView.frame;
            frame.origin.x = VIEWSAFEAREAINSETS(self.view).left;
            frame.origin.y = VIEWSAFEAREAINSETS(self.view).top;
            frame.size.width = ScreenWidth-VIEWSAFEAREAINSETS(self.view).left*2;
            frame.size.height = ScreenHeight-VIEWSAFEAREAINSETS(self.view).bottom;
            self.playerView.frame = frame;
        }
            break;
            
        default:
            break;
    }
#else
    
#endif
    
}

/**
 开始播放视频
 */
- (void)startPlayVideo{
    if (self.config.isLocal) {
        [self.playerView reset];
        [self.playerView setTitle:self.config.videoTitle];
        [self.playerView playViewPrepareWithLocalURL:self.config.videoUrl];
    }else{
        [self.playerView stop];
        
        [self.playerView reset];//不显示最后一帧
        //播放器播放方式
        if (!self.config) {
            self.config = [[AVCVideoConfig alloc] init];
        }
        
        switch (self.config.playMethod) {
            case AliyunPlayMedthodURL:
            {
                [self.playerView playViewPrepareWithURL:self.config.videoUrl];
            }
                break;
            case AliyunPlayMedthodSTS:
            {
                [self.playerView playViewPrepareWithVid:self.config.videoId
                                            accessKeyId:self.config.stsAccessKeyId
                                        accessKeySecret:self.config.stsAccessSecret
                                          securityToken:self.config.stsSecurityToken];
            }
                break;
            default:
                break;
        }
    }
}



- (void)dealloc{
    
    NSLog(@"dealloc");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self destroyPlayVideo];
    //    //保存正在下载的视频信息
    //    for(AVCDownloadVideo *video in self.downloadingVideoArray){
    //        [[AlivcVideoDataBase shared]addVideo:video];
    //    }
}

- (void)destroyPlayVideo{
    if (_playerView != nil) {
        [_playerView stop];
        [_playerView releasePlayer];
        [_playerView removeFromSuperview];
        _playerView = nil;
    }
}

- (void)becomeActive{
    if (!self.isPresent) {
        self.isBecome = NO;
        NSLog(@"播放器状态:%ld",(long)self.playerView.playerViewState);
        if (self.playerView && self.playerView.playerViewState == AliyunVodPlayerStatePause){
            NSLog(@"");
            [self.playerView resume];
            
        }
    }
    
}


- (void)resignActive{
    if (self.isPresent) {
        self.isBecome = YES;
    }
    if (_playerView){
        [self.playerView pause];
    }
}

#pragma mark - 网络变化
//网络状态判定
- (void)reachabilityChanged{
    AliyunPVNetworkStatus status = [self.reachability currentReachabilityStatus];
    if (status != AliyunPVNetworkStatusNotReachable) {
    }
}


/**
 播放视图
 */
- (AliyunVodPlayerView *__nullable)playerView{
    if (!_playerView) {
        CGFloat width = 0;
        CGFloat height = 0;
        CGFloat topHeight = 0;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait ) {
            width = ScreenWidth;
            height = ScreenWidth * 9 / 16.0;
            topHeight = 20;
        }else{
            width = ScreenWidth;
            height = ScreenHeight;
            topHeight = 20;
        }
        /****************UI播放器集成内容**********************/
        _playerView = [[AliyunVodPlayerView alloc] initWithFrame:CGRectMake(0,topHeight, width, height) andSkin:AliyunVodPlayerViewSkinRed];
        //        _playerView.circlePlay = YES;
        [_playerView setDelegate:self];
        [_playerView setAutoPlay:YES];
        
        [_playerView setPrintLog:YES];
        
        _playerView.isScreenLocked = false;
        _playerView.fixedPortrait = false;
        self.isLock = self.playerView.isScreenLocked||self.playerView.fixedPortrait?YES:NO;
        
        //边下边播缓存沙箱位置
        NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [pathArray objectAtIndex:0];
        //maxsize:单位 mb    maxDuration:单位秒 ,在prepare之前调用。
        [_playerView setPlayingCache:NO saveDir:docDir maxSize:300 maxDuration:10000];
    }
    return _playerView;
}

//界面
/**
 * 功能：返回按钮事件
 * 参数：playerView ：AliyunVodPlayerView
 */
- (void)onBackViewClickWithAliyunVodPlayerView:(AliyunVodPlayerView*)playerView {
    
}


/**
 * 功能：下载按钮事件
 * 参数：playerView ：AliyunVodPlayerView
 */
- (void)onDownloadButtonClickWithAliyunVodPlayerView:(AliyunVodPlayerView*)playerView {
    
}

/**
 * 功能：所有事件发生的汇总
 * 参数：event ： 发生的事件
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView happen:(AliyunVodPlayerEvent )event {
    
}

/**
 * 功能：暂停事件
 * 参数：currentPlayTime ： 暂停时播放时间
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onPause:(NSTimeInterval)currentPlayTime {
    
}

/**
 * 功能：继续事件
 * 参数：currentPlayTime ： 继续播放时播放时间。
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onResume:(NSTimeInterval)currentPlayTime {
    
}

/**
 * 功能：播放完成事件 ，请区别stop（停止播放）
 * 参数：playerView ： AliyunVodPlayerView
 */
- (void)onFinishWithAliyunVodPlayerView:(AliyunVodPlayerView*)playerView {
    NSLog(@"onFinish");
    if (self.config.isLocal) {
        [self.playerView setUIStatusToReplay];
        return;
    }
    
    [self.playerView setUIStatusToReplay];
    
}

/**
 * 功能：停止播放
 * 参数：currentPlayTime ： 播放停止时播放时间。
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onStop:(NSTimeInterval)currentPlayTime {
    
}

/**
 * 功能：拖动进度条结束事件
 * 参数：seekDoneTime ： seekDone时播放时间。
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onSeekDone:(NSTimeInterval)seekDoneTime {
    
}

/**
 * 功能：是否锁屏
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView lockScreen:(BOOL)isLockScreen {
    self.isLock = isLockScreen;
}

/**
 * 功能：切换后的清晰度
 * 参数：quality ：切换后的清晰度
 playerView ： AliyunVodPlayerView
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onVideoQualityChanged:(AliyunVodPlayerVideoQuality)quality {
    
}

/**
 * 功能：切换后的清晰度，清晰度非枚举类型，字符串，适应于媒体转码播放
 * 参数：videoDefinition ： 媒体处理，切换清晰度后清晰度
 playerView ：AliyunVodPlayerView
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView*)playerView onVideoDefinitionChanged:(NSString*)videoDefinition {
    
}

/**
 * 功能：返回调用全屏
 * 参数：isFullScreen ： 点击全屏按钮后，返回当前是否全屏状态
 */
- (void)aliyunVodPlayerView:(AliyunVodPlayerView *)playerView fullScreen:(BOOL)isFullScreen {
    NSLog(@"isfullScreen --%d",isFullScreen);
    
    self.isStatusHidden = isFullScreen  ;
    [self refreshUIWhenScreenChanged:isFullScreen];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - 锁屏功能
/**
 * 说明：播放器父类是UIView。
 屏幕锁屏方案需要用户根据实际情况，进行开发工作；
 如果viewcontroller在navigationcontroller中，需要添加子类重写navigationgController中的 以下方法，根据实际情况做判定 。
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    
    //    return toInterfaceOrientation = UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationPortrait;
    
    if (self.isBecome) {
        return toInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
    }
    
    if (self.isLock) {
        return toInterfaceOrientation = UIInterfaceOrientationPortrait;
    }else{
        return YES;
    }
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate{
    return !self.isLock;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    if (self.isBecome) {
        return UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
    }
    
    if (self.isLock) {
        return UIInterfaceOrientationMaskPortrait;
    }else{
        return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
    }
}

-(BOOL)prefersStatusBarHidden
{
    return self.isStatusHidden;
    
}

/**
 刷新UI，全屏和非全屏切换的时候
 
 @param isFullScreen 是否全屏
 */
- (void)refreshUIWhenScreenChanged:(BOOL)isFullScreen{
    if (isFullScreen) {
        //        //        self.selectView.hidden = true;
        //        self.exchangeContainView.hidden = true;
        //        self.logView.hidden = true;
        //        if (!self.isLookingVideoWhenFullScreen) {
        //            self.downloadContainView.hidden = true;
        //        }
        //
        //        self.listView.hidden = YES;
    }else{
        //        self.isLookingVideoWhenFullScreen = false;
        //        //        self.selectView.hidden = false;
        //        self.exchangeContainView.hidden = false;
        //        self.downloadContainView.hidden = false;
        //        self.listView.hidden = NO;
        //        switch (self.logOrDownload) {
        //            case 0:
        //                [self listButtonTouched];
        //                break;
        //            case 1:
        //                [self logButtonTouched];
        //                break;
        //            case 2:
        //                [self offLineVideoButtonTouched];
        //                break;
        //
        //            default:
        //                break;
        //        }
        //
    }
}


/**
 * 功能：循环播放开始
 * 参数：playerView ：AliyunVodPlayerView
 */
- (void)onCircleStartWithVodPlayerView:(AliyunVodPlayerView *)playerView {
    
}

- (void)onClickedAirPlayButtonWithVodPlayerView:(AliyunVodPlayerView *)playerView{
    [MBProgressHUD showSucessMessage:@"功能正在开发中" inView:self.view];
}

- (void)onClickedBarrageBtnWithVodPlayerView:(AliyunVodPlayerView *)playerView{
    [MBProgressHUD showSucessMessage:@"功能正在开发中" inView:self.view];
}

@end

