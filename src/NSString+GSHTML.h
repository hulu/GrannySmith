//
//  NSString+GSHTML.h
//  GSFancyTextDemo
//
//  Created by Ben Acland on 1/29/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//



@interface NSString (GSHTML)

/** 
 Unescapes all of the entities listed at w3schools.com/tags/ref_entities.asp
 This method does not support the 'soft hyphen,' &#173;, &shy;*/
- (NSString*)unescapeHTMLEntities;

@end
