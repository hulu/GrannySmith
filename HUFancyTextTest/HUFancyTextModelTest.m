//
//  HUFancyTextTest.m
//  HUFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "HUFancyText.h"

@interface HUFancyTextTest : SenTestCase {
}

@end

@implementation HUFancyTextTest

- (void)setUp {
    NSString* styleSheet = @".default{color: #ffffff; vertical-align:middle}\n\
    span.green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .right{text-align: right}\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    b.blue{color: blue}\
    .center{text-align: center}\
    .limit2{line-count:2; truncate-mode:tail}";
    
    [HUFancyText parseStyleAndSetGlobal:styleSheet];
}

- (void)tearDown {
    
}


- (void)testStyleParsing {    
    NSMutableDictionary* css;
    
    css = [HUFancyText parsedStyle:@"p.small {font-size: 11; font-weigth: normal;}   p.medium {font-size:14px; font-style   :italic} p.large{   font-size:20.f}"];
    
    STAssertTrue( [[css objectForKey:@"p"] allKeys].count == 3, @"CSS classes are not all recognized");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"small"], @"class small not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"medium"], @"class medium not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"large"], @"class large not read");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"medium"] objectForKey:@"font-size"] floatValue] == 14.f, @"Font size number parsing error");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"large"] objectForKey:@"font-size"] floatValue] == 20.f, @"Font size number parsing error");
    
    css = [HUFancyText parsedStyle:@".red {color: rEd; font-weigth: bold;}   .green {font-size:14px; color:#00ff00} p.blue{   color:RgB(0,  0,255)}"];
    
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"color"], [UIColor greenColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:@"p"] objectForKey:@"blue"] objectForKey:@"color"], [UIColor blueColor], @"Color parsing error");
    
    
    css = [HUFancyText parsedStyle:@".red {color: \"red\"; font-weigth: bold;}   .green {font-size:'14px'; color:#00ff00} .blue{   attrib:'{this is the fanciest value; period.}'"];
    
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"quoted color parsing error");
    STAssertEquals( [[[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"font-size"] floatValue], 14.f, @"quoted size parsing error");
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"blue"] objectForKey:@"attrib"], @"{this is the fanciest value; period.}", @"quoted string parsing error");
}

- (void)testGlobalStyle {
    NSMutableDictionary* globalStyle = [HUFancyText globalStyle];
    STAssertEquals([[[[globalStyle objectForKey:HUFancyTextDefaultClass] objectForKey:@"right"] objectForKey:@"text-align"] intValue], TextAlignRight, @"global style retrieving error");
}

- (void)testMarkupParsing {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=green>c</b>e"];
    // todo: a lot of weird cases to test
    
}

@end
