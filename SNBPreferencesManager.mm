#import "Interfaces.h"
#import "SNBPreferencesManager.h"

@interface SNBPreferencesManager (Private)
-(void)_preferencesChanged;
@end

static void preferencesChanged() {
	NSLog(@"prefs callback received");

    CFPreferencesAppSynchronize(CFSTR("com.phillipt.snakebite"));

    [[SNBPreferencesManager sharedManager] _preferencesChanged];
}

@implementation SNBPreferencesManager
+(void)load {
	NSLog(@"Load called");
	//make sure this exists in time
	[self sharedManager];
}
+(instancetype)sharedManager {
	// Setup instance for current class once
    static id sharedInstance = nil;
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
        sharedInstance = [self new];
    });
    // Provide instance
    return sharedInstance;
}
-(id)init {
	if ((self = [super init])) {
		NSLog(@"init called");

	    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		                                NULL,
		                                (CFNotificationCallback)preferencesChanged,
		                                CFSTR("com.phillipt.snakebite/prefsChanged"),
		                                NULL,
		                                CFNotificationSuspensionBehaviorDeliverImmediately);
	    [self _preferencesChanged];
	}
	return self;
}
-(void)attemptSettingFallbackPrefs {
	//set default values and bail
	//only force-set defaults if it seems like values haven't been set yet
	//once prefs have been set once, _blurStyle will only ever be 13 or 25, so let's use that to see if preferences have ever been set
	if (_blurStyle == 0) {
		NSLog(@"Setting default values because preferences have never been created");
		
		_enabled = YES;
		_showAppLabels = NO;
		_useMultitaskingMode = YES;
		_numApps = 6;
		_blurStyle = 25;
	}
}
-(void)_preferencesChanged {
	NSLog(@"preferencesChanged");
	CFStringRef appID = CFSTR("com.phillipt.snakebite");

	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (!keyList) {
		NSLog(@"There's been an error getting the key list!");

		[self attemptSettingFallbackPrefs];

		return;
	}
	
	NSDictionary* preferences = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
	CFRelease(keyList);

	if (!preferences) {
		NSLog(@"There's been an error getting the preferences dictionary!");

		[self attemptSettingFallbackPrefs];
	}

	NSLog(@"keysToValues: %@", preferences);

	_enabled = preferences[@"enabled"] ? [(NSNumber*)preferences[@"enabled"] boolValue] : YES;
	_showAppLabels = preferences[@"showAppLabels"] ? [(NSNumber*)preferences[@"showAppLabels"] boolValue] : NO;
	_useMultitaskingMode = preferences[@"useMultitaskingMode"] ? [(NSNumber*)preferences[@"useMultitaskingMode"] boolValue] : YES;
	_numApps = preferences[@"numApps"] ? [(NSNumber*)preferences[@"numApps"] intValue] : 6;
	_blurStyle = preferences[@"blurStyle"] ? [(NSNumber*)preferences[@"blurStyle"] intValue] : 25;

	NSMutableArray* favorites = [NSMutableArray new];
	for (NSString *key in [preferences allKeys]) {
		NSString* prefix = @"fav-";
		if ([key hasPrefix:prefix]) {
			NSString *trimmedBundleID = [key substringFromIndex:prefix.length];

			if ([((NSNumber*)preferences[key]) boolValue]) {
				[favorites addObject:trimmedBundleID];
			}
		}
	}
	_favoriteBundleIDs = [NSArray arrayWithArray:favorites];
}
@end