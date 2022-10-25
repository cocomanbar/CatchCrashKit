//
//  CCViewController.m
//  CatchCrashKit
//
//  Created by tanxl on 05/07/2022.
//  Copyright (c) 2022 tanxl. All rights reserved.
//

#import "CCViewController.h"

@interface CCViewController ()

@end

@implementation CCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = UIColor.whiteColor;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    // test1 SIGBUS:非法地址, 包括内存地址对齐(alignment)出错
    *((int *)(0x1234)) = 122;
    
    // test2
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self performSelector:@selector(test:)];
//    });
}


@end
