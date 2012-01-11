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
CGFloat const buttonWidth = 100;
CGFloat const buttonHeight = 40;
CGFloat const buttonMargin = 5;

@interface HUDemoViewController (Private)

- (void)setupButtons;
- (void)demoTextSwap:(id)sender;
- (void)demoStyleSwap:(id)sender;
- (void)resetTextAndStyle:(id)sender;
@end

@implementation HUDemoViewController

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
    
    NSString* style = @".default{color: #ffffff; vertical-align:middle}\n\
    span.green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .right{text-align: right}\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    .center{text-align: center}\
    center {text-align: center}\
    .limit2{line-count:2; truncate-mode:tail}";
    
    [HUFancyText parseStyleAndSetGlobal:style];
    
    
    // Creating the fancy text object
    
    NSString* text = @"<em>Hello</em> iOS world. <span id='abc' class='yellow'>The sunrise <strong>and</strong> the sunset.</span> <strong>drawing</strong> <lambda id=circle width=36 height=12 vertical-align=baseline> some shapes <p><span class='green right'> A new <strong><em>paragraph</em></strong> with different alignments</span> and <span class=blue>different</span> colors!</p><p>A&lt;&amp;&gt;<span class=center>B</span></p>Ah I am <font style=color:red>going</font> to be a line.<p class=right>1<strong>2</strong>3</p><p id=eee class=limit2>Really a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a lot of a <strong>lot</strong> of a lot of a lot of texts</p> END<f";
    
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:text];
    
    // Set the drawing block
    void(^drawStarBlock) (CGRect) = ^(CGRect rect) {
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(contextRef, 255, 0, 0, 1);
        CGContextSetRGBStrokeColor(contextRef, 255, 255, 0, 1);
        CGContextFillEllipseInRect(contextRef, CGRectMake(rect.origin.x + 12, rect.origin.y + 0, 12, 12));
    };
    [fancyText setBlock:drawStarBlock forLambdaID:@"circle"];

    // Put on the view

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
    [fancyTextView_ updateWithCurrentFrame];
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
    [fancyTextView_.fancyText changeNodeToStyledText:@"New <span class=green>Text</span> has been <span class=green>added</span>." forID:@"abc"];
    [fancyTextView_ updateWithCurrentFrame];

    self.contentSwitchButton.enabled = NO;
    self.resetButton.enabled = YES;
}

- (void)demoStyleSwap:(id)sender {
    [fancyTextView_.fancyText changeAttribute:@"color" to:[UIColor greenColor] on:HUFancyTextRoot withName:nil];
    [fancyTextView_.fancyText appendStyleSheet:@".cyan {color:cyan}"];
    [fancyTextView_.fancyText applyClass:@"cyan" on:HUFancyTextClass withName:@"green"];
    [fancyTextView_ updateWithCurrentFrame];
    
    self.styleSwitchButton.enabled = NO;
    self.resetButton.enabled = YES;
}

- (void)resetTextAndStyle:(id)sender {
    fancyTextView_.fancyText = originalFancyText_;
    [fancyTextView_ updateWithCurrentFrame];
    
    HURelease(originalFancyText_);
    originalFancyText_ = [fancyTextView_.fancyText copy];
    
    self.contentSwitchButton.enabled = YES;
    self.styleSwitchButton.enabled = YES;
    self.resetButton.enabled = NO;
}

@end
