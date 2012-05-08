//
//  GSFancyTextView.m
//  -GrannySmith-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "GSFancyTextView.h"

@implementation GSFancyTextView

@synthesize contentHeight = contentHeight_;
@synthesize fancyText = fancyText_;
@synthesize matchFrameHeightToContent = matchFrameHeightToContent_;
@synthesize matchFrameWidthToContent = matchFrameWidthToContent_;

#ifdef GS_ARC_ENABLED
#else
- (void)dealloc {
    GSRelease(fancyText_);
    [super dealloc];
}
#endif

-(id) initWithFrame:(CGRect)frame fancyText:(GSFancyText*)fancyText {
    if (( self = [super initWithFrame:frame] )) {
        fancyText_ = GSRetained(fancyText);
        fancyText_.width = frame.size.width;
        contentHeight_ = 0.f;
        self.backgroundColor = [UIColor clearColor];
        matchFrameHeightToContent_ = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [fancyText_ drawInRect:rect];
}


- (void)updateAccessibilityLabel {
    self.isAccessibilityElement = YES;
    NSString* pureText = [fancyText_ pureText];
    self.accessibilityLabel = pureText;
}

- (void)updateDisplay {
    self.fancyText.width = self.frame.size.width;
    [self.fancyText generateLines];
    if (matchFrameHeightToContent_) {
        [self setFrameHeightToContentHeight];
    }
    if (matchFrameWidthToContent_) {
        [self setFrameWidthToContentWidth];
    }
    [self setNeedsDisplay];
}

- (void)setFrameHeightToContentHeight {
    CGFloat textContentHeight = [fancyText_ contentHeight];
    CGFloat expectedHeight = (contentHeight_ >= textContentHeight? contentHeight_ : textContentHeight);
    
    if (!expectedHeight) {
        [fancyText_ generateLines];
        expectedHeight = [fancyText_ contentHeight];
    }
    
    CGRect frame = self.frame;
    frame.size.height = expectedHeight;
    self.frame = frame;
}

- (void)setFrameWidthToContentWidth {
    CGFloat width = [fancyText_ contentWidth];
    if (!width) {
        [fancyText_ generateLines];
        width = [fancyText_ contentWidth];
    }
    if (width > self.frame.size.width) {
        // decrease width only. Don't increase.
        return;
    }
    
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}


@end
