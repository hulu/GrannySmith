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

@interface GSFancyTextDemoViewController (Private)

- (void)setupButtons;
- (void)demoTextSwap:(id)sender;
- (void)demoStyleSwap:(id)sender;
- (void)resetTextAndStyle:(id)sender;
@end

@implementation GSFancyTextDemoViewController

@synthesize fancyTextView = fancyTextView_;
@synthesize originalFancyText = originalFancyText_;
@synthesize contentSwitchButton = contentSwitchButton_;
@synthesize styleSwitchButton = styleSwitchButton_;
@synthesize resetButton = resetButton_;

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
    
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:text];
    
    // Set the drawing block
    [fancyText defineLambdaID:@"circle" withBlock:^(CGRect rect) {
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(contextRef, 255, 0, 0, 1);
        CGContextSetRGBStrokeColor(contextRef, 255, 255, 0, 1);
        CGContextFillEllipseInRect(contextRef, CGRectMake(rect.origin.x + 12, rect.origin.y + 0, 12, 12));
    }];

    // Put on the view

    CGFloat xMargin = 10;
    CGFloat yMargin = 30;
    if ([[[UIDevice currentDevice] model] rangeOfString:@"iPad"].location!=NSNotFound) {
        xMargin = 100;
        yMargin = 100;
    }
    fancyTextView_ = [[GSFancyTextView alloc] initWithFrame:CGRectMake(xMargin, yMargin, textWidth, maxHeight) fancyText:fancyText];
    fancyTextView_.matchFrameHeightToContent = YES;
    fancyTextView_.backgroundColor = [UIColor blackColor];
    fancyTextView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:fancyTextView_];
    [fancyTextView_ updateDisplay];
    
    // Buttons for demo content/style switch
    [self setupButtons];
    
    // Backup original fancy text
    originalFancyText_ = [  fancyText copy];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fancyTextView = nil;
    self.originalFancyText = nil;
    
    self.contentSwitchButton = nil;
    self.styleSwitchButton = nil;
    self.resetButton = nil;
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
    
    self.contentSwitchButton = [self commonButtonWithTitle:@"Revise" selector:@selector(demoTextSwap:)];
    self.contentSwitchButton.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: self.contentSwitchButton];
    
    x += (buttonMargin + buttonWidth);
    
    self.styleSwitchButton = [self commonButtonWithTitle:@"Restyle" selector:@selector(demoStyleSwap:)];
    self.styleSwitchButton.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: self.styleSwitchButton];
    
    x += (buttonMargin + buttonWidth);
    
    self.resetButton = [self commonButtonWithTitle:@"Reset" selector:@selector(resetTextAndStyle:)];
    self.resetButton.frame = CGRectMake(x, y, buttonWidth, buttonHeight);
    [self.view addSubview: self.resetButton];
    self.resetButton.enabled = NO;
}

- (void)demoTextSwap:(id)sender {
    [fancyTextView_.fancyText changeNodeToStyledText:@"New <span class=green>Text</span> has been <span class=green>added</span>." forID:@"xyz"];
    [fancyTextView_ updateDisplay];

    self.contentSwitchButton.enabled = NO;
    self.resetButton.enabled = YES;
}

- (void)demoStyleSwap:(id)sender {
    [fancyTextView_.fancyText changeAttribute:@"color" to:[UIColor greenColor] on:GSFancyTextRoot withName:nil];
    [fancyTextView_.fancyText appendStyleSheet:@".cyan {color:cyan}"];
    [fancyTextView_.fancyText applyClass:@"cyan" on:GSFancyTextClass withName:@"green"];
    [fancyTextView_ updateDisplay];
    
    self.styleSwitchButton.enabled = NO;
    self.resetButton.enabled = YES;
}

- (void)resetTextAndStyle:(id)sender {
    fancyTextView_.fancyText = originalFancyText_;
    [fancyTextView_ updateDisplay];
    
    GSRelease(originalFancyText_);
    originalFancyText_ = [fancyTextView_.fancyText copy];
    
    self.contentSwitchButton.enabled = YES;
    self.styleSwitchButton.enabled = YES;
    self.resetButton.enabled = NO;
}

@end
