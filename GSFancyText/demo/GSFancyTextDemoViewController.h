//
//  GSFancyTextDemoViewController.h
//  GSFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import <UIKit/UIKit.h>
#import "GSFancyTextView.h"

@interface GSFancyTextDemoViewController : UIViewController {
    GSFancyTextView* fancyTextView_;
    GSFancyText* originalFancyText_; // it is a backup
    
    UIButton* contentSwitchButton_;
    UIButton* styleSwitchButton_;
    UIButton* resetButton_;
}

@property (nonatomic, retain) GSFancyTextView* fancyTextView;
@property (nonatomic, retain) GSFancyText* originalFancyText;

@property (nonatomic, retain) UIButton* contentSwitchButton;
@property (nonatomic, retain) UIButton* styleSwitchButton;
@property (nonatomic, retain) UIButton* resetButton;

@end
