//
//  NSString+GSParsingHelper.h
//  -GrannySmith-
//
//  Created by Bao Lei on 7/14/11.
//  Copyright 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

/// This category deals with line breakings of strings.

/// And added some other basic string processing methods.

#import <Foundation/Foundation.h>


@interface NSString(GSParsingHelper)

/** Breaks one string into an array of lines, based on word wrapping
 * @param width is the width of the paragraph (the confinement of the text)
 * @param font is the font the text used
 * @return an autoreleased NSMutableArray containing each line (a line is an NSString)
 */
- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font;


/** Breaks one string into an array of lines, based on word wrapping
 * @param width is the width of the paragraph (the confinement of the text)
 * @param firstWidth can override the width for the first line
 * @param font is the font the text used
 * @return an autoreleased NSMutableArray containing each line (a line is an NSString)
 */
- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font firstLineWidth:(CGFloat)firstLineWidth limitLineCount:(int)limitLineCount;


/** Returns a string that is copied from the current string and trimmed the leading whitespace
 */
- (NSString*)stringByTrimmingLeadingWhitespace;

/** Returns a string that is copied from the current string and trimmed the trailing whitespace
 */
- (NSString*)stringByTrimmingTrailingWhitespace;

/** Returns the first non-whitespace/newline character (in NSString). 
 *
 * E.g. "   xyz" gives "x", and the foundLocation will be set to 3.
 */
- (NSString*)firstNonWhitespaceCharacterSince:(int)location foundAt:(int*)foundLocation;


/** The string can be either "123 anyUnit" or "50%", if it's ended with %, return the percentage*base, otherwise just get the number.
 */
- (float)possiblyPercentageNumberWithBase: (float)base;

@end
