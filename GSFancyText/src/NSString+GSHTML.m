//
//  NSString+GSHTML.m
//  GSFancyTextDemo
//
//  Created by Ben Acland on 1/29/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "NSString+GSHTML.h"
#import "GSFancyTextDefines.h"

NSString *const ampString = @"&";
NSString *const semiString = @";";
static NSDictionary *unescapeTable_;
static NSUInteger maxUnescapeKeyLength_ = 0;
static NSUInteger minUnescapeKeyLength_ = NSUIntegerMax;
static NSCharacterSet *entityBoundaryCharacterSet_;
static NSCharacterSet *nonAmpCharacterSet_;

static void initUnescapeVars() {
    GSRelease(unescapeTable_);
    unescapeTable_ = [[NSDictionary alloc] initWithObjectsAndKeys:
                      @" ", @"&nbsp;",	//no-break space 
                      @" ", @"&#160;",	//no-break space 
                      @"¡", @"&iexcl;",	//inverted exclamation mark 
                      @"¡", @"&#161;",	//inverted exclamation mark 
                      @"¢", @"&cent;",	//cent sign 
                      @"¢", @"&#162;",	//cent sign 
                      @"£", @"&pound;",	//pound sterling sign 
                      @"£", @"&#163;",	//pound sterling sign 
                      @"¤", @"&curren;",//general currency sign 
                      @"¤", @"&#164;",	//general currency sign 
                      @"¥", @"&yen;",	//yen sign 
                      @"¥", @"&#165;",	//yen sign 
                      @"¦", @"&brvbar;",//broken (vertical) bar 
                      @"¦", @"&#166;",	//broken (vertical) bar 
                      @"§", @"&sect;",	//section sign 
                      @"§", @"&#167;",	//section sign 
                      @"¨", @"&uml;",	//umlaut (dieresis) 
                      @"¨", @"&#168;",	//umlaut (dieresis) 
                      @"©", @"&copy;",	//copyright sign 
                      @"©", @"&#169;",	//copyright sign 
                      @"ª", @"&ordf;",	//ordinal indicator, feminine 
                      @"ª", @"&#170;",	//ordinal indicator, feminine 
                      @"«", @"&laquo;",	//angle quotation mark, left 
                      @"«", @"&#171;",	//angle quotation mark, left 
                      @"¬", @"&not;",	//not sign 
                      @"¬", @"&#172;",	//not sign 
                      @"­", @"&shy;",	//soft hyphen 
                      @"­", @"&#173;",	//soft hyphen 
                      @"®", @"&reg;",	//registered sign 
                      @"®", @"&#174;",	//registered sign 
                      @"¯", @"&macr;",	//macron 
                      @"¯", @"&#175;",	//macron 
                      @"°", @"&deg;",	//degree sign 
                      @"°", @"&#176;",	//degree sign 
                      @"±", @"&plusmn;",//plus-or-minus sign 
                      @"±", @"&#177;",	//plus-or-minus sign 
                      @"²", @"&sup2;",	//superscript two 
                      @"²", @"&#178;",	//superscript two 
                      @"³", @"&sup3;",	//superscript three 
                      @"³", @"&#179;",	//superscript three 
                      @"´", @"&acute;",	//acute accent 
                      @"´", @"&#180;",	//acute accent 
                      @"µ", @"&micro;",	//micro sign 
                      @"µ", @"&#181;",	//micro sign 
                      @"¶", @"&para;",	//pilcrow (paragraph sign) 
                      @"¶", @"&#182;",	//pilcrow (paragraph sign) 
                      @"·", @"&middot;",//middle dot 
                      @"·", @"&#183;",	//middle dot 
                      @"¸", @"&cedil;",	//cedilla 
                      @"¸", @"&#184;",	//cedilla 
                      @"¹", @"&sup1;",	//superscript one 
                      @"¹", @"&#185;",	//superscript one 
                      @"º", @"&ordm;",	//ordinal indicator, masculine 
                      @"º", @"&#186;",	//ordinal indicator, masculine 
                      @"»", @"&raquo;",	//angle quotation mark, right 
                      @"»", @"&#187;",	//angle quotation mark, right 
                      @"¼", @"&frac14;",//fraction one-quarter 
                      @"¼", @"&#188;",	//fraction one-quarter 
                      @"½", @"&frac12;",//fraction one-half 
                      @"½", @"&#189;",	//fraction one-half 
                      @"¾", @"&frac34;",//fraction three-quarters 
                      @"¾", @"&#190;",	//fraction three-quarters 
                      @"¿", @"&iquest;",//inverted question mark 
                      @"¿", @"&#191;",	//inverted question mark 
                      @"À", @"&Agrave;",//capital A, grave accent 
                      @"À", @"&#192;",	//capital A, grave accent 
                      @"Á", @"&Aacute;",//capital A, acute accent 
                      @"Á", @"&#193;",	//capital A, acute accent 
                      @"Â", @"&Acirc;",	//capital A, circumflex accent 
                      @"Â", @"&#194;",	//capital A, circumflex accent 
                      @"Ã", @"&Atilde;",//capital A, tilde 
                      @"Ã", @"&#195;",	//capital A, tilde 
                      @"Ä", @"&Auml;",	//capital A, dieresis or umlaut mark 
                      @"Ä", @"&#196;",	//capital A, dieresis or umlaut mark 
                      @"Å", @"&Aring;",	//capital A, ring 
                      @"Å", @"&#197;",	//capital A, ring 
                      @"Æ", @"&AElig;",	//capital AE diphthong (ligature) 
                      @"Æ", @"&#198;",	//capital AE diphthong (ligature) 
                      @"Ç", @"&Ccedil;",//capital C, cedilla 
                      @"Ç", @"&#199;",	//capital C, cedilla 
                      @"È", @"&Egrave;",//capital E, grave accent 
                      @"È", @"&#200;",	//capital E, grave accent 
                      @"É", @"&Eacute;",//capital E, acute accent 
                      @"É", @"&#201;",	//capital E, acute accent 
                      @"Ê", @"&Ecirc;",	//capital E, circumflex accent 
                      @"Ê", @"&#202;",	//capital E, circumflex accent 
                      @"Ë", @"&Euml;",	//capital E, dieresis or umlaut mark 
                      @"Ë", @"&#203;",	//capital E, dieresis or umlaut mark 
                      @"Ì", @"&Igrave;",//capital I, grave accent 
                      @"Ì", @"&#204;",	//capital I, grave accent 
                      @"Í", @"&Iacute;",//capital I, acute accent 
                      @"Í", @"&#205;",	//capital I, acute accent 
                      @"Î", @"&Icirc;",	//capital I, circumflex accent 
                      @"Î", @"&#206;",	//capital I, circumflex accent 
                      @"Ï", @"&Iuml;",	//capital I, dieresis or umlaut mark 
                      @"Ï", @"&#207;",	//capital I, dieresis or umlaut mark 
                      @"Ð", @"&ETH;",	//capital Eth, Icelandic 
                      @"Ð", @"&#208;",	//capital Eth, Icelandic 
                      @"Ñ", @"&Ntilde;",//capital N, tilde 
                      @"Ñ", @"&#209;",	//capital N, tilde 
                      @"Ò", @"&Ograve;",//capital O, grave accent 
                      @"Ò", @"&#210;",	//capital O, grave accent 
                      @"Ó", @"&Oacute;",//capital O, acute accent 
                      @"Ó", @"&#211;",	//capital O, acute accent 
                      @"Ô", @"&Ocirc;",	//capital O, circumflex accent 
                      @"Ô", @"&#212;",	//capital O, circumflex accent 
                      @"Õ", @"&Otilde;",//capital O, tilde 
                      @"Õ", @"&#213;",	//capital O, tilde 
                      @"Ö", @"&Ouml;",	//capital O, dieresis or umlaut mark 
                      @"Ö", @"&#214;",	//capital O, dieresis or umlaut mark 
                      @"×", @"&times;",	//multiply sign 
                      @"×", @"&#215;",	//multiply sign 
                      @"Ø", @"&Oslash;",//capital O, slash 
                      @"Ø", @"&#216;",	//capital O, slash 
                      @"Ù", @"&Ugrave;",//capital U, grave accent 
                      @"Ù", @"&#217;",	//capital U, grave accent 
                      @"Ú", @"&Uacute;",//capital U, acute accent 
                      @"Ú", @"&#218;",	//capital U, acute accent 
                      @"Û", @"&Ucirc;",	//capital U, circumflex accent 
                      @"Û", @"&#219;",	//capital U, circumflex accent 
                      @"Ü", @"&Uuml;",	//capital U, dieresis or umlaut mark 
                      @"Ü", @"&#220;",	//capital U, dieresis or umlaut mark 
                      @"Ý", @"&Yacute;",//capital Y, acute accent 
                      @"Ý", @"&#221;",	//capital Y, acute accent 
                      @"Þ", @"&THORN;",	//capital THORN, Icelandic 
                      @"Þ", @"&#222;",	//capital THORN, Icelandic 
                      @"ß", @"&szlig;",	//small sharp s, German (sz ligature) 
                      @"ß", @"&#223;",	//small sharp s, German (sz ligature) 
                      @"à", @"&agrave;",//small a, grave accent 
                      @"à", @"&#224;",	//small a, grave accent 
                      @"á", @"&aacute;",//small a, acute accent 
                      @"á", @"&#225;",	//small a, acute accent 
                      @"â", @"&acirc;",	//small a, circumflex accent 
                      @"â", @"&#226;",	//small a, circumflex accent 
                      @"ã", @"&atilde;",//small a, tilde 
                      @"ã", @"&#227;",	//small a, tilde 
                      @"ä", @"&auml;",	//small a, dieresis or umlaut mark 
                      @"ä", @"&#228;",	//small a, dieresis or umlaut mark 
                      @"å", @"&aring;",	//small a, ring 
                      @"å", @"&#229;",	//small a, ring 
                      @"æ", @"&aelig;",	//small ae diphthong (ligature) 
                      @"æ", @"&#230;",	//small ae diphthong (ligature) 
                      @"ç", @"&ccedil;",//small c, cedilla 
                      @"ç", @"&#231;",	//small c, cedilla 
                      @"è", @"&egrave;",//small e, grave accent 
                      @"è", @"&#232;",	//small e, grave accent 
                      @"é", @"&eacute;",//small e, acute accent 
                      @"é", @"&#233;",	//small e, acute accent 
                      @"ê", @"&ecirc;",	//small e, circumflex accent 
                      @"ê", @"&#234;",	//small e, circumflex accent 
                      @"ë", @"&euml;",	//small e, dieresis or umlaut mark 
                      @"ë", @"&#235;",	//small e, dieresis or umlaut mark 
                      @"ì", @"&igrave;",//small i, grave accent 
                      @"ì", @"&#236;",	//small i, grave accent 
                      @"í", @"&iacute;",//small i, acute accent 
                      @"í", @"&#237;",	//small i, acute accent 
                      @"î", @"&icirc;",	//small i, circumflex accent 
                      @"î", @"&#238;",	//small i, circumflex accent 
                      @"ï", @"&iuml;",	//small i, dieresis or umlaut mark 
                      @"ï", @"&#239;",	//small i, dieresis or umlaut mark 
                      @"ð", @"&eth;",	//small eth, Icelandic 
                      @"ð", @"&#240;",	//small eth, Icelandic 
                      @"ñ", @"&ntilde;",//small n, tilde 
                      @"ñ", @"&#241;",	//small n, tilde 
                      @"ò", @"&ograve;",//small o, grave accent 
                      @"ò", @"&#242;",	//small o, grave accent 
                      @"ó", @"&oacute;",//small o, acute accent 
                      @"ó", @"&#243;",	//small o, acute accent 
                      @"ô", @"&ocirc;",	//small o, circumflex accent 
                      @"ô", @"&#244;",	//small o, circumflex accent 
                      @"õ", @"&otilde;",//small o, tilde 
                      @"õ", @"&#245;",	//small o, tilde 
                      @"ö", @"&ouml;",	//small o, dieresis or umlaut mark 
                      @"ö", @"&#246;",	//small o, dieresis or umlaut mark 
                      @"÷", @"&divide;",//divide sign 
                      @"÷", @"&#247;",	//divide sign 
                      @"ø", @"&oslash;",//small o, slash 
                      @"ø", @"&#248;",	//small o, slash 
                      @"ù", @"&ugrave;",//small u, grave accent 
                      @"ù", @"&#249;",	//small u, grave accent 
                      @"ú", @"&uacute;",//small u, acute accent 
                      @"ú", @"&#250;",	//small u, acute accent 
                      @"û", @"&ucirc;",	//small u, circumflex accent 
                      @"û", @"&#251;",	//small u, circumflex accent 
                      @"ü", @"&uuml;",	//small u, dieresis or umlaut mark 
                      @"ü", @"&#252;",	//small u, dieresis or umlaut mark 
                      @"ý", @"&yacute;",//small y, acute accent 
                      @"ý", @"&#253;",	//small y, acute accent 
                      @"þ", @"&thorn;",	//small thorn, Icelandic 
                      @"þ", @"&#254;",	//small thorn, Icelandic 
                      @"ÿ", @"&yuml;",	//small y, dieresis or umlaut mark 
                      @"ÿ", @"&#255;",	//small y, dieresis or umlaut mark 
                      @"ƒ", @"&fnof;",	//latin small f with hook, =function, =florin, u+0192 ISOtech 
                      @"ƒ", @"&#402;",	//latin small f with hook, =function, =florin, u+0192 ISOtech 
                      @"Α", @"&Alpha;",	//greek capital letter alpha,  u+0391 
                      @"Α", @"&#913;",	//greek capital letter alpha,  u+0391 
                      @"Β", @"&Beta;",	//greek capital letter beta,  u+0392 
                      @"Β", @"&#914;",	//greek capital letter beta,  u+0392 
                      @"Γ", @"&Gamma;",	//greek capital letter gamma,  u+0393 ISOgrk3 
                      @"Γ", @"&#915;",	//greek capital letter gamma,  u+0393 ISOgrk3 
                      @"Δ", @"&Delta;",	//greek capital letter delta,  u+0394 ISOgrk3 
                      @"Δ", @"&#916;",	//greek capital letter delta,  u+0394 ISOgrk3 
                      @"Ε", @"&Epsilon;",//greek capital letter epsilon,  u+0395 
                      @"Ε", @"&#917;",	//greek capital letter epsilon,  u+0395 
                      @"Ζ", @"&Zeta;",	//greek capital letter zeta,  u+0396 
                      @"Ζ", @"&#918;",	//greek capital letter zeta,  u+0396 
                      @"Η", @"&Eta;",	//greek capital letter eta,  u+0397 
                      @"Η", @"&#919;",	//greek capital letter eta,  u+0397 
                      @"Θ", @"&Theta;",	//greek capital letter theta,  u+0398 ISOgrk3 
                      @"Θ", @"&#920;",	//greek capital letter theta,  u+0398 ISOgrk3 
                      @"Ι", @"&Iota;",	//greek capital letter iota,  u+0399 
                      @"Ι", @"&#921;",	//greek capital letter iota,  u+0399 
                      @"Κ", @"&Kappa;",	//greek capital letter kappa,  u+039A 
                      @"Κ", @"&#922;",	//greek capital letter kappa,  u+039A 
                      @"Λ", @"&Lambda;",//greek capital letter lambda,  u+039B ISOgrk3 
                      @"Λ", @"&#923;",	//greek capital letter lambda,  u+039B ISOgrk3 
                      @"Μ", @"&Mu;",	//greek capital letter mu,  u+039C 
                      @"Μ", @"&#924;",	//greek capital letter mu,  u+039C 
                      @"Ν", @"&Nu;",	//greek capital letter nu,  u+039D 
                      @"Ν", @"&#925;",	//greek capital letter nu,  u+039D 
                      @"Ξ", @"&Xi;",	//greek capital letter xi,  u+039E ISOgrk3 
                      @"Ξ", @"&#926;",	//greek capital letter xi,  u+039E ISOgrk3 
                      @"Ο", @"&Omicron;",//greek capital letter omicron,  u+039F 
                      @"Ο", @"&#927;",	//greek capital letter omicron,  u+039F 
                      @"Π", @"&Pi;",	//greek capital letter pi,  u+03A0 ISOgrk3 
                      @"Π", @"&#928;",	//greek capital letter pi,  u+03A0 ISOgrk3 
                      @"Ρ", @"&Rho;",	//greek capital letter rho,  u+03A1 
                      @"Ρ", @"&#929;",	//greek capital letter rho,  u+03A1 
                      @"Σ", @"&Sigma;",	//greek capital letter sigma,  u+03A3 ISOgrk3 
                      @"Σ", @"&#931;",	//greek capital letter sigma,  u+03A3 ISOgrk3 
                      @"Τ", @"&Tau;",	//greek capital letter tau,  u+03A4 
                      @"Τ", @"&#932;",	//greek capital letter tau,  u+03A4 
                      @"Υ", @"&Upsilon;",//greek capital letter upsilon,  u+03A5 ISOgrk3 
                      @"Υ", @"&#933;",	//greek capital letter upsilon,  u+03A5 ISOgrk3 
                      @"Φ", @"&Phi;",	//greek capital letter phi,  u+03A6 ISOgrk3 
                      @"Φ", @"&#934;",	//greek capital letter phi,  u+03A6 ISOgrk3 
                      @"Χ", @"&Chi;",	//greek capital letter chi,  u+03A7 
                      @"Χ", @"&#935;",	//greek capital letter chi,  u+03A7 
                      @"Ψ", @"&Psi;",	//greek capital letter psi,  u+03A8 ISOgrk3 
                      @"Ψ", @"&#936;",	//greek capital letter psi,  u+03A8 ISOgrk3 
                      @"Ω", @"&Omega;",	//greek capital letter omega,  u+03A9 ISOgrk3 
                      @"Ω", @"&#937;",	//greek capital letter omega,  u+03A9 ISOgrk3 
                      @"α", @"&alpha;",	//greek small letter alpha, u+03B1 ISOgrk3 
                      @"α", @"&#945;",	//greek small letter alpha, u+03B1 ISOgrk3 
                      @"β", @"&beta;",	//greek small letter beta,  u+03B2 ISOgrk3 
                      @"β", @"&#946;",	//greek small letter beta,  u+03B2 ISOgrk3 
                      @"γ", @"&gamma;",	//greek small letter gamma,  u+03B3 ISOgrk3 
                      @"γ", @"&#947;",	//greek small letter gamma,  u+03B3 ISOgrk3 
                      @"δ", @"&delta;",	//greek small letter delta,  u+03B4 ISOgrk3 
                      @"δ", @"&#948;",	//greek small letter delta,  u+03B4 ISOgrk3 
                      @"ε", @"&epsilon;",//greek small letter epsilon,  u+03B5 ISOgrk3 
                      @"ε", @"&#949;",	//greek small letter epsilon,  u+03B5 ISOgrk3 
                      @"ζ", @"&zeta;",	//greek small letter zeta,  u+03B6 ISOgrk3 
                      @"ζ", @"&#950;",	//greek small letter zeta,  u+03B6 ISOgrk3 
                      @"η", @"&eta;",	//greek small letter eta,  u+03B7 ISOgrk3 
                      @"η", @"&#951;",	//greek small letter eta,  u+03B7 ISOgrk3 
                      @"θ", @"&theta;",	//greek small letter theta,  u+03B8 ISOgrk3 
                      @"θ", @"&#952;",	//greek small letter theta,  u+03B8 ISOgrk3 
                      @"ι", @"&iota;",	//greek small letter iota,  u+03B9 ISOgrk3 
                      @"ι", @"&#953;",	//greek small letter iota,  u+03B9 ISOgrk3 
                      @"κ", @"&kappa;",	//greek small letter kappa,  u+03BA ISOgrk3 
                      @"κ", @"&#954;",	//greek small letter kappa,  u+03BA ISOgrk3 
                      @"λ", @"&lambda;",//greek small letter lambda,  u+03BB ISOgrk3 
                      @"λ", @"&#955;",	//greek small letter lambda,  u+03BB ISOgrk3 
                      @"μ", @"&mu;",	//greek small letter mu,  u+03BC ISOgrk3 
                      @"μ", @"&#956;",	//greek small letter mu,  u+03BC ISOgrk3 
                      @"ν", @"&nu;",	//greek small letter nu,  u+03BD ISOgrk3 
                      @"ν", @"&#957;",	//greek small letter nu,  u+03BD ISOgrk3 
                      @"ξ", @"&xi;",	//greek small letter xi,  u+03BE ISOgrk3 
                      @"ξ", @"&#958;",	//greek small letter xi,  u+03BE ISOgrk3 
                      @"ο", @"&omicron;",//greek small letter omicron,  u+03BF NEW 
                      @"ο", @"&#959;",	//greek small letter omicron,  u+03BF NEW 
                      @"π", @"&pi;",	//greek small letter pi,  u+03C0 ISOgrk3 
                      @"π", @"&#960;",	//greek small letter pi,  u+03C0 ISOgrk3 
                      @"ρ", @"&rho;",	//greek small letter rho,  u+03C1 ISOgrk3 
                      @"ρ", @"&#961;",	//greek small letter rho,  u+03C1 ISOgrk3 
                      @"ς", @"&sigmaf;",//greek small letter final sigma,  u+03C2 ISOgrk3 
                      @"ς", @"&#962;",	//greek small letter final sigma,  u+03C2 ISOgrk3 
                      @"σ", @"&sigma;",	//greek small letter sigma,  u+03C3 ISOgrk3 
                      @"σ", @"&#963;",	//greek small letter sigma,  u+03C3 ISOgrk3 
                      @"τ", @"&tau;",	//greek small letter tau,  u+03C4 ISOgrk3 
                      @"τ", @"&#964;",	//greek small letter tau,  u+03C4 ISOgrk3 
                      @"υ", @"&upsilon;",//greek small letter upsilon,  u+03C5 ISOgrk3 
                      @"υ", @"&#965;",	//greek small letter upsilon,  u+03C5 ISOgrk3 
                      @"φ", @"&phi;",	//greek small letter phi,  u+03C6 ISOgrk3 
                      @"φ", @"&#966;",	//greek small letter phi,  u+03C6 ISOgrk3 
                      @"χ", @"&chi;",	//greek small letter chi,  u+03C7 ISOgrk3 
                      @"χ", @"&#967;",	//greek small letter chi,  u+03C7 ISOgrk3 
                      @"ψ", @"&psi;",	//greek small letter psi,  u+03C8 ISOgrk3 
                      @"ψ", @"&#968;",	//greek small letter psi,  u+03C8 ISOgrk3 
                      @"ω", @"&omega;",	//greek small letter omega,  u+03C9 ISOgrk3 
                      @"ω", @"&#969;",	//greek small letter omega,  u+03C9 ISOgrk3 
                      @"ϑ", @"&thetasym;",//greek small letter theta symbol,  u+03D1 NEW 
                      @"ϑ", @"&#977;",	//greek small letter theta symbol,  u+03D1 NEW 
                      @"ϒ", @"&upsih;",	//greek upsilon with hook symbol,  u+03D2 NEW 
                      @"ϒ", @"&#978;",	//greek upsilon with hook symbol,  u+03D2 NEW 
                      @"ϖ", @"&piv;",	//greek pi symbol,  u+03D6 ISOgrk3 
                      @"ϖ", @"&#982;",	//greek pi symbol,  u+03D6 ISOgrk3 
                      @"•", @"&bull;",	//bullet, =black small circle, u+2022 ISOpub  
                      @"•", @"&#8226;",	//bullet, =black small circle, u+2022 ISOpub  
                      @"…", @"&hellip;",//horizontal ellipsis, =three dot leader, u+2026 ISOpub  
                      @"…", @"&#8230;",	//horizontal ellipsis, =three dot leader, u+2026 ISOpub  
                      @"′", @"&prime;",	//prime, =minutes, =feet, u+2032 ISOtech 
                      @"′", @"&#8242;",	//prime, =minutes, =feet, u+2032 ISOtech 
                      @"″", @"&Prime;",	//double prime, =seconds, =inches, u+2033 ISOtech 
                      @"″", @"&#8243;",	//double prime, =seconds, =inches, u+2033 ISOtech 
                      @"‾", @"&oline;",	//overline, =spacing overscore, u+203E NEW 
                      @"‾", @"&#8254;",	//overline, =spacing overscore, u+203E NEW 
                      @"⁄", @"&frasl;",	//fraction slash, u+2044 NEW 
                      @"⁄", @"&#8260;",	//fraction slash, u+2044 NEW 
                      @"℘", @"&weierp;",//script capital P, =power set, =Weierstrass p, u+2118 ISOamso 
                      @"℘", @"&#8472;",	//script capital P, =power set, =Weierstrass p, u+2118 ISOamso 
                      @"ℑ", @"&image;",	//blackletter capital I, =imaginary part, u+2111 ISOamso 
                      @"ℑ", @"&#8465;",	//blackletter capital I, =imaginary part, u+2111 ISOamso 
                      @"ℜ", @"&real;",	//blackletter capital R, =real part symbol, u+211C ISOamso 
                      @"ℜ", @"&#8476;",	//blackletter capital R, =real part symbol, u+211C ISOamso 
                      @"™", @"&trade;",	//trade mark sign, u+2122 ISOnum 
                      @"™", @"&#8482;",	//trade mark sign, u+2122 ISOnum 
                      @"ℵ", @"&alefsym;",//alef symbol, =first transfinite cardinal, u+2135 NEW 
                      @"ℵ", @"&#8501;",	//alef symbol, =first transfinite cardinal, u+2135 NEW 
                      @"←", @"&larr;",	//leftwards arrow, u+2190 ISOnum 
                      @"←", @"&#8592;",	//leftwards arrow, u+2190 ISOnum 
                      @"↑", @"&uarr;",	//upwards arrow, u+2191 ISOnum
                      @"↑", @"&#8593;",	//upwards arrow, u+2191 ISOnum
                      @"→", @"&rarr;",	//rightwards arrow, u+2192 ISOnum 
                      @"→", @"&#8594;",	//rightwards arrow, u+2192 ISOnum 
                      @"↓", @"&darr;",	//downwards arrow, u+2193 ISOnum 
                      @"↓", @"&#8595;",	//downwards arrow, u+2193 ISOnum 
                      @"↔", @"&harr;",	//left right arrow, u+2194 ISOamsa 
                      @"↔", @"&#8596;",	//left right arrow, u+2194 ISOamsa 
                      @"↵", @"&crarr;",	//downwards arrow with corner leftwards, =carriage return, u+21B5 NEW 
                      @"↵", @"&#8629;",	//downwards arrow with corner leftwards, =carriage return, u+21B5 NEW 
                      @"⇐", @"&lArr;",	//leftwards double arrow, u+21D0 ISOtech 
                      @"⇐", @"&#8656;",	//leftwards double arrow, u+21D0 ISOtech 
                      @"⇑", @"&uArr;",	//upwards double arrow, u+21D1 ISOamsa 
                      @"⇑", @"&#8657;",	//upwards double arrow, u+21D1 ISOamsa 
                      @"⇒", @"&rArr;",	//rightwards double arrow, u+21D2 ISOtech 
                      @"⇒", @"&#8658;",	//rightwards double arrow, u+21D2 ISOtech 
                      @"⇓", @"&dArr;",	//downwards double arrow, u+21D3 ISOamsa 
                      @"⇓", @"&#8659;",	//downwards double arrow, u+21D3 ISOamsa 
                      @"⇔", @"&hArr;",	//left right double arrow, u+21D4 ISOamsa 
                      @"⇔", @"&#8660;",	//left right double arrow, u+21D4 ISOamsa 
                      @"∀", @"&forall;",//for all, u+2200 ISOtech 
                      @"∀", @"&#8704;",	//for all, u+2200 ISOtech 
                      @"∂", @"&part;",	//partial differential, u+2202 ISOtech  
                      @"∂", @"&#8706;",	//partial differential, u+2202 ISOtech  
                      @"∃", @"&exist;",	//there exists, u+2203 ISOtech 
                      @"∃", @"&#8707;",	//there exists, u+2203 ISOtech 
                      @"∅", @"&empty;",	//empty set, =null set, =diameter, u+2205 ISOamso 
                      @"∅", @"&#8709;",	//empty set, =null set, =diameter, u+2205 ISOamso 
                      @"∇", @"&nabla;",	//nabla, =backward difference, u+2207 ISOtech 
                      @"∇", @"&#8711;",	//nabla, =backward difference, u+2207 ISOtech 
                      @"∈", @"&isin;",	//element of, u+2208 ISOtech 
                      @"∈", @"&#8712;",	//element of, u+2208 ISOtech 
                      @"∉", @"&notin;",	//not an element of, u+2209 ISOtech 
                      @"∉", @"&#8713;",	//not an element of, u+2209 ISOtech 
                      @"∋", @"&ni;",	//contains as member, u+220B ISOtech 
                      @"∋", @"&#8715;",	//contains as member, u+220B ISOtech 
                      @"∏", @"&prod;",	//n-ary product, =product sign, u+220F ISOamsb 
                      @"∏", @"&#8719;",	//n-ary product, =product sign, u+220F ISOamsb 
                      @"∑", @"&sum;",	//n-ary sumation, u+2211 ISOamsb 
                      @"∑", @"&#8721;",	//n-ary sumation, u+2211 ISOamsb 
                      @"−", @"&minus;",	//minus sign, u+2212 ISOtech 
                      @"−", @"&#8722;",	//minus sign, u+2212 ISOtech 
                      @"∗", @"&lowast;",//asterisk operator, u+2217 ISOtech 
                      @"∗", @"&#8727;",	//asterisk operator, u+2217 ISOtech 
                      @"√", @"&radic;",	//square root, =radical sign, u+221A ISOtech 
                      @"√", @"&#8730;",	//square root, =radical sign, u+221A ISOtech 
                      @"∝", @"&prop;",	//proportional to, u+221D ISOtech 
                      @"∝", @"&#8733;",	//proportional to, u+221D ISOtech 
                      @"∞", @"&infin;",	//infinity, u+221E ISOtech 
                      @"∞", @"&#8734;",	//infinity, u+221E ISOtech 
                      @"∠", @"&ang;",	//angle, u+2220 ISOamso 
                      @"∠", @"&#8736;",	//angle, u+2220 ISOamso 
                      @"⊥", @"&and;",	//logical and, =wedge, u+2227 ISOtech 
                      @"⊥", @"&#8869;", //logical and, =wedge, u+2227 ISOtech 
                      @"⊦", @"&or;",    //logical or, =vee, u+2228 ISOtech 
                      @"⊦", @"&#8870;",	//logical or, =vee, u+2228 ISOtech 
                      @"∩", @"&cap;",	//intersection, =cap, u+2229 ISOtech 
                      @"∩", @"&#8745;",	//intersection, =cap, u+2229 ISOtech 
                      @"∪", @"&cup;",	//union, =cup, u+222A ISOtech 
                      @"∪", @"&#8746;",	//union, =cup, u+222A ISOtech 
                      @"∫", @"&int;",	//integral, u+222B ISOtech 
                      @"∫", @"&#8747;",	//integral, u+222B ISOtech 
                      @"∴", @"&there4;",//therefore, u+2234 ISOtech 
                      @"∴", @"&#8756;",	//therefore, u+2234 ISOtech 
                      @"∼", @"&sim;",	//tilde operator, =varies with, =similar to, u+223C ISOtech 
                      @"∼", @"&#8764;",	//tilde operator, =varies with, =similar to, u+223C ISOtech 
                      @"≅", @"&cong;",	//approximately equal to, u+2245 ISOtech 
                      @"≅", @"&#8773;",	//approximately equal to, u+2245 ISOtech 
                      @"≈", @"&asymp;",	//almost equal to, =asymptotic to, u+2248 ISOamsr 
                      @"≈", @"&#8776;",	//almost equal to, =asymptotic to, u+2248 ISOamsr 
                      @"≠", @"&ne;",	//not equal to, u+2260 ISOtech 
                      @"≠", @"&#8800;",	//not equal to, u+2260 ISOtech 
                      @"≡", @"&equiv;",	//identical to, u+2261 ISOtech 
                      @"≡", @"&#8801;",	//identical to, u+2261 ISOtech 
                      @"≤", @"&le;",	//less-than or equal to, u+2264 ISOtech 
                      @"≤", @"&#8804;",	//less-than or equal to, u+2264 ISOtech 
                      @"≥", @"&ge;",	//greater-than or equal to, u+2265 ISOtech 
                      @"≥", @"&#8805;",	//greater-than or equal to, u+2265 ISOtech 
                      @"⊂", @"&sub;",	//subset of, u+2282 ISOtech 
                      @"⊂", @"&#8834;",	//subset of, u+2282 ISOtech 
                      @"⊃", @"&sup;",	//superset of, u+2283 ISOtech 
                      @"⊃", @"&#8835;",	//superset of, u+2283 ISOtech 
                      @"⊄", @"&nsub;",	//not a subset of, u+2284 ISOamsn 
                      @"⊄", @"&#8836;",	//not a subset of, u+2284 ISOamsn 
                      @"⊆", @"&sube;",	//subset of or equal to, u+2286 ISOtech 
                      @"⊆", @"&#8838;",	//subset of or equal to, u+2286 ISOtech 
                      @"⊇", @"&supe;",	//superset of or equal to, u+2287 ISOtech 
                      @"⊇", @"&#8839;",	//superset of or equal to, u+2287 ISOtech 
                      @"⊕", @"&oplus;",	//circled plus, =direct sum, u+2295 ISOamsb 
                      @"⊕", @"&#8853;",	//circled plus, =direct sum, u+2295 ISOamsb 
                      @"⊗", @"&otimes;",//circled times, =vector product, u+2297 ISOamsb 
                      @"⊗", @"&#8855;",	//circled times, =vector product, u+2297 ISOamsb 
                      @"⊥", @"&perp;",	//up tack, =orthogonal to, =perpendicular, u+22A5 ISOtech 
                      @"⊥", @"&#8869;",	//up tack, =orthogonal to, =perpendicular, u+22A5 ISOtech 
                      @"⋅", @"&sdot;",	//dot operator, u+22C5 ISOamsb 
                      @"⋅", @"&#8901;",	//dot operator, u+22C5 ISOamsb 
                      @"⌈", @"&lceil;",	//left ceiling, =apl upstile, u+2308, ISOamsc  
                      @"⌈", @"&#8968;",	//left ceiling, =apl upstile, u+2308, ISOamsc  
                      @"⌉", @"&rceil;",	//right ceiling, u+2309, ISOamsc  
                      @"⌉", @"&#8969;",	//right ceiling, u+2309, ISOamsc  
                      @"⌊", @"&lfloor;",//left floor, =apl downstile, u+230A, ISOamsc  
                      @"⌊", @"&#8970;",	//left floor, =apl downstile, u+230A, ISOamsc  
                      @"⌋", @"&rfloor;",//right floor, u+230B, ISOamsc  
                      @"⌋", @"&#8971;",	//right floor, u+230B, ISOamsc  
                      @"〈", @"&lang;",	//left-pointing angle bracket, =bra, u+2329 ISOtech 
                      @"〈", @"&#9001;",	//left-pointing angle bracket, =bra, u+2329 ISOtech 
                      @"〉", @"&rang;",	//right-pointing angle bracket, =ket, u+232A ISOtech 
                      @"〉", @"&#9002;",	//right-pointing angle bracket, =ket, u+232A ISOtech 
                      @"◊", @"&loz;",	//lozenge, u+25CA ISOpub 
                      @"◊", @"&#9674;",	//lozenge, u+25CA ISOpub 
                      @"♠", @"&spades;",//black spade suit, u+2660 ISOpub 
                      @"♠", @"&#9824;",	//black spade suit, u+2660 ISOpub 
                      @"♣", @"&clubs;",	//black club suit, =shamrock, u+2663 ISOpub 
                      @"♣", @"&#9827;",	//black club suit, =shamrock, u+2663 ISOpub 
                      @"♥", @"&hearts;",//black heart suit, =valentine, u+2665 ISOpub 
                      @"♥", @"&#9829;",	//black heart suit, =valentine, u+2665 ISOpub 
                      @"♦", @"&diams;",	//black diamond suit, u+2666 ISOpub 
                      @"♦", @"&#9830;",	//black diamond suit, u+2666 ISOpub 
                      @"\"", @"&quot;",	//quotation mark, =apl quote, u+0022 ISOnum 
                      @"\"", @"&#34;",	//quotation mark, =apl quote, u+0022 ISOnum 
                      @"&", @"&amp;",	//ampersand, u+0026 ISOnum 
                      @"&", @"&#38;",	//ampersand, u+0026 ISOnum 
                      @"<", @"&lt;",	//less-than sign, u+003C ISOnum 
                      @"<", @"&#60;",	//less-than sign, u+003C ISOnum 
                      @">", @"&gt;",	//greater-than sign, u+003E ISOnum 
                      @">", @"&#62;",	//greater-than sign, u+003E ISOnum 
                      @"Œ", @"&OElig;",	//latin capital ligature oe, u+0152 ISOlat2 
                      @"Œ", @"&#338;",	//latin capital ligature oe, u+0152 ISOlat2 
                      @"œ", @"&oelig;",	//latin small ligature oe, u+0153 ISOlat2 
                      @"œ", @"&#339;",	//latin small ligature oe, u+0153 ISOlat2 
                      @"Š", @"&Scaron;",//latin capital letter s with caron, u+0160 ISOlat2 
                      @"Š", @"&#352;",	//latin capital letter s with caron, u+0160 ISOlat2 
                      @"š", @"&scaron;",//latin small letter s with caron, u+0161 ISOlat2 
                      @"š", @"&#353;",	//latin small letter s with caron, u+0161 ISOlat2 
                      @"Ÿ", @"&Yuml;",	//latin capital letter y with diaeresis, u+0178 ISOlat2 
                      @"Ÿ", @"&#376;",	//latin capital letter y with diaeresis, u+0178 ISOlat2 
                      @"ˆ", @"&circ;",	//modifier letter circumflex accent, u+02C6 ISOpub 
                      @"ˆ", @"&#710;",	//modifier letter circumflex accent, u+02C6 ISOpub 
                      @"˜", @"&tilde;",	//small tilde, u+02DC ISOdia 
                      @"˜", @"&#732;",	//small tilde, u+02DC ISOdia 
                      @" ", @"&ensp;",	//en space, u+2002 ISOpub 
                      @" ", @"&#8194;",	//en space, u+2002 ISOpub 
                      @" ", @"&emsp;",	//em space, u+2003 ISOpub 
                      @" ", @"&#8195;",	//em space, u+2003 ISOpub 
                      @" ", @"&thinsp;",//thin space, u+2009 ISOpub 
                      @" ", @"&#8201;",	//thin space, u+2009 ISOpub 
                      @"‌", @"&zwnj;",	//zero width non-joiner, u+200C NEW RFC 2070 
                      @"‌", @"&#8204;",	//zero width non-joiner, u+200C NEW RFC 2070 
                      @"‍", @"&zwj;",	//zero width joiner, u+200D NEW RFC 2070 
                      @"‍", @"&#8205;",	//zero width joiner, u+200D NEW RFC 2070 
                      @"‎", @"&lrm;",	//left-to-right mark, u+200E NEW RFC 2070 
                      @"‎", @"&#8206;",	//left-to-right mark, u+200E NEW RFC 2070 
                      @"‏", @"&rlm;",	//right-to-left mark, u+200F NEW RFC 2070 
                      @"‏", @"&#8207;",	//right-to-left mark, u+200F NEW RFC 2070 
                      @"–", @"&ndash;",	//en dash, u+2013 ISOpub 
                      @"–", @"&#8211;",	//en dash, u+2013 ISOpub 
                      @"—", @"&mdash;",	//em dash, u+2014 ISOpub 
                      @"—", @"&#8212;",	//em dash, u+2014 ISOpub 
                      @"‘", @"&lsquo;",	//left single quotation mark, u+2018 ISOnum 
                      @"‘", @"&#8216;",	//left single quotation mark, u+2018 ISOnum 
                      @"’", @"&rsquo;",	//right single quotation mark, u+2019 ISOnum 
                      @"’", @"&#8217;",	//right single quotation mark, u+2019 ISOnum 
                      @"‚", @"&sbquo;",	//single low-9 quotation mark, u+201A NEW 
                      @"‚", @"&#8218;",	//single low-9 quotation mark, u+201A NEW 
                      @"“", @"&ldquo;",	//left double quotation mark, u+201C ISOnum 
                      @"“", @"&#8220;",	//left double quotation mark, u+201C ISOnum 
                      @"”", @"&rdquo;",	//right double quotation mark, u+201D ISOnum 
                      @"”", @"&#8221;",	//right double quotation mark, u+201D ISOnum 
                      @"„", @"&bdquo;",	//double low-9 quotation mark, u+201E NEW 
                      @"„", @"&#8222;",	//double low-9 quotation mark, u+201E NEW 
                      @"†", @"&dagger;",//dagger, u+2020 ISOpub 
                      @"†", @"&#8224;",	//dagger, u+2020 ISOpub 
                      @"‡", @"&Dagger;",//double dagger, u+2021 ISOpub 
                      @"‡", @"&#8225;",	//double dagger, u+2021 ISOpub 
                      @"‰", @"&permil;",//per mille sign, u+2030 ISOtech 
                      @"‰", @"&#8240;",	//per mille sign, u+2030 ISOtech 
                      @"‹", @"&lsaquo;",//single left-pointing angle quotation mark, u+2039 ISO proposed 
                      @"‹", @"&#8249;",	//single left-pointing angle quotation mark, u+2039 ISO proposed 
                      @"›", @"&rsaquo;",//single right-pointing angle quotation mark, u+203A ISO proposed 
                      @"›", @"&#8250;",	//single right-pointing angle quotation mark, u+203A ISO proposed
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

    entityBoundaryCharacterSet_ = GSRetained([NSCharacterSet characterSetWithCharactersInString:@"&;"]);

    NSMutableCharacterSet *ampSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"&"];
    [ampSet invert];
    nonAmpCharacterSet_ = GSRetained(ampSet);
}

static NSString* unescapedStringForEntity(NSString *entity) {
    // entity should be something matching (&.*;).
    if (!entity || [entity length] > maxUnescapeKeyLength_ || [entity length] < minUnescapeKeyLength_) {
        return entity;
    }

    NSString *rString = [unescapeTable_ objectForKey:entity];
    if (rString) {
        return rString;
    }

    // we couldn't map to any value... return a copy
    return GSAutoreleased([entity copy]);
}

@implementation NSString(GSHTML)

- (NSString*)unescapeHTMLEntities {
    if ([self length] == 0) {
        return @"";
    }

    // make sure we're set up to unescape
    if (!unescapeTable_) {
        initUnescapeVars();
    }

    NSMutableString *rString = [[NSMutableString alloc] initWithCapacity:[self length]];
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    scanner.charactersToBeSkipped = nil;
    NSString *newString;
    NSString *entityString;
    NSString *heldAmpersand = @"";
    while (scanner.isAtEnd == NO) {
        // go until you find an &
        newString = nil;
        [scanner scanUpToString:ampString intoString:&newString];
        if (newString) {
            [rString appendString:newString];
        }
        if (scanner.isAtEnd) {
            GSRelease(scanner);
            return GSAutoreleased(rString);
        }

        // next time you see a ;, unescape stuff if you need to. 
        heldAmpersand = @"";
        while (scanner.isAtEnd == NO) {
            newString = nil;
            [scanner scanUpToCharactersFromSet:entityBoundaryCharacterSet_ intoString:&newString];

            if (scanner.isAtEnd) {
                [rString appendString:heldAmpersand];
                heldAmpersand = @"";

                [rString appendString:newString];
                break;
            }
            unichar nextChar = [self characterAtIndex:scanner.scanLocation];

            if (nextChar == '&') {
                // held ampersand will either be an ampersand or an empty string,
                // but we now know it's not important for parsing now
                [rString appendString:heldAmpersand];
                // heldAmpersand = @"";

                // put everything you've got so far into the rString and restart this loop
                if (newString) {
                    [rString appendString:newString];
                }

                // put all consecutive &'s you run into on the string, save the last one
                newString = nil;
                [scanner scanUpToCharactersFromSet:nonAmpCharacterSet_ intoString:&newString];
                heldAmpersand = @"&";
                if (newString && [newString length] > 1) {
                    NSString *subStr = [newString substringToIndex:[newString length]-1];
                    [rString appendString:subStr];
                }
                continue;
            }
            else if (nextChar == ';') {
                // newString will be nil if you collected 0 characters... replace w/empty
                if (!newString) {
                    newString = @"";
                }

                // parse what you've seen since the last &
                entityString = [[NSString alloc] initWithFormat:@"%@%@;", heldAmpersand, newString]; // released below

                newString = unescapedStringForEntity(entityString);
                if (newString) {
                    // string is unchanged if un-unescapable
                    [rString appendString:newString];
                }
                GSRelease(entityString);

                // advance the scanner past the ;
                scanner.scanLocation += 1;

                // break out of the while loop
                heldAmpersand = @"";
                break;
            }
        }

        // the held ampersand will either be an ampersand or an empty string
        [rString appendString:heldAmpersand];
    }
    
    GSRelease(scanner);
    
    return GSAutoreleased(rString);
}

@end
