@interface SNBFavoritesMenuCellItem : UIView {
    UIView* _highlightingView;
    UIImageView* _iconImageView;
}
@property (nonatomic, assign) BOOL isHighlighted;
@property (nonatomic, retain) NSString* bundleIdentifier;
-(id)initWithBundleIdentifier:(NSString*)bundleIdentifier cellSize:(CGSize)cellSize;
-(void)highlight;
-(void)unhighlight;
@end