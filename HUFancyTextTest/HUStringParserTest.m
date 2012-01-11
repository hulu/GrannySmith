//
//  HUStringParserTest.m
//  HUFancyTextDemo
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "NSString+ParsingHelper.h"
#import "HUFancyTextDefines.h"

@interface HUStringParserTest : SenTestCase {
    NSString* testString_;
}

@end

@implementation HUStringParserTest

- (void)setUp {
    testString_ = @"This application requires a Hulu Plus subscription.\n\
    \n\
    Hulu Plus. The Hulu You Know + More Shows and Movies + More Ways to Watch. Stream thousands of episodes from hundreds of current and classic TV shows to your iPad, iPhone 3GS, iPhone 4, 3rd generation iPod Touch, computer, TV, and other devices with a Hulu Plus subscription. \n\
    \n\
    Hulu Plus subscribers receive many exclusive benefits";
    HURetain(testString_);
}

- (void)tearDown {
    HURelease(testString_);
}

- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}

- (void)testNormalBreak {
    
    UIFont* systemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGFloat limitWidth = 300;
    NSArray* testArray = [testString_ linesWithWidth:limitWidth font:systemFont];
    //DebugLog(@"test array: %@", testArray);
    STAssertTrue(testArray.count == 15, @"Line break didn't give line count result");
    
    NSString* unmatched = HUAutoreleased([testString_ copy]);
    for (int i=0; i<testArray.count; i++) {
        NSString* line = [testArray objectAtIndex:i];
        STAssertTrue([line sizeWithFont:systemFont].width <= limitWidth, @"Line %d is longer than limit", i);
        unmatched = [unmatched stringByReplacingOccurrencesOfString:trim(line) withString:@"" options:NSLiteralSearch range:NSMakeRange(0, line.length)];
        unmatched = trim(unmatched);
    }
    STAssertTrue(trim(unmatched).length == 0, @"There's some text that the line breaker didn't find: %@", unmatched);
}


- (void)testLineLimit {
    
    UIFont* systemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGFloat limitWidth = 300;
    
    for (int lineCount =1; lineCount<=1; lineCount ++) {
        NSArray* testArray = [testString_ linesWithWidth:limitWidth font:systemFont firstLineWidth:limitWidth limitLineCount:lineCount];
        STAssertTrue(testArray.count == lineCount, @"Line breaker's line count limit not working properly");
        
        NSString* unmatched = HUAutoreleased([testString_ copy]);
        for (int i=0; i<testArray.count - 1; i++) {
            NSString* line = [testArray objectAtIndex:i];
            STAssertTrue([line sizeWithFont:systemFont].width <= limitWidth, @"Line %d is longer than limit", i);
            unmatched = [unmatched stringByReplacingOccurrencesOfString:trim(line) withString:@"" options:NSLiteralSearch range:NSMakeRange(0, line.length)];
            unmatched = trim(unmatched);
        }
        if (lineCount==1) {
            STAssertTrue([testString_ isEqualToString:[testArray objectAtIndex:0]]==YES, @"One line limit should give exactly the same string");
        }
        else {
            STAssertTrue(trim(unmatched).length == 0, @"There's some text that the line breaker didn't find: %@", unmatched);
        }
    }
}

- (void)testShorterFirstLine {
    UIFont* systemFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    CGFloat limitWidth = 300;
    CGFloat firstLine = 100;
    NSArray* testArray = [testString_ linesWithWidth:limitWidth font:systemFont firstLineWidth:firstLine limitLineCount:0];
    
    NSString* unmatched = HUAutoreleased([testString_ copy]);
    for (int i=0; i<testArray.count; i++) {
        NSString* line = [testArray objectAtIndex:i];
        if (i==0) {
            STAssertTrue([line sizeWithFont:systemFont].width <= firstLine, @"Line %d is longer than limit", i);
        }
        else {
            STAssertTrue([line sizeWithFont:systemFont].width <= limitWidth, @"Line %d is longer than limit", i);
        }
        unmatched = [unmatched stringByReplacingOccurrencesOfString:trim(line) withString:@"" options:NSLiteralSearch range:NSMakeRange(0, line.length)];
        unmatched = trim(unmatched);
    }
    STAssertTrue(trim(unmatched).length == 0, @"There's some text that the line breaker didn't find: %@", unmatched);
}

@end
