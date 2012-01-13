//
//  NSString+GSParsingHelper.h
//  -GrannySmith-
//
//  Created by Bao Lei on 7/14/11.
//  Copyright 2011 hulu. All rights reserved.
//

/** This category deals with line breakings of strings
 */

#import <Foundation/Foundation.h>


@interface NSString (GSParsingHelper)

/** breaks one string into an array of lines, based on word wrapping
 * @param width is the width of the paragraph (the confinement of the text)
 * @param font is the font the text used
 * @return an autoreleased NSMutableArray containing each line (a line is an NSString)
 */
- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font;


/** breaks one string into an array of lines, based on word wrapping
 * @param width is the width of the paragraph (the confinement of the text)
 * @param firstWidth can override the width for the first line
 * @param font is the font the text used
 * @return an autoreleased NSMutableArray containing each line (a line is an NSString)
 */
- (NSMutableArray*) linesWithWidth:(CGFloat)width font:(UIFont*)font firstLineWidth:(CGFloat)firstLineWidth limitLineCount:(int)limitLineCount;


/** returns a string that is copied from the current string and trimmed the leading whitespace
 */
- (NSString*)stringByTrimmingLeadingWhitespace;

/** returns a string that is copied from the current string and trimmed the trailing whitespace
 */
- (NSString*)stringByTrimmingTrailingWhitespace;

/** returns the first non-whitespace/newline character (in NSString)
 * @example @"   abc" gives @"a". And the foundLocation will be set to 3
 * @return @"" if the string is totally made up with whitespace chars
 */
- (NSString*)firstNonWhitespaceCharacterSince:(int)location foundAt:(int*)foundLocation;

@end
