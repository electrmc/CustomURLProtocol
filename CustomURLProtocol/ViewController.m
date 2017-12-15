//
//  ViewController.m
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/13.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#import "ViewController.h"
#import "SendRequest.h"

@interface ViewController ()
@property (nonatomic, strong) SendRequest *sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.sender = [[SendRequest alloc]init];
}

- (IBAction)requestWithCustomConfig:(id)sender {
    [self.sender requestWithCustomProtocol];
}

- (IBAction)requestWithShareSession:(id)sender {
    [self.sender requestWithShareSession];
}
- (IBAction)requestWithDefaultConfig:(id)sender {
    [self.sender requestWithDefaultConfig];
}

- (IBAction)cleanCookie:(id)sender {
    [self.sender cleanCookie];
}
- (IBAction)cleanCache:(id)sender {
    [self.sender cleanCache];
}
- (IBAction)printCookie:(id)sender {
    [self.sender printCookie];
}
- (IBAction)printCache:(id)sender {
    [self.sender printCache];
}
@end
