#import "SNBFavoritesMenuView.h"

@interface SNBMenuController : NSObject {
    BOOL _isSetup;
    BOOL _isFullyPresented;
    BOOL _isPeeking;
    BOOL _isPresentingOnSpringboard;
    BOOL _wasStatusBarHiddenOnInvocation;
    BOOL _wasForceTouchInvocation;
    BOOL _isPrimedForNonForceTouchSwipeInvocation;
    SNBFavoritesMenuView* _menuView;
    UIView* _contentViewContainerView;
    UIView* _contentView;
    UIView* _contentViewShadowView;
    CGRect _originalFrame;
    CGPoint _previousLocationInView;
}
+(instancetype)sharedInstance;
-(void)actuatePopFeedbackSimulateIfNecessary;
-(void)actuatePeekFeedbackSimulateIfNecessary;
-(void)presentForPeek:(BOOL)peek;
-(void)dismiss;
-(void)dismissWithCompletion:(void(^)(void))completion;
-(void)setupMainView;
-(void)_gestureStateChanged:(UIGestureRecognizer*)rec;
@end