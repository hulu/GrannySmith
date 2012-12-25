//
//  GSFancyTextDefines.m
//  -GrannySmith-
//
//  Created by Bao Lei on 1/9/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "GSFancyTextDefines.h"

int const GSFancyTextTypicalSize = 10;

#pragma mark - css keys

NSString* const GSFancyTextColorKey  = @"color";
NSString* const GSFancyTextShadowKey  = @"text-shadow";
NSString* const GSFancyTextFontNameKey  = @"font-family";
NSString* const GSFancyTextFontSizeKey  = @"font-size";
NSString* const GSFancyTextFontWeightKey  = @"font-weight";
NSString* const GSFancyTextFontStyleKey   = @"font-style";
NSString* const GSFancyTextLineHeightKey   = @"line-height";
NSString* const GSFancyTextTextAlignKey  = @"text-align";
NSString* const GSFancyTextVerticalAlignKey  = @"vertical-align";
NSString* const GSFancyTextMarginTop  = @"margin-top";
NSString* const GSFancyTextMarginBottom  = @"margin-bottom";
NSString* const GSFancyTextMarginLeft  = @"margin-left";
NSString* const GSFancyTextMarginRight  = @"margin-right";


#pragma mark - special attributes

NSString* const GSFancyTextLineCountKey  = @"line-count";
NSString* const GSFancyTextTruncateModeKey  = @"truncate-mode";
NSString* const GSFancyTextMinWidthKey = @"min-width";
NSString* const GSFancyTextAltKey = @"alt";

#pragma mark - values

NSString* const GSFancyTextBoldValue  = @"bold";
NSString* const GSFancyTextItalicValue  = @"italic";
NSString* const GSFancyTextRGBValue  = @"rgb";
NSString* const GSFancyTextRGBAValue  = @"rgba";
NSString* const GSFancyTextAlignLeftValue  = @"left";
NSString* const GSFancyTextAlignCenterValue  = @"center";
NSString* const GSFancyTextAlignRightValue  = @"right";
NSString* const GSFancyTextVAlignBaselineValue  = @"baseline";
NSString* const GSFancyTextVAlignTopValue  = @"top";
NSString* const GSFancyTextVAlignMiddleValue  = @"middle";
NSString* const GSFancyTextVAlignBottomValue  = @"bottom";
NSString* const GSFancyTextTruncateTailValue  = @"tail";
NSString* const GSFancyTextTruncateHeadValue  = @"head";
NSString* const GSFancyTextTruncateMiddleValue  = @"middle";
NSString* const GSFancyTextTruncateClipValue  = @"clip";

NSString* const GSFancyTextRootID  = @"root";

#pragma mark - markup elements

NSString* const GSFancyTextSpanElement  = @"span";
NSString* const GSFancyTextPElement  = @"p";
NSString* const GSFancyTextStrongElement  = @"strong";
NSString* const GSFancyTextEmElement  = @"em";
NSString* const GSFancyTextLambdaElement  = @"lambda";

NSString* const GSFancyTextClassKey  = @"class";
NSString* const GSFancyTextIDKey  = @"id";
NSString* const GSFancyTextWidthKey  = @"width";
NSString* const GSFancyTextHeightKey  = @"height";


#pragma mark - internal constants


// defaults
NSString* const GSFancyTextDefaultClass  = @"default";
NSString* const GSFancyTextDefaultFontFamily  = @"Helvetica";


// markup node dictionary
NSString* const GSFancyTextTextKey  = @"text";
/// @note key "font" is used only in the final stage (markup text structure parsed). In earlier stages (e.g. parsed tag, parsed styles) we should use font-family etc
NSString* const GSFancyTextFontKey  = @"font";

// special keys
NSString* const GSFancyTextLineIDKey  = @"line-id";
NSString* const GSFancyTextTagClosingKey  = @"is-closing-tag";
NSString* const GSFancyTextElementNameKey  = @"element-name";
NSString* const GSFancyTextInternalLambdaIDKey  = @"granny-smith-fancy-text-internal-lambda-id";
NSString* const GSFancyTextAdvancedTruncationKey  = @"advanced-truncation";

