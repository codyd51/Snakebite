#import "SnakebiteDiscreteSliderTableCell.h"
#import <objc/runtime.h>
#import <Preferences/PSSpecifier.h>
#import "../Interfaces.h"

@implementation SnakebiteDiscreteSliderTableCell

-(id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(id)arg2 specifier:(PSSpecifier *)specifier {
	NSLog(@"SnakebiteDiscreteSliderTableCell initWithStyle:%i reuseIdentifier:%@ specifier:%@", arg1, arg2. specifier);

    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:specifier];
    if (self) {
        PSDiscreteSlider *slider = [[objc_getClass("PSDiscreteSlider") alloc] initWithFrame:CGRectZero];
        
        [slider addTarget:specifier.target action:@selector(sliderMoved:) forControlEvents:UIControlEventAllTouchEvents];
        [self setControl:slider];
   		
    }
    return self;
}

@end