#import "Interfaces.h"

@interface SNBFavoritesMenuView : UIView {
    SBWallpaperEffectView* _wallpaperView;
    UILabel* _favoritesLabel;
    UIView* _sideView;
    NSMutableArray* _cellItems;
   	UIImageView* _iconImageView;
}
-(id)initWithCurrentFavoritesAndDefaultSize;
-(void)_touchMovedToPoint:(CGPoint)point;
-(void)_touchEndedAtPoint:(CGPoint)point;
-(void)performSlideInAnimationForPresentation;
-(void)performSlideOutAnimationForDismissal;
@end