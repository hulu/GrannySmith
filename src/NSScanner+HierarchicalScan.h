//
//  NSScanner+HierachicalScan.h
//  -HUSFT-
//
//  Created by Bao Lei on 12/22/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (HierachicalScan)

typedef enum {
    ScanMeetTarget,
    ScanMeetEndToken,
    ScanMeetEnd,
} ScanResult;

/** scan up to a either a target string or an end token (whichever comes first), and store the scanned string
 * @return ScanMeetTarget if the target string is met first, ScanMeetEndToken if the end token is met first, or ScanMeetEnd is neither is found.
 * @discussion This is useful when we are parsing a structure like: {item11, item12, item13} {item21, item22} {item31, item32,}
 * When we are at the parsing all the items inside one group, we can set the target to "," , and the endToken to "}"
 * So that we can use one scanner to take care of the 2-level parsing.
 */
- (ScanResult) scanUpToString:(NSString*)target endToken:(NSString*)endToken intoString:(NSString**)intoString;

/** Similar to the standard scanUpToString:intoString, but returns a ScanResult value
 * @discussion this is useful because, say we are parsing something like "abc <def>", we first scan up to "<" where we get abc, then the scanLocation is at "<". At this time we want do something based on either the ScanResult is ScanMeetTarget of ScanMeetEnd.
 */
- (ScanResult) scanWithScanResultUpToString:(NSString*)target intoString:(NSString**)intoString;

/** The character at the current scanning position of the scanner. For debug purpose.
 */
- (NSString*)atCharacter;

@end
