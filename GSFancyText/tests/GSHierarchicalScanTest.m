//
//  GSHierarchicalScan.m
//  GSFancyTextDemo
//
//  Created by Bao Lei on 1/30/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "NSScanner+GSHierarchicalScan.h"

#import <UIKit/UIKit.h>
//#import "application_headers" as required

#import <SenTestingKit/SenTestingKit.h>

@interface GSHierarchicalScan : SenTestCase

@end


@implementation GSHierarchicalScan

- (void)testScanner {
    NSString* text = @"Hello {cave man} meat ball";
    NSScanner* scanner = [NSScanner scannerWithString:text];
    NSString* result = nil;
    GSScanResult scanResult = [scanner scanUpToString:@";" endToken:@"}" intoString:&result];
    STAssertEqualObjects(@"Hello {cave man", result, @"scan failed: %@", result);
    STAssertEquals(ScanMeetEndToken, scanResult, @"scan failed: %@", result);
    
    text = @"Hi {spider; man}";
    scanner = [NSScanner scannerWithString:text];
    result = nil;
    scanResult = [scanner scanUpToString:@";" endToken:@"}" intoString:&result];
    STAssertEqualObjects(@"Hi {spider", result, @"scan failed: %@", result);
    STAssertEquals(ScanMeetTarget, scanResult, @"scan failed: %@", result);
    
    text = @"Metta World Peace";
    scanner = [NSScanner scannerWithString:text];
    result = nil;
    scanResult = [scanner scanUpToString:@";" endToken:@"}" intoString:&result];
    STAssertEqualObjects(@"Metta World Peace", result, @"scan failed: %@", result);
    STAssertEquals(ScanMeetEnd, scanResult, @"scan failed: %@", result);
    
    
    text = @"420 320 220 120";
    scanner = [NSScanner scannerWithString:text];
    result = nil;
    scanResult = [scanner scanUpToString:@"320" endToken:@"220" intoString:&result];
    STAssertEqualObjects(@"420 ", result, @"scan failed: %@", result);
    STAssertEquals(ScanMeetTarget, scanResult, @"scan failed: %@", result);
    
    text = @"420 320 220 120";
    scanner = [NSScanner scannerWithString:text];
    result = nil;
    scanResult = [scanner scanUpToString:@"120" endToken:@"220" intoString:&result];
    STAssertEqualObjects(@"420 320 ", result, @"scan failed: %@", result);
    STAssertEquals(ScanMeetEndToken, scanResult, @"scan failed: %@", result);
    STAssertEqualObjects(@"2", [scanner atCharacter], @"scan failed: %@", [scanner atCharacter]);
}

@end
