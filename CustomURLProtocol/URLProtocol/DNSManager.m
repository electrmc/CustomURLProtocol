//
//  DNSManager.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import "DNSManager.h"

@implementation DNSManager
+ (DNSManager*)shareManager {
    static DNSManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (NSString*)ipForHost:(NSString*)host {
    return @"127.0.0.1";
}
@end
