#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCMedia : NSObject
- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
@end

@interface VLCMediaPlayer : NSObject
@property (nonatomic, strong, nullable) VLCMedia *media;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, readonly) BOOL isEnded;
@property (nonatomic, strong, nullable) id drawable;
- (instancetype)init;
- (void)play;
- (void)pause;
- (void)stop;
- (void)setVolume:(int)value;
- (NSTimeInterval)time;
- (NSTimeInterval)remainingTime;
- (NSTimeInterval)duration;
- (void)setTime:(NSTimeInterval)time;
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
@end

@interface VLCDeinterlacingMode : NSObject
+ (NSString *)none;
+ (NSString *)blend;
+ (NSString *)bob;
+ (NSString *)yadif;
+ (NSString *)yadifBlend;
+ (NSString *)yadifMotionAdaptive;
+ (NSString *)linearBlend;
+ (NSString *)x;
+ (NSString *)yadif2x;
+ (NSString *)phosphor;
+ (NSString *)weightedList;
+ (NSString *)linearBlendX;
+ (NSString *)xBob;
+ (NSString *)discard;
@end

NS_ASSUME_NONNULL_END