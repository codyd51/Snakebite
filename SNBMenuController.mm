#import "SNBMenuController.h"
#import "Interfaces.h"
#include <dlfcn.h>
#import <substrate.h>

@implementation SNBMenuController
+ (instancetype)sharedInstance {
    // Setup instance for current class once
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
    });
    // Provide instance
    return sharedInstance;
}
+(UIImage*)snapshotOfView:(UIView*)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);

    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(id)init {
    if ((self = [super init])) {
        _isSetup = NO;
        _isFullyPresented = NO;
        _isPeeking = NO;
        _isPresentingOnSpringboard = NO;
        _isPrimedForNonForceTouchSwipeInvocation = NO;
    }
    return self;
}
-(void)presentForPeek:(BOOL)peek {
    if (_isFullyPresented) return;
    if (_isPeeking && peek) return;

    NSLog(@"presentForPeek: %i", (int)peek);

    if (!_isSetup) {
        [self setupMainView];
    }
    if (!peek) {
        [self actuatePopFeedbackSimulateIfNecessary];
    }

    [self _animateInvocationForPeek:peek];

    if (!peek) {
        _isFullyPresented = YES;
        _isPeeking = NO;
    }
    else {
        _isPeeking = YES;
        _isFullyPresented = NO;
    }
}
-(void)actuatePopFeedbackSimulateIfNecessary {
    [self _actuateFeedbackSimulateIfNecessaryWithType:UITapticEngineFeedbackPop];
}
-(void)actuatePeekFeedbackSimulateIfNecessary {
    [self _actuateFeedbackSimulateIfNecessaryWithType:UITapticEngineFeedbackPeek];
}
-(void)_actuateFeedbackSimulateIfNecessaryWithType:(int)type {
    NSLog(@"_actuateFeedbackSimulateIfNecessaryWithType");
    //if device is force touch enabled, actuate pop
    if ([[UIDevice currentDevice] respondsToSelector:@selector(_tapticEngine)]) {
        UITapticEngine *tapticEngine = [UIDevice currentDevice]._tapticEngine;
        if (tapticEngine) {
            [tapticEngine actuateFeedback:type];
        }
        else {
            typedef void* (*vibratePointer)(SystemSoundID inSystemSoundID, id arg, NSDictionary *vibratePattern);
            //vibrate
            NSMutableArray* vPattern = [NSMutableArray array];
            [vPattern addObject:[NSNumber numberWithBool:YES]];
            [vPattern addObject:[NSNumber numberWithInt:(type == UITapticEngineFeedbackPop) ? 50 : 25]];
            NSDictionary *vDict = @{ @"VibePattern" : vPattern, @"Intensity" : @1 };

            vibratePointer vibrate;
            void *handle = dlopen(0, 9);
            *(void**)(&vibrate) = dlsym(handle,"AudioServicesPlaySystemSoundWithVibration");
            vibrate(kSystemSoundID_Vibrate, nil, vDict);
        }
    }
    else {
        typedef void* (*vibratePointer)(SystemSoundID inSystemSoundID, id arg, NSDictionary *vibratePattern);
        //vibrate
        NSMutableArray* vPattern = [NSMutableArray array];
        [vPattern addObject:[NSNumber numberWithBool:YES]];
        [vPattern addObject:[NSNumber numberWithInt:(type == UITapticEngineFeedbackPop) ? 50 : 25]];
        NSDictionary *vDict = @{ @"VibePattern" : vPattern, @"Intensity" : @1 };

        vibratePointer vibrate;
        void *handle = dlopen(0, 9);
        *(void**)(&vibrate) = dlsym(handle,"AudioServicesPlaySystemSoundWithVibration");
        vibrate(kSystemSoundID_Vibrate, nil, vDict);
    }
}
-(void)dismissWithCompletion:(void(^)(void))completion {
    if ((!_isFullyPresented && !_isPeeking) || !_isSetup) return;

    void (^newCompletion)(void) = ^{
        _isFullyPresented = NO;
        _isPeeking = NO;
        _isSetup = NO; 

        completion();
    };

    [self _animateDismissalWithCompletion:newCompletion];
}
-(void)dismiss {
    [self dismissWithCompletion:nil];
}
-(void)setupMainView {
    if (_isSetup) {
        return;
    }

    if ([[UIApplication sharedApplication] _accessibilityFrontMostApplication]) {
        _isPresentingOnSpringboard = NO;
        [self _retreiveContentViewForAppFrontmost];
    }
    else {
        _isPresentingOnSpringboard = YES;
        [self _retreiveContentViewForSpringboardFrontmost];
    }
    [self _performCommonSetup];

    _isSetup = YES;
}
-(void)_retreiveContentViewForAppFrontmost {
    SBSceneManagerCoordinator* sceneManagerCoordinator = [NSClassFromString(@"SBSceneManagerCoordinator") sharedInstance];
    FBSDisplay* mainDisplay = [NSClassFromString(@"FBDisplayManager") mainDisplay];

    SBMainDisplaySceneManager* sceneManager = [sceneManagerCoordinator sceneManagerForDisplay:mainDisplay];

    SBMainDisplaySceneLayoutViewController* layoutController = [sceneManager layoutController];
    UIViewController* containerViewController = [layoutController _layoutElementControllerForLayoutRole:2];

    //if containerViewController is nil, then that probably means the user was at the homescreen
    //if so, the layout element view controller for that should be the main switcher view controller
    if (!containerViewController) {
        containerViewController = [NSClassFromString(@"SBMainSwitcherViewController") sharedInstance];
    }

    NSLog(@"containerViewController: %@", containerViewController);
    NSLog(@"view: %@", containerViewController.view);

    SBAppContainerView* view = (SBAppContainerView*)[containerViewController view];

    _contentView = view;
}
-(void)_retreiveContentViewForSpringboardFrontmost {
    SBHomeScreenView* homescreenView = ((SBUIController*)[NSClassFromString(@"SBUIController") sharedInstance]).window;

    _originalFrame = homescreenView.frame;

    UIImageView* copyImageView = [[UIImageView alloc] initWithImage:[SNBMenuController snapshotOfView:homescreenView]];
    UIView* contentView = [[UIView alloc] initWithFrame:copyImageView.frame];
    //the HS screeenshot is transparent 
    //so we add the wallpaper before adding the HS screenshot
    /*
    SBWallpaperEffectView* wallpaperView = [[NSClassFromString(@"SBWallpaperEffectView") alloc] initWithWallpaperVariant:0];
    wallpaperView.style = 6;
    wallpaperView.frame = contentView.frame;
    */

    //wallpaperView.alpha = 0;

    //get existing shared wallpaper view, or, homescreen wallpaper view if that doesn't exist
    SBWallpaperController* wallpaperController = [NSClassFromString(@"SBWallpaperController") sharedInstance];
    UIView* wallpaperView = ([wallpaperController valueForKey:@"_sharedWallpaperView"]) ?: [wallpaperController valueForKey:@"_homescreenWallpaperView"];
    UIImageView* wallpaperCopyImageView = [[UIImageView alloc] initWithImage:[SNBMenuController snapshotOfView:wallpaperView]];

    [contentView addSubview:wallpaperCopyImageView];
    [contentView addSubview:copyImageView];

    [homescreenView addSubview:contentView];

    _contentView = contentView;

}
-(void)_performCommonSetup {
    _originalFrame = _contentView.frame;

    _contentViewContainerView = [[UIView alloc] initWithFrame:_contentView.frame];
    _contentViewContainerView.clipsToBounds = NO;
    [_contentView.superview insertSubview:_contentViewContainerView belowSubview:_contentView];

    _contentViewShadowView = [[UIView alloc] initWithFrame:CGRectInset(_contentView.frame, 2.5, 2.5)];
    _contentViewShadowView.backgroundColor = [UIColor redColor];
    _contentViewShadowView.layer.shadowOffset = CGSizeMake(-7.5, 0);
    _contentViewShadowView.layer.shadowRadius = 10;
    _contentViewShadowView.layer.shadowOpacity = 0.6;
    [_contentViewContainerView addSubview:_contentViewShadowView];

    [_contentViewContainerView addSubview:_contentView];
    _contentView.layer.masksToBounds = YES;
    _contentView.layer.cornerRadius = 7.5;

    _menuView = [[SNBFavoritesMenuView alloc] initWithCurrentFavoritesAndDefaultSize];
    [_contentViewContainerView.superview insertSubview:_menuView belowSubview:_contentViewContainerView];

    _wasStatusBarHiddenOnInvocation = [UIApplication sharedApplication].statusBarHidden;
}
-(void)_animateInvocationForPeek:(BOOL)peek {
    CGFloat duration = (peek ? 0.3 : 0.4);

    [[UIApplication sharedApplication] setStatusBarHidden:YES duration:duration/2];

    if (!peek) {
        [_menuView performSlideInAnimationForPresentation];
    }

    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:(peek ? 0.8 : 0.70) initialSpringVelocity:(peek ? 0.0 : 0.3) options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent) animations:^{
        if (peek) {
            _contentViewContainerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.96, 0.96);
        }
        else {
            _contentViewContainerView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
            
        }
        CGFloat xOffset = _originalFrame.size.width - _contentViewContainerView.frame.size.width;
        CGFloat yOffset = _originalFrame.size.height - _contentViewContainerView.frame.size.height;

        _contentViewContainerView.frame = CGRectMake(xOffset * 2.0, yOffset / 2, _contentViewContainerView.frame.size.width, _contentViewContainerView.frame.size.height);
    } completion:nil];
}
-(void)_animateDismissalWithCompletion:(void(^)(void))completion {
    if (!_isFullyPresented && !_isPeeking) return;

    [[UIApplication sharedApplication] setStatusBarHidden:_wasStatusBarHiddenOnInvocation duration:0.1];

    [_menuView performSlideOutAnimationForDismissal];

    [UIView animateWithDuration:0.2 delay:0.0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut) animations:^{
        _contentViewContainerView.transform = CGAffineTransformIdentity;
        _contentViewContainerView.frame = _originalFrame;

        _contentView.layer.cornerRadius = 0;
    } completion:^(BOOL finished){
        if (finished) {
            NSLog(@"contentView: %@", _contentViewContainerView);
            [_menuView removeFromSuperview];
            [_contentViewContainerView.superview insertSubview:_contentView aboveSubview:_contentViewContainerView];
            [_contentViewContainerView removeFromSuperview];

            if (_isPresentingOnSpringboard) {
                [_contentView removeFromSuperview];
            }

            completion();
        }
    }];
}
-(void)_handleNonForceTouchTapInvocationBegan:(UITapGestureRecognizer*)rec {
    CGPoint touchLocation = [rec locationInView:rec.view];

    CGFloat snakebiteMenuWidth = _menuView.frame.size.width * 0.2;
    if (!_menuView) {
        snakebiteMenuWidth = rec.view.frame.size.width * 0.2;
    }

    //only declare the invocation is primed if they tapped on the edge of the screen
    if (touchLocation.x < snakebiteMenuWidth) {
        _isPrimedForNonForceTouchSwipeInvocation = YES;

        //allow a 0.5s period for the user to perform the screen edge pan gesture, completing invocation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            _isPrimedForNonForceTouchSwipeInvocation = NO;
        });
    }
}
-(void)_gestureStateChanged:(UIGestureRecognizer*)rec {
    CGPoint touchLocation = [rec locationInView:rec.view];
    if (!CGPointEqualToPoint(touchLocation, CGPointZero)) {
        _previousLocationInView = touchLocation;
    }

    if (rec.state == UIGestureRecognizerStateBegan) {
        if ([rec isMemberOfClass:objc_getClass("UIScreenEdgePanGestureRecognizer")]) {
            NSLog(@"Was not force touch invocation");
            _wasForceTouchInvocation = NO;

            //if this isn't a force touch device and we're using the tap + swipe invocation, quit early if they haven't already tapped
            if (!_isPrimedForNonForceTouchSwipeInvocation) {
                rec.enabled = NO;
                rec.enabled = YES;
            }
        }
        else {
            _wasForceTouchInvocation = YES;
        }
    }
    else if (rec.state == UIGestureRecognizerStateChanged) {
        NSArray* touches = MSHookIvar<NSArray*>(rec, "_touches");
        UITouch* touch = [touches firstObject];
        CGFloat pressure = MSHookIvar<CGFloat>(touch, "_previousPressure");

        //on my device, the lowest pressure I can get the force touch gesture invocation to begin at is 240
        CGFloat maximumPeekPressure = 400;
        [self presentForPeek:_wasForceTouchInvocation ? (pressure <= maximumPeekPressure) : NO];

        if (!_isPeeking) {
            //don't attempt to highlight views if we're merely peeking
            [_menuView _touchMovedToPoint:touchLocation];
        }
    }
    else if (rec.state == UIGestureRecognizerStateEnded || rec.state == UIGestureRecognizerStateCancelled || rec.state == 0) {
        //stop handling this touch
        rec.enabled = NO;
        rec.enabled = YES;

        //_isPeeking gets reset after dismissal, so save it before calling dismiss
        BOOL wasPeeking = _isPeeking;

        [self dismissWithCompletion:^{
            if (!wasPeeking || !_wasForceTouchInvocation) {
                NSLog(@"Informing menu view of finished gesture because user was not peeking");
                [_menuView _touchEndedAtPoint:_previousLocationInView];
            }
        }];
    }
}
@end
