//
//  HUFancyTextDefines.h
//  i2
//
//  Created by Bao Lei on 1/5/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#ifndef i2_HUFancyTextDefines_h
#define i2_HUFancyTextDefines_h


//#warning Please set the ARC_ENABLED flag according your situation. Comment out this line once you read and understand this so that the warning will be disabled.

// Comment the following line if ARC (Automatic Reference Counting) is enabled. Uncomment it if ARC is not enabled.
 #define ARC_ENABLED 1


/// The typical size involved in the text rendering process, including number of nodes in a tree, number of styles in a node.
/// It is used for initWithCapacity method, so it doesn't really limit. It's just close guess for perf optimization
extern int const HUFancyTextTypicalSize;

///-------------
/// @name enums
///-------------

/// Text align
typedef enum {
    TextAlignLeft, // default
    TextAlignCenter,
    TextAlignRight,
} TextAlign;

/// Vertical align
typedef enum {
    VerticalAlignBaseline, // default
    VerticalAlignBottom,
    VerticalAlignMiddle,
    VerticalAlignTop,
} VerticalAlign;

/// Reference Type (ID or class)
typedef enum {
    HUFancyTextID,
    HUFancyTextClass,
    HUFancyTextRoot,
} HUFancyTextReferenceType;


///-----------------------------
/// @name Segment dictionary
///-----------------------------
/// standard css supported
extern NSString* const HUFancyTextColorKey;  // @"color"
extern NSString* const HUFancyTextFontNameKey;  // @"font-family"
extern NSString* const HUFancyTextFontSizeKey;  // @"font-size"
extern NSString* const HUFancyTextFontWeightKey;  // @"font-weight"
extern NSString* const HUFancyTextFontStyleKey ;  // @"font-style"
extern NSString* const HUFancyTextLineHeightKey ;  // @"line-height"
extern NSString* const HUFancyTextTextAlignKey;  // @"text-align"
extern NSString* const HUFancyTextVerticalAlignKey;  // @"vertical-align"

/// some special attributes
extern NSString* const HUFancyTextLineCountKey;  // @"line-count"
extern NSString* const HUFancyTextTruncateModeKey;  // @"truncate-mode"

/// values
extern NSString* const HUFancyTextBoldValue;  // @"bold"
extern NSString* const HUFancyTextItalicValue;  // @"italic"
extern NSString* const HUFancyTextRGBValue;  // @"rgb"
extern NSString* const HUFancyTextAlignLeftValue;  // @"left"
extern NSString* const HUFancyTextAlignCenterValue;  // @"center"
extern NSString* const HUFancyTextAlignRightValue;  // @"right"
extern NSString* const HUFancyTextVAlignBaselineValue;  // @"baseline"
extern NSString* const HUFancyTextVAlignTopValue;  // @"top"
extern NSString* const HUFancyTextVAlignMiddleValue;  // @"middle"
extern NSString* const HUFancyTextVAlignBottomValue;  // @"bottom"
extern NSString* const HUFancyTextTruncateTailValue;  // @"tail"
extern NSString* const HUFancyTextTruncateHeadValue;  // @"head"
extern NSString* const HUFancyTextTruncateMiddleValue;  // @"middle"
extern NSString* const HUFancyTextTruncateClipValue;  // @"clip"

/// the default ID for the root node
extern NSString* const HUFancyTextRootID;  // @"root"

///--------------------------
/// @name markup elements
///--------------------------

extern NSString* const HUFancyTextSpanElement;  // @"span"
extern NSString* const HUFancyTextPElement;  // @"p"
extern NSString* const HUFancyTextStrongElement;  // @"strong"
extern NSString* const HUFancyTextEmElement;  // @"em"
extern NSString* const HUFancyTextLambdaElement;  // @"lambda"

/// For span and p
extern NSString* const HUFancyTextClassKey;  // @"class"
extern NSString* const HUFancyTextIDKey;  // @"id"
/// For lambda
extern NSString* const HUFancyTextWidthKey;  // @"width"
extern NSString* const HUFancyTextHeightKey;  // @"height"

///----------------------------
/// @name internal constants
///----------------------------

// defaults
extern NSString* const HUFancyTextDefaultClass;  // @"default"
extern NSString* const HUFancyTextDefaultFontFamily;  // @"Helvetica"

// markup node dictionary
extern NSString* const HUFancyTextTextKey;  // @"text"
///;  // @note key "font" is used only in the final stage (markup text structure parsed). In earlier stages (e.g. parsed tag, parsed styles) we should use font-family etc
extern NSString* const HUFancyTextFontKey;  // @"font"

// special keys
extern NSString* const HUFancyTextLineIDKey;  // @"line-id"
extern NSString* const HUFancyTextTagClosingKey;  // @"is-closing-tag"
extern NSString* const HUFancyTextElementNameKey;  // @"element-name"
extern NSString* const HUFancyTextInternalLambdaIDKey;  // @"hulu-fancy-text-internal-lambda-id"
extern NSString* const HUFancyTextHeightIsPercentageKey;  // @"line-height-is-percentage"


///---------------
/// @ Handy tools
///---------------

#define fancyTextTrim(s) [s stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]
#define fancyTextRGB(c) [UIColor colorWithRed:((c & 0xFF0000) >> 16)/255.0 green:((c & 0x00FF00) >> 8)/255.0 blue:(c & 0x0000FF)/255.0 alpha:1.0]


/// ARC - non-ARC compatibility
#ifdef ARC_ENABLED
#define release(obj) 
#define retain(obj)
#define retained(obj) obj
#define autorelease(obj) 
#define autoreleased(obj) obj
#else
#define release(obj) [obj release]
#define retain(obj) [obj retain]
#define retained(obj) [obj retain]
#define autorelease(obj) [obj autorelease]
#define autoreleased(obj) [obj autorelease]
#endif


#endif
