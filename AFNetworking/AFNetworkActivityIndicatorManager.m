// AFNetworkActivityIndicatorManager.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFNetworkActivityIndicatorManager.h"
#import "AFHTTPRequestOperation.h"
#import <libkern/OSAtomic.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
static NSTimeInterval const kAFNetworkActivityIndicatorInvisibilityDelay = 2.0;

@interface AFNetworkActivityIndicatorManager () {
@private
	NSInteger _activityCount;
    BOOL _enabled;
}

@property (readonly, getter = isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

- (void)_updateActivityCount;
- (void)_updateNetworkActivityIndicatorVisibility;
@end

@implementation AFNetworkActivityIndicatorManager
@synthesize enabled = _enabled;
@dynamic networkActivityIndicatorVisible;

+ (AFNetworkActivityIndicatorManager *)sharedManager {
    static AFNetworkActivityIndicatorManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incrementActivityCount) name:AFNetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decrementActivityCount) name:AFNetworkingOperationDidFinishNotification object:nil];
        
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updateActivityCount {
    if (_enabled) {
        if (!_activityCount) {
            // Delay hiding of activity indicator for a short interval, to avoid flickering
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kAFNetworkActivityIndicatorInvisibilityDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self _updateNetworkActivityIndicatorVisibility];
            });
        } else {
            [self _updateNetworkActivityIndicatorVisibility];
        }
    } else {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

- (BOOL)isNetworkActivityIndicatorVisible {
    return [UIApplication sharedApplication].networkActivityIndicatorVisible;
}

- (void)_updateNetworkActivityIndicatorVisibility {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(_activityCount > 0)];
}

- (void)incrementActivityCount {
    OSAtomicIncrement32(&_activityCount);
    
    [self _updateActivityCount];
}

- (void)decrementActivityCount {
    if (_activityCount <= 0) { 
        [self resetActivityCount];
        return;
    }
    
    OSAtomicDecrement32(&_activityCount);
    
    [self _updateActivityCount];
}

- (void)resetActivityCount
{
    OSAtomicCompareAndSwap32(_activityCount, 0, &_activityCount);
    
    [self _updateActivityCount];
}


@end

#endif
