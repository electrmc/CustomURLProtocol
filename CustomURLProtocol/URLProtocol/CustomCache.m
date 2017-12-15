//
//  CustomCache.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import "CustomCache.h"

@implementation CustomCache
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSLog(@"%s,%@",__func__,request);
    NSCachedURLResponse *response = [super cachedResponseForRequest:request];
    NSLog(@"cached response : \n%@",response.response);
    return response;
}
@end
