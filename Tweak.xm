#import "Interfaces.h"
#import "SNBMenuController.h"
#import "SNBPreferencesManager.h"

SBIcon* iconForBundleIdentifier(NSString* bundleIdentifier) {
    SBIconModel* model = ((SBIconController*)[%c(SBIconController) sharedInstance]).model;
    return [model expectedIconForDisplayIdentifier:bundleIdentifier];
}

%hook SBMainSwitcherGestureCoordinator
-(void)_handleSwitcherForcePressGesture:(UIGestureRecognizer*)rec {
	if ([SNBPreferencesManager sharedManager].enabled) {
    	dispatch_async(dispatch_get_main_queue(), ^{
        	[[SNBMenuController sharedInstance] _gestureStateChanged:rec];
    	});
    }
    else {
    	%orig;
    }
}
%end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)application {
	%orig;

	//if (![UIDevice currentDevice]._tapticEngine) {
		UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc] initWithTarget:[SNBMenuController sharedInstance] action:@selector(_handleNonForceTouchTapInvocationBegan:)];
		tapRec.numberOfTapsRequired = 1;
		[[%c(FBSystemGestureManager) sharedInstance] addGestureRecognizer:tapRec toDisplay:[%c(FBDisplayManager) mainDisplay]];

		UIScreenEdgePanGestureRecognizer* screenEdgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:[SNBMenuController sharedInstance] action:@selector(_gestureStateChanged:)];
		//left edge of screen
		screenEdgePan.edges = 2;
		[[%c(FBSystemGestureManager) sharedInstance] addGestureRecognizer:screenEdgePan toDisplay:[%c(FBDisplayManager) mainDisplay]];
	//}
}
%end