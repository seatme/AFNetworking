// AFXMLRequestOperation.m
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

#import "AFXMLRequestOperation.h"

#include <Availability.h>

@interface AFXMLRequestOperation ()
@property (readwrite, nonatomic, strong) NSXMLParser *responseXMLParser;
+ (NSSet *)defaultAcceptableContentTypes;
+ (NSSet *)defaultAcceptablePathExtensions;
@end

@implementation AFXMLRequestOperation
@synthesize responseXMLParser = _responseXMLParser;

+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser))success
                                                        failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser))failure
{
    
    AFXMLRequestOperation *requestOperation = [[self alloc] initWithRequest:urlRequest];
    //need to really split this class up.
    __weak AFXMLRequestOperation *weakself = requestOperation;
    requestOperation.finishedBlock = ^{
        AFXMLRequestOperation *strongself = weakself;
        if (strongself.error){
            if (failure) {
                failure(strongself.request, strongself.response, strongself.error, strongself.responseXMLParser);
            }
        }
        else
        {
            if (success) {
                success(strongself.request, strongself.response, strongself.responseXMLParser);
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
    
    __weak AFXMLRequestOperation *blockSelf = self;
    [self addExecutionBlock:^{
         blockSelf.responseXMLParser = [[NSXMLParser alloc] initWithData:blockSelf.responseData];
    }];
    
    self.acceptableContentTypes = [[self class] defaultAcceptableContentTypes];
    
    return self;
}


- (id)responseObject {
    return [self responseXMLParser];
}

- (NSXMLParser *)responseXMLParser {
    return _responseXMLParser;
}

#pragma mark - NSOperation


+ (BOOL)canProcessRequest:(NSURLRequest *)request {
    return [[self defaultAcceptableContentTypes] containsObject:[request valueForHTTPHeaderField:@"Accept"]] || [[self defaultAcceptablePathExtensions] containsObject:[[request URL] pathExtension]];
}

@end
