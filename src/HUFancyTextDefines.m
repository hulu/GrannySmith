//
//  HUFancyTextDefines.m
//  -HUSFT-
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import "HUFancyTextDefines.h"

int const HUFancyTextTypicalSize = 10;

#pragma mark - css keys

NSString* const HUFancyTextColorKey  = @"color";
NSString* const HUFancyTextFontNameKey  = @"font-family";
NSString* const HUFancyTextFontSizeKey  = @"font-size";
NSString* const HUFancyTextFontWeightKey  = @"font-weight";
NSString* const HUFancyTextFontStyleKey   = @"font-style";
NSString* const HUFancyTextLineHeightKey   = @"line-height";
NSString* const HUFancyTextTextAlignKey  = @"text-align";
NSString* const HUFancyTextVerticalAlignKey  = @"vertical-align";

#pragma mark - special attributes

NSString* const HUFancyTextLineCountKey  = @"line-count";
NSString* const HUFancyTextTruncateModeKey  = @"truncate-mode";
NSString* const HUFancyTextAltKey = @"alt";

#pragma mark - values

NSString* const HUFancyTextBoldValue  = @"bold";
NSString* const HUFancyTextItalicValue  = @"italic";
NSString* const HUFancyTextRGBValue  = @"rgb";
NSString* const HUFancyTextAlignLeftValue  = @"left";
NSString* const HUFancyTextAlignCenterValue  = @"center";
NSString* const HUFancyTextAlignRightValue  = @"right";
NSString* const HUFancyTextVAlignBaselineValue  = @"baseline";
NSString* const HUFancyTextVAlignTopValue  = @"top";
NSString* const HUFancyTextVAlignMiddleValue  = @"middle";
NSString* const HUFancyTextVAlignBottomValue  = @"bottom";
NSString* const HUFancyTextTruncateTailValue  = @"tail";
NSString* const HUFancyTextTruncateHeadValue  = @"head";
NSString* const HUFancyTextTruncateMiddleValue  = @"middle";
NSString* const HUFancyTextTruncateClipValue  = @"clip";

NSString* const HUFancyTextRootID  = @"root";

#pragma mark - markup elements

NSString* const HUFancyTextSpanElement  = @"span";
NSString* const HUFancyTextPElement  = @"p";
NSString* const HUFancyTextStrongElement  = @"strong";
NSString* const HUFancyTextEmElement  = @"em";
NSString* const HUFancyTextLambdaElement  = @"lambda";

NSString* const HUFancyTextClassKey  = @"class";
NSString* const HUFancyTextIDKey  = @"id";
NSString* const HUFancyTextWidthKey  = @"width";
NSString* const HUFancyTextHeightKey  = @"height";


#pragma mark - internal constants


// defaults
NSString* const HUFancyTextDefaultClass  = @"default";
NSString* const HUFancyTextDefaultFontFamily  = @"Helvetica";


// markup node dictionary
NSString* const HUFancyTextTextKey  = @"text";
/// @note key "font" is used only in the final stage (markup text structure parsed). In earlier stages (e.g. parsed tag, parsed styles) we should use font-family etc
NSString* const HUFancyTextFontKey  = @"font";

// special keys
NSString* const HUFancyTextLineIDKey  = @"line-id";
NSString* const HUFancyTextTagClosingKey  = @"is-closing-tag";
NSString* const HUFancyTextElementNameKey  = @"element-name";
NSString* const HUFancyTextInternalLambdaIDKey  = @"hulu-fancy-text-internal-lambda-id";
NSString* const HUFancyTextHeightIsPercentageKey  = @"line-height-is-percentage";
