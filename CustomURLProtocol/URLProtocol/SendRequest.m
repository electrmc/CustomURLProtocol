//
//  SendRequest.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import "SendRequest.h"
#import "CustomCache.h"

@interface SendRequest()<NSURLSessionDelegate,NSURLSessionDataDelegate>
@end

@implementation SendRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLCache *cacheObj = [[CustomCache alloc]initWithMemoryCapacity:1024*1024*10 diskCapacity:1024*1024*50 diskPath:nil];
            [NSURLCache setSharedURLCache:cacheObj];
        });
    }
    return self;
}

- (NSURLSessionConfiguration*)configCustomProtocol {
    static NSURLSessionConfiguration *config = nil;
    if (!config) {
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = INT_MAX; // 调试使用，防止断点时请求超时
        NSMutableArray *protocolArr = config.protocolClasses.mutableCopy;
        [protocolArr insertObject:NSClassFromString(@"CustomProtocol") atIndex:0];
        config.protocolClasses = protocolArr.copy;
    }
    return config;
}

- (void)requestWithCustomProtocol {
    NSURL *url = [NSURL URLWithString:@"https://localhost/"];
    NSURLSessionConfiguration *config = [self configCustomProtocol];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask *datatask = [session dataTaskWithURL:url];
    [datatask resume];
}

- (void)requestWithShareSession {
    NSURL *url = [NSURL URLWithString:@"https://localhost/"];
    NSURLSessionDataTask *datatask = [[NSURLSession sharedSession]dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"receive1 response");
        NSLog(@"error : %@",error);
    }];
    [datatask resume];
}

- (void)requestWithDefaultConfig {
    NSURL *url = [NSURL URLWithString:@"https://localhost/"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"receive2 response ");
        NSLog(@"error : %@",error);
    }];
    [dataTask resume];
    
}

- (void)cleanCache {
    [[CustomCache sharedURLCache] removeAllCachedResponses];
}

- (void)cleanCookie {
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] removeCookiesSinceDate:[NSDate dateWithTimeIntervalSince1970:1]];
}

- (void)printCache {
    NSURLCache *cacheobj = [CustomCache sharedURLCache];
    NSURL *url = [NSURL URLWithString:@"http://localhost:3000/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSCachedURLResponse *cacheResponse = [cacheobj cachedResponseForRequest:request];
    NSLog(@"%@",cacheResponse.response);
    NSLog(@"%@",cacheResponse.data);
}

- (void)printCookie {
    NSArray *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies;
    [cookies enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSHTTPCookie *cookie = (NSHTTPCookie*)obj;
        NSLog(@"%@",cookie.name);
        NSLog(@"%@",cookie.value);
        NSLog(@"%@",cookie.domain);
    }];
    
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSLog(@"%s %@",__func__,task.originalRequest.URL);
    if (completionHandler) {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"%s %@",__func__,task.originalRequest.URL);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse 
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);
    if (completionHandler) {
        completionHandler(proposedResponse);
    }
}

@end
