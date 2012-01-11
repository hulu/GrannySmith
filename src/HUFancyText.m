//
//  HUFancyText.m
//  i2
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

#import "GTMNSString+HTML.h"

#import "HUFancyText.h"
#import "NSString+ParsingHelper.h"
#import "NSScanner+HierarchicalScan.h"
#import <objc/message.h>

/// globalStyleDictionary_ is a parsed style dictionary that can be accessed globally
static NSMutableDictionary* globalStyleDictionary_;

/// lineID_ is a tracker or P tags. Each P tag has a unique lineID so line breaking is based on that.
static int lineID_ = 1;

@interface HUFancyText (Private)


/** Part of newParsedStyle:
 * Parse the color:red; size:17; etc inside a style sheet
 */
+ (NSMutableDictionary*)newParsedStyleAttributesFromScanner:(NSScanner*)scanner;

/** part of newParsedMarkupString:withStyleDict:
 * Parse the "span class=abc", "/p", etc, inside the markup tags
 */
+ (NSMutableDictionary*)newStyleFromCurrentTagInScanner:(NSScanner*)scanner withStyleDict:(NSDictionary*)styleDict;

/** A factory-like interface method for creating value objects (e.g. color, text align mode)
 */
+ (NSObject*)parseValue: (NSString*)value forKey:(NSString*)key intoDictionary:(NSMutableDictionary*)dict;

/** Parse color string
 * @return a UIColor object
 * @param value can be rgb(255,255,255), #ffffff, red, blue, etc. When text is used, there has to be a [UIColor xxxColor] method to match it
 * @note default return is black is the value isn't recoginized
 */
+ (UIColor*)parsedColor:(NSString*)value;

/** Parse line height and store into the dict
 * @param value can be either just a number (in px), or a percentage like 100%
 */
+ (NSNumber*)parseLineHeight:(NSString *)value intoDictionary:(NSMutableDictionary*)dict;


/** Parse text align
 * @param value should be left, right or center
 * @return an NSNumber with TextAlign integer
 */
+ (NSNumber*)parsedTextAlign: (NSString*)value;

/** Parse vertical align
 * @param value should be middle, top or bottom
 * @return an NSNumber with VerticalAlign integer
 */
+ (NSNumber*)parsedVerticalAlign: (NSString*)value;

/** Parse truncate mode
 * @param value should be tail, head, middle, clip
 * @return an NSNumber with a UILineBreakMode value
 */
+ (NSNumber*)parsedTruncationMode: (NSString*)value;

/** Get a list of HUMarkupNode objects based on a class name or ID
 * @return a retained array. An emtpy array if there's no match.
 * @note call this after parsing 
 */
- (NSArray*)newChangeListBasedOnType:(HUFancyTextReferenceType)type withName:(NSString*)name;

/** get styles from a class defined in the style dictionary (parsed from css-like style sheet)
 */
- (NSMutableDictionary*)newStylesFromClassName:(NSString*)className elementName:(NSString*)elementName;


@end

@implementation HUFancyText

@synthesize lambdaBlocks = lambdaBlocks_;
@synthesize style = style_;
@synthesize width = width_;
@synthesize maxHeight = maxHeight_;
@synthesize text = text_;

#ifdef ARC_ENABLED
#else
- (void)dealloc {
    release(style_);
    release(text_);
    release(parsedTree_);
    release(lambdaBlocks_);
    [super dealloc];
}
#endif

- (id)initWithMarkupText:(NSString*)text styleDict:(NSMutableDictionary*)styleDict width:(CGFloat)width maxHeight:(CGFloat)maxHeight {
    if ((self = [super init])) {
        width_ = width;
        maxHeight_ = maxHeight;
        self.style = styleDict;
        self.text = text;
        contentHeight_ = 0.f;
        lambdaBlocks_ = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    }
    return self;
}

- (id)initWithMarkupText:(NSString*)text {
    return [self initWithMarkupText:text styleDict:globalStyleDictionary_ width:0 maxHeight:0];
}


- (id)initWithParsedStructure:(HUMarkupNode*)tree {
    if ((self = [super init])) {
        width_ = 0.f;
        maxHeight_ = 0.f;
        parsedTree_ = [tree copy];
        lambdaBlocks_ = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
        self.style = globalStyleDictionary_;
        self.text = @"";
    }
    return self;
}

- (void)appendStyleSheet:(NSString *)newStyleSheet {
    NSMutableDictionary* styleDict = [[self class] parsedStyle:newStyleSheet];
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

- (HUMarkupNode*)parsedResultTree {
    return parsedTree_;
}

- (NSString*)pureText {
    if (!parsedTree_) {
        [self parseStructure];
    }
    
    NSArray* segments_ = [parsedTree_ newDepthFirstOrderDataArray];
    
//    NSLog(@"segments:%@", segments_);
    
    NSMutableString* texts = [[NSMutableString alloc] init];
    
    int lineID = 0;
    int previousLineID = 0;
    // if there is a forced line break, we add a stop sign.
    
    for (NSMutableDictionary* segment in segments_) {
        lineID = [[segment objectForKey:HUFancyTextLineIDKey] intValue];
        if (lineID != previousLineID && texts.length) {
            [texts appendString:@". "];
        }
        NSString* text = [segment objectForKey: HUFancyTextTextKey];
        if (text) {
            [texts appendString:text];
        }
        previousLineID = lineID;
    }
    
    release(segments_);
    return autoreleased(texts);
}

- (CGFloat)contentHeight {
    return contentHeight_;
}

- (HUMarkupNode*)parseStructure {
    //NSDate* startTime = [NSDate date];
    
    if (!text_ || !text_.length) {
        // in case the object is initialized with already parsed structure instead of markup text
        return parsedTree_;
    }
    
    release(parsedTree_);
    parsedTree_ = [[self class] newParsedMarkupString:text_ withStyleDict:style_];
    
    //NSLog(@"time to parse markup: %f", -[startTime timeIntervalSinceNow]);
    return parsedTree_;
}

- (NSMutableArray*)generateLines {
    
//    NSDate* startTime = [NSDate date];
    
    // step 1. parsing
    if (!parsedTree_) {
        [self parseStructure];
    }
    __block NSArray* segments_ = [parsedTree_ newDepthFirstOrderDataArray];

    // step 2. line breaking
    
    if (!width_) {
        return nil;
    }
    release(lines_);
    lines_ = [[NSMutableArray alloc] initWithCapacity:segments_.count];
    
    __block float totalHeight = 0.f;
    
    // line level vars
    
    __block NSMutableArray* currentLine = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
    __block CGFloat currentLineSpaceLeft = width_;
    __block int currentLineIDActualLineCount = 0;
    __block int currentLineIDLineCountLimit = 0;
    __block NSString* currentLineLastText;
    __block TextAlign currentLineLastTextAlign;
    __block CGFloat currentLineContentHeight = 0.f;
    __block CGFloat currentLineSpecifiedHeight = 0.f;
    __block BOOL currentLineSpecifiedHeightIsPct = YES;
    
    // piece/segment level vars
    
    NSMutableDictionary* segment;
    NSString* segmentText;
    UIFont* segmentFont;
    // some segment info that will affect line breaking
    __block int segmentLineCount;
    // the alignment will not affect line breaking, but will determine whether we need to trim the trailing whitespace of last one in line
    __block NSNumber* segmentAlignNumber;
    __block TextAlign segmentAlign;
    // some segment info that will be used to calculate the final height of a line
    __block CGFloat segmentContentHeight;
    __block NSNumber* segmentLineHeightNumber;
    __block NSNumber* segmentLineHeightIsPctNumber;
    __block CGFloat segmentLineHeight;
    __block BOOL segmentLineHeightIsPct;
    int segmentLineID = 0;
    int previousSegmentLineID = -1; // previous segment's line ID
    
    BOOL(^insertLineBlock)() = ^(){
        // return NO means it already reached max line height and there's no need to add more
        if (currentLine.count) {
            
            if (currentLineLastTextAlign==TextAlignRight) {
                NSString* lineText = [currentLineLastText stringByTrimmingTrailingWhitespace];
                [[currentLine lastObject] setObject:lineText forKey:HUFancyTextTextKey];
            }
            
            if (currentLineIDLineCountLimit && currentLineIDActualLineCount >= currentLineIDLineCountLimit) {
                [[lines_ lastObject] addObjectsFromArray:currentLine];
            }
            else {
                CGFloat nextHeight;
                if (currentLineSpecifiedHeightIsPct) {
                    nextHeight = totalHeight + currentLineSpecifiedHeight * currentLineContentHeight;
                }
                else {
                    nextHeight = totalHeight + currentLineSpecifiedHeight;
                }
                if (maxHeight_ && nextHeight > maxHeight_) {
                    contentHeight_ = totalHeight;
                    release(currentLine);
                    release(segments_);
                    return NO;
                }
                [lines_ addObject: currentLine];                
                currentLineIDActualLineCount ++;
                totalHeight = nextHeight;
                if (maxHeight_ == totalHeight) {
                    contentHeight_ = totalHeight;
                    release(currentLine);
                    release(segments_);
                    return NO;
                }
            }
            release(currentLine);
            currentLine = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
            currentLineSpaceLeft = width_;
            currentLineContentHeight = 0.f;
        }
        return YES;
    };
    
    void(^insertPieceForCurrentLineBlock)(NSMutableDictionary*) = ^(NSMutableDictionary* piece) {
        [currentLine addObject: piece];
        
        // also update some line level information
        currentLineIDLineCountLimit = segmentLineCount;
        currentLineLastTextAlign = segmentAlign;
        currentLineSpecifiedHeight = segmentLineHeight;
        currentLineSpecifiedHeightIsPct = segmentLineHeightIsPct;
        
        // there are several properties that we need the whole line to be consistent
        // in the drawRect method of fancy text view, we just read the first (the first object might not have that property set)
        if (currentLine.count>1) {
            if (segmentAlignNumber) {
                [[currentLine objectAtIndex:0] setObject: segmentAlignNumber forKey:HUFancyTextTextAlignKey];
            }
            if (segmentLineHeightNumber) {
                [[currentLine objectAtIndex:0] setObject: segmentLineHeightNumber forKey:HUFancyTextLineHeightKey];
            }
            if (segmentLineHeightIsPctNumber) {
                [[currentLine objectAtIndex:0] setObject: segmentLineHeightIsPctNumber forKey:HUFancyTextHeightIsPercentageKey];
            }
            NSNumber* segmentTruncationModeNumber = [piece objectForKey:HUFancyTextTruncateModeKey];
            if (segmentTruncationModeNumber) {
                [[currentLine objectAtIndex:0] setObject: segmentTruncationModeNumber forKey:HUFancyTextTruncateModeKey];
            }
        }
        
        // update the total line content height
        if (segmentContentHeight > currentLineContentHeight) {
            currentLineContentHeight = segmentContentHeight;
        }
    };
    
    for (int i=0; i<segments_.count; i++) {
        segment = [segments_ objectAtIndex:i];
        
        // Special case: a new line is required due to some elements like <p>
        NSNumber* lineIDNumber = [segment objectForKey:HUFancyTextLineIDKey];
        segmentLineID = lineIDNumber ? [lineIDNumber intValue] : 0;
        if (segmentLineID != previousSegmentLineID) {
            if (!insertLineBlock() ) {
                return lines_;
            }
            currentLineIDActualLineCount = 0;
        }
        previousSegmentLineID = segmentLineID;
        
        // retrieve some common segment info (required by adding both lambda or text)
        NSString* segmentLineCountString = [segment objectForKey:HUFancyTextLineCountKey];
        segmentLineCount = segmentLineCountString ? [segmentLineCountString intValue] : 0;
        segmentAlignNumber = [segment objectForKey:HUFancyTextTextAlignKey];
        segmentAlign = segmentAlignNumber ? [segmentAlignNumber intValue] : TextAlignLeft;
        segmentLineHeightNumber = [segment objectForKey:HUFancyTextLineHeightKey];
        segmentLineHeight = segmentLineHeightNumber ? [segmentLineHeightNumber floatValue] : 1.f;
        segmentLineHeightIsPctNumber = [segment objectForKey:HUFancyTextHeightIsPercentageKey];
        segmentLineHeightIsPct = segmentLineHeightIsPctNumber ? [segmentLineHeightIsPctNumber boolValue] : YES;
        
        // adding the segment(s)
        
        if ([[segment allKeys] containsObject:HUFancyTextInternalLambdaIDKey]) {
            // a lambda segment
            
            // retrieve some lambda segment specific info
            CGFloat segmentWidth = [[segment objectForKey:HUFancyTextWidthKey] floatValue];
            segmentContentHeight = [[segment objectForKey:HUFancyTextHeightKey] floatValue];

            // conclude the previous line if it's too long
            if (currentLine.count && currentLineSpaceLeft<segmentWidth) {
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
                if (!insertLineBlock() ) {
                    return lines_;
                }
            }
        }
        else {
            // text segment
            
            // retrieve some text segment specific info
            segmentText = [segment objectForKey:HUFancyTextTextKey];
            segmentFont = [segment objectForKey:HUFancyTextFontKey];
            segmentContentHeight = [segmentFont lineHeight];
            
            // split the lines 
            // (the currentLineSpaceLeft might be altered by the insertLineBlock above)
            NSArray* segmentLines = [segmentText linesWithWidth:width_ font:segmentFont firstLineWidth:currentLineSpaceLeft limitLineCount:segmentLineCount];
            
            // a line can contain several pieces, each piece has its own style
            NSMutableDictionary* piece;
            
            for (int i=0; i<segmentLines.count; i++) {
                NSString* lineText = [segmentLines objectAtIndex:i];
                // NSLog(@"i=%d, lineText=%@", i, lineText);
                
                // Special case: if the current line is empty... conclude the previous line, if there is any
                if (lineText.length < 1) {
                    if (!insertLineBlock() ) {
                        return lines_;
                    }
                    continue;
                }
                
                // Setting fonts and properties for all cases
                piece = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
                [piece setValuesForKeysWithDictionary:segment];// update other params like color
                
                // Special case: if it's a new line, truncate the leading white spaces
                if (!currentLine.count && segmentAlign==TextAlignLeft) {
                    lineText = [lineText stringByTrimmingLeadingWhitespace];
                }
                
                // Add the current piece to the current line
                [piece setObject:lineText forKey: HUFancyTextTextKey];
                
                insertPieceForCurrentLineBlock(piece);
                
                // update the currentLineLastText, when we are concluding the line, if it's right align, we need to trim trailing space from last text
                currentLineLastText = lineText;
                
                release(piece);
                
                // Regular case: if it is not the last line, it means that this line is long enough to cover a whole line
                // Or: if the markup tag (aka p) requires it to be an independent line
                if (i != segmentLines.count -1 ) { // || (isNewLine && [isNewLine boolValue])) {
                    if (!insertLineBlock() ) {
                        return lines_;
                    }
                }
                else {
                    // for any unfinished line, calculate the width left for the current line
                    CGFloat widthUsed = [lineText sizeWithFont:segmentFont].width;
                    // NSLog(@"piece:%@, width used: %f", [piece objectForKey:HUFancyTextTextKey], widthUsed);
                    currentLineSpaceLeft = currentLineSpaceLeft - widthUsed;
                }
            }
        }
    }
    
    
    if (! insertLineBlock() ) {
        return lines_;
    }
    
    release(segments_);
    release(currentLine);
    
//    NSLog(@"the lines: %@", lines_);
//    NSLog(@"time to generate line: %f", -[startTime timeIntervalSinceNow]);
    
    contentHeight_ = totalHeight;
    return lines_;
}




#pragma mark - Parsers and class methods


typedef enum {
    ParsingStyleName,
    ParsingStyleContent,
} StyleSheetParseMode;

+ (NSMutableDictionary*)newParsedStyle: (NSString*)styleString {

    NSMutableDictionary* cssDict = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    
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
        // NSLog(@"scan result (outer): %@ (@%d)", currentText, scanner.scanLocation);
        nameParts = [currentText componentsSeparatedByString:@"."];
        
        if (nameParts.count==1) {
            elementName = [fancyTextTrim(currentText) lowercaseString];
            if (elementName.length) {
                className = HUFancyTextDefaultClass;
            }
            else {
                className = @"";
            }
        }
        else if (nameParts.count==2){
            className = [fancyTextTrim( [nameParts objectAtIndex:1]) lowercaseString];
            elementName = [fancyTextTrim( [nameParts objectAtIndex:0]) lowercaseString];
            if (!elementName.length) {
                elementName = HUFancyTextDefaultClass;
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
        release(propertyList);
        
        // after the inner content scan finished, the location is at }, so it should be skipped in the next scan's result
        lengthToSkip = 1;
    }
    release(scanner);
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
    
    NSMutableDictionary* propertyList = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    
    NSString* currentText;
    NSString* currentAttribName;
    NSString* currentValue;
    AttributeParseMode mode = ParsingAttribName;
    NSString* scanTo;
    int lengthToSkip = 1; // initial skip length is 1 because the scanner is currently at the "{" location
    ScanResult scanResult = ScanMeetTarget;
    
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
                scanResult = [scanner scanWithScanResultUpToString:scanTo intoString: &currentText];
                break;
        }
        currentText = [currentText substringFromIndex: lengthToSkip];
        
        // analyzing scan result
        // NSLog(@"scanned text (inner): %@", currentText);
        switch (mode) {
            case ParsingAttribName:{
                currentAttribName = [fancyTextTrim([NSString stringWithString:currentText]) lowercaseString];
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
                currentValue = fancyTextTrim(currentText);
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
    return autoreleased([[self class] newParsedStyle:style]);
}

typedef enum {
    ParsingPureText,
    ParsingTaggedText,
    ParsingOpeningTag,
    ParsingOpeningOrClosingTag,
} ParseMode;


+ (HUMarkupNode*)newParsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict {
    // result container
    HUMarkupNode* resultRoot = [[HUMarkupNode alloc] init];
    resultRoot.isContainer = YES;
    
    NSMutableDictionary* idMap = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];  // id must be unique, so the value is just an HUMarkupString node pointer
    NSMutableDictionary* classesMap = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize]; // classes won't be unique, so the value is an array
    // the two maps will be added to the data of root node eventually 
    
    // 2 stacks were used to help maintain the containers and styles
    NSMutableArray* tagStack = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
    NSMutableArray* containerStack = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
    [containerStack addObject:resultRoot];
    
    // data structure preparation
    NSScanner* scanner = [[NSScanner alloc] initWithString: markup];
    NSString* currentSegmentText;
    NSString* lookFor = @"<";
    int lengthToSkip=0;
    NSMutableDictionary* defaultStyle = [NSMutableDictionary dictionaryWithObjectsAndKeys:[UIColor blackColor], HUFancyTextColorKey,
                                         HUFancyTextDefaultFontFamily, HUFancyTextFontNameKey,
                                         [NSNumber numberWithFloat:[UIFont systemFontSize]], HUFancyTextFontSizeKey,
                                         nil];
    NSMutableDictionary* allClasses = [styleDict objectForKey:HUFancyTextDefaultClass];
    if (allClasses) {
        [defaultStyle setValuesForKeysWithDictionary:[allClasses objectForKey:HUFancyTextDefaultClass]];
    }
    
    // set the default font here
    [[self class] createFontKeyForDict: defaultStyle];

    HUMarkupNode* currentSegment;
    
    // Let the parsing begin!
    while (![scanner isAtEnd]) {
        
        currentSegmentText = @"";
        [scanner scanUpToString:lookFor intoString:&currentSegmentText];
        
        if (!currentSegmentText || currentSegmentText.length < lengthToSkip) {
            continue;
        }
        
        currentSegmentText = [currentSegmentText substringFromIndex:lengthToSkip];
        
        // outside the HTML tags.. do unescape to take care of &gt; &lt; etc
        currentSegmentText = [currentSegmentText gtm_stringByUnescapingFromHTML];
        
        // NSLog(@"segment text:%@ (length=%d)", currentSegmentText, currentSegmentText.length);
        
        if (currentSegmentText.length) {
            currentSegment = [[HUMarkupNode alloc] init];
            [currentSegment.data setObject:[NSString stringWithString:currentSegmentText] forKey:HUFancyTextTextKey];
            [currentSegment.data setValuesForKeysWithDictionary:defaultStyle];
            // apply all the styles in the stack.
            for (HUMarkupNode* node in containerStack) {
                [currentSegment.data setValuesForKeysWithDictionary: node.data];
            }
            currentSegment.isContainer = NO;
            
            // set the font based on font-related keys here, because all tags that apply to this segment is analyzed
            [[self class] createFontKeyForDict: currentSegment.data];
            
            // NSLog(@"adding %@", currentSegment.data);
            
            [[containerStack lastObject] appendChild:currentSegment];
            
            release(currentSegment);
        }
        
        NSMutableDictionary* stylesInTag = [[self class] newStyleFromCurrentTagInScanner:scanner withStyleDict:styleDict];

        // whether it's a lambda tag or style tag, there is going to be a tree node to insert
        HUMarkupNode* nodeToAdd = [[HUMarkupNode alloc] init];
        
        if ([stylesInTag allKeys].count) {
            
            // handling several special keys: elementName, isClosingTag, ID, class
            NSString* elementName = [stylesInTag objectForKey: HUFancyTextElementNameKey];
//            NSLog(@"getting HUFancyTextElementNameKey name as %@", elementName);
            
            BOOL isClosingTag = [[stylesInTag objectForKey:HUFancyTextTagClosingKey] boolValue];
            [stylesInTag removeObjectForKey:HUFancyTextTagClosingKey];
            
            NSString* tagID = [stylesInTag objectForKey: HUFancyTextIDKey];
            if (tagID) {
                [idMap setObject:nodeToAdd forKey:tagID];
            }
            
            NSArray* tagClassNames = [stylesInTag objectForKey: HUFancyTextClassKey];
            if (tagClassNames) {
                for (NSString* className in tagClassNames) {
                    [[self class] addObject:nodeToAdd intoDict:classesMap underKey:className];
                }
            }
            
            // handle the tag based on if it's a lambda or opening tag or closing tag
            if ([elementName caseInsensitiveCompare: HUFancyTextLambdaElement]==NSOrderedSame) {
                [nodeToAdd.data setValuesForKeysWithDictionary:stylesInTag];
                for (HUMarkupNode* node in containerStack) {
                    [nodeToAdd.data setValuesForKeysWithDictionary: node.data];
                }
                nodeToAdd.isContainer = NO;
                [[containerStack lastObject] appendChild:nodeToAdd];
                NSString* lambdaID = [nodeToAdd.data objectForKey:HUFancyTextInternalLambdaIDKey];
                [nodeToAdd.data setObject:lambdaID forKey:HUFancyTextIDKey];
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
        release(nodeToAdd);
        release(stylesInTag);
        
//        NSLog(@"after taking care of a tag. the location:%@", [scanner atCharacter]);
        lengthToSkip = 1;
        // after scanning a tag, we are expected to be at the > position
        // we don't move scanner location because in that way the first space after > will be skipped in the next scan (damn it apple!)
        // so we set a lengthToSkip to skip the > for the next scan
    }
    
    release(scanner);
    release(containerStack);
    release(tagStack);
    // NSLog(@"segments: %@", segments);
    
    resultRoot.IDMap = idMap;
    resultRoot.classesMap = classesMap;
    
    release(idMap);
    release(classesMap);
    
//    NSLog(@"tree (right after generation):\n%@", [resultRoot displayTree]);
    
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
    
    NSMutableDictionary* style = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    
    // scanning params
    InTagParsingMode mode = ParsingTagName;
    ScanResult scanResult = ScanMeetTarget;
    NSString* scanTo;
    NSString* currentText;
    
    // result containers
    NSString* elementName = nil;
    NSString* classNames = nil;
    BOOL knownElement = YES;
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
    [style setObject:[NSNumber numberWithBool:isClosing] forKey:HUFancyTextTagClosingKey];
    
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
                scanResult = [scanner scanWithScanResultUpToString:scanTo intoString:&currentText];
                break;
        }
        
//        NSLog(@"scan result: %@. scanTo:%@ scanResult=%d", currentText, scanTo, scanResult);
        
        // handling read text
        switch (mode) {
            case ParsingTagName:
                elementName = [fancyTextTrim(currentText) lowercaseString];
                
//                NSLog(@"setting element name to %@", elementName);
                [style setObject:elementName forKey: HUFancyTextElementNameKey];
                
                /** Some supported markup tags
                 */
                if (!isClosing) {
                    if ([elementName caseInsensitiveCompare:HUFancyTextStrongElement]==NSOrderedSame) {
                        [style setObject:@"bold" forKey:HUFancyTextFontWeightKey];
                    }
                    else if ([elementName caseInsensitiveCompare:HUFancyTextEmElement]==NSOrderedSame) {
                        [style setObject:@"italic" forKey:HUFancyTextFontStyleKey];
                    }
                    else if ([elementName caseInsensitiveCompare:HUFancyTextPElement]==NSOrderedSame) {
                        lineID_++;
                        [style setObject:[NSNumber numberWithInt: lineID_ ] forKey:HUFancyTextLineIDKey];
                    }
                    else if ([elementName caseInsensitiveCompare:HUFancyTextSpanElement]==NSOrderedSame ||
                             [elementName caseInsensitiveCompare:HUFancyTextLambdaElement]==NSOrderedSame
                             ) {
                        // don't set the line ID in this case, so if there's an outer <p>, it inherits
                    }
                    else {
                        knownElement = NO;
                    }
                }
                mode = ParsingLhs;
                if (scanResult==ScanMeetTarget) {
                    scanner.scanLocation += fancyTextTrim(scanTo).length;
                }
                break;
            case ParsingLhs:{
                attribName = fancyTextTrim(currentText);
                if ([attribName caseInsensitiveCompare:HUFancyTextClassKey]==NSOrderedSame) {
                    attrib = ReadingClass; // currently we only care about class=, otherwise we should use an enum instead of BOOL
                }
                else if ([elementName caseInsensitiveCompare:HUFancyTextLambdaElement]==NSOrderedSame) {
                    attrib = ReadingLambdaAttrib;
                }
                else {
                    attrib = ReadingNothing;
                }
                
                NSString* content = [scanner string];
                int nextCharLocation;
                NSString* next = [content firstNonWhitespaceCharacterSince:scanner.scanLocation+1 foundAt:&nextCharLocation];
//                NSLog(@"(reading %d, after =) next: %@ (at %d of %d)", attrib, next, nextCharLocation, scanner.string.length);
                
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
                        scanner.scanLocation += fancyTextTrim(scanTo).length;
                    }
                }
                break;
            }
            case ParsingUnquotedRhs:
            case ParsingDoubleQuotedRhs:
            case ParsingSingleQuotedRhs:
                if (knownElement && !isClosing) {
                    if (attrib == ReadingClass) {
                        classNames = fancyTextTrim(currentText);
                        
                        NSArray* individualClassNames = [classNames componentsSeparatedByString:@" "];
                        // apply class styles of all classes
                        for (NSString* className in individualClassNames) {
                            NSMutableDictionary* allClasses = [styleDict objectForKey:HUFancyTextDefaultClass];
                            if (allClasses) {
                                //[style setValuesForKeysWithDictionary:[allClasses objectForKey: HU_FANCY_TEXT_ALL_VALUE]];//don't need this because the default default is already applied outside
                                [style setValuesForKeysWithDictionary:[allClasses objectForKey: className]];
                            }
                            NSMutableDictionary* elementClasses = [styleDict objectForKey:elementName];
                            if (elementClasses) {
                                [style setValuesForKeysWithDictionary:[elementClasses objectForKey: HUFancyTextDefaultClass]];
                                [style setValuesForKeysWithDictionary:[elementClasses objectForKey: className]];
                            }
                        }
                        [style setValue: individualClassNames forKey:HUFancyTextClassKey];
                    }
                    else if (attrib == ReadingLambdaAttrib) {
                        if ([attribName caseInsensitiveCompare:HUFancyTextIDKey]==NSOrderedSame) {
                            [style setObject:fancyTextTrim(currentText) forKey:HUFancyTextInternalLambdaIDKey];
                            [style setObject:fancyTextTrim(currentText) forKey:HUFancyTextIDKey];
                        }
                        else {
//                            [style setObject:[[self class] parsedValue:fancyTextTrim(currentText) forKey:attribName] forKey: attribName];
                            [[self class] parseValue:fancyTextTrim(currentText) forKey:attribName intoDictionary:style];
                        }
                    }
                    else if ([attribName caseInsensitiveCompare:HUFancyTextIDKey]==NSOrderedSame) {
                        // save the ID as one attribute
                        [style setObject:fancyTextTrim(currentText) forKey:HUFancyTextIDKey];
                    }
                }
                mode = ParsingLhs;
                if (scanResult==ScanMeetTarget) {
                    scanner.scanLocation += fancyTextTrim(scanTo).length;
                }
//                NSLog(@"mode changed to parsingLHS, scanner at: %@", [scanner atCharacter]);
                break;
        }
    }
    
//    NSLog(@"end of tag: location: %@", [scanner atCharacter]);
    return style;
}


+ (HUMarkupNode*)parsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict {
    return autoreleased([[self class] newParsedMarkupString:markup withStyleDict:styleDict]);
}


+ (NSObject*)parseValue: (NSString*)value forKey:(NSString*)key intoDictionary:(NSMutableDictionary*)dict {
    
    if ([key caseInsensitiveCompare:HUFancyTextLineHeightKey]==NSOrderedSame) {
        return [[self class] parseLineHeight:value intoDictionary:dict];
    }
    
    NSObject* object;
    if ([key caseInsensitiveCompare:HUFancyTextColorKey]==NSOrderedSame) {
        object = [[self class] parsedColor:value];
    }
    else if ([key caseInsensitiveCompare:HUFancyTextTextAlignKey]==NSOrderedSame) {
        object = [[self class] parsedTextAlign:value];
    }
    else if ([key caseInsensitiveCompare:HUFancyTextTruncateModeKey]==NSOrderedSame) {
        object = [[self class] parsedTruncationMode:value];
    }
    else if ([key caseInsensitiveCompare:HUFancyTextVerticalAlignKey]==NSOrderedSame) {
        object = [[self class] parsedVerticalAlign:value];
    }
    else {
        object = [NSString stringWithString:value];
        // just to be consistent with other cases, return an autorelease copy instead of just value
        // e.g. jic the code before this call is value=[[xxx alloc] init], and after this call there is a release(value)
    }
    
    if (dict) {
        [dict setObject:object forKey:key];
    }
    return object;
}

+ (UIColor*)parsedColor:(NSString *)value_ {
    NSString* value = [value_ lowercaseString];
    if (!value.length) {
        return [UIColor blackColor];
    }
    else if ([[value substringToIndex:1] isEqualToString:@"#"]) {
        unsigned result = 0;
        NSScanner *scanner = [NSScanner scannerWithString:value];
        
        [scanner setScanLocation:1]; // bypass '#' character
        [scanner scanHexInt:&result];
        return fancyTextRGB(result);
    }
    else if ([value rangeOfString:HUFancyTextRGBValue].location != NSNotFound) {
        value = [value stringByReplacingOccurrencesOfString:HUFancyTextRGBValue withString:@""];
        value = [value stringByReplacingOccurrencesOfString:@"(" withString:@""];
        value = [value stringByReplacingOccurrencesOfString:@")" withString:@""];
        NSArray* colors = [value componentsSeparatedByString:@","];
        if (colors.count != 3) {
            return [UIColor blackColor];
        }
        CGFloat r = [(NSString*)[colors objectAtIndex:0] floatValue];
        CGFloat g = [(NSString*)[colors objectAtIndex:1] floatValue];
        CGFloat b = [(NSString*)[colors objectAtIndex:2] floatValue];
        
        return [UIColor colorWithRed:r/255.f green:g/255.f blue:b/255.f alpha:1];
    }
    else {
        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@Color", value]);
        if ([[UIColor class] respondsToSelector: sel]) {
            return objc_msgSend([UIColor class], sel);
        }
    }
    return [UIColor blackColor];
}

+ (NSNumber*)parseLineHeight:(NSString *)value intoDictionary:(NSMutableDictionary*)dict {
    // don't want to do this logic in draw rect..
    NSNumber* object;
    if ([value rangeOfString:@"%"].location == value.length - 1) {
        float percentage = [[value stringByReplacingOccurrencesOfString:@"%" withString:@""] floatValue];
        if (!percentage) {
            percentage = 100;
        }
        object = [NSNumber numberWithFloat: percentage/100.f];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:HUFancyTextHeightIsPercentageKey];
    }
    else {
        float px = [value floatValue];
        if (!px) {
            return [NSNumber numberWithFloat: 1];
        }
        object = [NSNumber numberWithFloat: px]; // only use the px value when it's > 10
        [dict setObject:[NSNumber numberWithBool:NO] forKey:HUFancyTextHeightIsPercentageKey];
    }
    [dict setObject:object forKey:HUFancyTextLineHeightKey];
    return object;
}


+ (NSNumber*)parsedTextAlign: (NSString*)value {
    if ([value caseInsensitiveCompare:HUFancyTextAlignCenterValue]==NSOrderedSame) {
        return [NSNumber numberWithInt: TextAlignCenter];
    }
    else if ([value caseInsensitiveCompare:HUFancyTextAlignRightValue]==NSOrderedSame ) {
        return [NSNumber numberWithInt: TextAlignRight];
    }
    else {
        return [NSNumber numberWithInt: TextAlignLeft];
    }
}

+ (NSNumber*)parsedVerticalAlign: (NSString*)value {    
    VerticalAlign result = VerticalAlignBaseline;
    if ([value caseInsensitiveCompare:HUFancyTextVAlignMiddleValue]==NSOrderedSame) {
        result = VerticalAlignMiddle;
    }
    else if ([value caseInsensitiveCompare:HUFancyTextVAlignTopValue]==NSOrderedSame ) {
        result = VerticalAlignTop;
    }
    else if ([value caseInsensitiveCompare:HUFancyTextVAlignBottomValue]==NSOrderedSame ) {
        result = VerticalAlignBottom;
    }
    return [NSNumber numberWithInt: result];
}

+ (NSNumber*)parsedTruncationMode: (NSString*)value {
    UILineBreakMode mode;
    if ([value caseInsensitiveCompare:HUFancyTextTruncateHeadValue]==NSOrderedSame) {
        mode = UILineBreakModeHeadTruncation;
    }
    else if ([value caseInsensitiveCompare:HUFancyTextTruncateMiddleValue]==NSOrderedSame) {
        mode = UILineBreakModeMiddleTruncation;
    }
    else if ([value caseInsensitiveCompare:HUFancyTextTruncateClipValue]==NSOrderedSame) {
        mode = UILineBreakModeClip;
    }
    else {
        mode = UILineBreakModeTailTruncation;
    }
    return [NSNumber numberWithInt: mode];
}


static NSMutableDictionary* fontMemory_;
+ (UIFont*)fontWithName:(NSString*)name size:(CGFloat)size weight:(NSString*)weight style:(NSString*)style {    
    
    if (!fontMemory_) {
        fontMemory_ = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    }
    
    NSString* realFontName = name;
    
    BOOL bold = weight? [weight caseInsensitiveCompare:HUFancyTextBoldValue]==NSOrderedSame : NO;
    BOOL italic = style? [style caseInsensitiveCompare:HUFancyTextItalicValue]==NSOrderedSame : NO;
    
    if (!size) {
        size = [UIFont systemFontSize];
    }
        
    NSString* familyName;
    NSArray* fontFamilies = [UIFont familyNames];
    
    if ([fontFamilies containsObject:name]) {
        familyName = name;
    }
    else {
        familyName = HUFancyTextDefaultFontFamily;
    }
    NSArray* availableFontNames = [UIFont fontNamesForFamilyName:familyName];
    
    if (!availableFontNames.count) {
        familyName = HUFancyTextDefaultFontFamily;
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
    
//    NSLog(@"in: %@,%@,%@,  out:%@", name, weight, style, realFontName);
    return [UIFont fontWithName:realFontName size:size];
}

+ (void)createFontKeyForDict:(NSMutableDictionary*)dict {
    UIFont* finalFont = [[self class] fontWithName: [dict objectForKey:HUFancyTextFontNameKey]
                                              size: [[dict objectForKey:HUFancyTextFontSizeKey] floatValue]
                                            weight: [dict objectForKey:HUFancyTextFontWeightKey]
                                             style: [dict objectForKey:HUFancyTextFontStyleKey]
                         ];
    [dict setObject:finalFont forKey:HUFancyTextFontKey];
    
    // keep these individual keys because we might need to change one of them later and regenerate the font
//    [dict removeObjectForKey: HUFancyTextFontNameKey];
//    [dict removeObjectForKey: HUFancyTextFontSizeKey];
//    [dict removeObjectForKey: HUFancyTextFontWeightKey];
//    [dict removeObjectForKey: HUFancyTextFontStyleKey];
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
    release(globalStyleDictionary_);
    globalStyleDictionary_ = [[self class] newParsedStyle:styleSheet];
    return globalStyleDictionary_;
}

+ (NSMutableDictionary*)globalStyle {
    return globalStyleDictionary_;
}

#pragma mark - Content switch

- (void)changeNodeToText:(NSString*)text forID:(NSString*)nodeID {
    if (self.parsedResultTree) {
        HUMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            [theNode resetChildToText:text];
        }
    }
}

- (void)changeNodeToStyledText:(NSString*)styledText forID:(NSString*)nodeID {
    if (self.parsedResultTree) {
        HUMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            // do it only when the current HUFancyText is parsed and has the nodeID
            
            [theNode dismissAllChildren];
            HUMarkupNode* newTree = [[self class] parsedMarkupString:styledText withStyleDict:self.style];
            [self.parsedResultTree appendSubtree:newTree underNode:theNode];
        }
    }
}

- (void)removeID: (NSString*)nodeID {
    if (self.parsedResultTree) {
        HUMarkupNode* theNode = [self.parsedResultTree childNodeWithID:nodeID];
        if (theNode) {
            [theNode cutFromParent];
        }
    }
}

#pragma mark - Style switch

- (NSArray*)newChangeListBasedOnType:(HUFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList;
    if (type == HUFancyTextRoot) {
        changeList = [[NSMutableArray alloc] initWithObjects:self.parsedResultTree, nil];
    }
    else if (type == HUFancyTextID) {
        HUMarkupNode* theNode = [self.parsedResultTree childNodeWithID:name];
        if (theNode) {
            changeList = [[NSMutableArray alloc] initWithObjects:theNode, nil];
        }
        else {
            changeList = [[NSMutableArray alloc] initWithCapacity:1];
        }
    }
    else if (type == HUFancyTextClass){
        changeList = retained([self.parsedResultTree childrenNodesWithClassName:name]);
    }
    return changeList;
}

- (NSMutableDictionary*)newStylesFromClassName:(NSString*)className elementName:(NSString*)elementName {
    NSMutableDictionary* resultStyles = [[NSMutableDictionary alloc] initWithCapacity:HUFancyTextTypicalSize];
    
    NSMutableDictionary* allClasses = [self.style objectForKey:HUFancyTextDefaultClass];
    if (allClasses) {
        [resultStyles setValuesForKeysWithDictionary:[allClasses objectForKey: className]];
    }
    NSMutableDictionary* elementClasses = [self.style objectForKey:elementName];
    if (elementClasses) {
        [resultStyles setValuesForKeysWithDictionary:[elementClasses objectForKey: className]];
    }
    [resultStyles setValue: className forKey:HUFancyTextClassKey];
    
    return resultStyles;
}

- (void)changeAttribute:(NSString*)attribute to:(id)value on:(HUFancyTextReferenceType)type withName:(NSString*)name {
    NSMutableDictionary* stylesToAdd = [[NSMutableDictionary alloc] initWithObjectsAndKeys:value, attribute, nil];
    [self addStyles:stylesToAdd on:type withName:name];
    release(stylesToAdd);
}

- (void)addStyles:(NSMutableDictionary*)styles on:(HUFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (HUMarkupNode* node in changeList) {
        [node applyAndSpreadStyles:styles removeOldStyles:NO];
    }
    release(changeList);
}

- (void)applyClass:(NSString*)className on:(HUFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (HUMarkupNode* node in changeList) {
        NSMutableDictionary* styles = [self newStylesFromClassName:className elementName:[node.data objectForKey:HUFancyTextElementNameKey]];
        [node applyAndSpreadStyles:styles removeOldStyles:NO];
//        NSLog(@"node.child.style: %@", [[node.children objectAtIndex:0] data]);
        release(styles);
    }
    release(changeList);
}

- (void)changeStylesToClass:(NSString*)className on:(HUFancyTextReferenceType)type withName:(NSString*)name {
    NSArray* changeList = [self newChangeListBasedOnType:type withName:name];
    for (HUMarkupNode* node in changeList) {
        NSMutableDictionary* styles = [self newStylesFromClassName:className elementName:[node.data objectForKey:HUFancyTextElementNameKey]];
        [node applyAndSpreadStyles:styles removeOldStyles:YES];
//        NSLog(@"node.child.style: %@", [[node.children objectAtIndex:0] data]);
        release(styles);
    }
    release(changeList);
}

#pragma mark - draw

- (void)drawInRect:(CGRect)rect {
    
    //NSDate* startDraw = [NSDate date];
    
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
    
    void(^getSegmentAtIndexBlock) (int) = ^(int index) {
        segment = [segments objectAtIndex:index];
        segmentIsLambda = [[segment allKeys] containsObject:HUFancyTextInternalLambdaIDKey];
    };
    
    void(^getSegmentInfoBlock) () = ^(void) {
        segmentFont = [segment objectForKey:HUFancyTextFontKey];
        segmentText = [segment objectForKey: HUFancyTextTextKey];
        segmentBaseline = (segmentFont.lineHeight - segmentFont.ascender - segmentFont.descender)/2.f;
        //note that descender is a negative number. -descender is the absolute height of descender from the baseline
        
        // NSLog(@"baseline of %@ is %f", segmentText, segmentBaseline);
    };
    void(^getSegmentInfoWithWidthBlock) () = ^(void) {
        
        if (segmentIsLambda) {
            segmentWidth = [[segment objectForKey:HUFancyTextWidthKey] floatValue];
        }
        else {
            getSegmentInfoBlock();
            segmentWidth = [segmentText sizeWithFont:segmentFont].width;
        }
        CGFloat left = frameWidth - w;
        if (segmentWidth > left) {
            segmentWidth = left;
        }
    };
    void(^updateLineTextHeightBlock) () = ^(void) {
        if (segmentIsLambda) {
            segmentHeight = [[segment objectForKey:HUFancyTextHeightKey] floatValue];
        }
        else {
            segmentHeight = [(UIFont*)[segment objectForKey:HUFancyTextFontKey] lineHeight];
        }
        if (segmentHeight > h) {
            h = segmentHeight;
            baseline = segmentBaseline; // we use the baseline of the biggest font to be the standard baseline of this line
            //            NSLog(@"setting line baseline to %f based on %@", segmentBaseline, segmentIsLambda? @"lambda": segmentText);
        }
    };
    
    for (int l=0; l < lines_.count; l++){
        segments = [lines_ objectAtIndex:l];
        
        // determine if we need to calculate total width
        TextAlign align = TextAlignLeft;
        NSNumber* alignNumber = [[segments objectAtIndex:0] objectForKey:HUFancyTextTextAlignKey];
        if (alignNumber) {
            align = [alignNumber intValue];
        }
        UILineBreakMode truncateMode = UILineBreakModeTailTruncation;
        NSNumber* truncateNumber = [[segments objectAtIndex:0] objectForKey:HUFancyTextTruncateModeKey];
        if (truncateNumber) {
            truncateMode = [truncateNumber intValue];
        }
        
        h = 0.f;
        w = 0.f;
        
        // first loop: preparation (pre-calculate width, height and starting x)
        NSMutableArray* widthForSegment = nil; // the width for each segment. Use this only for head and middle truncation.
        // because for tail truncation and clip, space assignment is first come first serve.
        if (truncateMode == UILineBreakModeHeadTruncation) {
            widthForSegment = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
            for (int i = segments.count-1 ; i>=0; i--) {
                if (w >= frameWidth) {
                    [widthForSegment insertObject:[NSNumber numberWithFloat:0] atIndex:0];
                }
                else {
                    getSegmentAtIndexBlock(i);
                    getSegmentInfoWithWidthBlock();
                    w += segmentWidth;
                    [widthForSegment insertObject:[NSNumber numberWithFloat:segmentWidth] atIndex:0];
                    
                    updateLineTextHeightBlock();
                }
                
            }
        }
        else if (truncateMode == UILineBreakModeMiddleTruncation) {
            widthForSegment = [[NSMutableArray alloc] initWithCapacity:HUFancyTextTypicalSize];
            int i;
            if (segments.count == 1) {
                [widthForSegment addObject:[NSNumber numberWithFloat:frameWidth]];
                getSegmentAtIndexBlock(0);
                getSegmentInfoBlock();
                updateLineTextHeightBlock();
            }
            else {
                for (i = 0; i<segments.count; i++) {
                    getSegmentAtIndexBlock(i);
                    getSegmentInfoWithWidthBlock();
                    if (w + segmentWidth >= frameWidth * .7f) { // hold if the width exceeds 2/3 of the line
                        break;
                    }
                    else {
                        w += segmentWidth;
                        [widthForSegment addObject:[NSNumber numberWithFloat:segmentWidth]];
                        updateLineTextHeightBlock();
                    }
                }
                for (int j=segments.count - 1; j>i; j--) {
                    if (w >= frameWidth) {
                        [widthForSegment insertObject:[NSNumber numberWithFloat:0] atIndex:i];
                    }
                    else {
                        getSegmentAtIndexBlock(j);
                        getSegmentInfoWithWidthBlock();
                        [widthForSegment insertObject:[NSNumber numberWithFloat:segmentWidth] atIndex:i];
                        w += segmentWidth;
                        updateLineTextHeightBlock();
                    }
                }
                [widthForSegment insertObject:[NSNumber numberWithFloat:frameWidth-w] atIndex:i];
            }
        }
        else { // clip or truncate tail, the simplest cases
            for (int i = 0; i<segments.count; i++) {
                getSegmentAtIndexBlock(i);
                getSegmentInfoBlock();
                updateLineTextHeightBlock();
                BOOL needTotalLength = (align==TextAlignCenter || align==TextAlignRight);
                if (needTotalLength) {
                    getSegmentInfoWithWidthBlock();
                    w += segmentWidth;
                }
            }
        }
        
        // Calculating starting X
        if (align==TextAlignLeft) {
            x = 0.f;
        }
        else if (align == TextAlignCenter) {
            x = (frameWidth - w)/2.f;
        }
        else if (align == TextAlignRight) {
            x = frameWidth - w;
        }
        if (x<0) {
            x = 0;
        }
        
        w = x; // since now w will mean the width of space covered by text that's already drawn (it will be used by blocks to determine the available width)
        x += rect.origin.x;
        CGFloat maxX = frameWidth + rect.origin.x;
        
        // Drawing loop
        for (int i=0; i<segments.count; i++) {
            getSegmentAtIndexBlock(i);
            
            // get text(if necessary) and height, baseline
            if (segmentIsLambda) {
                segmentHeight = [[segment objectForKey:HUFancyTextHeightKey] floatValue];
                segmentBaseline = 0;
            }
            else {
                getSegmentInfoBlock();
                segmentHeight = segmentFont.lineHeight;
            }
            
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
            
            // get vertical align
            NSNumber* valignNumber = [segment objectForKey:HUFancyTextVerticalAlignKey];
            VerticalAlign valign = valignNumber ? [valignNumber intValue] : 0; // 0 is always the default, no matter what the default is
            CGFloat actualY;
            switch (valign) {
                case VerticalAlignBaseline:
                    actualY = y + h - segmentHeight - (baseline - segmentBaseline);
                    break;
                case VerticalAlignBottom:
                    actualY = y + h - segmentHeight;
                    break;
                case VerticalAlignMiddle:
                    actualY = y + (h-segmentHeight)/2;
                    break;
                case VerticalAlignTop:
                    actualY = y;
                    break;
            }
            //            NSLog(@"line:%d, y:%f, h:%f, segmentHeight:%f, align:%d, actualY:%f. baseline: %f vs %f",
            //                          l, y,    h,    segmentHeight,   valign,    actualY,  segmentBaseline, baseline);
            
            // draw
            if (segmentIsLambda) {
                // to do: call block method
                NSString* lambdaID = [segment objectForKey:HUFancyTextInternalLambdaIDKey];
                CGFloat lwidth = [[segment objectForKey:HUFancyTextWidthKey] floatValue];
                CGFloat lheight = [[segment objectForKey:HUFancyTextHeightKey] floatValue];
                void(^drawingBlock)(CGRect);
                if ((drawingBlock = [lambdaBlocks_ objectForKey:lambdaID])) {
                    CGRect rect = CGRectMake(x, actualY, lwidth, lheight);
                    drawingBlock(rect);
//                    NSLog(@"finished drawing %@ for %@...", lambdaID, [[segments_ objectAtIndex:0] objectForKey:HUFancyTextTextKey]);
                }
//                else {
//                    NSLog(@"can't find %@ block for %@...", lambdaID, [[segments_ objectAtIndex:0] objectForKey:HUFancyTextTextKey]);
//                }
            }
            else {
                // get color
                UIColor* segmentColor = [segment objectForKey:HUFancyTextColorKey];
                CGContextSetFillColorWithColor(ctx, [segmentColor CGColor]);
                CGContextSetStrokeColorWithColor(ctx, [segmentColor CGColor]);
                
                // actually draw
                CGRect textArea = CGRectMake(x, actualY, segmentWidth, segmentHeight);
                [segmentText drawInRect:textArea withFont:segmentFont lineBreakMode:truncateMode];
            }
            
            x += segmentWidth;
            w += segmentWidth;
            
            if (x >= maxX) {
                break;
            }
        }
        
        release(widthForSegment);
        
        // Updating Y for the next line
        CGFloat lineHeight = [[[segments objectAtIndex:0] objectForKey:HUFancyTextLineHeightKey] floatValue];
        if (!lineHeight) {
            lineHeight = h;
        }
        else if ([[[segments objectAtIndex:0] objectForKey:HUFancyTextHeightIsPercentageKey] boolValue]) { // percentage
            lineHeight = lineHeight * h;
        }
        y += lineHeight;
        
    }
    
    contentHeight_ = y - rect.origin.y;
    //NSLog(@"final content height: %f", contentHeight_);
    
    //NSLog(@"drawing time: %f", -[startDraw timeIntervalSinceNow]);
    
}

- (void)setBlock:(void(^)(CGRect))drawingBlock forLambdaID:(NSString*)lambdaID {
    if (!drawingBlock) {
        [lambdaBlocks_ removeObjectForKey:lambdaID];
    }
    else {
        // copy the block onto the heap
        void(^theBlock)(CGPoint) = autoreleased([drawingBlock copy]);
        [lambdaBlocks_ setObject:theBlock forKey:lambdaID];
    }
}


# pragma mark - helper

+ (void)addObject:(NSObject*)object intoDict:(NSMutableDictionary*)dict underKey:(NSString*)key {
    NSMutableArray* array = [dict objectForKey:key];
    if (!array) {
        array = [[NSMutableArray alloc] initWithObjects:object, nil];
        [dict setObject:array forKey:key];
        release(array);
    }
    else {
        [array addObject:object];
    }
}

#pragma mark - copy

/// @note: it will only copy user set info and parsing result, but not line generating result (including content height)
- (id)copy {
    // if the original one is parsed, then just copy the parsed result tree
    HUFancyText* newFancyText;
    if (self.parsedResultTree) {
        HUMarkupNode* newTree = [self.parsedResultTree copy];
        newFancyText = [[HUFancyText alloc] initWithParsedStructure:newTree];
        release(newTree);
    }
    else {
        NSString* newText = [self.text copy];
        newFancyText = [[HUFancyText alloc] initWithMarkupText:newText];
        release(newText);
    }
    newFancyText.width = self.width;
    newFancyText.maxHeight = self.maxHeight;
    
    NSMutableDictionary* newStyle = [self.style copy];
    newFancyText.style = newStyle;
    release(newStyle);
    
    NSMutableDictionary* newlambdaBlocks = [self.lambdaBlocks copy];
    newFancyText.lambdaBlocks = newlambdaBlocks;
    release(newlambdaBlocks);
 
    return newFancyText;
}

@end
