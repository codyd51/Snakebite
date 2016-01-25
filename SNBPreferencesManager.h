@interface SNBPreferencesManager : NSObject
@property (nonatomic, assign, readonly) BOOL enabled;
@property (nonatomic, assign, readonly) BOOL showAppLabels;
@property (nonatomic, assign, readonly) BOOL useMultitaskingMode;
@property (nonatomic, assign, readonly) NSInteger numApps;
@property (nonatomic, assign, readonly) NSInteger blurStyle;
@property (nonatomic, retain, readonly) NSArray* favoriteBundleIDs;
+(instancetype)sharedManager;
@end