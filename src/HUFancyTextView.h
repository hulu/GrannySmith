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
    
    BOOL matchFrameHeightToContent_;
}

@property (nonatomic, retain) HUFancyText* fancyText;
@property (nonatomic, assign) CGFloat contentHeight;

/** If matchFrameHeightToContent is set to YES, the frame content height will be set to match the content height
 * every time updateWithCurrentFrame method is called.
 */
@property (nonatomic, assign) BOOL matchFrameHeightToContent;

/** initialize a fancy text view with a frame and a fancyText
 */
- (id)initWithFrame:(CGRect)frame fancyText:(HUFancyText*)fancyText;

/** enable and update the accessibility label
 */
- (void)updateAccessibilityLabel;


/** inform fancyText model object the frame change (mainly width) and let it re-calculate the drawing
 * @note for best visual experience, call this method in view controller's willAnimateRotationToInterfaceOrientation:duration: method
 * @note this can also be called in loadView method after adding the fancyTextView to the screen, so that the frame height can be updated (need to set matchFrameHeightToContent in this case)
 */
- (void)updateWithCurrentFrame;


/** we may assign extra/more than enough space at the beginning, so after the drawing we can truncate the view frame to fit the content.
 * @note this method sets frame height for once. For automatical frame height update, see matchFrameHeightToContent property.
 */
- (void)setFrameHeightToContentHeight;

@end
