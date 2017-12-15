//
//  CustomProtocol.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import "CustomProtocol.h"
#import "DNSManager.h"
#import "QNSURLSessionDemux.h"
#import "CookieManager.h"
#import "CacheStoragePolicy.h"
#import "AppleSourceCode.h"

// 用来打印在startLoading前会走多少次protocol系统，实验证明会很多次
#if 0
#define LOG NSLog
#else
#define LOG(...) nil
#endif

static NSString *const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface CustomProtocol()<NSURLSessionDelegate,NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *task;
@end

@implementation CustomProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    LOG(@"canInitWithRequest %@",request.URL);
    if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) {
        return NO;
    } 
    return [self _canFindIp:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    LOG(@"canonicalRequestForRequest %@",request.URL);
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    LOG(@"requestIsCacheEquivalent %@ to %@",a.URL,b.URL);
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    /**
     IP替换域名
     要保证header的host内容是域名，因此服务器要用这个域名做处理
     */
    NSString *host = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = self.request.URL.host;
    }
    NSMutableURLRequest *newReq = [self.request mutableCopy];
    
    NSString *ip = [[DNSManager shareManager]ipForHost:host];
    if (ip.length >0 && host.length >0 && ![ip isEqualToString:host]) {
        NSString *originURL = self.request.URL.absoluteString; 
        NSRange range = [originURL rangeOfString:host];
        NSString *newURLStr = [originURL stringByReplacingCharactersInRange:range withString:ip];
        newReq.URL = [NSURL URLWithString:newURLStr];
        [newReq setValue:host forHTTPHeaderField:@"host"];
        // 处理cookie
        [self _setCookieBeforeRequest:newReq]; 
    }
    
    // 标记request已经被处理过了，防止无限循环处理请求
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:newReq];
    
    // 生成task，发送请求
    self.task = [[QNSURLSessionDemux sharedDemux] dataTaskWithRequest:newReq delegate:self modes:[self _currentRunLoopModes]];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
    self.task = nil;
}

#pragma mark - private
+ (BOOL)_canFindIp:(NSURLRequest*)request {
    NSString *host = [[request allHTTPHeaderFields] objectForKey:@"host"];
    if (!host) {
        host = request.URL.host;
    }
    NSString *ip = [[DNSManager shareManager]ipForHost:host];
    return ip?YES:NO;
}


- (NSArray*)_currentRunLoopModes {
    NSRunLoopMode currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if (![currentMode isEqualToString:NSDefaultRunLoopMode]) {
        return @[NSDefaultRunLoopMode,currentMode];
    } else  {
        return @[currentMode];
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task 
willPerformHTTPRedirection:(NSHTTPURLResponse *)response 
        newRequest:(NSURLRequest *)request 
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSLog(@"%s %@",__func__,task.originalRequest.URL);
    //重定向的时候应该防止使用相对地址的新request使用IP
    //否则在后续的处理中,无法准确将http header的host设置为域名
    NSMutableURLRequest *newRequest = request.mutableCopy;
    [NSURLProtocol removePropertyForKey:URLProtocolHandledKey inRequest:newRequest];
    if (response) {
        //重定向是否是相对地址
        NSString *location = [response.allHeaderFields objectForKey:@"location"];
        if ([location hasPrefix:@"./"]) {
            //获取原始host
            NSURLRequest *originalRequest = task.originalRequest;
            NSString *originalHost = [[originalRequest allHTTPHeaderFields] objectForKey:@"host"];
            if (!originalHost) {
                originalHost = originalRequest.URL.host;
            }
            //替换新请求的host
            NSString *urlStr = newRequest.URL.absoluteString;
            NSString *host = newRequest.URL.host;
            if (urlStr && host) {
                NSString *newURLStr = [urlStr stringByReplacingOccurrencesOfString:host withString:originalHost];
                NSURL *newURL = [NSURL URLWithString:newURLStr];
                
                newRequest.URL = newURL;
            }
        }
    }
    
    [self.client URLProtocol:self wasRedirectedToRequest:newRequest redirectResponse:response];
    [self.task cancel];
    
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    NSLog(@"%s %@",__func__,task.originalRequest.URL);
    if (!challenge) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    //获取原始域名信息。
    NSString *currentHost = [[self.request allHTTPHeaderFields] objectForKey:@"host"];
    if (!currentHost) {
        currentHost = self.request.URL.host;
    }
    
    // 验证服务器会返回NSURLAuthenticationMethodServerTrust类型，其他还有很多类型，不过不是HTTPS建立连接时使用的
    if ([challenge.protectionSpace.authenticationMethod  isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([self _evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:currentHost]) {
            disposition = NSURLSessionAuthChallengeUseCredential; //使用指定证书
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    /**
     NSURLSessionAuthChallengePerformDefaultHandling 
     如果是百度这类的签名，是可以通过的，如果是自签名证书不会通过。
     */
    completionHandler(disposition,credential);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"%s %@",__func__,task.originalRequest.URL);
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    
    //错误处理
    if (error) {
        NSInteger errorCode = error.code;
        NSURLRequest *request = task.currentRequest;
        NSString *ip = request.URL.host;
        NSString *host = [[request allHTTPHeaderFields] objectForKey:@"host"];
        
        //未使用TCPDNS
        if (!ip || !host) {
            // 根据以上信息统计DNS失败次数
            return; 
        }
        
    }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);    
    /**
     使用原始请求的域名保存cookies
     */
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
    NSHTTPURLResponse *retResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL 
                                                                 statusCode:httpURLResponse.statusCode
                                                                HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                                               headerFields:httpURLResponse.allHeaderFields];
    [self _saveCookieAfterRequestWithResponse:retResponse];
    
    /**
     处理Cache:
     >1 根据response header中的内容来决定原始请求是否缓存response
     >2 代发请求的task执行全部缓存的策略
     
     NSURLSessionResponseAllow-解释
     >1 只要是completionHander的参数是NSURLSessionResponseAllow，那么系统都会缓存response
        无论ResponseHeader的Cache-Control是什么
     >2 是否发请求到服务器还是由Header中的Cache-Control字段控制，即使本地有缓存也可能到服务器请求资源
     */ 
    NSURLCacheStoragePolicy cacheStoragePolicy;
    NSInteger               statusCode;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        cacheStoragePolicy = CacheStoragePolicyForRequestAndResponse(self.task.originalRequest, (NSHTTPURLResponse *) response);
        statusCode = [((NSHTTPURLResponse *) response) statusCode];
    } else {
        assert(NO);
        cacheStoragePolicy = NSURLCacheStorageNotAllowed;
        statusCode = 42;
    }
    /**
     这是是否缓存response影响的是通过defaultSessionConfiguration创建的请求，即那些不走CustomProtocol的请求；
     那些经过Protocol处理的请求需要的缓存是替换IP后的缓存
     */
    [self.client URLProtocol:self didReceiveResponse:retResponse cacheStoragePolicy:cacheStoragePolicy];
    
    /**
     代发请求的task会缓存所有应答的response
     但是是否发请求到服务器还是由Header中的Cache-Control字段控制
     */ 
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);
    // 这里可以根据收到的数据量做流量统计
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    NSLog(@"%s %@",__func__,dataTask.originalRequest.URL);
    completionHandler(proposedResponse);
}

#pragma mark - 证书校验
- (BOOL)_evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain {
    //创建证书校验策略
    NSMutableArray *policies = [NSMutableArray array];
    if (domain) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    
    //绑定校验策略到服务端的证书上
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
    //评估当前serverTrust是否可信任，
    //官方建议在result = kSecTrustResultUnspecified 或 kSecTrustResultProceed
    //的情况下serverTrust可以被验证通过，https://developer.apple.com/library/ios/technotes/tn2232/_index.html
    //关于SecTrustResultType的详细信息请参考SecTrust.h
    SecTrustResultType result;
    SecTrustEvaluate(serverTrust, &result);
    
    return (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
}

#pragma mark - Cookie
- (void)_setCookieBeforeRequest:(NSMutableURLRequest *)req {
    CookieManager *cm = [CookieManager sharedInstance];
    NSString *cookie = [cm getRequestCookieHeaderForURL:self.request.URL];
    if (cookie.length > 0) {
        [req setValue:cookie forHTTPHeaderField:@"Cookie"];
    }
}

- (void)_saveCookieAfterRequestWithResponse:(NSHTTPURLResponse *)response {
    NSDictionary *headerFields = [response allHeaderFields];
    CookieManager *cm = [CookieManager sharedInstance];
    
    [cm handleHeaderFields:headerFields forURL:self.request.URL];
}
@end
