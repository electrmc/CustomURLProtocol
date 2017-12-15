//
//  CookieManager.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/4/14.
//  Copyright © 2017年 Hexin. All rights reserved.
//

#import "CookieManager.h"

@implementation CookieManager {
    HTTPDNSCookieFilter cookieFilter;
}

- (instancetype)init {
    if (self = [super init]) {
        cookieFilter = ^BOOL(NSHTTPCookie *cookie, NSURL *URL) {
            if (!URL) return NO;
            if ([URL.host containsString:cookie.domain] || [cookie.domain containsString:URL.host]) {
                return YES;
            } else {
                return NO;
            }
        };
    }
    return self;
}

+ (instancetype)sharedInstance {
    static CookieManager *singletonInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [[CookieManager alloc] init];
    });
    return singletonInstance;
}

- (void)setCookieFilter:(HTTPDNSCookieFilter)filter {
    if (filter != nil) {
        cookieFilter = filter;
    }
}

- (NSArray<NSHTTPCookie *> *)handleHeaderFields:(NSDictionary *)headerFields forURL:(NSURL *)URL {
    if (!URL) { return nil; }
    NSArray *cookieArray = [NSHTTPCookie cookiesWithResponseHeaderFields:headerFields forURL:URL];
    if (cookieArray != nil) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookieArray) {
            if (cookieFilter(cookie, URL)) {
                [cookieStorage setCookie:cookie];
            }
        }
    }
    return cookieArray;
}

- (NSString *)getRequestCookieHeaderForURL:(NSURL *)URL {
    if (!URL) { return nil; }
    NSArray *cookieArray = [self searchAppropriateCookies:URL];
    if (cookieArray != nil && cookieArray.count > 0) {
        NSDictionary *cookieDic = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieArray];
        if ([cookieDic objectForKey:@"Cookie"]) {
            return cookieDic[@"Cookie"];
        }
    }
    return nil;
}

- (NSArray *)searchAppropriateCookies:(NSURL *)URL {
    if (!URL) { return nil; }
    NSMutableArray *cookieArray = [NSMutableArray array];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if (cookieFilter(cookie, URL)) {
            [cookieArray addObject:cookie];
        }
    }
    return cookieArray;
}

- (NSInteger)deleteCookieForURL:(NSURL *)URL {
    if (!URL) { return 0; }
    NSInteger delCount = 0;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *tempArray = [cookieStorage cookies];
    for (NSHTTPCookie *cookie in tempArray) {
        if (cookieFilter(cookie, URL)) {
            NSLog(@"Delete a cookie: %@", cookie);
            [cookieStorage deleteCookie:cookie];
            delCount++;
        }
    }
    return delCount;
}

@end
