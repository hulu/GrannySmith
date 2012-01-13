//
//  GSStringParserTest.m
//  GSFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "NSString+GSParsingHelper.h"
#import "GSFancyTextDefines.h"

@interface GSParsingHelperTest : SenTestCase {
    NSString* testString_;
    int limitWidth_;
    UIFont* systemFont_;
}

@end

@implementation GSParsingHelperTest

- (void)setUp {
    testString_ = @"This application requires a Hulu Plus subscription.\
\n    Hulu Plus. The Hulu You Know + More Shows and Movies + More Ways to Watch. Stream thousands of episodes from hundreds of current and classic TV shows to your iPad, iPhone 3GS, iPhone 4, 3rd generation iPod Touch, computer, TV, and other devices with a Hulu Plus subscription.\
\n    Hulu Plus subscribers receive many exclusive benefits";
    
    limitWidth_ = 300;
    
    systemFont_ = GSRetained([UIFont systemFontOfSize:[UIFont systemFontSize]]);
    
    GSRetain(testString_);
}

- (void)tearDown {
    GSRelease(testString_);
    GSRelease(systemFont_);
}

- (void)testMath
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}


- (NSArray*)standardTestWithString:(NSString*)string lineWidth:(CGFloat)lineWidth font:(UIFont*)font firstLineWidth:(CGFloat)firstLineWidth limitLineCount:(int)limitLineCount {
    NSArray* testArray = [string linesWithWidth:lineWidth font:font firstLineWidth:firstLineWidth limitLineCount:limitLineCount];
    NSLog(@"result array:\n%@", testArray);
    
    if (limitLineCount>0) {
        STAssertTrue(testArray.count <= limitLineCount, @"too many lines: %d", testArray.count);
    }
    
    NSString* unmatched = GSAutoreleased([string copy]);
    for (int i=0; i<testArray.count; i++) {
        NSString* line = [testArray objectAtIndex:i];
        if (limitLineCount==0 || i!=testArray.count-1) {
            STAssertTrue([line sizeWithFont:systemFont_].width <= limitWidth_, @"Line %d is longer than limit", i);
        }
        unmatched = [unmatched stringByReplacingOccurrencesOfString:trim(line) withString:@"" options:NSLiteralSearch range:NSMakeRange(0, line.length)];
        unmatched = trim(unmatched);
    }
    STAssertTrue(trim(unmatched).length == 0, @"There's some text that the line breaker didn't find: %@", unmatched);
    return testArray;
}

- (NSArray*)standardTestWithString:(NSString*)string {
    return [self standardTestWithString:string lineWidth:limitWidth_ font:systemFont_ firstLineWidth:limitWidth_ limitLineCount:0];
}

- (void)testNormalBreak {
    
    NSArray* testArray = [self standardTestWithString:testString_];
    NSLog(@"result array:\n%@", testArray);
    
    STAssertTrue(testArray.count == 13, @"Line break didn't give line count result");
}

- (void)testLineLimit {
    
    for (int lineCount =1; lineCount<=1; lineCount ++) {
        NSArray* testArray = [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:limitWidth_ limitLineCount:lineCount];
        STAssertTrue(testArray.count == lineCount, @"Line breaker's line count limit not working properly");
        
        if (lineCount==1) {
            STAssertTrue([testString_ isEqualToString:[testArray objectAtIndex:0]]==YES, @"One line limit should give exactly the same string");
        }
    }
}

- (void)testShorterFirstLine {
    CGFloat firstLine = 100;
    [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:firstLine limitLineCount:0];
}

- (void)testJapanese {
//    NSString* jpTestString = @"マイリストに動画が登録されていません。\n動画を登録するには、動画の紹介画像をホールドし、マイリストに追加してください。";
}

- (void)testMisc {
    [self standardTestWithString: @"NBC in association with Broadway Video Enterprises bring you the landmark sketch comedy series."];
    [self standardTestWithString: @"Lovable oaf Peter Griffin is a middle-class New Englander surrounded by his loving wife, Lois, a former beauty queen; daughter, Meg; sons Chris and baby Stewie; and the talking family dog, Brian. While Peter bumbles through life, diabolical Stewie is set on conquering the world, and a brainy Brian puts the moves on any blonde that comes his way."];
    [self standardTestWithString: @"The life of the head writer at a late-night television variety show. From the creator and stars of SNL comes this workplace comedy. A brash network executive bullies head writer Liz Lemon into hiring an unstable movie star. A self-obsessed celeb, an arrogant boss, and a sensitive writing staff challenge Lemon to run a successful program -- without losing her mind."];
}

@end
