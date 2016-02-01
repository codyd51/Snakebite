#import <objc/runtime.h>
#import "UIImage+SNBAdditions.h"
#import <AudioToolbox/AudioToolbox.h>

#define kTweakName @"Snakebite"
#ifdef DEBUG
    #define NSLog(FORMAT, ...) NSLog(@"[%@: %s - %i] %@", kTweakName, __FILE__, __LINE__, [NSString stringWithFormat:FORMAT, ##__VA_ARGS__])
#else
    #define NSLog(FORMAT, ...) do {} while(0)
#endif

@interface SBIcon : NSObject
@property (nonatomic, retain) NSString* applicationBundleID;
-(NSString*)displayNameForLocation:(NSInteger)location;
-(UIImage*)generateIconImage:(int)arg1;
@end
@interface UIApplication (Private)
@property (nonatomic, assign) BOOL statusBarHidden;
-(id)_accessibilityFrontMostApplication;
-(void)launchApplicationWithIdentifier:(NSString*)identifier suspended:(BOOL)suspended;
-(void)setStatusBarHidden:(BOOL)hidden duration:(CGFloat)duration;
@end
@interface SBIconModel : NSObject
-(id)expectedIconForDisplayIdentifier:(NSString*)ident;
@end
@interface SBIconController : UIViewController
+(instancetype)sharedInstance;
@property (nonatomic, retain) SBIconModel* model;
@end
@interface SBApplicationShortcutMenuBackgroundView : UIView
@end
@interface SBApplication : NSObject
@property (nonatomic, retain) NSString* bundleIdentifier;
@end
@interface FBSDisplay : NSObject
@end
@interface FBDisplayManager : NSObject
+(id)sharedInstance;
+(FBSDisplay*)mainDisplay;
@end
@interface FBRootWindow : UIWindow
@end
@interface FBSceneManager : NSObject
+(id)sharedInstance;
-(FBRootWindow*)_rootWindowForDisplay:(FBSDisplay*)display createIfNecessary:(BOOL)createIfNecessary;
@end
@interface SBAppContainerView : UIView
@end
@interface SBAppContainerViewController : UIViewController
@property (nonatomic, retain) SBAppContainerView* view;
@end
@interface SBMainDisplaySceneLayoutViewController : UIViewController
-(SBAppContainerViewController*)_layoutElementControllerForLayoutRole:(int)role;
-(CGRect)referenceFrameForIdentifier:(NSString*)identifier inLayoutState:(int)layoutState;
@end
@interface SBMainDisplaySceneManager : NSObject
-(SBMainDisplaySceneLayoutViewController*)layoutController;
@end
@interface SBSceneManagerCoordinator : NSObject
+(id)sharedInstance;
-(SBMainDisplaySceneManager*)sceneManagerForDisplay:(FBSDisplay*)display;
@end
@interface SBHomeScreenView : UIView
@end
@interface SBUIController : NSObject
@property (nonatomic, retain) SBHomeScreenView* window;
+(instancetype)sharedInstance;
-(BOOL)handleMenuDoubleTap;
@end
@interface _UIBackdropViewSettings : NSObject
+(id)settingsForStyle:(NSInteger)style graphicsQuality:(NSInteger)quality;
+(id)settingsForStyle:(NSInteger)style;
-(void)setDefaultValues;
-(id)initWithDefaultValues;
@end
@interface _UIBackdropView : UIView
-(id)initWithFrame:(CGRect)frame autosizesToFitSuperview:(BOOL)autoresizes settings:(_UIBackdropViewSettings*)settings;
@end
static int const UITapticEngineFeedbackPeek = 1001;
static int const UITapticEngineFeedbackPop = 1002;
@interface UITapticEngine : NSObject
- (void)actuateFeedback:(int)arg1;
- (void)endUsingFeedback:(int)arg1;
- (void)prepareUsingFeedback:(int)arg1;
@end
@interface UIDevice (Private)
-(UITapticEngine*)_tapticEngine;
@end
@interface SBMainSwitcherViewController : UIViewController
+(id)sharedInstance;
@end
@interface SBWallpaperEffectView : UIView
@property (nonatomic, assign) int style;
-(id)initWithWallpaperVariant:(int)variant;
@end
@interface SBFWallpaperView : UIView
@end
@interface SBWallpaperController : NSObject {
    SBFWallpaperView* _sharedWallpaperView;
    SBFWallpaperView* _homescreenWallpaperView;
}
-(id)initWithOrientation:(int)orientation variant:(int)variant;
@end
@interface MPUSystemMediaControlsViewController : UIViewController
@end
@interface SBAppSwitcherModel : NSObject {
	NSMutableArray *_recentDisplayItems;
}
+(instancetype)sharedInstance;
-(NSArray*)mainSwitcherDisplayItems;
@end
@interface SBDisplayItem : NSObject
@property (nonatomic, retain) NSString* displayIdentifier;
@end

@interface FBSystemGestureManager : NSObject <UIGestureRecognizerDelegate>
+(id)sharedInstance;
-(void)addGestureRecognizer:(id)arg1 toDisplay:(id)arg2 ;
-(void)removeGestureRecognizer:(id)arg1 fromDisplay:(id)arg2 ;
@end

OBJC_EXTERN UIImage *_UICreateScreenUIImage(void) NS_RETURNS_RETAINED;

//Declared in Tweak.xm
SBIcon* iconForBundleIdentifier(NSString* bundleIdentifier);