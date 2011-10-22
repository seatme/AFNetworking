// AFXMLRequestOperation.h
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

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"

#import <Availability.h>

/**
 `AFXMLRequestOperation` is a subclass of `AFHTTPRequestOperation` for downloading and working with XML response data.
 
 ## Acceptable Content Types
 
 By default, `AFXMLRequestOperation` accepts the following MIME types, which includes the official standard, `application/xml`, as well as other commonly-used types:
 
 - `application/xml`
 - `text/xml`
 */
@interface AFXMLRequestOperation : AFHTTPRequestOperation {
@private
    NSXMLParser *_responseXMLParser;
#if __MAC_OS_X_VERSION_MIN_REQUIRED
    NSXMLDocument *_responseXMLDocument;
#endif
    NSError *_XMLError;
    void (^_processResponseBlock)(void);
}

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
 An `NSXMLParser` object constructed from the response data.
 */
@property (readonly, nonatomic, retain) NSXMLParser *responseXMLParser;

#if __MAC_OS_X_VERSION_MIN_REQUIRED
/**
 An `NSXMLDocument` object constructed from the response data. If an error occurs while parsing, `nil` will be returned, and the `error` property will be set to the error.
 */
@property (readonly, nonatomic, retain) NSXMLDocument *responseXMLDocument;
#endif

/**
 Creates and returns an `AFXMLRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the XML parser constructed with the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network error that occurred.
 
 @return A new XML request operation
 */
+ (AFXMLRequestOperation *)XMLParserRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                        success:(AFHTTPRequestOperationSuccessBlock)success
                                                        failure:(AFHTTPRequestOperationFailureBlock)failure;


#if __MAC_OS_X_VERSION_MIN_REQUIRED
/**
 Creates and returns an `AFXMLRequestOperation` object and sets the specified success and failure callbacks.
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param success A block object to be executed when the operation finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the XML document created from the response data of request.
 @param failure A block object to be executed when the operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data as XML. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error describing the network or parsing error that occurred.
 
 @return A new XML request operation
 */
+ (AFXMLRequestOperation *)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                          success:(AFHTTPRequestOperationSuccessBlock)success
                                                          failure:(AFHTTPRequestOperationFailureBlock)failure;
#endif

@end
