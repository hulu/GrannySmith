//
//  GSFancyTextView.h
//  -GrannySmith-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GSFancyTextDefines.h"
#import "GSFancyText.h"

/// The view class based on GSFancyText model.
///
/// Features include: setting accessibility lable, auto-resizing, updating view frame height based on content height, etc

@interface GSFancyTextView : UIView {
    GSFancyText* fancyText_;
    CGFloat contentHeight_;
    
    BOOL matchFrameHeightToContent_;
}

/// @name Properties

/// The GSFancyText object for this view
@property (nonatomic, retain) GSFancyText* fancyText;

/// The content height of the fancyText object
@property (nonatomic, assign) CGFloat contentHeight;

/** If matchFrameHeightToContent is set to YES, the frame content height will be set to match the content height
 * every time updateWithCurrentFrame method is called.
 *
 * If it's set to NO, every time we call updateWithCurrentFrame, only the new width will be used to affect the line height.
 */
@property (nonatomic, assign) BOOL matchFrameHeightToContent;

/// @name Initialization

/** Initialize a fancy text view with a frame and a fancyText
 */
- (id)initWithFrame:(CGRect)frame fancyText:(GSFancyText*)fancyText;

/// @name Accessibility label

/** Enable and update the accessibility label
 */
- (void)updateAccessibilityLabel;


/** Inform fancyText model object the frame change (mainly width) and let it re-calculate the drawing
 *
 * For best visual experience, call this method in view controller's willAnimateRotationToInterfaceOrientation:duration: method
 *
 * This can also be called in loadView method after adding the fancyTextView to the screen, so that the frame height can be updated (need to set matchFrameHeightToContent in this case)
 */
- (void)updateWithCurrentFrame;


/** Updates the frame size based on fancyText content height
 *
 * We may assign extra/more than enough space at the beginning, so after the drawing we can truncate the view frame to fit the content.
 *
 * Note: this method sets frame height for once. For automatical frame height update, see matchFrameHeightToContent property.
 */
- (void)setFrameHeightToContentHeight;

@end
