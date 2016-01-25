#import "SNBFavoritesMenuView.h"
#import "SNBFavoritesMenuCellItem.h"
#import "SNBPreferencesManager.h"
#import "Interfaces.h"

@implementation SNBFavoritesMenuView 
-(id)initWithCurrentFavoritesAndDefaultSize {
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        self.clipsToBounds = NO;

        CGRect transformedRect = CGRectMake(0, 0, self.frame.size.width*0.8, self.frame.size.height*0.8);

        CGPoint minimizedZero = CGPointMake(self.frame.size.width - transformedRect.size.width + 2, self.frame.size.height - transformedRect.size.height + 2);
        UIBezierPath* linePath = [UIBezierPath bezierPath];
        [linePath moveToPoint:CGPointZero];
        [linePath addLineToPoint:minimizedZero];

        CAShapeLayer* shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = linePath.CGPath;
        shapeLayer.fillColor = nil;
        shapeLayer.opacity = 0.3;
        shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.lineWidth = 2.0;

        //TODO current orientation
        _wallpaperView = [[NSClassFromString(@"SBWallpaperEffectView") alloc] initWithWallpaperVariant:0];
        _wallpaperView.style = [SNBPreferencesManager sharedManager].blurStyle;
        _wallpaperView.frame = self.frame;
        [self addSubview:_wallpaperView];

        CGRect topFrame = CGRectMake(0, 0, transformedRect.size.width, self.frame.size.height - transformedRect.size.height);
        CGRect sideFrame = CGRectMake(0, 0, self.frame.size.width - transformedRect.size.width, transformedRect.size.height);

        _cellItems = [[NSMutableArray alloc] init];

        _sideView = [[UIView alloc] initWithFrame:sideFrame];
        _sideView.frame = CGRectMake(0, 0, _sideView.frame.size.width, self.frame.size.height);
        _sideView.alpha = 0.0;
        [self addSubview:_sideView];
        [self populateSideView];
    }
    return self;
}
-(NSArray*)snakebiteIdentifiers {
    NSMutableArray* snakebiteIdentifiers = [NSMutableArray new];
    if ([SNBPreferencesManager sharedManager].useMultitaskingMode) {
        NSInteger startingIndex = 0;
        if ([[UIApplication sharedApplication] _accessibilityFrontMostApplication]) {
            startingIndex = 1;
        }

        NSArray* displayItems = [[[objc_getClass("SBAppSwitcherModel") sharedInstance] mainSwitcherDisplayItems] subarrayWithRange:NSMakeRange(startingIndex, [SNBPreferencesManager sharedManager].numApps)];
        for (SBDisplayItem* displayItem in displayItems) {
            [snakebiteIdentifiers addObject:displayItem.displayIdentifier];
        }
    }
    else {
        [snakebiteIdentifiers addObjectsFromArray:[SNBPreferencesManager sharedManager].favoriteBundleIDs];
    }

    [snakebiteIdentifiers addObject:@"com.snakebite.multitasking"];

    return [NSArray arrayWithArray:snakebiteIdentifiers];
}
-(void)populateSideView {
    NSArray* snakebiteIdentifiers = [self snakebiteIdentifiers];
    CGFloat cellHeight = _sideView.frame.size.height / snakebiteIdentifiers.count;
    cellHeight = fmin(cellHeight, _sideView.frame.size.width*1.5);

    for (int i = 0; i < snakebiteIdentifiers.count; i++) {
        NSString* bundleIdentifier = snakebiteIdentifiers[i];

        SNBFavoritesMenuCellItem* cellItem = [[SNBFavoritesMenuCellItem alloc] initWithBundleIdentifier:bundleIdentifier cellSize:CGSizeMake(_sideView.frame.size.width, cellHeight)];
        cellItem.center = [self centerForCellItemAtIndex:i];
        [_sideView addSubview:cellItem];

        [_cellItems addObject: cellItem];
    }
}
-(CGPoint)centerForCellItemAtIndex:(NSInteger)index {
    NSArray* snakebiteIdentifiers = [self snakebiteIdentifiers];
    CGFloat cellHeight = _sideView.frame.size.height / snakebiteIdentifiers.count;

    return CGPointMake(_sideView.frame.size.width/2, (cellHeight - 1) * index + (cellHeight/2));
}
-(void)_touchMovedToPoint:(CGPoint)point {
    for (SNBFavoritesMenuCellItem* cellItem in _cellItems) {
        CGRect convertedFrame = [self convertRect:cellItem.frame fromView:cellItem.superview];
        if (CGRectContainsPoint(convertedFrame, point)) {
            [cellItem highlight];
        }
        else {
            [cellItem unhighlight];
        }
    }
}
-(void)_touchEndedAtPoint:(CGPoint)point {
    for (SNBFavoritesMenuCellItem* cellItem in _cellItems) {
        CGRect convertedFrame = [self convertRect:cellItem.frame fromView:cellItem.superview];
        //if (CGRectContainsPoint(convertedFrame, point)) {
        //if (convertedFrame.origin.y - 10 < point.y && convertedFrame.origin.y + convertedFrame.size.height + 10 > point.y && convertedFrame.origin.x + convertedFrame.size.width + 10 > point.x) {
        if (cellItem.isHighlighted) {
            //found item they were touching
            NSString* bundleIdentifier = cellItem.bundleIdentifier;
            if ([bundleIdentifier isEqualToString:@"com.snakebite.multitasking"]) {
                NSLog(@"launching Snakebite multitasking");
                [[NSClassFromString(@"SBUIController") sharedInstance] handleMenuDoubleTap];
            }
            else {
                NSLog(@"launching app with identifier: %@", bundleIdentifier);
                [[UIApplication sharedApplication] launchApplicationWithIdentifier:bundleIdentifier suspended:NO];
            }
            break;
        }
    }
}
-(void)performSlideInAnimationForPresentation {
    _sideView.alpha = 1.0;

    CGPoint previousCenter = _sideView.center;
    CGPoint shiftedCenter = CGPointMake(_sideView.center.x * 1.5, _sideView.center.y);
    _sideView.center = shiftedCenter;

    _sideView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 0.85);

    [UIView animateWithDuration:0.3 animations:^{
        _sideView.center = previousCenter;
        _sideView.transform = CGAffineTransformIdentity;
    }];
}
-(void)performSlideOutAnimationForDismissal {
    CGPoint previousCenter = _sideView.center;
    CGPoint shiftedCenter = CGPointMake(_sideView.center.x * 1.5, _sideView.center.y);

    [UIView animateWithDuration:0.2 animations:^{
        _sideView.center = shiftedCenter;
        _sideView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 0.85);
    } completion:^(BOOL finished){
        _sideView.center = previousCenter;
        _sideView.transform = CGAffineTransformIdentity;  
        _sideView.alpha = 0.0;
    }];
}
@end