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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0 || !defined(GS_ARC_ENABLED)
    if (workingQueue_) {
        dispatch_release(workingQueue_);
    }
#endif
#ifdef GS_ARC_ENABLED
}
#else
    GSRelease(fancyText_);
    
    [super dealloc];
}
#endif

- (id)initWithFrame:(CGRect)frame {
    if (( self = [super initWithFrame:frame])) {
        contentHeight_ = 0.f;
        self.backgroundColor = [UIColor clearColor];
        matchFrameHeightToContent_ = NO;
    }
    return self;
}

-(id) initWithFrame:(CGRect)frame fancyText:(GSFancyText*)fancyText {
    if (( self = [self initWithFrame:frame] )) {
        fancyText_ = GSRetained(fancyText);
        fancyText_.width = frame.size.width;
    }
    return self;
}

- (dispatch_queue_t)workingQueue {
    @synchronized(self) {
        if (!workingQueue_) {
            workingQueue_ = dispatch_queue_create("gs.fancytext.queue", NULL);
        }
    }
    return workingQueue_;
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
    dispatch_async(self.workingQueue, ^{
        NSString* pureText = [fancyText_ pureText];
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.isAccessibilityElement = YES;
            self.accessibilityLabel = pureText;
        });
    });
}

- (void)updateDisplayWithCompletionHandler:(void(^)())completionHandler {
    [self updateDisplayWithCompletionHandler:completionHandler justForResize:NO];
}

- (void)updateDisplayWithCompletionHandler:(void(^)())completionHandler justForResize:(BOOL)justForResize {
    self.fancyText.width = self.frame.size.width;
//    self.hidden = YES;
    dispatch_async(self.workingQueue, ^{
        CGSize currentSize = self.frame.size;
        if (justForResize && currentSize.width == lastHandledSize_.width && currentSize.height == lastHandledSize_.height) {
            return;
        }
        lastHandledSize_ = currentSize;
        [self.fancyText generateLines];
        [self.fancyText prepareDrawingInRect:self.bounds];
        
        if (matchFrameHeightToContent_) {
            [self setFrameHeightToContentHeight];
        }
        if (matchFrameWidthToContent_) {
            [self setFrameWidthToContentWidth];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay];
//            self.hidden = NO;
            if (completionHandler) {
                completionHandler();
            }
        });
    });
}

- (void)updateDisplay {
    [self updateDisplayWithCompletionHandler:nil justForResize:NO];
}

- (void)setFrameHeightToContentHeight {
    CGFloat textContentHeight = [fancyText_ contentHeight];
    CGFloat expectedHeight = (contentHeight_ >= textContentHeight? contentHeight_ : textContentHeight);
    if (!expectedHeight) {
        [fancyText_ generateLines];
        expectedHeight = [fancyText_ contentHeight];
    }
    
    void(^updateFrameBlock)() = ^{
        CGRect frame = self.frame;
        frame.size.height = expectedHeight;
        self.frame = frame;
    };
    
    if ([NSThread isMainThread]) {
        updateFrameBlock();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), updateFrameBlock);
    }
}

- (void)setFrameWidthToContentWidth {
    CGFloat width = [fancyText_ contentWidth];
    if (!width) {
        [fancyText_ generateLines];
        width = [fancyText_ contentWidth];
    }
    void(^updateFrameBlock)() = ^{
        if (width > self.frame.size.width) {
            // decrease width only. Don't increase.
            return;
        }
        CGRect frame = self.frame;
        frame.size.width = width;
        self.frame = frame;
    };
    
    if ([NSThread isMainThread]) {
        updateFrameBlock();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), updateFrameBlock);
    }
}


// TODO this won't work perfectly yet, so disabling it for now and will think about later.
// In some cases we don't want to trigger updateDisplay call without inserting a completion handler
//- (void)layoutSubviews {
//    [super layoutSubviews];
//    [self updateDisplayWithCompletionHandler:nil justForResize:YES];
//}

@end
