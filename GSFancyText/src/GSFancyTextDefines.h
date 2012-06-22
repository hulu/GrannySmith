//
//  GSFancyTextDefines.h
//  -GrannySmith-
//
//  Created by Bao Lei on 1/5/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//


#import "GSConfig.h"


#ifndef GSFancyTextDefines_h
#define GSFancyTextDefines_h

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
extern NSString* const GSFancyTextShadowKey;  // @"text-shadow"
extern NSString* const GSFancyTextFontNameKey;  // @"font-family"
extern NSString* const GSFancyTextFontSizeKey;  // @"font-size"
extern NSString* const GSFancyTextFontWeightKey;  // @"font-weight"
extern NSString* const GSFancyTextFontStyleKey ;  // @"font-style"
extern NSString* const GSFancyTextLineHeightKey ;  // @"line-height"
extern NSString* const GSFancyTextTextAlignKey;  // @"text-align"
extern NSString* const GSFancyTextVerticalAlignKey;  // @"vertical-align"
extern NSString* const GSFancyTextMarginTop;  // @"margin-top"
extern NSString* const GSFancyTextMarginBottom;  // @"margin-bottom"
extern NSString* const GSFancyTextMarginLeft;  // @"margin-left"
extern NSString* const GSFancyTextMarginRight;  // @"margin-right"

/// some special attributes
extern NSString* const GSFancyTextLineCountKey;  // @"line-count"
extern NSString* const GSFancyTextTruncateModeKey;  // @"truncate-mode"
extern NSString* const GSFancyTextMinWidthKey; // @"min-width"
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
extern NSString* const GSFancyTextInternalLambdaIDKey;  // @"granny-smith-fancy-text-internal-lambda-id"
extern NSString* const GSFancyTextAdvancedTruncationKey; // @"advanced-truncation"


///---------------
/// @ Handy tools
///---------------

#define GSTrim(s) [s stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]
#define GSRgb(c) [UIColor colorWithRed:((c & 0xFF0000) >> 16)/255.0 green:((c & 0x00FF00) >> 8)/255.0 blue:(c & 0x0000FF)/255.0 alpha:1.0]
#define GSRectMakeRounded(x, y, width, height) CGRectMake(roundf(x), roundf(y), roundf(width), roundf(height))


/// ARC - non-ARC compatibility
#ifdef GS_ARC_ENABLED
#define GSRelease(obj) 
#define GSRetain(obj)
#define GSRetained(obj) obj
#define GSAutorelease(obj) 
#define GSAutoreleased(obj) obj
  #ifdef GS_ARC_WEAK_REF_ENABLED
    #define GSWeak weak
    #define GSWeakPrefix __weak
  #else
    #define GSWeak assign
    #define GSWeakPrefix __unsafe_unretained
  #endif
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



#ifdef GS_DEBUG_ALL
// Components we want to include in the general debug
#define GS_DEBUG_MARKUP 1
#define GS_DEBUG_PERFORMANCE 1
#define GS_DEBUG_CODE 1
#endif


/**Things that use GSDebugLog()
 * Don't call this from a thread before you set up an autorelease pool
 * Use the first one for standard behavior.  Use the second for standard + display
 * in the in-app debug view.
 */
#if defined(GS_DEBUG_ALL) || \
defined(GS_DEBUG_MARKUP) || \
defined(GS_DEBUG_PERFORMANCE) || \
defined(GS_DEBUG_CODE)

/* standard */
#define GSDebugLog( s, ... ) NSLog( @"%@    (%@ %p @ %@::%d)",\
    [NSString stringWithFormat:(s), ##__VA_ARGS__],\
    NSStringFromClass( [self class] ),\
    &self,\
    [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
    __LINE__ )

#else
#define GSDebugLog( s, ... )
#endif




#endif
