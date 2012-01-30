//
//  GSHTMLTest.m
//  GSFancyTextDemo
//
//  Created by Bao Lei on 1/29/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import "NSString+GSHTML.h"

#import <UIKit/UIKit.h>
//#import "application_headers" as required

#import <SenTestingKit/SenTestingKit.h>

@interface GSHTMLTest : SenTestCase

@end

@implementation GSHTMLTest

- (void)testUnescape {
    NSString* html = @"A&lt;B&gt;C";
    NSString* unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"A<B>C", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"You &amp; I";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"You & I", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"You &a&mp; I";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"You &a&mp; I", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"Hello &;Man";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"Hello &;Man", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"Hi & Bye";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"Hi & Bye", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"Meet the sign &";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"Meet the sign &", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"& there are less;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"& there are less;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&amp; begins it";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"& begins it", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"End it with E=mc&sup2;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"End it with E=mc²", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"Test unicode:&yen;. What the $$! Chinese RMB is also &yen;! Why &rmb; or &renminbi; or &yuan; does not work!";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"Test unicode:¥. What the $$! Chinese RMB is also ¥! Why &rmb; or &renminbi; or &yuan; does not work!", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&lt;&gt;&amp;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"<>&", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&lt";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&lt", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"& gt;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"& gt;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&&&&&yen;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&&&&¥", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&;&&&&yen;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&;&&&¥", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&lt;;;;;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"<;;;;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"& there are more &amp;s";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"& there are more &s", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"& & ; & &lt; &gt; ;; ;&;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"& & ; & < > ;; ;&;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&imaginary;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&imaginary;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&l t;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&l t;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&g_t;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&g_t;", unescaped, @"incorrect unescape: %@", unescaped);
    
    html = @"&\namp;&amp;";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"&\namp;&", unescaped, @"incorrect unescape: %@", unescaped);
    
    // this is a trickier situation. currently when we call this method, we already stripped html tags before hand
    // so we don't ignore <...> in this method, and that's fine
    html = @"<div>&lt;</div>";
    unescaped = [html unescapeHTMLEntities];
    STAssertEqualObjects(@"<div><</div>", unescaped, @"incorrect unescape: %@", unescaped);
}

@end
