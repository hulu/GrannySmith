////
////  GSStringParserTest.m
////  GSFancyTextTest
////
////  Created by Bao Lei on 1/10/12.
////  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
////
//
//#import <SenTestingKit/SenTestingKit.h>
//#import <UIKit/UIKit.h>
//#import "NSString+GSParsingHelper.h"
//#import "GSFancyTextDefines.h"
//
//@interface GSParsingHelperTest : SenTestCase {
//    NSString* testString_;
//    int limitWidth_;
//    UIFont* systemFont_;
//}
//
//@end
//
//@implementation GSParsingHelperTest
//
//- (void)setUp {
//    testString_ = @"This application requires a Hulu Plus subscription.\n\
//    Hulu Plus. The Hulu You Know + More Shows and Movies + More Ways to Watch. Stream thousands of episodes from hundreds of current and classic TV shows to your iPad, iPhone 3GS, iPhone 4, 3rd generation iPod Touch, computer, TV, and other devices with a Hulu Plus subscription.\n\
//    Hulu Plus subscribers receive many exclusive benefits";
//    
//    limitWidth_ = 300;
//    
//    systemFont_ = GSRetained([UIFont systemFontOfSize:[UIFont systemFontSize]]);
//    
//    GSRetain(testString_);
//}
//
//- (void)tearDown {
//    GSRelease(testString_);
//    GSRelease(systemFont_);
//}
//
//- (void)testMath
//{
//    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
//}
//
///// the general test, making sure that line and width limits are met, no texts are lost
//- (NSArray*)standardTestWithString:(NSString*)string lineWidth:(CGFloat)lineWidth font:(UIFont*)font firstLineWidth:(CGFloat)firstLineWidth limitLineCount:(int)limitLineCount {
//    NSArray* testArray = [string linesWithWidth:lineWidth font:font firstLineWidth:firstLineWidth limitLineCount:limitLineCount];
//    
//    for (int i=0; i<testArray.count; i++) {
//        #ifdef GS_DEBUG_CODE
//        GSDebugLog(@"%d: %@", i, [testArray objectAtIndex:i]);
//        #endif
//    }
//    
//    if (limitLineCount>0) {
//        STAssertTrue(testArray.count <= limitLineCount, @"too many lines: %d", testArray.count);
//    }
//    
//    NSString* unmatched = GSAutoreleased([string copy]);
//    for (int i=0; i<testArray.count; i++) {
//        NSString* line = [testArray objectAtIndex:i];
//        if (limitLineCount==0 || i!=testArray.count-1) {
//            STAssertTrue([line sizeWithFont:systemFont_].width <= limitWidth_, @"Line %d is longer than limit", i);
//        }
//        int lengthToTrim = line.length;
//        if (lengthToTrim > unmatched.length) {
//            lengthToTrim = unmatched.length;
//        }
//        unmatched = [unmatched stringByReplacingOccurrencesOfString:GSTrim(line) withString:@"" options:NSLiteralSearch range:NSMakeRange(0, lengthToTrim)];
//        unmatched = GSTrim(unmatched);
//    }
//    STAssertTrue(GSTrim(unmatched).length == 0, @"There's some text that the line breaker didn't find: %@", unmatched);
//    return testArray;
//}
//
//- (NSArray*)standardTestWithString:(NSString*)string {
//    return [self standardTestWithString:string lineWidth:limitWidth_ font:systemFont_ firstLineWidth:limitWidth_ limitLineCount:0];
//}
//
//- (void)testNormalBreak {
//    NSArray* testArray = [self standardTestWithString:testString_];
//    STAssertTrue(testArray.count == 13, @"Line break didn't give line count result");
//}
//
//- (void)testLineLimit {
//    
//    for (int lineCount =1; lineCount<=1; lineCount ++) {
//        NSArray* testArray = [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:limitWidth_ limitLineCount:lineCount];
//        STAssertTrue(testArray.count == lineCount, @"Line breaker's line count limit not working properly");
//        
//        if (lineCount==1) {
//            STAssertTrue([testString_ isEqualToString:[testArray objectAtIndex:0]]==YES, @"One line limit should give exactly the same string");
//        }
//    }
//}
//
//- (void)testShorterFirstLine {
//    CGFloat firstLine = 100;
//    [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:firstLine limitLineCount:0];
//}
//
//- (void)testInternational {
//    NSString* jpTestString = @"マイリストに動画が登録されていません。\n動画を登録するには、動画の紹介画像をホールドし、マイリストに追加してください。";
//    NSArray* lines = [self standardTestWithString:jpTestString];
//    STAssertTrue(lines.count==4, @"Japanese line break failed: %d lines", lines.count);
//    
//    NSString* zhTestString = @"NBC与百脑汇合作，为您献上标志性的系列喜剧节目。";
//    lines = [self standardTestWithString:zhTestString lineWidth:100.f font:systemFont_ firstLineWidth:100.f limitLineCount:0];
//    STAssertTrue(lines.count==4, @"Chinese line break failed: %d lines", lines.count);
//}
//
//- (void)testMisc {
//    [self standardTestWithString: @"NBC in association with Broadway Video Enterprises bring you the landmark sketch comedy series."];
//    [self standardTestWithString: @"Lovable oaf Peter Griffin is a middle-class New Englander surrounded by his loving wife, Lois, a former beauty queen; daughter, Meg; sons Chris and baby Stewie; and the talking family dog, Brian. While Peter bumbles through life, diabolical Stewie is set on conquering the world, and a brainy Brian puts the moves on any blonde that comes his way."];
//    [self standardTestWithString: @"The life of the head writer at a late-night television variety show. From the creator and stars of SNL comes this workplace comedy. A brash network executive bullies head writer Liz Lemon into hiring an unstable movie star. A self-obsessed celeb, an arrogant boss, and a sensitive writing staff challenge Lemon to run a successful program -- without losing her mind."];
//}
//
//- (void)testLineLimitEdgeCase {
//    CGFloat firstCharWidth = [[testString_ substringWithRange:NSMakeRange(0, 1)] sizeWithFont:systemFont_].width;
//    NSArray* lines = [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:firstCharWidth*2 limitLineCount:0];
//    int firstLineLength = [[lines objectAtIndex:0] length];
//    int secondLineLength = [[lines objectAtIndex:1] length];
//    STAssertEquals(firstLineLength, 0, @"first line should be empty");
//    STAssertTrue(secondLineLength > 0, @"second line shouldn't be empty");
//    
//    lines = [self standardTestWithString:testString_ lineWidth:limitWidth_ font:systemFont_ firstLineWidth:1 limitLineCount:0];
//    firstLineLength = [[lines objectAtIndex:0] length];
//    secondLineLength = [[lines objectAtIndex:1] length];
//    STAssertEquals(firstLineLength, 0, @"first line should be empty");
//    STAssertTrue(secondLineLength > 0, @"second line shouldn't be empty");
//    
//    lines = [self standardTestWithString:testString_ lineWidth:firstCharWidth*2 font:systemFont_ firstLineWidth:firstCharWidth*2 limitLineCount:0];
//    firstLineLength = [[lines objectAtIndex:0] length];
//    secondLineLength = [[lines objectAtIndex:1] length];
//    STAssertTrue(firstLineLength > 0, @"first line shouldn't be empty");
//    STAssertTrue(secondLineLength > 0, @"second line shouldn't be empty");
//    
//    lines = [self standardTestWithString:testString_ lineWidth:1 font:systemFont_ firstLineWidth:1 limitLineCount:0];
//    firstLineLength = [[lines objectAtIndex:0] length];
//    secondLineLength = [[lines objectAtIndex:1] length];
//    STAssertTrue(firstLineLength == 1, @"first line should be 1 char. but it's %d", firstLineLength);
//    STAssertTrue(secondLineLength == 1, @"second line should be 1 char, but it's %d", secondLineLength);
//}
//
//- (void)testLeadingSpace {
//    NSString* testString = @"    hallelujah hallelujah hallelujah hallelujah   hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah hallelujah   \n     RSS";
//    NSArray* lines = [self standardTestWithString:testString];
//    NSString* line = [lines objectAtIndex:0];
//    NSString* firstChar = [line substringToIndex:1];
//    STAssertEqualObjects(firstChar, @" ", @"first line starting with %@", firstChar);
//    line = [lines objectAtIndex:1];
//    firstChar = [line substringToIndex:1];
//    STAssertTrue(![firstChar isEqualToString: @" "], @"second line starting with %@", firstChar);
//    
//    for (int i=2; i<lines.count; i++) {
//        line = [lines objectAtIndex:i];
//        if (line.length) {
//            firstChar = [line substringToIndex:1];
//            if ([firstChar isEqualToString:@" "]) {
//                NSString* firstRealChar = [line firstNonWhitespaceCharacterSince:0 foundAt:nil];
//                STAssertEqualObjects(firstRealChar, @"R", @"seeing leading space at line: %@", line);
//            }
//        }
//    }
//}
//
//- (void)testNumberParsing {
//    float number = [@"5" possiblyPercentageNumberWithBase:10];
//    STAssertTrue(number == 5, @"wrong number parsing: %f", number);
//    
//    number = [@"12 px" possiblyPercentageNumberWithBase:10];
//    STAssertTrue(number == 12, @"wrong number parsing: %f", number);
//    
//    number = [@"23 human beings" possiblyPercentageNumberWithBase:10];
//    STAssertTrue(number == 23, @"wrong number parsing: %f", number);
//    
//    number = [@"2.3 cows" possiblyPercentageNumberWithBase:10];
//    STAssertEqualsWithAccuracy(number, 2.3f, 0.1, @"wrong number parsing: %f", number);
//    
//    number = [@"50 %" possiblyPercentageNumberWithBase:10];
//    STAssertTrue(number == 5, @"wrong number parsing: %f", number);
//    
//    number = [@"20%" possiblyPercentageNumberWithBase:20];
//    STAssertTrue(number == 4, @"wrong number parsing: %f", number);
//    
//    number = [@" 30 %   " possiblyPercentageNumberWithBase:20];
//    STAssertTrue(number == 6, @"wrong number parsing: %f", number);
//    
//    number = [@"30.123% " possiblyPercentageNumberWithBase:20];
//    STAssertEqualsWithAccuracy(number, 6.0246f, 0.0001, @"wrong number parsing: %f", number);
//}
//
//@end
