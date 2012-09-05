//
//  GSFancyText.m
//  -GrannySmith-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "GSFancyText.h"
#import "NSString+GSParsingHelper.h"
#import "NSString+GSHTML.h"
#import "NSScanner+GSHierarchicalScan.h"
#import <objc/message.h>

/// globalStyleDictionary_ is a parsed style dictionary that can be accessed globally
static NSMutableDictionary* globalStyleDictionary_;

/// lineID_ is a tracker or P tags. Each P tag has a unique lineID so line breaking is based on that.
static int lineID_ = 1;

@interface GSFancyText (Private)


/** Part of newParsedStyle:
 * Parse the color:red; size:17; etc inside a style sheet
 */
+ (NSMutableDictionary*)newParsedStyleAttributesFromScanner:(NSScanner*)scanner;

/** part of newParsedMarkupString:withStyleDict:
 * Parse the "span class=xyz", "/p", etc, inside the markup tags
 */
+ (NSMutableDictionary*)newStyleFromCurrentTagInScanner:(NSScanner*)scanner withStyleDict:(NSDictionary*)styleDict;

/** A factory-like interface method for creating value objects (e.g. color, text align mode)
 */
+ (NSObject*)parseValue: (NSString*)value forKey:(NSString*)key intoDictionary:(NSMutableDictionary*)dict;

/** Parse color and store into the dict
 * @return a UIColor object
 * @param value can be rgb(255,255,255), #ffffff, red, blue, etc. When text is used, there has to be a [UIColor xxxColor] method to match it
 * @note default return is black is the value isn't recoginized
 */
+ (UIColor*)parseColor:(NSString*)value intoDictionary:(NSMutableDictionary*)dict;

/** Parse text align and store into the dict
 * @param value should be left, right or center
 * @return an NSNumber with GSTextAlign integer
 */
+ (NSNumber*)parseTextAlign: (NSString*)value intoDictionary:(NSMutableDictionary*)dict;

/** Parse vertical align and store into the dict
 * @param value should be middle, top or bottom
 * @return an NSNumber with GSVerticalAlign integer
 */
+ (NSNumber*)parseVerticalAlign: (NSString*)value intoDictionary:(NSMutableDictionary*)dict;

/** Parse truncate mode and store into the dict
 * @param value should be tail, head, middle, clip
 * @return an NSNumber with a UILineBreakMode value
 */
+ (NSNumber*)parseTruncationMode: (NSString*)value intoDictionary:(NSMutableDictionary*)dict;

/** If the fancyText isn't parsed yet, parse it and return the result tree.
 */
- (GSMarkupNode*)parseIfUnparsed;

/** Get a list of GSMarkupNode objects based on a class name or ID
 * @return a retained array. An emtpy array if there's no match.
 * @note call this after parsing 
 */
- (NSArray*)newChangeListBasedOnType:(GSFancyTextReferenceType)type withName:(NSString*)name;

/** get styles from a class defined in the style dictionary (parsed from css-like style sheet)
 */
- (NSMutableDictionary*)newStylesFromClassName:(NSString*)className elementName:(NSString*)elementName;

/** Append a parsed style dictionary to the current fancyText
 */
- (void)appendStyleDict:(NSMutableDictionary*)styleDict;

@end

@implementation GSFancyText

@synthesize lambdaBlocks = lambdaBlocks_;
@synthesize style = style_;
@synthesize width = width_;
@synthesize maxHeight = maxHeight_;
@synthesize text = text_;

#ifdef GS_ARC_ENABLED
#else
- (void)dealloc {
    GSRelease(style_);
    GSRelease(text_);
    GSRelease(lines_);
    GSRelease(parsedTree_);
    GSRelease(lambdaBlocks_);
    [super dealloc];
}
#endif

- (id)initWithMarkupText:(NSString*)text styleDict:(NSMutableDictionary*)styleDict width:(CGFloat)width maxHeight:(CGFloat)maxHeight {
    if ((self = [super init])) {
        width_ = width;
        maxHeight_ = maxHeight;
        if (globalStyleDictionary_) {
            self.style = globalStyleDictionary_;
            if (styleDict != globalStyleDictionary_) {
                [self appendStyleDict:styleDict];
            }
        }
        else {
            self.style = styleDict;
        }
        self.text = text;
        contentHeight_ = 0.f;
        contentWidth_ = 0.f;
        lambdaBlocks_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    }
    return self;
}

- (id)initWithMarkupText:(NSString*)text {
    return [self initWithMarkupText:text styleDict:nil width:0 maxHeight:0];
}


- (id)initWithParsedStructure:(GSMarkupNode*)tree {
    if ((self = [super init])) {
        width_ = 0.f;
        maxHeight_ = 0.f;
        parsedTree_ = [tree copy];
        lambdaBlocks_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
        self.style = globalStyleDictionary_;
        self.text = @"";
    }
    return self;
}

- (void)appendStyleSheet:(NSString *)newStyleSheet {
    NSMutableDictionary* styleDict = [[self class] parsedStyle:newStyleSheet];
    [self appendStyleDict: styleDict];
}

- (void)appendStyleDict:(NSMutableDictionary*)styleDict {
    for (NSString* element in [styleDict allKeys]) {
        if ([[self.style allKeys] containsObject:element]) {
            [[self.style objectForKey:element] setValuesForKeysWithDictionary: [styleDict objectForKey:element]];
        }
        else {
            [self.style setObject:[styleDict objectForKey:element] forKey:element];
        }
    }
}


- (NSMutableArray*)lines {
    return lines_;
}

- (GSMarkupNode*)parsedResultTree {
    return parsedTree_;
}

- (NSString*)pureText {
    if (!parsedTree_) {
        [self parseStructure];
    }
    
    NSArray* segments_ = [parsedTree_ newDepthFirstOrderDataArray];
    
    NSMutableString* texts = [[NSMutableString alloc] init];
    
    int lineID = 0;
    int previousLineID = 0;
    // if there is a forced line break, we add a stop sign.
    
    for (NSMutableDictionary* segment in segments_) {
        lineID = [[segment objectForKey:GSFancyTextLineIDKey] intValue];
        if (lineID != previousLineID && texts.length) {
            [texts appendString:@". "];
        }
        NSString* text = [segment objectForKey: GSFancyTextTextKey];
        if (text) {
            [texts appendString:text];
        }
        else if ([segment objectForKey:GSFancyTextInternalLambdaIDKey] && (text = [segment objectForKey: GSFancyTextAltKey])) {
            [texts appendString:text];
        }
        previousLineID = lineID;
    }
    
    GSRelease(segments_);
    return GSAutoreleased(texts);
}

- (CGFloat)contentHeight {
    return contentHeight_;
}

- (CGFloat)contentWidth {
    return contentWidth_;
}

- (GSMarkupNode*)parseStructure {
    #ifdef GS_DEBUG_PERFORMANCE
    NSDate* startTime = [NSDate date];
    #endif
    
    if (!text_ || !text_.length) {
        // in case the object is initialized with already parsed structure instead of markup text
        return parsedTree_;
    }
    
    GSRelease(parsedTree_);
    parsedTree_ = [[self class] newParsedMarkupString:text_ withStyleDict:style_];
    
    #ifdef GS_DEBUG_PERFORMANCE
    GSDebugLog(@"time to parse markup: %f", -[startTime timeIntervalSinceNow]);
    #endif
    
    return parsedTree_;
}

- (NSMutableArray*)generateLines {
    
    #ifdef GS_DEBUG_PERFORMANCE
    NSDate* startTime = [NSDate date];
    #endif
    
    // step 1. parsing
    if (!parsedTree_) {
        [self parseStructure];
    }
    __block NSArray* segments_ = [parsedTree_ newDepthFirstOrderDataArray];

    // step 2. line breaking
    
    if (!width_) {
        return nil;
    }
    GSRelease(lines_);
    lines_ = [[NSMutableArray alloc] initWithCapacity:segments_.count];
    
    __block float totalHeight = 0.f;
    contentWidth_ = 0.f;
    
    // line level vars
    
    __block NSMutableArray* currentLine = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    __block int currentLineID = -1;
    __block CGFloat currentLineSpaceLeft = width_;
    __block int currentLineIDActualLineCount = 0;
    __block int currentLineIDLineCountLimit = 0;
    __block NSString* currentLineLastText;
    __block GSTextAlign currentLineLastTextAlign;
    __block CGFloat currentLineHeight = 0.f;
    __block NSString* currentLineMarginTopString;
    __block NSString* currentLineMarginBottomString;
    __block int lineIDWithMarginsAdded = -1;
    __block CGFloat currentLineMarginX;
    
    // piece/segment level vars
    
    NSMutableDictionary* segment;
    NSString* segmentText;
    UIFont* segmentFont;
    // some segment info that will affect line breaking
    __block int segmentLineCount;
    // the alignment will not affect line breaking, but will determine whether we need to trim the trailing whitespace of last one in line
    __block NSNumber* segmentAlignNumber;
    __block GSTextAlign segmentAlign;
    // some segment info that will be used to calculate the final height of a line
    __block CGFloat segmentHeight;
    NSString* segmentLineHeightString;
    __block float segmentMarginX;
    __block NSString* segmentMarginTopString;
    __block NSString* segmentMarginBottomString;
    
    __block int segmentLineID = 0;
    int previousSegmentLineID = -1; // previous segment's line ID
    
    BOOL(^insertLineBlock)() = ^(){
        // return NO means it already reached max line height and there's no need to add more
        if (currentLine.count) {
            
            if (currentLineLastTextAlign==GSTextAlignRight) {
                NSString* lineText = [currentLineLastText stringByTrimmingTrailingWhitespace];
                [[currentLine lastObject] setObject:lineText forKey:GSFancyTextTextKey];
            }
            
            // if we reached line-count limit, squeeze the current line into the last line
            // and mark this line as "advanced truncation"
            if (currentLineIDLineCountLimit && currentLineIDActualLineCount >= currentLineIDLineCountLimit) {
                [[lines_ lastObject] addObjectsFromArray:currentLine];
                [[[lines_ lastObject] objectAtIndex:0] setObject:[NSNumber numberWithBool:YES] forKey:GSFancyTextAdvancedTruncationKey];
            }
            else {
                CGFloat nextHeight;
                CGFloat introducedHeight = currentLineHeight;
                
                if (currentLineID!=lineIDWithMarginsAdded) {
                    CGFloat topMargin = 0.f;
                    CGFloat bottomMargin = 0.f;
                    if (currentLineMarginTopString) {
                        topMargin = [currentLineMarginTopString possiblyPercentageNumberWithBase:currentLineHeight];   
                    }
                    if (currentLineMarginBottomString) {
                        bottomMargin = [currentLineMarginBottomString possiblyPercentageNumberWithBase:currentLineHeight];
                    }
                    introducedHeight += (topMargin + bottomMargin);
                    lineIDWithMarginsAdded = currentLineID;
                }
                
                nextHeight = totalHeight + introducedHeight;
                
                // if there is not enough height
                if (maxHeight_ && nextHeight > maxHeight_) {
                    
                    // if the line ID of this line is still the same as last line, give some "..." to the last line to indicate it's truncated
                    if (lines_.count) {
                        NSMutableDictionary* lastLineLastSegment = [[lines_ lastObject] lastObject];
                        int lastLineID = [[lastLineLastSegment objectForKey:GSFancyTextLineIDKey] intValue];
                        if (lastLineID == currentLineID) {
                            NSString* lastText = [lastLineLastSegment objectForKey:GSFancyTextTextKey];
                            [lastLineLastSegment setObject:[NSString stringWithFormat:@"%@ %@", lastText, [[currentLine objectAtIndex:0] objectForKey:GSFancyTextTextKey]] forKey:GSFancyTextTextKey];
                            [[[lines_ lastObject] objectAtIndex:0] setObject:[NSNumber numberWithBool:YES] forKey:GSFancyTextAdvancedTruncationKey];
                        }
                    }
                    contentHeight_ = totalHeight;
                    GSRelease(currentLine);
                    GSRelease(segments_);
                    return NO;
                }
                [lines_ addObject: currentLine];                
                currentLineIDActualLineCount ++;
                totalHeight = nextHeight;
                if (maxHeight_ == totalHeight) {
                    contentHeight_ = totalHeight;
                    GSRelease(currentLine);
                    GSRelease(segments_);
                    return NO;
                }
            }
            GSRelease(currentLine);
            currentLine = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
            currentLineSpaceLeft = width_;
            currentLineHeight = 0.f;
        }
        return YES;
    };
    
    void(^insertPieceForCurrentLineBlock)(NSMutableDictionary*) = ^(NSMutableDictionary* piece) {
        [currentLine addObject: piece];
        
        // also update some line level information
        currentLineID = segmentLineID;
        currentLineIDLineCountLimit = segmentLineCount;
        currentLineLastTextAlign = segmentAlign;
        currentLineMarginTopString = GSAutoreleased([segmentMarginTopString copy]);
        currentLineMarginBottomString = GSAutoreleased([segmentMarginBottomString copy]);
        currentLineMarginX = segmentMarginX;
        
        // update the total line content height
        if (segmentHeight > currentLineHeight) {
            currentLineHeight = segmentHeight;
        }
    };
    
    for (int i=0; i<segments_.count; i++) {
        segment = [segments_ objectAtIndex:i];
        
        // Special case: a new line is required due to some elements like <p>
        NSNumber* lineIDNumber = [segment objectForKey:GSFancyTextLineIDKey];
        segmentLineID = lineIDNumber ? [lineIDNumber intValue] : 0;
        if (segmentLineID != previousSegmentLineID) {
            if (!insertLineBlock() ) {
                return lines_;
            }
            currentLineIDActualLineCount = 0;
        }
        previousSegmentLineID = segmentLineID;
        
        // retrieve some common segment info (required by adding both lambda or text)
        NSString* segmentLineCountString = [segment objectForKey:GSFancyTextLineCountKey];
        segmentLineCount = segmentLineCountString ? [segmentLineCountString intValue] : 0;
        segmentAlignNumber = [segment objectForKey:GSFancyTextTextAlignKey];
        segmentAlign = segmentAlignNumber ? [segmentAlignNumber intValue] : 0;
        segmentLineHeightString = [segment objectForKey:GSFancyTextLineHeightKey];
        
        // read margins
        NSString* segmentMarginLeftString = [segment objectForKey:GSFancyTextMarginLeft];
        NSString* segmentMarginRightString = [segment objectForKey:GSFancyTextMarginRight];
        segmentMarginTopString = [segment objectForKey:GSFancyTextMarginTop];
        segmentMarginBottomString = [segment objectForKey:GSFancyTextMarginBottom];
        
        CGFloat segmentMarginLeft = segmentMarginLeftString ? [segmentMarginLeftString possiblyPercentageNumberWithBase:width_] : 0.f;
        CGFloat segmentMarginRight = segmentMarginRightString ? [segmentMarginRightString possiblyPercentageNumberWithBase:width_] : 0.f;
        segmentMarginX = segmentMarginLeft + segmentMarginRight;
        
        // when a new line starts, cut the space by marginX
        if (!currentLine.count) {
            currentLineSpaceLeft -= segmentMarginX;
        }
        
        // adding the segment(s)
        
        if ([[segment allKeys] containsObject:GSFancyTextInternalLambdaIDKey]) {
            // a lambda segment
            
            // retrieve some lambda segment specific info
            CGFloat segmentWidth = [[segment objectForKey:GSFancyTextWidthKey] floatValue];
            segmentHeight = [[segment objectForKey:GSFancyTextHeightKey] floatValue];
            if (segmentLineHeightString) {
                segmentHeight = [segmentLineHeightString possiblyPercentageNumberWithBase:segmentHeight];
            }

            // conclude the previous line if it's too long
            if (currentLine.count && currentLineSpaceLeft<segmentWidth) {
                contentWidth_ = width_;
                if (!insertLineBlock() ) {
                    return lines_;
                }
            }
            
            // insert current segment
            insertPieceForCurrentLineBlock(segment);
            currentLineLastText = @""; // no need to trim text if the last object of a line is a lambda
            
            // updating the space left, conclude a line if necessary
            currentLineSpaceLeft = currentLineSpaceLeft - segmentWidth;
            if (currentLineSpaceLeft <= 0) {
                currentLineSpaceLeft = 0;
                contentWidth_ = width_;
                if (!insertLineBlock() ) {
                    return lines_;
                }
            }
            
            CGFloat currentLineContentWidth = width_-currentLineSpaceLeft;
            if (contentWidth_ < currentLineContentWidth) {
                contentWidth_ = currentLineContentWidth;
            }
        }
        else {
            // text segment
            
            // retrieve some text segment specific info
            segmentText = [segment objectForKey:GSFancyTextTextKey];
            segmentFont = [segment objectForKey:GSFancyTextFontKey];
            if (!segmentFont) {
                [[self class] createFontKeyForDict:segment];
                segmentFont = [segment objectForKey:GSFancyTextFontKey];
            }
            segmentHeight = [segmentFont lineHeight];
            if (segmentLineHeightString) {
                segmentHeight = [segmentLineHeightString possiblyPercentageNumberWithBase:segmentHeight];
            }
            
            // split the lines 
            // (the currentLineSpaceLeft might be altered by the insertLineBlock above)
            NSArray* segmentLines = [segmentText linesWithWidth:(width_-segmentMarginX) font:segmentFont firstLineWidth:currentLineSpaceLeft limitLineCount:segmentLineCount];
            
            // a line can contain several pieces, each piece has its own style
            NSMutableDictionary* piece;
            
            for (int i=0; i<segmentLines.count; i++) {
                NSString* lineText = [segmentLines objectAtIndex:i];
                
                // Special case: if the current line is empty... conclude the previous line, if there is any
                if (lineText.length < 1) {
                    if (!insertLineBlock() ) {
                        return lines_;
                    }
                    continue;
                }
                
                // Setting fonts and properties for all cases
                piece = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
                [piece setValuesForKeysWithDictionary:segment];// update other params like color
                
                // Special case: if it's a new line, and it's not the first line of this line ID, truncate the leading white spaces
                if (!currentLine.count && segmentAlign==GSTextAlignLeft && currentLineIDActualLineCount>0) {
                    lineText = [lineText stringByTrimmingLeadingWhitespace];
                }
                
                // Add the current piece to the current line
                [piece setObject:lineText forKey: GSFancyTextTextKey];
                
                insertPieceForCurrentLineBlock(piece);
                
                // update the currentLineLastText, when we are concluding the line, if it's right align, we need to trim trailing space from last text
                currentLineLastText = lineText;
                
                GSRelease(piece);
                
                // Regular case: if it is not the last line, it means that this line is long enough to cover a whole line
                if (i != segmentLines.count -1 ) {
                    CGFloat widthUsed = [lineText sizeWithFont:segmentFont].width;
                    CGFloat currentLineContentWidth = widthUsed + (width_ - currentLineSpaceLeft);
                    contentWidth_ = MAX(contentWidth_, currentLineContentWidth);
                    if (!insertLineBlock() ) {
                        return lines_;
                    }
                }
                else {
                    // for any unfinished line, calculate the width left for the current line
                    CGFloat widthUsed = [lineText sizeWithFont:segmentFont].width;
                    currentLineSpaceLeft = currentLineSpaceLeft - widthUsed;
                    // this is the last line of this segment, and there are more than 1 line in this break, 
                    // remove the margin space
                    if (segmentLines.count>1 && currentLine.count==1) {
                        currentLineSpaceLeft = currentLineSpaceLeft - segmentMarginX;
                    }
                    
                    CGFloat currentLineContentWidth = width_-currentLineSpaceLeft;
                    if (contentWidth_ < currentLineContentWidth) {
                        contentWidth_ = currentLineContentWidth;
                    }
                }
            }
        }
    }
    
    
    if (! insertLineBlock() ) {
        return lines_;
    }
    
    GSRelease(segments_);
    GSRelease(currentLine);
    
    #ifdef GS_DEBUG_PERFORMANCE
    GSDebugLog(@"time to generate line: %f", -[startTime timeIntervalSinceNow]);
    #endif
    
    contentHeight_ = totalHeight;
    
    return lines_;
}




#pragma mark - Parsers and class methods


typedef enum {
    ParsingStyleName,
    ParsingStyleContent,
} StyleSheetParseMode;

+ (NSMutableDictionary*)newParsedStyle: (NSString*)styleString {

    NSMutableDictionary* cssDict = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    // scanner and scan parameters
    NSScanner* scanner = [[NSScanner alloc] initWithString:styleString];
    int lengthToSkip = 0;
    NSString* currentText;
    NSString* scanTo = @"{";
    
    // result container
    NSArray* nameParts;
    NSString* elementName;
    NSString* className;
    NSMutableDictionary* propertyList;
    
    while (![scanner isAtEnd]) {
        
        // doing name scanning
        [scanner scanUpToString:scanTo intoString:&currentText];
        currentText = [currentText substringFromIndex:lengthToSkip];
        
        // handle scan result
        nameParts = [currentText componentsSeparatedByString:@"."];
        
        if (nameParts.count==1) {
            elementName = [GSTrim(currentText) lowercaseString];
            if (elementName.length) {
                className = GSFancyTextDefaultClass;
            }
            else {
                className = @"";
            }
        }
        else if (nameParts.count==2){
            className = [GSTrim( [nameParts objectAtIndex:1]) lowercaseString];
            elementName = [GSTrim( [nameParts objectAtIndex:0]) lowercaseString];
            if (!elementName.length) {
                elementName = GSFancyTextDefaultClass;
            }
        }
        else {
            elementName = @"";
            className = @"";
        }
        
        // scan the content
        propertyList = [[self class] newParsedStyleAttributesFromScanner:scanner];
        
        if (className.length && elementName.length && [propertyList allKeys].count) {
            NSMutableDictionary* element = [cssDict objectForKey:elementName];
            if (element) {
                [element setObject:propertyList forKey:className];
            }
            else {
                [cssDict setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:propertyList, className, nil] forKey:elementName];
            }
        }
        GSRelease(propertyList);
        
        // after the inner content scan finished, the location is at }, so it should be skipped in the next scan's result
        lengthToSkip = 1;
    }
    GSRelease(scanner);
    return cssDict;
}

typedef enum {
    ParsingAttribName,
    ParsingSingleQuotedValue,
    ParsingDoubleQuotedValue,
    AdvancingToSemicolon,
    ParsingUnquotedValue,
} AttributeParseMode;

+ (NSMutableDictionary*)newParsedStyleAttributesFromScanner:(NSScanner*)scanner {
    
    NSMutableDictionary* propertyList = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    NSString* currentText;
    NSString* currentAttribName;
    NSString* currentValue;
    AttributeParseMode mode = ParsingAttribName;
    NSString* scanTo;
    int lengthToSkip = 1; // initial skip length is 1 because the scanner is currently at the "{" location
    GSScanResult scanResult = ScanMeetTarget;
    
    while ((![scanner isAtEnd]) && scanResult!=ScanMeetEndToken) {
        // setting scan target
        switch (mode) {
            case ParsingAttribName:
                scanTo = @":";
                break;
            case ParsingSingleQuotedValue:
                scanTo = @"'";
                break;
            case ParsingDoubleQuotedValue:
                scanTo = @"\"";
                break;
            case ParsingUnquotedValue:
            case AdvancingToSemicolon:
                scanTo = @";";
                break;
        }
        
        // doing scan
        switch (mode) {
            case ParsingAttribName:
            case ParsingUnquotedValue:
            case AdvancingToSemicolon:
                scanResult = [scanner scanUpToString:scanTo endToken:@"}" intoString:&currentText];
                break;
            case ParsingSingleQuotedValue:
            case ParsingDoubleQuotedValue:
                scanResult = [scanner scanWithGSScanResultUpToString:scanTo intoString: &currentText];
                break;
        }
        currentText = [currentText substringFromIndex: lengthToSkip];
        
        // analyzing scan result
        switch (mode) {
            case ParsingAttribName:{
                currentAttribName = [GSTrim([NSString stringWithString:currentText]) lowercaseString];
                int nextCharLocation;
                NSString* next = [scanner.string firstNonWhitespaceCharacterSince:scanner.scanLocation+1 foundAt:&nextCharLocation];
                if (!next.length) {
                    scanner.scanLocation = scanner.string.length;
                    return propertyList;
                }
                else if ([next isEqualToString:@"'"]) {
                    mode = ParsingSingleQuotedValue;
                    scanner.scanLocation = nextCharLocation + 1;
                    lengthToSkip = 0;
                }
                else if ([next isEqualToString:@"\""]) {
                    mode = ParsingDoubleQuotedValue;
                    scanner.scanLocation = nextCharLocation + 1;
                    lengthToSkip = 0;
                }
                else {
                    mode = ParsingUnquotedValue;
                    lengthToSkip = scanTo.length;
                }
                break;
            }
            case ParsingSingleQuotedValue:
            case ParsingDoubleQuotedValue:
                mode = AdvancingToSemicolon;
                currentValue = [NSString stringWithString: currentText]; // don't trim it if it's already quoted
                lengthToSkip = scanTo.length;
//                [propertyList setObject: [[self class] parsedValue:currentValue forKey:currentAttribName] forKey:currentAttribName];
                [[self class] parseValue:currentValue forKey:currentAttribName intoDictionary:propertyList];
                break;
            case ParsingUnquotedValue:
                mode = ParsingAttribName;
                currentValue = GSTrim(currentText);
//                [propertyList setObject: [[self class] parsedValue:currentValue forKey:currentAttribName] forKey:currentAttribName];
                [[self class] parseValue:currentValue forKey:currentAttribName intoDictionary:propertyList];
                lengthToSkip = scanTo.length;
                
                break;
            case AdvancingToSemicolon:
                mode = ParsingAttribName;
                lengthToSkip = scanTo.length;
                break;
        }
    }
    return propertyList;
}


+ (NSMutableDictionary*)parsedStyle:(NSString *)style {
    return GSAutoreleased([[self class] newParsedStyle:style]);
}

typedef enum {
    ParsingPureText,
    ParsingTaggedText,
    ParsingOpeningTag,
    ParsingOpeningOrClosingTag,
} ParseMode;


+ (GSMarkupNode*)newParsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict {
    // result container
    GSMarkupNode* resultRoot = [[GSMarkupNode alloc] init];
    resultRoot.isContainer = YES;
    
    NSMutableDictionary* idMap = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];  // id must be unique, so the value is just an HUMarkupString node pointer
    NSMutableDictionary* classesMap = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize]; // classes won't be unique, so the value is an array
    // the two maps will be added to the data of root node eventually 
    
    // 2 stacks were used to help maintain the containers and styles
    NSMutableArray* tagStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    NSMutableArray* containerStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    [containerStack addObject:resultRoot];
    
    // data structure preparation
    NSScanner* scanner = [[NSScanner alloc] initWithString: markup];
    NSString* currentSegmentText;
    NSString* lookFor = @"<";
    int lengthToSkip=0;
    NSMutableDictionary* defaultStyle = [NSMutableDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], GSFancyTextColorKey,
                                         GSFancyTextDefaultFontFamily, GSFancyTextFontNameKey,
                                         [NSNumber numberWithFloat:[UIFont systemFontSize]], GSFancyTextFontSizeKey,
                                         nil];
    NSMutableDictionary* allClasses = [styleDict objectForKey:GSFancyTextDefaultClass];
    if (allClasses) {
        [defaultStyle setValuesForKeysWithDictionary:[allClasses objectForKey:GSFancyTextDefaultClass]];
    }
    
    // set the default font here
    [[self class] createFontKeyForDict: defaultStyle];

    GSMarkupNode* currentSegment;
    
    // Let the parsing begin!
    while (![scanner isAtEnd]) {
        
        currentSegmentText = @"";
        [scanner scanUpToString:lookFor intoString:&currentSegmentText];
        
        if (!currentSegmentText || currentSegmentText.length < lengthToSkip) {
            continue;
        }
        
        currentSegmentText = [currentSegmentText substringFromIndex:lengthToSkip];
        
        // outside the HTML tags.. do unescape to take care of &gt; &lt; etc
        currentSegmentText = [currentSegmentText unescapeHTMLEntities];
        
        if (currentSegmentText.length) {
            currentSegment = [[GSMarkupNode alloc] init];
            [currentSegment.data setObject:[NSString stringWithString:currentSegmentText] forKey:GSFancyTextTextKey];
            [currentSegment.data setValuesForKeysWithDictionary:defaultStyle];
            // apply all the styles in the stack.
            for (GSMarkupNode* node in containerStack) {
                [currentSegment.data setValuesForKeysWithDictionary: node.data];
            }
            currentSegment.isContainer = NO;
            
            // set the font based on font-related keys here, because all tags that apply to this segment is analyzed
            [[self class] createFontKeyForDict: currentSegment.data];
            
            [[containerStack lastObject] appendChild:currentSegment];
            
            GSRelease(currentSegment);
        }
        
        NSMutableDictionary* stylesInTag = [[self class] newStyleFromCurrentTagInScanner:scanner withStyleDict:styleDict];

        // whether it's a lambda tag or style tag, there is going to be a tree node to insert
        GSMarkupNode* nodeToAdd = [[GSMarkupNode alloc] init];
        
        if ([stylesInTag allKeys].count) {
            
            // handling several special keys: elementName, isClosingTag, ID, class
            NSString* elementName = [stylesInTag objectForKey: GSFancyTextElementNameKey];

            BOOL isClosingTag = [[stylesInTag objectForKey:GSFancyTextTagClosingKey] boolValue];
            [stylesInTag removeObjectForKey:GSFancyTextTagClosingKey];
            
            NSString* tagID = [stylesInTag objectForKey: GSFancyTextIDKey];
            if (tagID) {
                [idMap setObject:nodeToAdd forKey:tagID];
            }
            
            NSArray* tagClassNames = [stylesInTag objectForKey: GSFancyTextClassKey];
            if (tagClassNames) {
                for (NSString* className in tagClassNames) {
                    [[self class] addObject:nodeToAdd intoDict:classesMap underKey:className];
                }
            }
            
            // handle the tag based on if it's a lambda or opening tag or closing tag
            if ([elementName caseInsensitiveCompare: GSFancyTextLambdaElement]==NSOrderedSame) {
                // first apply .default style
                if (allClasses) {
                    [nodeToAdd.data setValuesForKeysWithDictionary:[allClasses objectForKey:GSFancyTextDefaultClass]];
                }
                // then apply the container stack styles
                for (GSMarkupNode* node in containerStack) {
                    [nodeToAdd.data setValuesForKeysWithDictionary: node.data];
                }
                // lastly apply its own style
                [nodeToAdd.data setValuesForKeysWithDictionary:stylesInTag];
                nodeToAdd.isContainer = NO;
                [[containerStack lastObject] appendChild:nodeToAdd];
                NSString* lambdaID = [nodeToAdd.data objectForKey:GSFancyTextInternalLambdaIDKey];
                if (!lambdaID) {
                    lambdaID = @"";
                    [nodeToAdd.data setObject:lambdaID forKey:GSFancyTextInternalLambdaIDKey];
                }
                [nodeToAdd.data setObject:lambdaID forKey:GSFancyTextIDKey];
                [idMap setObject:nodeToAdd forKey:lambdaID]; // lambda ID also needs to be saved in hash map
            }
            else if (isClosingTag) {
                if (tagStack.count && [elementName caseInsensitiveCompare:[tagStack lastObject]] == NSOrderedSame) {
                    // good. matching tag. pop the stack by 1.
                    [tagStack removeLastObject];
                    [containerStack removeLastObject];
                }
            }
            else {
                // stack push the current tag
                [tagStack addObject: [[elementName componentsSeparatedByString:@" "] objectAtIndex:0]];
                [nodeToAdd.data setValuesForKeysWithDictionary: stylesInTag];
                nodeToAdd.isContainer = YES;
                [[containerStack lastObject] appendChild: nodeToAdd];
                [containerStack addObject: nodeToAdd];
            }

        }
        GSRelease(nodeToAdd);
        GSRelease(stylesInTag);
        
        lengthToSkip = 1;
        // after scanning a tag, we are expected to be at the > position
        // we don't move scanner location because in that way the first space after > will be skipped in the next scan (damn it apple!)
        // so we set a lengthToSkip to skip the > for the next scan
    }
    
    GSRelease(scanner);
    GSRelease(containerStack);
    GSRelease(tagStack);
    
    resultRoot.IDMap = idMap;
    resultRoot.classesMap = classesMap;
    
    GSRelease(idMap);
    GSRelease(classesMap);
        
    return resultRoot;
}



typedef enum {
    ParsingTagName,
    ParsingLhs,
    ParsingDoubleQuotedRhs,
    ParsingSingleQuotedRhs,
    ParsingUnquotedRhs,
} InTagParsingMode;

typedef enum {
    ReadingClass,
    ReadingLambdaAttrib,
    ReadingNothing
} InTagAttrib;

+ (NSMutableDictionary*)newStyleFromCurrentTagInScanner:(NSScanner*)scanner withStyleDict:(NSDictionary*)styleDict {
    
    NSMutableDictionary* style = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    // scanning params
    InTagParsingMode mode = ParsingTagName;
    GSScanResult scanResult = ScanMeetTarget;
    NSString* scanTo;
    NSString* currentText;
    
    // result containers
    NSString* elementName = nil;
    NSString* classNames = nil;
    NSString* attribName = nil;
    InTagAttrib attrib = ReadingNothing;
    
    int nextCharLocation;
    BOOL isClosing;
    NSString* next = [scanner.string firstNonWhitespaceCharacterSince:scanner.scanLocation+1 foundAt:&nextCharLocation];
    if (!next.length) {
        scanner.scanLocation = scanner.string.length;
        return style;
    }
    else if ([next isEqualToString:@"/"]) {
        isClosing = YES;
        scanner.scanLocation = nextCharLocation + 1;
    }
    else {
        isClosing = NO;
        scanner.scanLocation = nextCharLocation;
    }
    [style setObject:[NSNumber numberWithBool:isClosing] forKey:GSFancyTextTagClosingKey];
    
    while (![scanner isAtEnd] && scanResult!=ScanMeetEndToken) {
        // setting target
        switch (mode) {
            case ParsingTagName:
            case ParsingUnquotedRhs:
                scanTo = @" ";
                break;
            case ParsingDoubleQuotedRhs:
                scanTo = @"\"";
                break;
            case ParsingSingleQuotedRhs:
                scanTo = @"'";
                break;
            case ParsingLhs:
                scanTo = @"=";
                break;
        }
        
        // parsing work
        currentText = @"";
        switch (mode) {
            case ParsingTagName:
            case ParsingUnquotedRhs:
            case ParsingLhs:
                scanResult = [scanner scanUpToString:scanTo endToken:@">" intoString:&currentText];
                break;
            case ParsingDoubleQuotedRhs:
            case ParsingSingleQuotedRhs:
                scanResult = [scanner scanWithGSScanResultUpToString:scanTo intoString:&currentText];
                break;
        }
        
        // handling read text
        switch (mode) {
            case ParsingTagName:
                elementName = [GSTrim(currentText) lowercaseString];
                
                [style setObject:elementName forKey: GSFancyTextElementNameKey];
                
                /** Some supported markup tags
                 */
                if (!isClosing) {
                    if ([elementName caseInsensitiveCompare:GSFancyTextStrongElement]==NSOrderedSame) {
                        [style setObject:@"bold" forKey:GSFancyTextFontWeightKey];
                    }
                    else if ([elementName caseInsensitiveCompare:GSFancyTextEmElement]==NSOrderedSame) {
                        [style setObject:@"italic" forKey:GSFancyTextFontStyleKey];
                    }
                    else if ([elementName caseInsensitiveCompare:GSFancyTextPElement]==NSOrderedSame) {
                        lineID_++;
                        [style setObject:[NSNumber numberWithInt: lineID_ ] forKey:GSFancyTextLineIDKey];
                    }
                }
                mode = ParsingLhs;
                if (scanResult==ScanMeetTarget) {
                    scanner.scanLocation += GSTrim(scanTo).length;
                }
                break;
            case ParsingLhs:{
                attribName = GSTrim(currentText);
                if ([attribName caseInsensitiveCompare:GSFancyTextClassKey]==NSOrderedSame) {
                    attrib = ReadingClass; // currently we only care about class=, otherwise we should use an enum instead of BOOL
                }
                else if ([elementName caseInsensitiveCompare:GSFancyTextLambdaElement]==NSOrderedSame) {
                    attrib = ReadingLambdaAttrib;
                }
                else {
                    attrib = ReadingNothing;
                }
                
                NSString* content = [scanner string];
                int nextCharLocation;
                NSString* next = [content firstNonWhitespaceCharacterSince:scanner.scanLocation+1 foundAt:&nextCharLocation];

                if (!next.length) {
                    scanner.scanLocation = content.length;
                    return style;
                }
                else if ([next isEqualToString:@"'"]) {
                    mode = ParsingSingleQuotedRhs;
                    scanner.scanLocation = nextCharLocation + 1;
                }
                else if ([next isEqualToString:@"\""]) {
                    mode = ParsingDoubleQuotedRhs;
                    scanner.scanLocation = nextCharLocation + 1;
                }
                else {
                    mode = ParsingUnquotedRhs;
                    if (scanResult==ScanMeetTarget) {
                        scanner.scanLocation += GSTrim(scanTo).length;
                    }
                }
                break;
            }
            case ParsingUnquotedRhs:
            case ParsingDoubleQuotedRhs:
            case ParsingSingleQuotedRhs:
                if (!isClosing) {
                    if (attrib == ReadingClass) {
                        classNames = GSTrim(currentText);
                        
                        NSArray* individualClassNames = [classNames componentsSeparatedByString:@" "];
                        // apply class styles of all classes
                        for (NSString* className in individualClassNames) {
                            NSMutableDictionary* allClasses = [styleDict objectForKey:GSFancyTextDefaultClass];
                            if (allClasses) {
                                //[style setValuesForKeysWithDictionary:[allClasses objectForKey: HU_FANCY_TEXT_ALL_VALUE]];//don't need this because the default default is already applied outside
                                [style setValuesForKeysWithDictionary:[allClasses objectForKey: className]];
                            }
                            NSMutableDictionary* elementClasses = [styleDict objectForKey:elementName];
                            if (elementClasses) {
                                [style setValuesForKeysWithDictionary:[elementClasses objectForKey: GSFancyTextDefaultClass]];
                                [style setValuesForKeysWithDictionary:[elementClasses objectForKey: className]];
                            }
                        }
                        [style setValue: individualClassNames forKey:GSFancyTextClassKey];
                    }
                    else if (attrib == ReadingLambdaAttrib) {
                        if ([attribName caseInsensitiveCompare:GSFancyTextIDKey]==NSOrderedSame) {
                            [style setObject:GSTrim(currentText) forKey:GSFancyTextInternalLambdaIDKey];
                            [style setObject:GSTrim(currentText) forKey:GSFancyTextIDKey];
                        }
                        else {
//                            [style setObject:[[self class] parsedValue:GSTrim(currentText) forKey:attribName] forKey: attribName];
                            [[self class] parseValue:GSTrim(currentText) forKey:attribName intoDictionary:style];
                        }
                    }
                    else if ([attribName caseInsensitiveCompare:GSFancyTextIDKey]==NSOrderedSame) {
                        // save the ID as one attribute
                        [style setObject:GSTrim(currentText) forKey:GSFancyTextIDKey];
                    }
                }
                mode = ParsingLhs;
                if (scanResult==ScanMeetTarget) {
                    scanner.scanLocation += GSTrim(scanTo).length;
                }
                break;
        }
    }
    
    [[self class] cleanStyleDict:style];
    return style;
}


+ (GSMarkupNode*)parsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict {
    return GSAutoreleased([[self class] newParsedMarkupString:markup withStyleDict:styleDict]);
}


+ (NSObject*)parseValue: (NSString*)value forKey:(NSString*)key intoDictionary:(NSMutableDictionary*)dict {
    
    NSObject* object;
    if ([key caseInsensitiveCompare:GSFancyTextColorKey]==NSOrderedSame) {
        object = [[self class] parseColor:value intoDictionary:dict];
    }
    else if ([key caseInsensitiveCompare:GSFancyTextTextAlignKey]==NSOrderedSame) {
        object = [[self class] parseTextAlign:value intoDictionary:dict];
    }
    else if ([key caseInsensitiveCompare:GSFancyTextTruncateModeKey]==NSOrderedSame) {
        object = [[self class] parseTruncationMode:value intoDictionary:dict];
    }
    else if ([key caseInsensitiveCompare:GSFancyTextVerticalAlignKey]==NSOrderedSame) {
        object = [[self class] parseVerticalAlign:value intoDictionary:dict];
    }
    else {
        object = [NSString stringWithString:value];
        // just to be consistent with other cases, return an autorelease copy instead of just value
        // e.g. jic the code before this call is value=[[xxx alloc] init], and after this call there is a GSRelease(value)
        [dict setObject:object forKey:key];
    }
    return object;
}

+ (UIColor*)parseColor:(NSString *)value_ intoDictionary:(NSMutableDictionary*)dict {
    NSString* value = [value_ lowercaseString];
    UIColor* color;
    if (!value.length) {
        // fail
    }
    else if ([[value substringToIndex:1] isEqualToString:@"#"]) {
        unsigned result = 0;
        NSScanner *scanner = [NSScanner scannerWithString:value];
        
        [scanner setScanLocation:1]; // bypass '#' character
        [scanner scanHexInt:&result];
        color = GSRgb(result);
    }
    else if ([value rangeOfString:GSFancyTextRGBValue].location != NSNotFound) {
        value = [value stringByReplacingOccurrencesOfString:GSFancyTextRGBValue withString:@""];
        value = [value stringByReplacingOccurrencesOfString:@"(" withString:@""];
        value = [value stringByReplacingOccurrencesOfString:@")" withString:@""];
        NSArray* colors = [value componentsSeparatedByString:@","];
        if (colors.count == 3) {
            CGFloat r = [(NSString*)[colors objectAtIndex:0] floatValue];
            CGFloat g = [(NSString*)[colors objectAtIndex:1] floatValue];
            CGFloat b = [(NSString*)[colors objectAtIndex:2] floatValue];
            
            if (r<=255.f && r>=0.f && g<=255.f && g>=0.f && b<=255.f && b>=0.f) {
                color = [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:1];
            }
        }
    }
    else {
        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@Color", value]);
        if ([[UIColor class] respondsToSelector: sel]) {
            color = objc_msgSend([UIColor class], sel);
        }
    }
    
    if (color) {
        if (dict) {
            [dict setObject:color forKey:GSFancyTextColorKey];
        }
        return color;
    }
    else {
        #ifdef GS_DEBUG_MARKUP
        GSDebugLog(@"\n[Warning]\nColor parsing error. \"%@\" is not recognized.\n\n", value_);
        #endif
        return nil;
    }
}


+ (NSNumber*)parseTextAlign: (NSString*)value intoDictionary:(NSMutableDictionary*)dict {
    NSNumber* textAlignNumber;
    if ([value caseInsensitiveCompare:GSFancyTextAlignCenterValue]==NSOrderedSame) {
        textAlignNumber = [NSNumber numberWithInt: GSTextAlignCenter];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextAlignRightValue]==NSOrderedSame ) {
        textAlignNumber = [NSNumber numberWithInt: GSTextAlignRight];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextAlignLeftValue]==NSOrderedSame ) {
        textAlignNumber = [NSNumber numberWithInt: GSTextAlignLeft];
    }
    
    if (textAlignNumber) {
        if (dict) {
            [dict setObject:textAlignNumber forKey:GSFancyTextTextAlignKey];
        }
        return textAlignNumber;
    }
    else {
        #ifdef GS_DEBUG_MARKUP
        GSDebugLog(@"\n[Warning]\nText alignment parsing error. \"%@\" is not recognized.\n\n", value);
        #endif
        return nil;
    }
}

+ (NSNumber*)parseVerticalAlign: (NSString*)value intoDictionary:(NSMutableDictionary*)dict {
    NSNumber* result;
    if ([value caseInsensitiveCompare:GSFancyTextVAlignMiddleValue]==NSOrderedSame) {
        result = [NSNumber numberWithInteger:GSVerticalAlignMiddle];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextVAlignTopValue]==NSOrderedSame ) {
        result = [NSNumber numberWithInteger:GSVerticalAlignTop];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextVAlignBottomValue]==NSOrderedSame ) {
        result = [NSNumber numberWithInteger:GSVerticalAlignBottom];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextVAlignBaselineValue]==NSOrderedSame ) {
        result = [NSNumber numberWithInteger:GSVerticalAlignBaseline];
    }
    
    if (result) {
        if (dict) {
            [dict setObject:result forKey:GSFancyTextVerticalAlignKey];
        }
        return result;
    }
    else {
        #ifdef GS_DEBUG_MARKUP
        GSDebugLog(@"\n[Warning]\nVertical alignment parsing error. \"%@\" is not recognized.\n\n", value);
        #endif
        return nil;
    }
}

+ (NSNumber*)parseTruncationMode: (NSString*)value intoDictionary:(NSString*)dict {
    NSNumber* mode;
    if ([value caseInsensitiveCompare:GSFancyTextTruncateHeadValue]==NSOrderedSame) {
        mode = [NSNumber numberWithInt: UILineBreakModeHeadTruncation];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextTruncateMiddleValue]==NSOrderedSame) {
        mode = [NSNumber numberWithInt: UILineBreakModeMiddleTruncation];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextTruncateClipValue]==NSOrderedSame) {
        mode = [NSNumber numberWithInt: UILineBreakModeClip];
    }
    else if ([value caseInsensitiveCompare:GSFancyTextTruncateTailValue]==NSOrderedSame) {
        mode = [NSNumber numberWithInt: UILineBreakModeTailTruncation];
    }
    if (mode) {
        if (dict) {
            [dict setValue:mode forKey:GSFancyTextTruncateModeKey];
        }
        return mode;
    }
    else {
        #ifdef GS_DEBUG_MARKUP
        GSDebugLog(@"\n[Warning]\nTruncation mode parsing error. \"%@\" is not recognized.\n\n", value);
        #endif
        return nil;
    }
}


static NSMutableDictionary* fontMemory_;
+ (UIFont*)fontWithName:(NSString*)name size:(CGFloat)size weight:(NSString*)weight style:(NSString*)style {    
    
    if (!fontMemory_) {
        fontMemory_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    }
    
    NSString* realFontName = name;
    
    BOOL bold = weight? [weight caseInsensitiveCompare:GSFancyTextBoldValue]==NSOrderedSame : NO;
    BOOL italic = style? [style caseInsensitiveCompare:GSFancyTextItalicValue]==NSOrderedSame : NO;
    
    if (!size) {
        size = [UIFont systemFontSize];
    }
        
    NSString* familyName;
    NSArray* fontFamilies = [UIFont familyNames];
    
    if ([fontFamilies containsObject:name]) {
        familyName = name;
    }
    else {
        familyName = GSFancyTextDefaultFontFamily;
    }
    NSArray* availableFontNames = [UIFont fontNamesForFamilyName:familyName];
    
    if (!availableFontNames.count) {
        familyName = GSFancyTextDefaultFontFamily;
        availableFontNames = [UIFont fontNamesForFamilyName:familyName];
    }
    
    NSString* internalName = [NSString stringWithFormat:@"%@-%d-%d", familyName, bold, italic];
    NSString* cachedName;
    if ((cachedName = [fontMemory_ objectForKey:internalName])) {
        // cache hit
        realFontName = cachedName;
    }
    else {
        // cache miss
        for (NSString* fontName in availableFontNames) {
            if (
                (bold == ([fontName rangeOfString:@"bold" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                          [fontName rangeOfString:@"medium" options:NSCaseInsensitiveSearch].location != NSNotFound || 
                          [fontName rangeOfString:@"w6" options:NSCaseInsensitiveSearch].location != NSNotFound)
                 ) &&
                (italic == ([fontName rangeOfString:@"italic" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                            [fontName rangeOfString:@"oblique" options:NSCaseInsensitiveSearch].location != NSNotFound) 
                 )
                ) {
                realFontName = fontName;
                break;
            }
        }
        if (!realFontName) {
            realFontName = [availableFontNames objectAtIndex:0];
        }
        [fontMemory_ setObject:realFontName forKey:internalName];
    }
    
    return [UIFont fontWithName:realFontName size:size];
}

+ (void)createFontKeyForDict:(NSMutableDictionary*)dict {
    UIFont* finalFont = [[self class] fontWithName: [dict objectForKey:GSFancyTextFontNameKey]
                                              size: [[dict objectForKey:GSFancyTextFontSizeKey] floatValue]
                                            weight: [dict objectForKey:GSFancyTextFontWeightKey]
                                             style: [dict objectForKey:GSFancyTextFontStyleKey]
                         ];
    [dict setObject:finalFont forKey:GSFancyTextFontKey];
    
    // keep these individual keys because we might need to change one of them later and regenerate the font
//    [dict removeObjectForKey: GSFancyTextFontNameKey];
//    [dict removeObjectForKey: GSFancyTextFontSizeKey];
//    [dict removeObjectForKey: GSFancyTextFontWeightKey];
//    [dict removeObjectForKey: GSFancyTextFontStyleKey];
}

+ (NSString*)availableFonts {
    NSMutableString* all = [NSMutableString stringWithCapacity:100];
    NSArray* availableFamilies = [UIFont familyNames];
    for (NSString* family in availableFamilies) {
        NSArray* availableFonts = [UIFont fontNamesForFamilyName:family];
        [all appendFormat: @"%@: %@", family, availableFonts ];
    }
    return all;
}


#pragma mark - global style

+ (NSMutableDictionary*)parseStyleAndSetGlobal: (NSString*)styleSheet {
    GSRelease(globalStyleDictionary_);
    globalStyleDictionary_ = [[self class] newParsedStyle:styleSheet];
    return globalStyleDictionary_;
}

+ (NSMutableDictionary*)globalStyle {
    return globalStyleDictionary_;
}

#pragma mark - Content switch

- (GSMarkupNode*)parseIfUnparsed {
    if (!parsedTree_) {
        return [self parseStructure];
    }
    return parsedTree_;
}

- (void)changeNodeToText:(NSString*)text forID:(NSString*)nodeID {
    if ([self parseIfUnparsed]) {
        GSMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            [theNode resetChildToText:text];
        }
    }
}

- (void)changeNodeToStyledText:(NSString*)styledText forID:(NSString*)nodeID {
    if ([self parseIfUnparsed]) {
        GSMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            // do it only when the current GSFancyText is parsed and has the nodeID
            
            [theNode dismissAllChildren];
            GSMarkupNode* newTree = [[self class] parsedMarkupString:styledText withStyleDict:self.style];
            [self.parsedResultTree appendSubtree:newTree underNode:theNode];
        }
    }
}

- (void)appendStyledText:(NSString*)styledText toID:(NSString*)nodeID {
    if ([self parseIfUnparsed]) {
        GSMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            GSMarkupNode* newTree = [[self class] parsedMarkupString:styledText withStyleDict:self.style];
            [self.parsedResultTree appendSubtree:newTree underNode:theNode];
        }
    }
}

- (void)removeID: (NSString*)nodeID {
    if ([self parseIfUnparsed]) {
        GSMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            [theNode cutFromParent];
        }
    }
}

#pragma mark - Style switch

- (NSArray*)newChangeListBasedOnType:(GSFancyTextReferenceType)type withName:(NSString*)name {
    [self parseIfUnparsed];
    
    NSArray* changeList;
    if (type == GSFancyTextRoot) {
        changeList = [[NSMutableArray alloc] initWithObjects:self.parsedResultTree, nil];
    }
    else if (type == GSFancyTextID) {
        GSMarkupNode* theNode = [self.parsedResultTree childNodeWithID:name];
        if (theNode) {
            changeList = [[NSMutableArray alloc] initWithObjects:theNode, nil];
        }
        else {
            changeList = [[NSMutableArray alloc] initWithCapacity:1];
        }
    }
    else if (type == GSFancyTextClass){
        changeList = GSRetained([self.parsedResultTree childrenNodesWithClassName:name]);
    }
    return changeList;
}

- (NSMutableDictionary*)newStylesFromClassName:(NSString*)className elementName:(NSString*)elementName {
    NSMutableDictionary* resultStyles = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    NSMutableDictionary* allClasses = [self.style objectForKey:GSFancyTextDefaultClass];
    if (allClasses) {
        [resultStyles setValuesForKeysWithDictionary:[allClasses objectForKey: className]];
    }
    NSMutableDictionary* elementClasses = [self.style objectForKey:elementName];
    if (elementClasses) {
        [resultStyles setValuesForKeysWithDictionary:[elementClasses objectForKey: className]];
    }
    [resultStyles setValue: className forKey:GSFancyTextClassKey];
    
    return resultStyles;
}

- (void)changeAttribute:(NSString*)attribute to:(id)value on:(GSFancyTextReferenceType)type withName:(NSString*)name {
    NSMutableDictionary* stylesToAdd = [[NSMutableDictionary alloc] initWithObjectsAndKeys:value, attribute, nil];
    [self addStyles:stylesToAdd on:type withName:name];
    GSRelease(stylesToAdd);
}

- (void)addStyles:(NSMutableDictionary*)styles on:(GSFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (GSMarkupNode* node in changeList) {
        [node applyAndSpreadStyles:styles removeOldStyles:NO];
    }
    GSRelease(changeList);
}

- (void)applyClass:(NSString*)className on:(GSFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (GSMarkupNode* node in changeList) {
        NSMutableDictionary* styles = [self newStylesFromClassName:className elementName:[node.data objectForKey:GSFancyTextElementNameKey]];
        [node applyAndSpreadStyles:styles removeOldStyles:NO];
        GSRelease(styles);
    }
    GSRelease(changeList);
}

- (void)changeStylesToClass:(NSString*)className on:(GSFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (GSMarkupNode* node in changeList) {
        NSMutableDictionary* styles = [self newStylesFromClassName:className elementName:[node.data objectForKey:GSFancyTextElementNameKey]];
        [node applyAndSpreadStyles:styles removeOldStyles:YES];
        GSRelease(styles);
    }
    GSRelease(changeList);
}

#pragma mark - draw

- (void)drawInRect:(CGRect)rect {
    
    #ifdef GS_DEBUG_PERFORMANCE
    NSDate* startDraw = [NSDate date];
    #endif
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat frameWidth = rect.size.width;
    
    if (width_ != frameWidth) {
        width_ = frameWidth;
        [self generateLines];
    }
    else if (!lines_) {
        [self generateLines];
    }
    
    // x, y, h, w, baseline are line level parameters
    CGFloat x = 0.f;
    CGFloat y = rect.origin.y;
    __block CGFloat h = 0.f;
    __block CGFloat w = 0.f;
    __block CGFloat baseline = 0.f;
    
    // the following are segment level paramters, each line may have several segments
    __block NSArray* segments;
    __block NSDictionary* segment;
    __block CGFloat segmentHeight;
    __block CGFloat segmentWidth;
    __block UIFont* segmentFont;
    __block NSString* segmentText;
    __block BOOL segmentIsLambda;
    __block CGFloat segmentBaseline;
    __block CGFloat lineWidthLimit = 0;
    CGFloat lineLeftMargin = 0;
    __block CGFloat lineRightMargin = 0;
    int lineID = -1;
    int previousLineID = -1;
    CGFloat previousLineBottomMargin = 0;
    
    void(^getSegmentAtIndexBlock) (int) = ^(int index) {
        segment = [segments objectAtIndex:index];
        segmentIsLambda = [[segment allKeys] containsObject:GSFancyTextInternalLambdaIDKey];
    };
    
    void(^getSegmentInfoBlock) () = ^(void) {
        segmentFont = [segment objectForKey:GSFancyTextFontKey];
        segmentText = [segment objectForKey: GSFancyTextTextKey];
        segmentBaseline = (segmentFont.lineHeight - segmentFont.ascender - segmentFont.descender)/2.f;
        //note that descender is a negative number. -descender is the absolute height of descender from the baseline
    };
    void(^getSegmentInfoWithWidthBlock) () = ^(void) {
        
        if (segmentIsLambda) {
            segmentWidth = [[segment objectForKey:GSFancyTextWidthKey] floatValue];
        }
        else {
            getSegmentInfoBlock();
            segmentWidth = [segmentText sizeWithFont:segmentFont].width;
        }
        CGFloat left = frameWidth - lineRightMargin - w;
        if (segmentWidth > left) {
            segmentWidth = left;
        }
    };
    void(^updateLineTextHeightBlock) () = ^(void) {
        if (segmentIsLambda) {
            segmentHeight = [[segment objectForKey:GSFancyTextHeightKey] floatValue];
        }
        else {
            segmentHeight = [(UIFont*)[segment objectForKey:GSFancyTextFontKey] lineHeight];
        }
        NSString* specifiedHeight = [segment objectForKey:GSFancyTextLineHeightKey];
        if (specifiedHeight) {
            segmentHeight = [specifiedHeight possiblyPercentageNumberWithBase:segmentHeight];
        }
        if (segmentHeight > h) {
            h = segmentHeight;
            baseline = segmentBaseline; // we use the baseline of the biggest font to be the standard baseline of this line
        }
    };
    
    for (int l=0; l < lines_.count; l++){
        segments = [lines_ objectAtIndex:l];
        if (!segments.count) {
            continue;
        }
        NSDictionary* firstSegment = [segments objectAtIndex:0];
        lineLeftMargin = [[firstSegment objectForKey:GSFancyTextMarginLeft] possiblyPercentageNumberWithBase:frameWidth];
        lineRightMargin = [[firstSegment objectForKey:GSFancyTextMarginRight] possiblyPercentageNumberWithBase:frameWidth];
        lineWidthLimit = frameWidth - lineLeftMargin - lineRightMargin;
        
        lineID = [[firstSegment objectForKey:GSFancyTextLineIDKey] intValue];
        if (previousLineID>=0 && lineID!=previousLineID) {
            y += previousLineBottomMargin;
        }
        
        // determine if we need to calculate total width
        GSTextAlign align = 0;
        NSNumber* alignNumber = [firstSegment objectForKey:GSFancyTextTextAlignKey];
        if (alignNumber) {
            align = [alignNumber intValue];
        }
        
        BOOL advancedTruncation = [[firstSegment objectForKey:GSFancyTextAdvancedTruncationKey] boolValue];
        
        h = 0.f;
        w = 0.f;
        
        // first loop: preparation (pre-calculate width, height and starting x)
        NSMutableArray* widthForSegment = nil; // the width for each segment. Use this only for head and middle truncation.
        // because for tail truncation and clip, space assignment is first come first serve.
        
        if (advancedTruncation) {
            // advanced truncation case.. a lot of shit here
            widthForSegment = [[NSMutableArray alloc] initWithCapacity:segments.count];
            CGFloat totalWidth = 0;
            for (int i = 0; i<segments.count; i++) {
                getSegmentAtIndexBlock(i);
                getSegmentInfoWithWidthBlock();
                updateLineTextHeightBlock();
                [widthForSegment addObject:[NSNumber numberWithFloat:segmentWidth]];
                totalWidth += segmentWidth;
            }
            if (totalWidth > lineWidthLimit) {
                for (int i = 0; i<segments.count; i++) {
                    getSegmentAtIndexBlock(i);
                    CGFloat maxWidth = [[widthForSegment objectAtIndex:i] floatValue];
                    NSString* minWidthString = [segment objectForKey:GSFancyTextMinWidthKey];
                    CGFloat minWidth = minWidthString? [minWidthString possiblyPercentageNumberWithBase:frameWidth] : maxWidth;
                    CGFloat roomToCut = maxWidth>minWidth? (maxWidth - minWidth) : 0.f;
                    CGFloat needToCut = totalWidth - lineWidthLimit;
                    
                    if (roomToCut >= needToCut) {
                        // if this segment is willing to get enough truncate to save the whole line, it's all set here
                        [widthForSegment replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:(maxWidth - needToCut)]];
                        break;
                    }
                    else if (roomToCut > 0) {
                        [widthForSegment replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:minWidth]];
                        totalWidth -= roomToCut;
                    }
                }
            }
        }
        else { // clip or truncate tail, the simplest cases
            for (int i = 0; i<segments.count; i++) {
                getSegmentAtIndexBlock(i);
                getSegmentInfoBlock();
                updateLineTextHeightBlock();
                BOOL needTotalLength = (align==GSTextAlignCenter || align==GSTextAlignRight);
                if (needTotalLength) {
                    getSegmentInfoWithWidthBlock();
                    w += segmentWidth;
                }
            }
        }
        
        
        
        // determine some geometries
        
        // Calculating starting X
        if (align==GSTextAlignLeft) {
            x = lineLeftMargin;
        }
        else if (align == GSTextAlignCenter) {
            x = lineLeftMargin + (lineWidthLimit - w)/2.f;
        }
        else if (align == GSTextAlignRight) {
            x = frameWidth - w - lineRightMargin;
        }
        if (x<0) {
            x = 0;
        }
        
        w = x; // since now w will mean the width of space covered by text that's already drawn (it will be used by blocks to determine the available width)
        x += rect.origin.x;
        CGFloat maxX = rect.origin.x + (frameWidth - lineRightMargin);
        
        // h, y related
        CGFloat lineTopMargin = [[[segments objectAtIndex:0] objectForKey:GSFancyTextMarginTop] possiblyPercentageNumberWithBase:h];
        previousLineBottomMargin = [[[segments objectAtIndex:0] objectForKey:GSFancyTextMarginBottom] possiblyPercentageNumberWithBase:h];
        
        // Drawing loop
        for (int i=0; i<segments.count; i++) {
            getSegmentAtIndexBlock(i);
            
            // get text(if necessary) and height, baseline
            if (segmentIsLambda) {
                segmentHeight = [[segment objectForKey:GSFancyTextHeightKey] floatValue];
                segmentBaseline = 0;
            }
            else {
                getSegmentInfoBlock();
                segmentHeight = segmentFont.lineHeight;
            }
            
            if (i==segments.count-1) {
                segmentWidth = lineWidthLimit - (w - lineLeftMargin);
            }
            else {
                // get confined width
                if (widthForSegment) {
                    segmentWidth = [[widthForSegment objectAtIndex:i] floatValue];
                    if (!segmentWidth) {
                        continue; // ignore segments that we don't have space for
                    }
                }
                else {
                    getSegmentInfoWithWidthBlock();
                }
            }
            
            // update y based on top margin 
            if (lineID != previousLineID) {
                // it's not for every line
                y += lineTopMargin;
                
                // we don't need to use previousLineID from here, so just set previousID to lineID
                previousLineID = lineID;
            }
            
            // get vertical align
            NSNumber* valignNumber = [segment objectForKey:GSFancyTextVerticalAlignKey];
            GSVerticalAlign valign = valignNumber ? [valignNumber intValue] : 0; // 0 is always the default, no matter what the default is
            CGFloat actualY;
            switch (valign) {
                case GSVerticalAlignBaseline:
                    actualY = y + h - segmentHeight - (baseline - segmentBaseline);
                    break;
                case GSVerticalAlignBottom:
                    actualY = y + h - segmentHeight;
                    break;
                case GSVerticalAlignMiddle:
                    actualY = y + (h-segmentHeight)/2;
                    break;
                case GSVerticalAlignTop:
                    actualY = y;
                    break;
            }
            
            // draw
            if (segmentIsLambda) {
                NSString* lambdaID = [segment objectForKey:GSFancyTextInternalLambdaIDKey];
                CGFloat lwidth = [[segment objectForKey:GSFancyTextWidthKey] floatValue];
                CGFloat lheight = [[segment objectForKey:GSFancyTextHeightKey] floatValue];
                void(^drawingBlock)(CGRect);
                if ((drawingBlock = [lambdaBlocks_ objectForKey:lambdaID])) {
                    CGRect rect = GSRectMakeRounded(x, actualY, lwidth, lheight);
                    drawingBlock(rect);
                }
                #ifdef GS_DEBUG_MARKUP
                else {
                    GSDebugLog(@"\n[Warning]\nBlock %@... undefined. A blank space will be created.\n\n", lambdaID);
                }
                #endif
            }
            else {
                // get color
                UIColor* segmentColor = [segment objectForKey:GSFancyTextColorKey];
                CGContextSetFillColorWithColor(ctx, [segmentColor CGColor]);
                CGContextSetStrokeColorWithColor(ctx, [segmentColor CGColor]);
                
                // get shadow if there is any
                NSString* segmentShadow = [segment objectForKey:GSFancyTextShadowKey];
                [self processShadow:segmentShadow forContext:ctx];
                
                // get truncation
                NSNumber* truncationNumber = [segment objectForKey:GSFancyTextTruncateModeKey];
                UILineBreakMode truncateMode = truncationNumber ? [truncationNumber intValue] : UILineBreakModeTailTruncation;
                
                // actually draw
                CGRect textArea = GSRectMakeRounded(x, actualY, segmentWidth, segmentHeight);
                [segmentText drawInRect:textArea withFont:segmentFont lineBreakMode:truncateMode];
            }
            
            x += segmentWidth;
            w += segmentWidth;
            
            if (x >= maxX) {
                break;
            }
        }
        
        GSRelease(widthForSegment);
        
        // Updating Y for the next line
        y += h;
    }
    y += previousLineBottomMargin;
    
    contentHeight_ = y - rect.origin.y;
    
    #ifdef GS_DEBUG_PERFORMANCE
    GSDebugLog(@"drawing time: %f", -[startDraw timeIntervalSinceNow]);
    #endif
    
}

- (void)defineLambdaID:(NSString*)lambdaID withBlock:(void(^)(CGRect))drawingBlock {
    if (!drawingBlock) {
        [lambdaBlocks_ removeObjectForKey:lambdaID];
    }
    else {
        // copy the block onto the heap
        void(^theBlock)(CGPoint) = GSAutoreleased([drawingBlock copy]);
        [lambdaBlocks_ setObject:theBlock forKey:lambdaID];
    }
}

#pragma mark - Processing drawing parameters

- (void)processShadow:(NSString*)shadowValue forContext:(CGContextRef)context {
    BOOL hasShadow = NO;
    CGFloat hOffset = 0.f;
    CGFloat vOffset = 0.f;
    CGFloat blur = 0.f;
    UIColor* color = nil;
    
    if (shadowValue) {
        NSArray* args = [shadowValue componentsSeparatedByString:@" "];
        if (args.count >= 2) {
            hasShadow = YES;
            hOffset = [[args objectAtIndex:0] floatValue];
            vOffset = [[args objectAtIndex:1] floatValue];
            if (args.count == 3) {
                color = [[self class] parseColor:[args objectAtIndex:2] intoDictionary:nil];
                if (!color) {
                    blur = [[args objectAtIndex:2] floatValue];
                }
            }
            else { // >=4
                blur = [[args objectAtIndex:2] floatValue];
                color = [[self class] parseColor:[args objectAtIndex:3] intoDictionary:nil];
            }
        }
    }
    
    if (hasShadow) {
        if (!color) {
            color = [UIColor blackColor];
        }
        CGContextSetShadowWithColor(context, CGSizeMake(hOffset, vOffset), blur, color.CGColor);
    }
    else {
        CGContextSetShadow(context, CGSizeMake(0.f, 0.f), 0.f);
    }
}

# pragma mark - Node searching

- (GSMarkupNode*)nodeWithID:(NSString*)nodeID {
    if (!parsedTree_) {
        [self parseStructure];
    }
    return [parsedTree_ childNodeWithID:nodeID];
}

- (NSArray*)nodesWithClass:(NSString*)className {
    if (!parsedTree_) {
        [self parseStructure];
    }
    return [parsedTree_ childrenNodesWithClassName:className];
}


# pragma mark - helper

+ (void)addObject:(NSObject*)object intoDict:(NSMutableDictionary*)dict underKey:(NSString*)key {
    NSMutableArray* array = [dict objectForKey:key];
    if (!array) {
        array = [[NSMutableArray alloc] initWithObjects:object, nil];
        [dict setObject:array forKey:key];
        GSRelease(array);
    }
    else {
        [array addObject:object];
    }
}

+ (void)cleanStyleDict:(NSMutableDictionary*)dict {

    if (![dict objectForKey:GSFancyTextLineIDKey]) {
        
        NSArray* attribsForPOnly = [[NSArray alloc] initWithObjects:GSFancyTextTextAlignKey, GSFancyTextLineCountKey, GSFancyTextMarginTop, GSFancyTextMarginBottom, GSFancyTextMarginLeft, GSFancyTextMarginRight, nil];
        
#ifdef GS_DEBUG_MARKUP
        NSArray* classNames = [dict objectForKey: GSFancyTextClassKey];
        NSString* elementName = [dict objectForKey: GSFancyTextElementNameKey];
        NSString* message = @"\n[Warning]\nFound definition of %@ in a <%@> tag through class %@. It is supposed to be set in <p> tags, and will be ignored here.\n\n";
        for (NSString* attrib in attribsForPOnly) {
            if ([dict objectForKey:attrib]) {
                GSDebugLog(message, attrib, elementName, classNames);
            }
        }
#endif
        for (NSString* attrib in attribsForPOnly) {
            [dict removeObjectForKey:attrib];
        }
        GSRelease(attribsForPOnly);
    }
}

#pragma mark - copy

/// @note: it will only copy user set info and parsing result, but not line generating result (including content height)
- (id)copy {
    // if the original one is parsed, then just copy the parsed result tree
    GSFancyText* newFancyText;
    if (self.parsedResultTree) {
        GSMarkupNode* newTree = [self.parsedResultTree copy];
        newFancyText = [[GSFancyText alloc] initWithParsedStructure:newTree];
        GSRelease(newTree);
    }
    else {
        NSString* newText = [self.text copy];
        newFancyText = [[GSFancyText alloc] initWithMarkupText:newText];
        GSRelease(newText);
    }
    newFancyText.width = self.width;
    newFancyText.maxHeight = self.maxHeight;
    
    NSMutableDictionary* newStyle = [self.style copy];
    newFancyText.style = newStyle;
    GSRelease(newStyle);
    
    NSMutableDictionary* newlambdaBlocks = [[NSMutableDictionary alloc] initWithCapacity:self.lambdaBlocks.allKeys.count]; //[self.lambdaBlocks copy];
    [newlambdaBlocks setValuesForKeysWithDictionary:self.lambdaBlocks];
    newFancyText.lambdaBlocks = newlambdaBlocks;
    GSRelease(newlambdaBlocks);
 
    return newFancyText;
}

@end
