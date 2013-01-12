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


- (void)dealloc {
    dispatch_release(workingQueue_);
#ifdef GS_ARC_ENABLED
}
#else
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
        workingQueue_ = dispatch_queue_create("gs.fancytext.queue", NULL);
    }
    return self;
}

+ (GSFancyTextView*)fancyTextViewWithFrame:(CGRect)frame markupText:(NSString*)markup,... {
    va_list args;
    va_start(args, markup);
    NSString* content = [[NSString alloc] initWithFormat:markup arguments:args];
    va_end(args);
    GSFancyText* ft = [[GSFancyText alloc] initWithMarkupText:content];
    GSFancyTextView* ftv = [[self alloc] initWithFrame:frame fancyText:ft];
    GSRelease(ft);
    return GSAutoreleased(ftv);
}

- (void)drawRect:(CGRect)rect
{
    [fancyText_ drawInRect:rect];
}


- (void)updateAccessibilityLabel {
    dispatch_async(workingQueue_, ^{
        NSString* pureText = [fancyText_ pureText];
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.isAccessibilityElement = YES;
            self.accessibilityLabel = pureText;
        });
    });
}

- (void)updateDisplayWithCompletionHandler:(void(^)())completionHandler {
    self.fancyText.width = self.frame.size.width;
    dispatch_async(workingQueue_, ^{
        [self.fancyText generateLines];
        if (matchFrameHeightToContent_) {
            [self setFrameHeightToContentHeight];
        }
        if (matchFrameWidthToContent_) {
            [self setFrameWidthToContentWidth];
        }
        [self.fancyText prepareDrawingInRect:self.bounds];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay];
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

- (void)updateDisplay {
    [self updateDisplayWithCompletionHandler:nil];
}

- (void)setFrameHeightToContentHeight {
    dispatch_async(workingQueue_, ^{
        CGFloat textContentHeight = [fancyText_ contentHeight];
        CGFloat expectedHeight = (contentHeight_ >= textContentHeight? contentHeight_ : textContentHeight);
        if (!expectedHeight) {
            [fancyText_ generateLines];
            expectedHeight = [fancyText_ contentHeight];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            CGRect frame = self.frame;
            frame.size.height = expectedHeight;
            self.frame = frame;
        });
    });
}

- (void)setFrameWidthToContentWidth {
    dispatch_async(workingQueue_, ^{
        CGFloat width = [fancyText_ contentWidth];
        if (!width) {
            [fancyText_ generateLines];
            width = [fancyText_ contentWidth];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (width > self.frame.size.width) {
                // decrease width only. Don't increase.
                return;
            }
            
            CGRect frame = self.frame;
            frame.size.width = width;
            self.frame = frame;
        });
    });
}


@end
