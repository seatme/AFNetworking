//
// AFXMLDocumentRequestOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// Copyright (c) Zac Bowling (zac@zacbowling.com)

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

#import "AFXMLDocumentRequestOperation.h"

#if __MAC_OS_X_VERSION_MIN_REQUIRED
#include <Availability.h>

@interface AFXMLDocumentRequestOperation ()
@property (readwrite, nonatomic, retain) NSXMLDocument *responseXMLDocument;
@property (readwrite, nonatomic, retain) NSError *error;
+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFXMLDocumentRequestOperation
@synthesize responseXMLDocument = _responseXMLDocument;
@synthesize error = _XMLError;

+ (AFXMLDocumentRequestOperation *)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                          success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLDocument *document))success
                                                          failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLDocument *document))failure
{
    AFXMLDocumentRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    __weak AFXMLDocumentRequestOperation *weakself = requestOperation;
    requestOperation.finishedBlock = ^{
        if (weakself.error){
            if (failure) {
                failure(weakself.request, weakself.response, weakself.error, weakself.responseXMLDocument);
            }
        }
        else
        {
            if (success) {
                success(weakself.request, weakself.response, weakself.responseXMLDocument);
            }
        }
        
    };
    
    return requestOperation;
}

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml", nil];
}

+ (NSSet *)defaultAcceptablePathExtensions {
    return [NSSet setWithObjects:@"xml", nil];
}

- (id)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    __block AFXMLDocumentRequestOperation *blockSelf = self;
    [self addExecutionBlock:^{
        NSError *error = nil;
        blockSelf.responseXMLDocument = [[NSXMLDocument alloc] initWithData:blockSelf.responseData options:0 error:&error];
        blockSelf.error = error;
    }];
    
    return self;
}

- (id)responseObject {
    return [self responseXMLDocument];
}


- (NSXMLDocument *)responseXMLDocument {
    return _responseXMLDocument;
}

- (NSError *)error {
    if (_XMLError) {
        return _XMLError;
    } else {
        return [super error];
    }
}

#pragma mark - NSOperation

- (void)cancel {
    [super cancel];
}

+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

@end
#endif
