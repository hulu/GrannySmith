//
//  GSFancyTextAppDelegate.h
//  GSFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import <UIKit/UIKit.h>
#import "GSFancyTextDemoViewController.h"

@interface GSFancyTextAppDelegate : UIResponder <UIApplicationDelegate> {
    GSFancyTextDemoViewController* demoViewController_;
}

@property (strong, nonatomic) UIWindow *window;

@end
