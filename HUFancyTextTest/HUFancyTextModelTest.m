//
//  HUFancyTextTest.m
//  HUFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "HUFancyText.h"

@interface HUFancyTextTest : SenTestCase {
}

@end

@implementation HUFancyTextTest

- (void)setUp {
    NSString* styleSheet = @".default{color: #ffffff; vertical-align:middle}\n\
    .green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .right{text-align: right}\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    span.blue{color: blue}\
    .center{text-align: center}\
    .limit2{line-count:2; truncate-mode:tail}";
    
    [HUFancyText parseStyleAndSetGlobal:styleSheet];
}

- (void)tearDown {
    
}


- (void)testStyleParsing {    
    NSMutableDictionary* css;
    
    css = [HUFancyText parsedStyle:@"p.small {font-size: 11; font-weigth: normal;}   p.medium {font-size:14px; font-style   :italic} p.large{   font-size:20.f}"];
    
    STAssertTrue( [[css objectForKey:@"p"] allKeys].count == 3, @"CSS classes are not all recognized");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"small"], @"class small not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"medium"], @"class medium not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"large"], @"class large not read");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"medium"] objectForKey:@"font-size"] floatValue] == 14.f, @"Font size number parsing error");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"large"] objectForKey:@"font-size"] floatValue] == 20.f, @"Font size number parsing error");
    
    css = [HUFancyText parsedStyle:@".red {color: rEd; font-weigth: bold;}   .green {font-size:14px; color:#00ff00} p.blue{   color:RgB(0,  0,255)}"];
    
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"color"], [UIColor greenColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:@"p"] objectForKey:@"blue"] objectForKey:@"color"], [UIColor blueColor], @"Color parsing error");
    
    
    css = [HUFancyText parsedStyle:@".red {color: \"red\"; font-weigth: bold;}   .green {font-size:'14px'; color:#00ff00} .blue{   attrib:'{this is the fanciest value; period.}'"];
    
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"quoted color parsing error");
    STAssertEquals( [[[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"font-size"] floatValue], 14.f, @"quoted size parsing error");
    STAssertEqualObjects( [[[css objectForKey:HUFancyTextDefaultClass] objectForKey:@"blue"] objectForKey:@"attrib"], @"{this is the fanciest value; period.}", @"quoted string parsing error");
}

- (void)testGlobalStyle {
    NSMutableDictionary* globalStyle = [HUFancyText globalStyle];
    STAssertEquals([[[[globalStyle objectForKey:HUFancyTextDefaultClass] objectForKey:@"right"] objectForKey:@"text-align"] intValue], TextAlignRight, @"global style retrieving error");
}

- (void)testMarkupParsing {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=green>c</b>e"];
    [fancyText parseStructure];
    int count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    HUMarkupNode* node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"green"] objectAtIndex:0] children] objectAtIndex:0];
    UIColor* color = [node.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor greenColor], @"class green's text color is %@", color);
    HURelease(fancyText);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"yellow\">c</p><p class='green'>e</p>"];
    [fancyText parseStructure];
    count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 2, @"expecting 2 children but seeing %d", count);
    node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"green"] objectAtIndex:0] children] objectAtIndex:0];
    color = [node.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor greenColor], @"class green's text color is %@", color);
    node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"yellow"] objectAtIndex:0] children] objectAtIndex:0];
    color = [node.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"class yellow's text color is %@", color);
    HURelease(fancyText);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">c</p><span class='blue' id=2>e</span>"];
    [fancyText parseStructure];
    node = [[[fancyText.parsedResultTree childNodeWithID:@"1"] children] objectAtIndex:0];
    color = [node.data objectForKey:HUFancyTextColorKey];
    UIColor* white = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    STAssertEqualObjects(color, white, @"color is %@ but we expect white", color);
    node = [[[fancyText.parsedResultTree childNodeWithID:@"2"] children] objectAtIndex:0];
    color = [node.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor blueColor], @"class blue's text color is %@", color);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"yellow>c</p><p class='green'>e</p>"];
    [fancyText parseStructure];
    count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=green><ufo class=yellow id=1>c</ufo><span class='green'>e</span></p>"];
    [fancyText parseStructure];
    node = [fancyText.parsedResultTree childNodeWithID:@"1"];
    node = [node.children objectAtIndex:0];
    NSString* text = [node.data objectForKey:HUFancyTextTextKey];
    STAssertEqualObjects(text, @"c", @"text inside special tag parsing error: %@", text);
    color = [node.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"color inside special tag parsing error: %@", color);
}

- (void)testLineBreak {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<span class=green>Span 1</span><span>Span 2</span>"];
    fancyText.width = 1000.f;
    [fancyText generateLines];
    int count = fancyText.lines.count;
    STAssertEquals(count, 1, @"expecting 1 line but seeing %d", count);
    HURelease(fancyText);

    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=green>1 <span>s</span></p>2<p>3</p>"];
    fancyText.width = 1000.f;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 3, @"expecting 3 lines but seeing %d", count);
    HURelease(fancyText);
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=green>Here is a long long long line.<span>s</span></p>2<p>3</p>"];
    fancyText.width = [@"Here is a long long" sizeWithFont:[UIFont systemFontOfSize:14.f]].width;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 4, @"expecting 4 lines but seeing %d", count);
    HURelease(fancyText);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=limit2>Here is a long long long long long long long long long long long long line.<span>s</span></p>2<p>3</p>"];
    fancyText.width = [@"Here is a" sizeWithFont:[UIFont systemFontOfSize:14.f]].width;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 4, @"expecting 3 lines but seeing %d", count);
    HURelease(fancyText);
}

- (void)testContentChange {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span></p> <p> L2 </p>"];
    [fancyText parseStructure];    
    [fancyText changeNodeToText:@"Blah" forID:@"1"];
    HUMarkupNode* changedNode = [fancyText.parsedResultTree childNodeWithID:@"1"];
    int count = changedNode.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    HUMarkupNode* child = [changedNode.children objectAtIndex:0];
    NSString* text = [child.data objectForKey:HUFancyTextTextKey];
    STAssertEqualObjects(text, @"Blah", @"text change failed. It's %@", text);
    HURelease(fancyText);
    
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span> <lambda id=L></p> <p> L2 </p>"];
    [fancyText parseStructure];
    [fancyText changeNodeToStyledText:@"<strong>B</strong>lah" forID:@"1"];
    changedNode = [fancyText.parsedResultTree childNodeWithID:@"1"];
    count = changedNode.children.count;
    STAssertEquals(count, 1, @"expecting 2 children but seeing %d", count);
    HUMarkupNode* newRoot = [changedNode.children objectAtIndex:0];
    STAssertEquals(newRoot.isContainer, YES, @"styled text change failed.");
    STAssertTrue(newRoot.children.count == 2, @"inserted tree children count wrong: %d", newRoot.children.count);
    child = [newRoot.children objectAtIndex:0];
    STAssertEquals(child.isContainer, YES, @"styled text change failed.");
    child = [child.children objectAtIndex:0];
    text = [child.data objectForKey:HUFancyTextTextKey];
    STAssertEqualObjects(text, @"B", @"styled text change failed. It's %@", text);
    HURelease(fancyText);
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span> <lambda id=L></p> <p> L2 </p>"];
    [fancyText parseStructure];
    HUMarkupNode* id1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    count = id1.children.count;
    [fancyText appendStyledText:@"<strong>B</strong>lah" toID:@"1"];
    STAssertTrue(id1.children.count == count + 1, @"appending node didn't give the right count");
    newRoot = [changedNode.children lastObject]; // getting the new root
    child = [newRoot.children lastObject];
    text = [child.data objectForKey:HUFancyTextTextKey];
    STAssertEqualObjects(text, @"lah", @"styled text change failed. It's %@", text);
    HURelease(fancyText);
    
    fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p id=1 class=right>Real right. Fake <span id=2 class=center>center</span></p>"];
    [fancyText parseStructure];
    id1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    HUMarkupNode* id2 = [fancyText.parsedResultTree childNodeWithID:@"2"];
    HUMarkupNode* node = [id1.children objectAtIndex:0];
    TextAlign align = [[node.data objectForKey:HUFancyTextTextAlignKey] intValue];
    STAssertTrue(align==TextAlignRight, @"p align incorrect:%d", align);
    node = [id2.children objectAtIndex:0];
    align = [[node.data objectForKey:HUFancyTextTextAlignKey] intValue];
    STAssertTrue(align==TextAlignRight, @"span align incorrect:%d", align);
}


- (void)testStyleChange {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<p class=\"green\" id=\"1\">1 and something else like <span class='blue' id=2>e</span></p> <p> L2 </p>"];
    [fancyText parseStructure];    
    [fancyText applyClass:@"yellow" on:HUFancyTextID withName:@"1"];
    HUMarkupNode* node1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    HUMarkupNode* node2 = [fancyText.parsedResultTree childNodeWithID:@"2"];
    UIColor* color = [node1.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"color apply failed. color is %@", color);
    color = [node2.data objectForKey:HUFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor blueColor], @"color protection failed. color is %@", color);
    NSString* fontStyle = [node1.data objectForKey:HUFancyTextFontStyleKey];
    STAssertEqualObjects(fontStyle, @"italic", @"font style retain failed. style is %@", fontStyle);
    
    [fancyText changeStylesToClass:@"yellow" on:HUFancyTextID withName:@"1"];
    fontStyle = [node1.data objectForKey:HUFancyTextFontStyleKey];
    STAssertNil(fontStyle, @"italic", @"font style remove failed. style is %@", fontStyle);
    
    HURelease(fancyText);
}

- (void)testPureText {
    HUFancyText* fancyText = [[HUFancyText alloc] initWithMarkupText:@"<span>Hello</span>! <a>How</a> <dog>are</dog> you doing? <lambda id=x alt='Read me if you can'>"];
    [fancyText parseStructure];
    NSString* pureText = [fancyText pureText];
    STAssertEqualObjects(pureText, @"Hello! How are you doing? Read me if you can", @"wrong pure text: %@", pureText);
}

@end
