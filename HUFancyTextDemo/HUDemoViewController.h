//
//  HUDemoViewController.h
//  HUFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HUFancyTextView.h"

@interface HUDemoViewController : UIViewController {
    HUFancyTextView* fancyTextView_;
    HUFancyText* originalFancyText_; // it is a backup
    
    UIButton* contentSwitchButton_;
    UIButton* styleSwitchButton_;
    UIButton* resetButton_;
}

@property (nonatomic, retain) HUFancyTextView* fancyTextView;
@property (nonatomic, retain) HUFancyText* originalFancyText;

@property (nonatomic, retain) UIButton* contentSwitchButton;
@property (nonatomic, retain) UIButton* styleSwitchButton;
@property (nonatomic, retain) UIButton* resetButton;

@end
