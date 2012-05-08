//
//  NSScanner+GSHierarchicalScan.h
//  -GrannySmith-
//
//  Created by Bao Lei on 12/22/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

/// Some additions to NSScanner

#import <Foundation/Foundation.h>

@interface NSScanner(GSHierarchicalScan)

typedef enum {
    ScanMeetTarget,
    ScanMeetEndToken,
    ScanMeetEnd,
} GSScanResult;

/** Scan up to a either a target string or an end token (whichever comes first), and store the scanned string
 *
 * This is useful when we are parsing a structure like: {item11, item12, item13} {item21, item22} {item31, item32,}
 *
 * When we are at the parsing all the items inside one group, we can set the target to "," , and the endToken to "}"
 *
 * So that we can use one scanner to take care of the 2-level parsing.
 *
 * @return ScanMeetTarget if the target string is met first, ScanMeetEndToken if the end token is met first, or ScanMeetEnd is neither is found.
 */
- (GSScanResult) scanUpToString:(NSString*)target endToken:(NSString*)endToken intoString:(NSString**)intoString;

/** Similar to the standard scanUpToString:intoString, but returns a GSScanResult value
 *
 * This is useful because, say we are parsing something like "123 <456>", we first scan up to "<" where we get 123, then the scanLocation is at "<". At this time we want do something based on either the GSScanResult is ScanMeetTarget of ScanMeetEnd.
 */
- (GSScanResult) scanWithGSScanResultUpToString:(NSString*)target intoString:(NSString**)intoString;

/** The character at the current scanning position of the scanner. Mainly for debug purpose.
 */
- (NSString*)atCharacter;

@end
