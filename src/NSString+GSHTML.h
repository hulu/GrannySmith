//
//  NSString+GSHTML.h
//  GSFancyTextDemo
//
//  Created by Ben Acland on 1/29/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

/// HTML related tools for NSString

@interface NSString(GSHTML)

/** 
 Unescapes all of the entities listed at http://www.w3.org/TR/WD-html40-970708/sgml/entities.html
 This method does not support the 'soft hyphen,' &#173;, &shy;*/
- (NSString*)unescapeHTMLEntities;

@end
