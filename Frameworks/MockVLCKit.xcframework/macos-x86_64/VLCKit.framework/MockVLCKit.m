#import "MockVLCKit.h"

@implementation VLCMedia {
    NSURL *_url;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}
@end

@implementation VLCMediaPlayer {
    VLCMedia *_media;
    BOOL _isPlaying;
    BOOL _isPaused;
    BOOL _isEnded;
    id _drawable;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isPlaying = NO;
        _isPaused = NO;
        _isEnded = NO;
    }
    return self;
}

- (void)setMedia:(VLCMedia *)media {
    _media = media;
}

- (VLCMedia *)media {
    return _media;
}

- (void)play {
    _isPlaying = YES;
    _isPaused = NO;
    _isEnded = NO;
}

- (void)pause {
    _isPlaying = NO;
    _isPaused = YES;
}

- (void)stop {
    _isPlaying = NO;
    _isPaused = NO;
    _isEnded = YES;
}

- (void)setVolume:(int)value {
}

- (NSTimeInterval)time {
    return 0;
}

- (NSTimeInterval)remainingTime {
    return 0;
}

- (NSTimeInterval)duration {
    return 0;
}

- (void)setTime:(NSTimeInterval)time {
}

- (BOOL)isPlaying {
    return _isPlaying;
}

- (BOOL)isPaused {
    return _isPaused;
}

- (BOOL)isEnded {
    return _isEnded;
}

- (void)setDrawable:(id)drawable {
    _drawable = drawable;
}

- (id)drawable {
    return _drawable;
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context {
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    [super removeObserver:observer forKeyPath:keyPath];
}

@end

@implementation VLCDeinterlacingMode

+ (NSString *)none { return @"none"; }
+ (NSString *)blend { return @"blend"; }
+ (NSString *)bob { return @"bob"; }
+ (NSString *)yadif { return @"yadif"; }
+ (NSString *)yadifBlend { return @"yadifBlend"; }
+ (NSString *)yadifMotionAdaptive { return @"yadifMotionAdaptive"; }
+ (NSString *)linearBlend { return @"linearBlend"; }
+ (NSString *)x { return @"x"; }
+ (NSString *)yadif2x { return @"yadif2x"; }
+ (NSString *)phosphor { return @"phosphor"; }
+ (NSString *)weightedList { return @"weightedList"; }
+ (NSString *)linearBlendX { return @"linearBlendX"; }
+ (NSString *)xBob { return @"xBob"; }
+ (NSString *)discard { return @"discard"; }

@end