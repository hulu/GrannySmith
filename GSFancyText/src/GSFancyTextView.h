//
//  GSFancyTextView.h
//  -GrannySmith-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import <UIKit/UIKit.h>

#import "GSFancyTextDefines.h"
#import "GSFancyText.h"

/// The view class based on GSFancyText model.

/// Features include: setting accessibility lable, auto-resizing, updating view frame height based on content height, etc

@interface GSFancyTextView : UIView {
    GSFancyText* fancyText_;
    CGFloat contentHeight_;
    
    BOOL matchFrameHeightToContent_;
    BOOL matchFrameWidthToContent_;
}

/// @name Properties

/// The GSFancyText object for this view
@property (nonatomic, retain) GSFancyText* fancyText;

/// The content height of the fancyText object.
@property (nonatomic, assign, readonly) CGFloat contentHeight;

/** If matchFrameHeightToContent is set to YES, the view frame height will be set to match the content height
 * every time updateDisplay method is called.
 *
 * If it's set to NO, every time we call updateDisplay, only the new width will be used to affect the line height.
 */
@property (nonatomic, assign) BOOL matchFrameHeightToContent;


/** If it is set to YES, the view frame width will be set to match the content width (if the actually content is narrower than assigned width)
 * every time updateDisplay method is called.
 */
@property (nonatomic, assign) BOOL matchFrameWidthToContent;

/// @name Initialization

/** Initialize a fancy text view with a frame and a fancyText
 */
- (id)initWithFrame:(CGRect)frame fancyText:(GSFancyText*)fancyText;

/// @name Frame update

/** Whenever the fancyText parsed structure changes, or view frame changes, call this method to make sure that the display will be updated.
 *
 * It will do 3 things: 1. re-generate the lines, 2. update the view height is demanded, 3. setNeedsDisplay for the view
 *
 * For best visual experience, call this method in view controller's willAnimateRotationToInterfaceOrientation:duration: method
 *
 * This can also be called in loadView method after adding the fancyTextView to the screen, so that the frame height can be updated (need to set matchFrameHeightToContent in this case)
 */
- (void)updateDisplay;


/** Updates the frame size based on fancyText content height
 *
 * We may assign extra/more than enough space at the beginning, so after the drawing we can truncate the view frame to fit the content.
 *
 * Note: this method sets frame height for once. For automatical frame height update, see matchFrameHeightToContent property.
 */
- (void)setFrameHeightToContentHeight;

/** Updates the frame size based on fancyText content width
 *
 * Does it once. For automatical frame width update, see matchFrameWidthToContent property.
 */
- (void)setFrameWidthToContentWidth;

/// @name Accessibility label

/** Enable and update the accessibility label
 */
- (void)updateAccessibilityLabel;

@end
