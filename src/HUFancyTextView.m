//
//  HUFancyTextView.m
//  i2
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import "HUFancyTextView.h"

@implementation HUFancyTextView

@synthesize contentHeight = contentHeight_;
@synthesize fancyText = fancyText_;
@synthesize matchFrameHeightToContent = matchFrameHeightToContent_;

#ifdef ARC_ENABLED
#else
- (void)dealloc {
    release(fancyText_);
    [super dealloc];
}
#endif

-(id) initWithFrame:(CGRect)frame fancyText:(HUFancyText*)fancyText {
    if (( self = [super initWithFrame:frame] )) {
        fancyText_ = retained(fancyText);
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

- (void)updateWithCurrentFrame {
    self.fancyText.width = self.frame.size.width;
    [self.fancyText generateLines];
    if (matchFrameHeightToContent_) {
        [self setFrameHeightToContentHeight];
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

@end
