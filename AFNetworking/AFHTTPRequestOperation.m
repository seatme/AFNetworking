// AFHTTPOperation.m
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

#import "AFHTTPRequestOperation.h"

@interface AFHTTPRequestOperation ()
@property (readwrite, nonatomic, strong) NSError *HTTPError;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
- (void)endBackgroundTask;
#endif
@end

static NSString * AFStringFromIndexSet(NSIndexSet *indexSet) {
    NSMutableString *string = [NSMutableString string];

    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }

        if (string.length) {
            [string appendString:@","];
        }

        if (range.length == 1) {
            [string appendFormat:@"%u", range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%u-%u", firstIndex, lastIndex];
        }

        range.location = nextIndex;
        range.length = 1;
    }

    return string;
}

#pragma mark -

@implementation AFHTTPRequestOperation
@synthesize acceptableStatusCodes = _acceptableStatusCodes;
@synthesize acceptableContentTypes = _acceptableContentTypes;
@synthesize HTTPError = _HTTPError;
@dynamic callbackQueue;
@dynamic responseObject;
@synthesize finishedBlock = _finishedBlock;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@synthesize attemptToContinueWhenAppEntersBackground=_attemptToContinueWhenAppEntersBackground;
#endif

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super initWithRequest:request];
    if (!self) {
        return nil;
    }
    
    _finishedBlock = nil; 
    _completionBlock = nil;
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    
    //by default we will use the main queue.
    self.callbackQueue = dispatch_get_main_queue();
    
    __weak AFHTTPRequestOperation *weakSelf = self;
    super.completionBlock = ^ {
        AFHTTPRequestOperation *strongSelf = weakSelf;
        if (strongSelf->_completionBlock) {
            strongSelf->_completionBlock(); //call any child completion blocks that may have been passed in that they may want to run
        }
        
        if ([strongSelf isCancelled]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
            [strongSelf endBackgroundTask];
#endif
            strongSelf.finishedBlock = nil;
            return;
        }
        
        if (strongSelf.finishedBlock) {
            dispatch_sync(strongSelf.callbackQueue, ^(void) {
                strongSelf.finishedBlock();
            });
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
            [strongSelf endBackgroundTask];
#endif
            strongSelf.finishedBlock = nil;
        } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
            [strongSelf endBackgroundTask];
#endif
        }
    };
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    self.attemptToContinueWhenAppEntersBackground = NO;
    _backgroundTask = UIBackgroundTaskInvalid;
#endif
    
    return self;
}

- (void)dealloc {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    [self endBackgroundTask];
#endif
    
    _completionBlock=nil;
    
    if (_callbackQueue) {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < 60000)
        dispatch_release(_callbackQueue);
#endif
        _callbackQueue = NULL;
    }
    
    _finishedBlock = nil;
}

- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)[super response];
}

- (NSError *)error {
    if (self.response && !self.HTTPError) {
        if (![self hasAcceptableStatusCode]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code in (%@), got %d", nil), AFStringFromIndexSet(self.acceptableStatusCodes), [self.response statusCode]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
        } else if ([self.responseData length] > 0 && ![self hasAcceptableContentType]) { // Don't invalidate content type if there is no content
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected content type %@, got %@", nil), self.acceptableContentTypes, [self.response MIMEType]] forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            
            self.HTTPError = [[NSError alloc] initWithDomain:AFNetworkingErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
        }
    }
    
    if (self.HTTPError) {
        return self.HTTPError;
    } else {
        return [super error];
    }
}

- (BOOL)hasAcceptableStatusCode {
    return !self.acceptableStatusCodes || [self.acceptableStatusCodes containsIndex:[self.response statusCode]];
}

- (BOOL)hasAcceptableContentType {
    return !self.acceptableContentTypes || [self.acceptableContentTypes containsObject:[self.response MIMEType]];
}

#pragma mark - iOSMultitasking support 

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
- (void)endBackgroundTask {
    if (_backgroundTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
        _backgroundTask = UIBackgroundTaskInvalid;
    }
}

//override 
- (void) start {
    if (![self isReady]) {
        return;
    }
    if (self.attemptToContinueWhenAppEntersBackground){
        if (_backgroundTask != UIBackgroundTaskInvalid) {
            [self endBackgroundTask];
        }
        
        BOOL multiTaskingSupported = NO;
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
            multiTaskingSupported = [[UIDevice currentDevice] isMultitaskingSupported];
        }
        
        if (multiTaskingSupported && _attemptToContinueWhenAppEntersBackground) {
            _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                if (_backgroundTask != UIBackgroundTaskInvalid)
                {
                    [self cancel];
                    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
                    _backgroundTask = UIBackgroundTaskInvalid;
                }
            }];
        }
    }
    [super start];
}

- (void)finish {
    [super finish];
    [self endBackgroundTask];
}
#endif


#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return YES;
}

- (void)setCompletionBlock:(void (^)(void))block
{
    if (block != _completionBlock){
        _completionBlock = [block copy];
    }
}

- (dispatch_queue_t)callbackQueue {
    return _callbackQueue;
}

- (void) setCallbackQueue:(dispatch_queue_t)callbackQueue {
    if (_callbackQueue == callbackQueue) 
        return;
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < 60000)
    if (_callbackQueue)
        dispatch_release(_callbackQueue);
    
    if (callbackQueue){
        dispatch_retain(callbackQueue);
        _callbackQueue = callbackQueue;
    }
#endif
    
    _callbackQueue = callbackQueue;
}

- (id) responseObject {
    //default implementation returns the raw data.
    return [self responseData];
}

@end
