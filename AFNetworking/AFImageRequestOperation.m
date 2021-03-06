// AFImageRequestOperation.m
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

#import "AFImageRequestOperation.h"

static dispatch_queue_t af_image_request_operation_processing_queue;
static dispatch_queue_t image_request_operation_processing_queue() {
    if (af_image_request_operation_processing_queue == NULL) {
        af_image_request_operation_processing_queue = dispatch_queue_create("com.alamofire.networking.image-request.processing", 0);
    }
    
    return af_image_request_operation_processing_queue;
}

@interface AFImageRequestOperation ()
#if __IPHONE_OS_VERSION_MIN_REQUIRED
typedef UIImage AFImage;
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
typedef NSImage AFImage;
#endif
@property (readwrite, nonatomic, strong) AFImage *responseImage;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFImageRequestOperation
@synthesize responseImage = _responseImage;
@synthesize imageProcessingBlock=_imageProcessingBlock;
@synthesize cacheName=_cacheName;
#if __IPHONE_OS_VERSION_MIN_REQUIRED
@synthesize imageScale = _imageScale;
#endif

+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest                
                                                      success:(void (^)(AFImage *image))success
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, AFImage *image) {
        if (success) {
            success(image);
        }
    } failure:nil];
}


+ (AFImageRequestOperation *)imageRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                         imageProcessingBlock:(AFImage *(^)(AFImage *))imageProcessingBlock
                                                    cacheName:(NSString *)cacheNameOrNil
                                                      success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, AFImage *image))success
                                                      failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    AFImageRequestOperation *operation = [[AFImageRequestOperation alloc] initWithRequest:urlRequest];
    
    operation.cacheName = cacheNameOrNil;
    __weak AFImageRequestOperation *weakOperation = operation;
    operation.finishedBlock = ^{
        AFImageRequestOperation *strongOperation = weakOperation;
        if (strongOperation.error) {
            if (failure) {
                failure(strongOperation.request, strongOperation.response, strongOperation.error);
            }
        } else {                
            
            if (success) {
                success(strongOperation.request, strongOperation.response, strongOperation.responseImage);
            }
        }   
    };
    return operation;
}


+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"image/tiff", @"image/jpeg", @"image/gif", @"image/png", @"image/ico", @"image/x-icon", @"image/bmp", @"image/x-bmp", @"image/x-xbitmap", @"image/x-win-bitmap", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"ico", @"bmp", @"cur", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED
    self.imageScale = [[UIScreen mainScreen] scale];
#endif
    
    __weak AFImageRequestOperation *blockSelf = self;
    [self addExecutionBlock:^{
#if __IPHONE_OS_VERSION_MIN_REQUIRED
        UIImage *image = [UIImage imageWithData:blockSelf.responseData];
        if (blockSelf.imageScale != 1.0f || image.imageOrientation != UIImageOrientationUp) {
            CGImageRef imageRef = [image CGImage];
            //This seems like the wrong way to handle this. shouldn't the guy at the end handle this?
            image = [UIImage imageWithCGImage:imageRef scale:blockSelf.imageScale orientation:UIImageOrientationUp];
        }
        
        if (blockSelf.imageProcessingBlock) {
            image = blockSelf.imageProcessingBlock(image);
        }
        
        blockSelf.responseImage = image;
        
        
#elif __MAC_OS_X_VERSION_MIN_REQUIRED
        NSImage *image = [[NSImage alloc] initWithData:blockSelf.responseData];
        
        if (blockSelf.imageProcessingBlock) {
            image = blockSelf.imageProcessingBlock(image);
        }
#endif 
    }];
    
    return self;
}


- (id)responseObject {
    return [self responseImage];
}


#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)setImageScale:(CGFloat)imageScale {
    if (imageScale == _imageScale) {
        return;
    }
    
    [self willChangeValueForKey:@"imageScale"];
    _imageScale = imageScale;
    [self didChangeValueForKey:@"imageScale"];
}

#elif __MAC_OS_X_VERSION_MIN_REQUIRED 
- (NSImage *)responseImage {
    if (!_responseImage && [self.responseData length] > 0 && [self isFinished]) {
        // Ensure that the image is set to it's correct pixel width and height
        NSBitmapImageRep *bitimage = [[NSBitmapImageRep alloc] initWithData:self.responseData];
        self.responseImage = [[NSImage alloc] initWithSize:NSMakeSize([bitimage pixelsWide], [bitimage pixelsHigh])];
        [self.responseImage addRepresentation:bitimage];
    }
    
    return _responseImage;
}
#endif

#pragma mark - AFHTTPClientOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

//? why.
+ (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(id object))success 
                                                    failure:(void (^)(NSHTTPURLResponse *response, NSError *error))failure
{
    return [self imageRequestOperationWithRequest:urlRequest imageProcessingBlock:nil cacheName:nil success:^(NSURLRequest __unused *request, NSHTTPURLResponse __unused *response, AFImage *image) {
        success(image);
    } failure:^(NSURLRequest __unused *request, NSHTTPURLResponse *response, NSError *error) {
        failure(response, error);
    }];
}

@end
