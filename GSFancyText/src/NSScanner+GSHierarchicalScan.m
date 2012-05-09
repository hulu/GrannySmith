//
//  NSScanner+GSHierarchicalScan.m
//  -GrannySmith-
//
//  Created by Bao Lei on 12/22/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "NSScanner+GSHierarchicalScan.h"
#import "GSFancyTextDefines.h"

@implementation NSScanner(GSHierarchicalScan)

- (GSScanResult) scanUpToString:(NSString*)target endToken:(NSString*)endToken intoString:(NSString**)intoString {
    
    // fast approach if we are targeting single characters
    if (target.length==1 && endToken.length==1) {
        NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%@%@", target, endToken]];
        [self scanUpToCharactersFromSet:set intoString:intoString];
        if (self.isAtEnd) {
            return ScanMeetEnd;
        }
        else if ([[self atCharacter] isEqualToString:target]) {
            return ScanMeetTarget;
        }
        else {
            return ScanMeetEndToken;
        }
    }
    
    int locationBeforeScan = self.scanLocation;
    
    [self scanUpToString:target intoString:intoString];
    NSString* resultString = *intoString;
    GSScanResult result;
    
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

- (GSScanResult) scanWithGSScanResultUpToString:(NSString*)target intoString:(NSString**)intoString {
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
