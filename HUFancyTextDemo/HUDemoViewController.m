//
//  HUDemoViewController.m
//  HUFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import "HUDemoViewController.h"

#import "HUFancyTextView.h"

CGFloat const textWidth = 300;
CGFloat const maxHeight = 1000;

@implementation HUDemoViewController

@synthesize fancyTextView = fancyTextView_;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    UIView* view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = view;
    
    NSString* style = @".default{color: #ffffff; vertical-align:middle}\n\
    span.green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    b.blue{color: blue}\
    .center{text-align: center}\
    .limit2{line-count:2; truncate-mode:tail}";
    
    NSString* text = @"<em>Hello</em> iOS world. <span id='abc' class='yellow'>The sunrise <strong>and</strong> the sunset.</span> <strong>drawing</strong> <lambda id=circle width=36 height=12 vertical-align=baseline> some shapes <p><span class='green right'> A new <strong><em>paragraph</em></strong> with different alignments</span> and <span class=blue>different</span> colors!</p><p>A&lt;&amp;&gt;<span class=center>B</span></p>Ah I am <font style=color:red>going</font> to be a line.<p class=right>1<strong>2</strong>3</p><p id=eee class=limit2>Really a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a <strong>lot</strong> of a lot of a lot of texts</p> END<f";
    
    [HUFancyText parseStyleAndSetGlobal:style];
    
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:text];
    [fancyText appendStyleSheet: @".right{text-align: right}"];
    [fancyText changeNodeToStyledText:@"New <span class=green>Text</span> has been <span class=green>added</span>." forID:@"abc"];
    
    void(^drawStarBlock) (CGRect) = ^(CGRect rect) {
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(contextRef, 255, 0, 0, 1);
        CGContextSetRGBStrokeColor(contextRef, 255, 255, 0, 1);
        CGContextFillEllipseInRect(contextRef, CGRectMake(rect.origin.x + 12, rect.origin.y + 0, 12, 12));
    };
    [fancyText setBlock:drawStarBlock forLambdaID:@"circle"];

    
    CGFloat xMargin = 10;
    CGFloat yMargin = 30;
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location!=NSNotFound) {
        xMargin = 100;
        yMargin = 100;
    }
    fancyTextView_ = [[HUFancyTextView alloc] initWithFrame:CGRectMake(xMargin, yMargin, textWidth, maxHeight) fancyText:fancyText];
    fancyTextView_.matchFrameHeightToContent = YES;
    fancyTextView_.backgroundColor = [UIColor blackColor];
    fancyTextView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:fancyTextView_];
    [fancyTextView_ updateWithCurrentFrame];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fancyTextView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [fancyTextView_ updateWithCurrentFrame];
}


@end
