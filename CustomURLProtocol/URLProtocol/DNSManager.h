//
//  DNSManager.h
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNSManager : NSObject
+ (DNSManager*)shareManager;
- (NSString*)ipForHost:(NSString*)host;
@end
