#import <Preferences/Preferences.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSDiscreteSlider.h>
#import "../Interfaces.h"

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
