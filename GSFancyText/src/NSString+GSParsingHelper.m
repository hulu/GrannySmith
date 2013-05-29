//
//  NSString+GSParsingHelper.m
//  -GrannySmith-
//
//  Created by Bao Lei on 7/14/11.
//  Copyright 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "NSString+GSParsingHelper.h"
#import "GSFancyTextDefines.h"

#import <CoreText/CoreText.h>

const CGFloat ConservativeSpaceReservation = 1.f;

@implementation NSString(GSParsingHelper)

- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font firstLineWidth:(CGFloat)firstLineWidth limitLineCount:(int)limitLineCount {

    if (limitLineCount==1) {
        return [NSMutableArray arrayWithObject:self];
    }

    #ifdef GS_DEBUG_CODE
    GSDebugLog(@"LineBreak - The string: %@, 1st line: %f, other lines: %f", self, firstLineWidth, width);
    #endif
    
    // Prepare font
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    // Create an attributed string
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { ctFont };
    CFDictionaryRef attr = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values,
                                              sizeof(keys) / sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, (__bridge CFStringRef)self, attr);
    CFRelease(ctFont);
    
    CTTypesetterRef ts = CTTypesetterCreateWithAttributedString(attrString);
    
    // if the first line is too narrow, and we have a second line that has enough space, we should skip the first line
    NSString* temp = [NSString stringWithFormat:@" %@", self];
    CFAttributedStringRef tempAttribStr = CFAttributedStringCreate(NULL, (__bridge CFStringRef)temp, attr);
    CTTypesetterRef tempTs = CTTypesetterCreateWithAttributedString(tempAttribStr);
    BOOL firstLineTooNarrow = CTTypesetterSuggestLineBreak(tempTs, 0, firstLineWidth)<=1;
    BOOL secondLineBetter = CTTypesetterSuggestLineBreak(ts, 0, width) > CTTypesetterSuggestLineBreak(ts, 0, firstLineWidth);
    BOOL shouldSkipFirstLine = (firstLineTooNarrow && secondLineBetter && limitLineCount!=1);
    // the logic above is not perfect, e.g. if the str starts with "abcde ..." and the space in 1st line just fits "abcde" but won't fit " abcde", the space in the 1st line will be wasted, but it's not that bad, since the difference between "abcde" and ". abcde" is not that obvious. At least it's much better than getting the first word truncated to fit the 1st line while 2nd line has a lot of spaces.
    
    
    NSMutableArray* result = [NSMutableArray array];
    CFIndex start = 0;
    CFIndex len = 0;
    if (shouldSkipFirstLine) {
        [result addObject:@""];
    }
    else {
        len = CTTypesetterSuggestLineBreak(ts, start, firstLineWidth - ConservativeSpaceReservation);
        NSString* subString = [self substringWithRange:NSMakeRange(start, len)];
        [result addObject:subString];
    }
    while (start + len < self.length) {
        if (limitLineCount>0 && result.count == limitLineCount-1) {
            [result addObject:[self substringFromIndex:start+len]];
            
            CFRelease(ts);
            CFRelease(tempTs);
            CFRelease(attrString);
            CFRelease(tempAttribStr);
            CFRelease(attr);
            return GSAutoreleased(result);
        }
        start = start + len;
        len = CTTypesetterSuggestLineBreak(ts, start, width - ConservativeSpaceReservation);
        NSString* subString = [self substringWithRange:NSMakeRange(start, len)];
        [result addObject:subString];
    }
    
    CFRelease(ts);
    CFRelease(tempTs);
    CFRelease(attrString);
    CFRelease(tempAttribStr);
    CFRelease(attr);
    
    return result;
}


- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font {
    return [self linesWithWidth:width font:font firstLineWidth:width limitLineCount:0];
}

-(NSString*)stringByTrimmingLeadingWhitespace {
    if (! GSTrim(self).length) {
        return @"";
    }
    
    int i = 0;
    while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    return [self substringFromIndex:i];
}

- (NSString*)stringByTrimmingTrailingWhitespace {
    if (! GSTrim(self).length) {
        return @"";
    }
    
    int i = self.length - 1;
    while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i--;
    }
    return [self substringToIndex:i+1];
}

- (NSString*)firstNonWhitespaceCharacterSince:(int)location foundAt:(int*)foundLocation {
    if (! GSTrim(self).length) {
        return @"";
    }
    BOOL found = NO;
    int i;
    NSString* character;
    for (i=location; i<self.length; i++) {
        character = [self substringWithRange:NSMakeRange(i, 1)];
        if (GSTrim(character).length) {
            found = YES;
            break;
        }
    }
    
    if (found) {
        if (foundLocation) {
            *foundLocation = i;
        }
        return character;
    }
    else {
        if (foundLocation) {
            *foundLocation = self.length;
        }
        return @"";
    }
}

- (float)possiblyPercentageNumberWithBase: (float)base {
    NSString* trimmed = GSTrim(self);
    if (!trimmed.length) {
        return 0.f;
    }
    float number = [self floatValue];
    if ([[trimmed substringFromIndex:(trimmed.length-1)] isEqualToString:@"%"]) {
        return number * base /100.f;
    }
    else {
        return number;
    }
}

- (CGFloat)widthWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth {
    CFMutableAttributedStringRef attributedString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attributedString, CFRangeMake(0, 0), (CFStringRef)self);
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    CFAttributedStringSetAttribute(attributedString, CFRangeMake(0, CFAttributedStringGetLength(attributedString)), kCTFontAttributeName, ctFont);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(maxWidth, CGFLOAT_MAX), NULL);
    
    CFRelease(framesetter);
    CFRelease(attributedString);
    CFRelease(ctFont);
    
    return textSize.width + ConservativeSpaceReservation;
}

@end
