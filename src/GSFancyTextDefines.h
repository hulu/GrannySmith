//
//  GSFancyTextDefines.h
//  -GrannySmith-
//
//  Created by Bao Lei on 1/5/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#ifndef GSFancyTextDefines_h
#define GSFancyTextDefines_h


//#warning Please set the ARC_ENABLED flag according your situation. Comment out this line once you read and understand this so that the warning will be disabled.

// Comment the following line if ARC (Automatic Reference Counting) is enabled. Uncomment it if ARC is not enabled.
 #define ARC_ENABLED 1

// Enable the warning
#define GS_DEBUG_MODE 1

/// The typical size involved in the text rendering process, including number of nodes in a tree, number of styles in a node.
/// It is used for initWithCapacity method, so it doesn't really limit. It's just close guess for perf optimization
extern int const GSFancyTextTypicalSize;

///-------------
/// @name enums
///-------------

/// Text align
typedef enum {
    GSTextAlignLeft, // default
    GSTextAlignCenter,
    GSTextAlignRight,
} GSTextAlign;

/// Vertical align
typedef enum {
    GSVerticalAlignBaseline, // default
    GSVerticalAlignBottom,
    GSVerticalAlignMiddle,
    GSVerticalAlignTop,
} GSVerticalAlign;

/// Reference Type (ID or class)
typedef enum {
    GSFancyTextID,
    GSFancyTextClass,
    GSFancyTextRoot,
} GSFancyTextReferenceType;


///-----------------------------
/// @name Segment dictionary
///-----------------------------
/// standard css supported
extern NSString* const GSFancyTextColorKey;  // @"color"
extern NSString* const GSFancyTextFontNameKey;  // @"font-family"
extern NSString* const GSFancyTextFontSizeKey;  // @"font-size"
extern NSString* const GSFancyTextFontWeightKey;  // @"font-weight"
extern NSString* const GSFancyTextFontStyleKey ;  // @"font-style"
extern NSString* const GSFancyTextLineHeightKey ;  // @"line-height"
extern NSString* const GSFancyTextTextAlignKey;  // @"text-align"
extern NSString* const GSFancyTextVerticalAlignKey;  // @"vertical-align"

/// some special attributes
extern NSString* const GSFancyTextLineCountKey;  // @"line-count"
extern NSString* const GSFancyTextTruncateModeKey;  // @"truncate-mode"
extern NSString* const GSFancyTextAltKey;  // @"alt"

/// values
extern NSString* const GSFancyTextBoldValue;  // @"bold"
extern NSString* const GSFancyTextItalicValue;  // @"italic"
extern NSString* const GSFancyTextRGBValue;  // @"rgb"
extern NSString* const GSFancyTextAlignLeftValue;  // @"left"
extern NSString* const GSFancyTextAlignCenterValue;  // @"center"
extern NSString* const GSFancyTextAlignRightValue;  // @"right"
extern NSString* const GSFancyTextVAlignBaselineValue;  // @"baseline"
extern NSString* const GSFancyTextVAlignTopValue;  // @"top"
extern NSString* const GSFancyTextVAlignMiddleValue;  // @"middle"
extern NSString* const GSFancyTextVAlignBottomValue;  // @"bottom"
extern NSString* const GSFancyTextTruncateTailValue;  // @"tail"
extern NSString* const GSFancyTextTruncateHeadValue;  // @"head"
extern NSString* const GSFancyTextTruncateMiddleValue;  // @"middle"
extern NSString* const GSFancyTextTruncateClipValue;  // @"clip"

/// the default ID for the root node
extern NSString* const GSFancyTextRootID;  // @"root"

///--------------------------
/// @name markup elements
///--------------------------

extern NSString* const GSFancyTextSpanElement;  // @"span"
extern NSString* const GSFancyTextPElement;  // @"p"
extern NSString* const GSFancyTextStrongElement;  // @"strong"
extern NSString* const GSFancyTextEmElement;  // @"em"
extern NSString* const GSFancyTextLambdaElement;  // @"lambda"

/// For span and p
extern NSString* const GSFancyTextClassKey;  // @"class"
extern NSString* const GSFancyTextIDKey;  // @"id"
/// For lambda
extern NSString* const GSFancyTextWidthKey;  // @"width"
extern NSString* const GSFancyTextHeightKey;  // @"height"

///----------------------------
/// @name internal constants
///----------------------------

// defaults
extern NSString* const GSFancyTextDefaultClass;  // @"default"
extern NSString* const GSFancyTextDefaultFontFamily;  // @"Helvetica"

// markup node dictionary
extern NSString* const GSFancyTextTextKey;  // @"text"
///;  // @note key "font" is used only in the final stage (markup text structure parsed). In earlier stages (e.g. parsed tag, parsed styles) we should use font-family etc
extern NSString* const GSFancyTextFontKey;  // @"font"

// special keys
extern NSString* const GSFancyTextLineIDKey;  // @"line-id"
extern NSString* const GSFancyTextTagClosingKey;  // @"is-closing-tag"
extern NSString* const GSFancyTextElementNameKey;  // @"element-name"
extern NSString* const GSFancyTextInternalLambdaIDKey;  // @"hulu-fancy-text-internal-lambda-id"
extern NSString* const GSFancyTextHeightIsPercentageKey;  // @"line-height-is-percentage"


///---------------
/// @ Handy tools
///---------------

#define GSTrim(s) [s stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]
#define GSRgb(c) [UIColor colorWithRed:((c & 0xFF0000) >> 16)/255.0 green:((c & 0x00FF00) >> 8)/255.0 blue:(c & 0x0000FF)/255.0 alpha:1.0]


/// ARC - non-ARC compatibility
#ifdef ARC_ENABLED
#define GSRelease(obj) 
#define GSRetain(obj)
#define GSRetained(obj) obj
#define GSAutorelease(obj) 
#define GSAutoreleased(obj) obj
#define GSWeak weak
#define GSWeakPrefix __weak
#define GSBridgePreix __bridge
#else
#define GSRelease(obj) [obj release]
#define GSRetain(obj) [obj retain]
#define GSRetained(obj) [obj retain]
#define GSAutorelease(obj) [obj autorelease]
#define GSAutoreleased(obj) [obj autorelease]
#define GSWeak assign
#define GSWeakPrefix 
#define GSBridgePreix 
#endif

#ifdef GS_DEBUG_MODE
#define GSDebugLog(...) NSLog(__VA_ARGS__)
#else
#define GSDebugLog(...) 
#endif



#endif
