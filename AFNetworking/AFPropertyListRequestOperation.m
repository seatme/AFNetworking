// AFPropertyListRequestOperation.m
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

#import "AFPropertyListRequestOperation.h"

@interface AFPropertyListRequestOperation ()
@property (readwrite, nonatomic, strong) id responsePropertyList;
@property (readwrite, nonatomic, assign) NSPropertyListFormat propertyListFormat;
@property (readwrite, nonatomic, strong) NSError *propertyListError;

+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFPropertyListRequestOperation
@synthesize responsePropertyList = _responsePropertyList;
@synthesize propertyListReadOptions = _propertyListReadOptions;
@synthesize propertyListFormat = _propertyListFormat;
@synthesize propertyListError = _propertyListError;

+ (AFPropertyListRequestOperation *)propertyListRequestOperationWithRequest:(NSURLRequest *)request
                                                                    success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList))success
                                                                    failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList))failure
{
    AFPropertyListRequestOperation *requestOperation = [[self alloc] initWithRequest:request];
    
    __weak AFPropertyListRequestOperation *weakSelf = requestOperation;
    requestOperation.finishedBlock = ^{
        AFPropertyListRequestOperation *strongSelf = weakSelf;
        if (strongSelf.error) {
            if (failure) {
                failure(strongSelf.request, strongSelf.response, strongSelf.error, strongSelf.responsePropertyList);
            }
        }
        else 
        {
            if (success) {
                success(strongSelf.request, strongSelf.response, strongSelf.responsePropertyList);
            }
        }
    };
    
    return requestOperation;
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/x-plist", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"plist", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    __weak AFPropertyListRequestOperation *weakSelf = self;
    [self addExecutionBlock:^{
        AFPropertyListRequestOperation *strongSelf = weakSelf;
        NSPropertyListFormat format;
        NSError *error = nil;
        strongSelf.responsePropertyList = [NSPropertyListSerialization propertyListWithData:strongSelf.responseData 
                                                                                    options:strongSelf.propertyListReadOptions 
                                                                                     format:&format 
                                                                                      error:&error];
        strongSelf.propertyListFormat = format;
        strongSelf.propertyListError = error; 
    }];
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    self.propertyListReadOptions = NSPropertyListImmutable;
    
    
    return self;
}

- (id)responseObject {
    return [self responsePropertyList];
}

- (NSError *)error {
    if (_propertyListError) {
        return _propertyListError;
    } else {
        return [super error];
    }
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

@end
