//
//  HUAppDelegate.h
//  HUFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HUDemoViewController.h"

@interface HUAppDelegate : UIResponder <UIApplicationDelegate> {
    HUDemoViewController* demoViewController_;
}

@property (strong, nonatomic) UIWindow *window;

@end
