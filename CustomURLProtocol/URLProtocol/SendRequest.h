//
//  SendRequest.h
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendRequest : NSObject

- (void)requestWithCustomProtocol;
- (void)requestWithShareSession;
- (void)requestWithDefaultConfig;

- (void)cleanCache;
- (void)cleanCookie;

- (void)printCache;
- (void)printCookie;
@end
