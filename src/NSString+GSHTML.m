//
//  NSString+GSHTML.m
//  GSFancyTextDemo
//
//  Created by Ben Acland on 1/29/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import "NSString+GSHTML.h"
#import "GSFancyTextDefines.h"

NSString *const ampString = @"&";
NSString *const semiString = @";";
static NSDictionary *unescapeTable_;
static NSUInteger maxUnescapeKeyLength_ = 0;
static NSUInteger minUnescapeKeyLength_ = NSUIntegerMax;

static void initUnescapeTable() {
    GSRelease(unescapeTable);
    unescapeTable_ = [[NSDictionary alloc] initWithObjectsAndKeys:
                      @"\"", @"&#34;",	// quotation mark
                      @"\"", @"&quot;",	// quotation mark
                      @"'", @"&#39;",	// apostrophe 
                      @"'", @"&apos;",	// apostrophe 
                      @"&", @"&#38;",	// ampersand
                      @"&", @"&amp;",	// ampersand
                      @"<", @"&#60;",	// less-than
                      @"<", @"&lt;",	// less-than
                      @">", @"&#62;",	// greater-than
                      @">", @"&gt;",	// greater-than
                      @" ", @"&#160;",	// non-breaking space
                      @" ", @"&nbsp;",	// non-breaking space
                      @"¡", @"&#161;",	// inverted exclamation mark
                      @"¡", @"&iexcl;",	// inverted exclamation mark
                      @"¢", @"&#162;",	// cent
                      @"¢", @"&cent;",	// cent
                      @"£", @"&#163;",	// pound
                      @"£", @"&pound;",	// pound
                      @"¤", @"&#164;",	// currency
                      @"¤", @"&curren;",// currency
                      @"¥", @"&#165;",	// yen
                      @"¥", @"&yen;",	// yen
                      @"¦", @"&#166;",	// broken vertical bar
                      @"¦", @"&brvbar;",// broken vertical bar
                      @"§", @"&#167;",	// section
                      @"§", @"&sect;",	// section
                      @"¨", @"&#168;",	// spacing diaeresis
                      @"¨", @"&uml;",	// spacing diaeresis
                      @"©", @"&#169;",	// copyright
                      @"©", @"&copy;",	// copyright
                      @"ª", @"&#170;",	// feminine ordinal indicator
                      @"ª", @"&ordf;",	// feminine ordinal indicator
                      @"«", @"&#171;",	// angle quotation mark (left)
                      @"«", @"&laquo;",	// angle quotation mark (left)
                      @"¬", @"&#172;",	// negation
                      @"¬", @"&not;",	// negation
                      @"®", @"&#174;",	// registered trademark
                      @"®", @"&reg;",	// registered trademark
                      @"¯", @"&#175;",	// spacing macron
                      @"¯", @"&macr;",	// spacing macron
                      @"°", @"&#176;",	// degree
                      @"°", @"&deg;",	// degree
                      @"±", @"&#177;",	// plus-or-minus 
                      @"±", @"&plusmn;",// plus-or-minus 
                      @"²", @"&#178;",	// superscript 2
                      @"²", @"&sup2;",	// superscript 2
                      @"³", @"&#179;",	// superscript 3
                      @"³", @"&sup3;",	// superscript 3
                      @"´", @"&#180;",	// spacing acute
                      @"´", @"&acute;",	// spacing acute
                      @"µ", @"&#181;",	// micro
                      @"µ", @"&micro;",	// micro
                      @"¶", @"&#182;",	// paragraph
                      @"¶", @"&para;",	// paragraph
                      @"·", @"&#183;",	// middle dot
                      @"·", @"&middot;",// middle dot
                      @"¸", @"&#184;",	// spacing cedilla
                      @"¸", @"&cedil;",	// spacing cedilla
                      @"¹", @"&#185;",	// superscript 1
                      @"¹", @"&sup1;",	// superscript 1
                      @"º", @"&#186;",	// masculine ordinal indicator
                      @"º", @"&ordm;",	// masculine ordinal indicator
                      @"»", @"&#187;",	// angle quotation mark (right)
                      @"»", @"&raquo;",	// angle quotation mark (right)
                      @"¼", @"&#188;",	// fraction 1/4
                      @"¼", @"&frac14;",// fraction 1/4
                      @"½", @"&#189;",	// fraction 1/2
                      @"½", @"&frac12;",// fraction 1/2
                      @"¾", @"&#190;",	// fraction 3/4
                      @"¾", @"&frac34;",// fraction 3/4
                      @"¿", @"&#191;",	// inverted question mark
                      @"¿", @"&iquest;",// inverted question mark
                      @"×", @"&#215;",	// multiplication
                      @"×", @"&times;",	// multiplication
                      @"÷", @"&#247;",	// division
                      @"÷", @"&divide;",// division
                      @"À", @"&#192;",	// capital a, grave accent
                      @"À", @"&Agrave;",// capital a, grave accent
                      @"Á", @"&#193;",	// capital a, acute accent
                      @"Á", @"&Aacute;",// capital a, acute accent
                      @"Â", @"&#194;",	// capital a, circumflex accent
                      @"Â", @"&Acirc;",	// capital a, circumflex accent
                      @"Ã", @"&#195;",	// capital a, tilde
                      @"Ã", @"&Atilde;",// capital a, tilde
                      @"Ä", @"&#196;",	// capital a, umlaut mark
                      @"Ä", @"&Auml;",	// capital a, umlaut mark
                      @"Å", @"&#197;",	// capital a, ring
                      @"Å", @"&Aring;",	// capital a, ring
                      @"Æ", @"&#198;",	// capital ae
                      @"Æ", @"&AElig;",	// capital ae
                      @"Ç", @"&#199;",	// capital c, cedilla
                      @"Ç", @"&Ccedil;",// capital c, cedilla
                      @"È", @"&#200;",	// capital e, grave accent
                      @"È", @"&Egrave;",// capital e, grave accent
                      @"É", @"&#201;",	// capital e, acute accent
                      @"É", @"&Eacute;",// capital e, acute accent
                      @"Ê", @"&#202;",	// capital e, circumflex accent
                      @"Ê", @"&Ecirc;",	// capital e, circumflex accent
                      @"Ë", @"&#203;",	// capital e, umlaut mark
                      @"Ë", @"&Euml;",	// capital e, umlaut mark
                      @"Ì", @"&#204;",	// capital i, grave accent
                      @"Ì", @"&Igrave;",// capital i, grave accent
                      @"Í", @"&#205;",	// capital i, acute accent
                      @"Í", @"&Iacute;",// capital i, acute accent
                      @"Î", @"&#206;",	// capital i, circumflex accent
                      @"Î", @"&Icirc;",	// capital i, circumflex accent
                      @"Ï", @"&#207;",	// capital i, umlaut mark
                      @"Ï", @"&Iuml;",	// capital i, umlaut mark
                      @"Ð", @"&#208;",	// capital eth, Icelandic
                      @"Ð", @"&ETH;",	// capital eth, Icelandic
                      @"Ñ", @"&#209;",	// capital n, tilde
                      @"Ñ", @"&Ntilde;",// capital n, tilde
                      @"Ò", @"&#210;",	// capital o, grave accent
                      @"Ò", @"&Ograve;",// capital o, grave accent
                      @"Ó", @"&#211;",	// capital o, acute accent
                      @"Ó", @"&Oacute;",// capital o, acute accent
                      @"Ô", @"&#212;",	// capital o, circumflex accent
                      @"Ô", @"&Ocirc;",	// capital o, circumflex accent
                      @"Õ", @"&#213;",	// capital o, tilde
                      @"Õ", @"&Otilde;",// capital o, tilde
                      @"Ö", @"&#214;",	// capital o, umlaut mark
                      @"Ö", @"&Ouml;",	// capital o, umlaut mark
                      @"Ø", @"&#216;",	// capital o, slash
                      @"Ø", @"&Oslash;",// capital o, slash
                      @"Ù", @"&#217;",	// capital u, grave accent
                      @"Ù", @"&Ugrave;",// capital u, grave accent
                      @"Ú", @"&#218;",	// capital u, acute accent
                      @"Ú", @"&Uacute;",// capital u, acute accent
                      @"Û", @"&#219;",	// capital u, circumflex accent
                      @"Û", @"&Ucirc;",	// capital u, circumflex accent
                      @"Ü", @"&#220;",	// capital u, umlaut mark
                      @"Ü", @"&Uuml;",	// capital u, umlaut mark
                      @"Ý", @"&#221;",	// capital y, acute accent
                      @"Ý", @"&Yacute;",// capital y, acute accent
                      @"Þ", @"&#222;",	// capital THORN, Icelandic
                      @"Þ", @"&THORN;",	// capital THORN, Icelandic
                      @"ß", @"&#223;",	// small sharp s, German
                      @"ß", @"&szlig;",	// small sharp s, German
                      @"à", @"&#224;",	// small a, grave accent
                      @"à", @"&agrave;",// small a, grave accent
                      @"á", @"&#225;",	// small a, acute accent
                      @"á", @"&aacute;",// small a, acute accent
                      @"â", @"&#226;",	// small a, circumflex accent
                      @"â", @"&acirc;",	// small a, circumflex accent
                      @"ã", @"&#227;",	// small a, tilde
                      @"ã", @"&atilde;",// small a, tilde
                      @"ä", @"&#228;",	// small a, umlaut mark
                      @"ä", @"&auml;",	// small a, umlaut mark
                      @"å", @"&#229;",	// small a, ring
                      @"å", @"&aring;",	// small a, ring
                      @"æ", @"&#230;",	// small ae
                      @"æ", @"&aelig;",	// small ae
                      @"ç", @"&#231;",	// small c, cedilla
                      @"ç", @"&ccedil;",// small c, cedilla
                      @"è", @"&#232;",	// small e, grave accent
                      @"è", @"&egrave;",// small e, grave accent
                      @"é", @"&#233;",	// small e, acute accent
                      @"é", @"&eacute;",// small e, acute accent
                      @"ê", @"&#234;",	// small e, circumflex accent
                      @"ê", @"&ecirc;",	// small e, circumflex accent
                      @"ë", @"&#235;",	// small e, umlaut mark
                      @"ë", @"&euml;",	// small e, umlaut mark
                      @"ì", @"&#236;",	// small i, grave accent
                      @"ì", @"&igrave;",// small i, grave accent
                      @"í", @"&#237;",	// small i, acute accent
                      @"í", @"&iacute;",// small i, acute accent
                      @"î", @"&#238;",	// small i, circumflex accent
                      @"î", @"&icirc;",	// small i, circumflex accent
                      @"ï", @"&#239;",	// small i, umlaut mark
                      @"ï", @"&iuml;",	// small i, umlaut mark
                      @"ð", @"&#240;",	// small eth, Icelandic
                      @"ð", @"&eth;",	// small eth, Icelandic
                      @"ñ", @"&#241;",	// small n, tilde
                      @"ñ", @"&ntilde;",// small n, tilde
                      @"ò", @"&#242;",	// small o, grave accent
                      @"ò", @"&ograve;",// small o, grave accent
                      @"ó", @"&#243;",	// small o, acute accent
                      @"ó", @"&oacute;",// small o, acute accent
                      @"ô", @"&#244;",	// small o, circumflex accent
                      @"ô", @"&ocirc;",	// small o, circumflex accent
                      @"õ", @"&#245;",	// small o, tilde
                      @"õ", @"&otilde;",// small o, tilde
                      @"ö", @"&#246;",	// small o, umlaut mark
                      @"ö", @"&ouml;",	// small o, umlaut mark
                      @"ø", @"&#248;",	// small o, slash
                      @"ø", @"&oslash;",// small o, slash
                      @"ù", @"&#249;",	// small u, grave accent
                      @"ù", @"&ugrave;",// small u, grave accent
                      @"ú", @"&#250;",	// small u, acute accent
                      @"ú", @"&uacute;",// small u, acute accent
                      @"û", @"&#251;",	// small u, circumflex accent
                      @"û", @"&ucirc;",	// small u, circumflex accent
                      @"ü", @"&#252;",	// small u, umlaut mark
                      @"ü", @"&uuml;",	// small u, umlaut mark
                      @"ý", @"&#253;",	// small y, acute accent
                      @"ý", @"&yacute;",// small y, acute accent
                      @"þ", @"&#254;",	// small thorn, Icelandic
                      @"þ", @"&thorn;",	// small thorn, Icelandic
                      @"ÿ", @"&#255;",	// small y, umlaut mark
                      @"ÿ", @"&yuml;",	// small y, umlaut mark
                      nil];
    for (NSString *key in [unescapeTable_ allKeys]) {
        NSUInteger keyLength = [key length];
        if (keyLength > maxUnescapeKeyLength_) {
            maxUnescapeKeyLength_ = keyLength;
        }
        if (keyLength < minUnescapeKeyLength_) {
            minUnescapeKeyLength_ = keyLength;
        }
    }
}

static NSString* unescapedStringForEntity(NSString *entity, BOOL* didEscape) {
    if (!unescapeTable_) {
        initUnescapeTable();
    }

    // entity should be something matching (&.*;).
    if (!entity || [entity length] > maxUnescapeKeyLength_ || [entity length] < minUnescapeKeyLength_) {
        return entity;
    }

    NSString *rString = [unescapeTable_ objectForKey:entity];
    if (rString) {
        if (didEscape != NULL) {
            *didEscape = YES;
        }
        return rString;
    }
    else {
        if (didEscape != NULL) {
            *didEscape = NO;
        }
        return entity;
    }
}

@implementation NSString (GSHTML)

- (NSString*)unescapeHTMLEntities {
    if ([self length] == 0) {
        return @"";
    }

    NSMutableString *rString = [[NSMutableString alloc] initWithCapacity:[self length]];
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    scanner.charactersToBeSkipped = nil;
    NSString *newString;
    NSString *entityString;
    BOOL didEscape = NO;
    while (scanner.isAtEnd == NO) {
        // go until you find an &
        newString = nil;
        [scanner scanUpToString:ampString intoString:&newString];
        if (scanner.isAtEnd) {
            return newString;
        }
        if (newString) {
            [rString appendString:newString];
        }

        // next time you see a ;, unescape stuff if you need to
        newString = nil;
        [scanner scanUpToString:semiString intoString:&newString];
        if (scanner.isAtEnd) {
            [rString appendString:newString];
            break;
        }

        // newString is now something that matches (&.*)
        didEscape = NO;
        entityString = [[NSString alloc] initWithFormat:@"%@;", newString]; // released at end
        newString = unescapedStringForEntity(entityString, &didEscape);
        if (newString) {
            [rString appendString:newString];
        }

        // advance the scanner past the ; if you escaped
        if (didEscape) {
            scanner.scanLocation += 1;
        }

        GSRelease(entityString);
    }
    return rString;
}

@end
