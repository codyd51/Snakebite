#import <Preferences/Preferences.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSDiscreteSlider.h>
#import "../Interfaces.h"

/*********************************************************************************************************************************************************************
*	  _______            _        ___                ____         _                 _            ___                     __    										 *
*	 / ___/ / ___ ____  (____    / _ \_______       / _____ ___ _(____ ___ ___ ____(____ ___ _  / _ \_______ ______ ___ / /_____   									 *
*	/ /__/ _ / _ `/ _ \/ / _ \  / ___/ __/ -_/ __  / _// _ / _ `/ / _ / -_/ -_/ __/ / _ / _ `/ / ___/ __/ -_(_-/ -_/ _ / __(_-<     								 *
*	\___/_//_\_,_/ .__/_/_//_/ /_/  /_/  \__/     /___/_//_\_, /_/_//_\__/\__/_/ /_/_//_\_, / /_/  /_/  \__/___\__/_//_\__/___/     								 *
*	            /_/                                       /___/                        /___/                                        								 *
*********************************************************************************************************************************************************************/

/*********************************************************************************************************************************************************************
*	______            _   _                  _____           _       ___  ___          _ _  __ _           _   _               _     _ _                          	 *
*	| ___ \          | | (_)                /  __ \         | |      |  \/  |         | (_)/ _(_)         | | (_)             | |   (_| |                         	 *
*	| |_/ _   _ _ __ | |_ _ _ __ ___   ___  | /  \/ ___   __| | ___  | .  . | ___   __| |_| |_ _  ___ __ _| |_ _  ___  _ __   | |    _| |__  _ __ __ _ _ __ _   _ 	 *
*	|    | | | | '_ \| __| | '_ ` _ \ / _ \ | |    / _ \ / _` |/ _ \ | |\/| |/ _ \ / _` | |  _| |/ __/ _` | __| |/ _ \| '_ \  | |   | | '_ \| '__/ _` | '__| | | |	 *
*	| |\ | |_| | | | | |_| | | | | | |  __/ | \__/| (_) | (_| |  __/ | |  | | (_) | (_| | | | | | (_| (_| | |_| | (_) | | | | | |___| | |_) | | | (_| | |  | |_| |   *
*	\_| \_\__,_|_| |_|\__|_|_| |_| |_|\___|  \____/\___/ \__,_|\___| \_|  |_/\___/ \__,_|_|_| |_|\___\__,_|\__|_|\___/|_| |_| \_____|_|_.__/|_|  \__,_|_|   \__, |   *
*                                                                                                                                                     		 __/ |   *                                                                                                                                            |___/ 
*																																									 *
*********************************************************************************************************************************************************************/

/*********************************************************************************************************************************************************************
*																																									 *
*	  _____                    __            ____    _                																								 *
*	 / ______  __ _  ___ __ __/ /____ ____  / ______(____ ___ _______ 																								 *
*	/ /__/ _ \/  ' \/ _ / // / __/ -_/ __/ _\ \/ __/ / -_/ _ / __/ -_)																								 *
*	\___/\___/_/_/_/ .__\_,_/\__/\__/_/   /___/\__/_/\__/_//_\__/\__/ 																								 *
*	              /_/                                                 																								 *
*																																									 *
**********************************************************************************************************************************************************************/

/*********************************************************************************************************************************************************************
																																									 *
*	   ___  __   _ _____        ______                          ___            _ __  ___ ___    ___ ___ _______														 *
*	  / _ \/ /  (_/ / (____    /_  _____ ___  ___ ___ ___      / _ | ___  ____(_/ / |_  / _ \  |_  / _ <  / __/														 *
*	 / ___/ _ \/ / / / / _ \    / / / -_/ _ \/ _ / -_/ _ \_   / __ |/ _ \/ __/ / / / __/\_, / / __/ // / / _ \ 														 *
*	/_/  /_//_/_/_/_/_/ .__/   /_/  \__/_//_/_//_\__/_//_( ) /_/ |_/ .__/_/ /_/_/ /____/___/ /____\___/_/\___/ 														 *
*                 /_/                                 |/       /_/                                          														 *
*																																									 *
*********************************************************************************************************************************************************************/

static inline void preObjc_msgSend_common(id self, uintptr_t lr, SEL _cmd, ThreadCallStack *cs, arg_list &args) {

#ifdef MAIN_THREAD_ONLY
  if (self && pthread_main_np() && cs->isLoggingEnabled) {
#else
  if (self && cs->isLoggingEnabled) {
#endif

    Class clazz = object_getClass(self);
    RLOCK;

    //check for hits.
    BOOL isWatchedObject = selectorSetContainsSelector((HashMapRef)HMGet(objectsMap, (void *)self), _cmd);
    BOOL isWatchedClass = selectorSetContainsSelector((HashMapRef)HMGet(classMap, (void *)clazz), _cmd);
    BOOL isWatchedSel = (HMGet(selsSet, (void *)_cmd) != NULL);

    UNLOCK;

    if (isWatchedObject && _cmd == @selector(dealloc)) {
      WLOCK;
      mapDestroySelectorSet(objectsMap, self);
      UNLOCK;
    }
    if (isWatchedObject || isWatchedClass || isWatchedSel) {
      onWatchHit(cs, args);
    } 
    else if (cs->numWatchHits > 0 || cs->isCompleteLoggingEnabled) {
      onNestedCall(cs, args);
    }
  }
}

// Called in our replacementObjc_msgSend after calling the original objc_msgSend.
// This returns the lr in r0/x0.
uintptr_t postObjc_msgSend() {
  ThreadCallStack *cs = (ThreadCallStack *)pthread_getspecific(threadKey);
  CallRecord *record = popCallRecord(cs);
  if (record->isWatchHit) {
    --cs->numWatchHits;
    cs->lastHitIndex = record->prevHitIndex;
  }
  if (cs->lastPrintedIndex > cs->index) {
    cs->lastPrintedIndex = cs->index;
  }
  return record->lr;
}

static NSInteger specIndex;
static PSSpecifier *sliderSpecifier;

@interface PSListController (Private)
-(NSBundle*)bundle;
@end

@interface SnakebiteListController: PSListController {
	PSSpecifier *sliderLabel;
	BOOL _isUsingDarkBlur;
}
@end

@implementation SnakebiteListController
-(void)viewDidLoad {
	[self _updateIsUsingDarkBlur];
	[self updateHeaderLogoForInitialPresentation:YES];

    [super viewDidLoad];
}

-(void)updateHeaderLogoForInitialPresentation:(BOOL)initialPresentation {
	NSString* bundlePath = [self bundle].bundlePath;
	NSString* imagePath = [bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"header%@", (_isUsingDarkBlur ? @"_dark.png" : @"_light.png")]];

    UIImage *icon = [[UIImage alloc] initWithContentsOfFile:imagePath];
 
    if (initialPresentation) {
    	UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
    	self.navigationItem.titleView = iconView;

    	self.navigationItem.titleView.alpha = 0;
    	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(revealHeaderIcon) userInfo:nil repeats:NO];
    }
    else {
    	[UIView transitionWithView:self.navigationItem.titleView duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            ((UIImageView*)self.navigationItem.titleView).image = icon;
        } completion:nil];
    }
}

-(void)_updateIsUsingDarkBlur {
	CFStringRef appID = CFSTR("com.phillipt.snakebite");

	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		NSLog(@"There's been an error getting the key list!");
		return;
	}
	NSDictionary* preferences = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
	if (!preferences) {
		NSLog(@"There's been an error getting the preferences dictionary!");
	}
	CFRelease(keyList);

	NSInteger blurStyle = preferences[@"blurStyle"] ? [(NSNumber*)preferences[@"blurStyle"] intValue] : 25;

	_isUsingDarkBlur = (blurStyle != 25);
}

- (void)revealHeaderIcon {
    [UIView animateWithDuration:0.25 animations:^{
        self.navigationItem.titleView.alpha = 1;
    } completion:nil];
}
-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if ([specifier.name isEqualToString:@"Blur style"]) {
		NSLog(@"changed blur style");

		[self _updateIsUsingDarkBlur];
		[self updateHeaderLogoForInitialPresentation:NO];
	}
}
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Snakebite" target:self];
		specIndex = [_specifiers indexOfObject:[self specifierForID:@"SliderLabelCell"]];
		sliderSpecifier = [self specifierForID:@"AppsCountCell"];
		sliderLabel = [PSSpecifier groupSpecifierWithHeader:@"Number of apps shown" footer:nil];

		NSMutableArray* newSpecifiers = [NSMutableArray arrayWithArray:_specifiers];
		newSpecifiers[specIndex] = sliderLabel;
		_specifiers = [NSArray arrayWithArray:newSpecifiers];

		NSLog(@"specifiers: %@", _specifiers);
		NSLog(@"_specifiers[specIndex] %@", _specifiers[specIndex]);
	}

	return _specifiers;
}
-(void)sliderMoved:(PSDiscreteSlider *)slider {
	NSLog(@"sliderMoved: %@", slider);

	sliderLabel = [PSSpecifier groupSpecifierWithHeader:@"Number of apps shown" footer:nil];
	
	NSMutableArray* newSpecifiers = [NSMutableArray arrayWithArray:_specifiers];
	newSpecifiers[specIndex] = sliderLabel;
	_specifiers = [NSArray arrayWithArray:newSpecifiers];

	[self setPreferenceValue:@(slider.value) specifier:sliderSpecifier];
	[self reloadSpecifierAtIndex:specIndex];
	[self reloadSpecifiers];
	[self reloadSpecifierAtIndex:specIndex+1];
}
@end

// vim:ft=objc
