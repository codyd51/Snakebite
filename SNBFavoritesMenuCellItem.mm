#import "SNBFavoritesMenuCellItem.h"
#import "SNBPreferencesManager.h"
#import "Interfaces.h"

extern "C" CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);

@implementation SNBFavoritesMenuCellItem
-(id)initWithBundleIdentifier:(NSString*)bundleIdentifier cellSize:(CGSize)cellSize {
    CGSize screenSize = [[objc_getClass("SBIconController") sharedInstance] view].frame.size;
    CGFloat cellWidth = fmin(cellSize.width , screenSize.width * 0.8);
    CGFloat cellHeight = fmin(cellSize.height, screenSize.height * 0.8);
    if ((self = [super initWithFrame:CGRectMake(0, 0, cellWidth, cellHeight)])) {
        NSLog(@"cellWidth: %f cellHeight: %f", cellWidth, cellHeight);

        _bundleIdentifier = bundleIdentifier;
        _isHighlighted = NO;

        _highlightingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cellSize.height*0.6, cellSize.height*0.6)];
        _highlightingView.center = self.center;
        _highlightingView.layer.cornerRadius = 13;
        _highlightingView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        _highlightingView.alpha = 0.0;
        [self addSubview:_highlightingView];

        SBIcon* icon = iconForBundleIdentifier(bundleIdentifier);
        UIImage* iconImage = [icon generateIconImage:2];

        if ([bundleIdentifier isEqualToString:@"com.snakebite.multitasking"]) {
            iconImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/Snakebite/multitasking.png"];
        }
        UIImageView* iconImageView = [[UIImageView alloc] initWithImage:iconImage];

        iconImageView.frame = CGRectMake(0, 0, cellSize.height * 0.5, cellSize.height * 0.5);
        iconImageView.center = self.center;

        if ([SNBPreferencesManager sharedManager].showAppLabels) { 
            UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * 0.25)];
            nameLabel.text = (__bridge NSString*)SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)bundleIdentifier);

            if ([bundleIdentifier isEqualToString:@"com.snakebite.multitasking"]) {
                nameLabel.text = @"Multitasking";
            }

            nameLabel.font = [UIFont systemFontOfSize:12];
            nameLabel.adjustsFontSizeToFitWidth = YES;
            nameLabel.textColor = [UIColor whiteColor];
            nameLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:nameLabel];

            nameLabel.center = CGPointMake(self.center.x, self.center.y * 1.75);
        }

        [self addSubview:iconImageView];
        _iconImageView = iconImageView;

        [iconImageView.layer setShadowOffset:CGSizeMake(-2, 1.5)];
        [iconImageView.layer setShadowRadius:2.5];
        [iconImageView.layer setShadowColor:[UIColor colorWithRed:34/255.f green:25/255.f blue:25/255.f alpha:1.0].CGColor];
        [iconImageView.layer setShadowOpacity:0.2];

        CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:iconImageView.bounds cornerRadius:13].CGPath;
        [iconImageView.layer setShadowPath:path];
    }
    return self;
}
-(void)setIconImage:(UIImage*)image {
    [_iconImageView setImage:image];
}
-(void)highlight {
    if (_isHighlighted) return;

    [UIView animateWithDuration:0.1 delay:0.0 options:nil animations:^{
        _highlightingView.alpha = 1.0;
    } completion:^(BOOL finished){
        if (finished) {
            _isHighlighted = YES;
        }
    }];
}
-(void)unhighlight {
    if (!_isHighlighted) return;

    [UIView animateWithDuration:0.1 delay:0.0 options:nil animations:^{
        _highlightingView.alpha = 0.0;
    } completion:^(BOOL finished){
        if (finished) {
            _isHighlighted = NO;
        }
    }];
}
@end