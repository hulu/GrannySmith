//
//  NSScanner+HierachicalScan.m
//  i2
//
//  Created by Bao Lei on 12/22/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import "NSScanner+HierarchicalScan.h"
#import "HUFancyTextDefines.h"

@implementation NSScanner (HierachicalScan)

- (ScanResult) scanUpToString:(NSString*)target endToken:(NSString*)endToken intoString:(NSString**)intoString {
    int locationBeforeScan = self.scanLocation;
    
    [self scanUpToString:target intoString:intoString];
    NSString* resultString = *intoString;
    ScanResult result;
    
    int endTokenLocation = [resultString rangeOfString:endToken].location;
    if (endTokenLocation != NSNotFound) {
        self.scanLocation = locationBeforeScan + endTokenLocation;
        if (endTokenLocation==0) {
            *intoString = @"";
        }
        else {
            *intoString = [resultString substringToIndex:endTokenLocation];
        }
        result = ScanMeetEndToken;
    }
    else {
        result = [self isAtEnd]? ScanMeetEnd : ScanMeetTarget;
    }
    
    return result;
}

- (ScanResult) scanWithScanResultUpToString:(NSString*)target intoString:(NSString**)intoString {
    [self scanUpToString:target intoString:intoString];
    if ([self isAtEnd]) {
        return ScanMeetEnd;
    }
    else {
        return ScanMeetTarget;
    }
}

- (NSString*)atCharacter {
    NSString* at;
    if (!self.isAtEnd) {
        at = [self.string substringWithRange:NSMakeRange(self.scanLocation, 1)];
    }
    else {
        at = @"End";
    }
    return at;
}

@end
