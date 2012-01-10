//
//  HUFancyTextView.h
//  i2
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HUFancyTextDefines.h"
#import "HUFancyText.h"

/// The view class
/// based on HUFancyText model.
/// Added features include: setting accessibility lable, update view frame height based on content height, etc

@interface HUFancyTextView : UIView {
    HUFancyText* fancyText_;
    CGFloat contentHeight_;
}

@property (nonatomic, retain) HUFancyText* fancyText;
@property (nonatomic, assign) CGFloat contentHeight;

/** initialize a fancy text view with a frame and a fancyText
 */
- (id)initWithFrame:(CGRect)frame fancyText:(HUFancyText*)fancyText;



/** enable and update the accessibility label
 */
- (void)updateAccessibilityLabel;

/** we may assign extra/more than enough space at the beginning, so after the drawing we can truncate the view frame to fit the content
 */
- (void)setFrameHeightToContentHeight;

@end
