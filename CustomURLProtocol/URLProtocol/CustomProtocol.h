//
//  CustomProtocol.h
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 NSURLProtocol只有三个只读的属性：
 1，NSURLRequest *request 
 2，id <NSURLProtocolClient> client
 3，NSCachedURLResponse *cachedResponse
 */
@interface CustomProtocol : NSURLProtocol

@end
