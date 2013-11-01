//
//  GSFancyTextDemoViewController.m
//  GSFancyTextDemo
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "GSFancyTextDemoViewController.h"

#import "GSFancyTextView.h"

CGFloat const textWidth = 300;
CGFloat const maxHeight = 1000;
CGFloat const buttonWidth = 100;
CGFloat const buttonHeight = 40;
CGFloat const buttonMargin = 5;


@implementation GSFancyTextDemoViewController

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
    
    // Preparing the style
    
    NSString* style = @".default{color: #ffffff; vertical-align:middle;}\n\
    span.green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .right{text-align: right}\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    .center{text-align: center}\
    .margin{margin-left: 40; margin-right:40}\
    .bmargin{margin-bottom:10}\
    .tmargin{margin-top: 10;}\
    .limit2{line-count:2; truncate-mode:tail}\
    .halfwidth {min-width:50%}\
    .middle {truncate-mode:middle}\
    .doublespace {line-height: 200%}";
    
    [GSFancyText parseStyleAndSetGlobal:style];
    
    
    // Creating the fancy text object
    
    NSString* text = @"<em>Hello</em> iOS world. <span id='xyz' class='yellow'>The sunrise <strong>and</strong> the sunset.</span> <strong>drawing</strong> <lambda id=circle width=36 height=12 vertical-align=baseline> some shapes <p class='right'><span class='green'> A new <strong><em>paragraph</em></strong> with different alignments</span> and <span class=blue>different</span> colors!</p><p class='center'>A&lt;&amp;&gt;B</p>Ah I am going to be a line.<p class='margin right'>A line with <em>>1</em> classes</p><p id=eee class='limit2 tmargin bmargin halfwidth'>Really a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of <span class='halfwidth'><strong>texts</strong></span></p>";

    // Put on the view

    CGFloat xMargin = 10;
    CGFloat yMargin = 30;
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location!=NSNotFound) {
        xMargin = 100;
        yMargin = 100;
    }
    
    fancyTextView_ = [GSFancyTextView fancyTextViewWithFrame:CGRectMake(xMargin, yMargin, textWidth, maxHeight) markupText:text];
    fancyTextView_.matchFrameHeightToContent = YES;
    fancyTextView_.backgroundColor = [UIColor blackColor];
    fancyTextView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    // Set the drawing block
    [fancyTextView_.fancyText defineLambdaID:@"circle" withBlock:^(CGRect rect) {
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(contextRef, 255, 0, 0, 1);
        CGContextSetRGBStrokeColor(contextRef, 255, 255, 0, 1);
        CGContextFillEllipseInRect(contextRef, CGRectMake(rect.origin.x + 12, rect.origin.y + 0, 12, 12));
    }];
    
    [self.view addSubview:fancyTextView_];
    [fancyTextView_ updateDisplay];
    
    // Buttons for demo content/style switch
    [self setupButtons];
    
    // Backup original fancy text
    originalFancyText_ = [fancyTextView_.fancyText copy];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [fancyTextView_ updateDisplay];
}


- (UIButton*)commonButtonWithTitle:(NSString*)title selector:(SEL)selector {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)setupButtons {
    CGFloat y = self.view.frame.size.height - buttonHeight - buttonMargin;
    CGFloat x = buttonMargin;
    
    contentSwitchButton_ = [self commonButtonWithTitle:@"Revise" selector:@selector(demoTextSwap:)];
    contentSwitchButton_.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: contentSwitchButton_];
    
    x += (buttonMargin + buttonWidth);
    
    styleSwitchButton_ = [self commonButtonWithTitle:@"Restyle" selector:@selector(demoStyleSwap:)];
    styleSwitchButton_.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: styleSwitchButton_];
    
    x += (buttonMargin + buttonWidth);
    
    resetButton_ = [self commonButtonWithTitle:@"Reset" selector:@selector(resetTextAndStyle:)];
    resetButton_.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: resetButton_];
    resetButton_.enabled = NO;
}

- (void)demoTextSwap:(id)sender {
    [fancyTextView_.fancyText changeNodeToStyledText:@"New <span class=green>Text</span> has been <span class=green>added</span>." forID:@"xyz"];
    [fancyTextView_ updateDisplay];

    contentSwitchButton_.enabled = NO;
    resetButton_.enabled = YES;
}

- (void)demoStyleSwap:(id)sender {
    [fancyTextView_.fancyText changeAttribute:@"color" to:[UIColor greenColor] on:GSFancyTextRoot withName:nil];
    [fancyTextView_.fancyText appendStyleSheet:@".cyan {color:cyan}"];
    [fancyTextView_.fancyText applyClass:@"cyan" on:GSFancyTextClass withName:@"green"];
    [fancyTextView_ updateDisplay];
    
    styleSwitchButton_.enabled = NO;
    resetButton_.enabled = YES;
}

- (void)resetTextAndStyle:(id)sender {
    fancyTextView_.fancyText = originalFancyText_;
    [fancyTextView_ updateDisplay];
    
    GSRelease(originalFancyText_);
    originalFancyText_ = [fancyTextView_.fancyText copy];
    
    contentSwitchButton_.enabled = YES;
    styleSwitchButton_.enabled = YES;
    resetButton_.enabled = NO;
}

@end
