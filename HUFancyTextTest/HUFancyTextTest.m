//
//  HUFancyTextTest.m
//  HUFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "HUFancyText.h"

@interface HUFancyTextTest : SenTestCase

@end

@implementation HUFancyTextTest


- (void)testStyleParsing {
    UIFont* font = [UIFont systemFontOfSize:14];
    NSLog(@"font: %@", font);
    
    NSDictionary* css;
    
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
}

- (void)testMarkupParsing {
    
}

@end
