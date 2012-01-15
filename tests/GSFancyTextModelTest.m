//
//  GSFancyTextTest.m
//  GSFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "GSFancyText.h"
#import "NSString+GSParsingHelper.h"

@interface GSFancyTextTest : SenTestCase {
}

@end

@implementation GSFancyTextTest

- (void)setUp {
    NSString* styleSheet = @".default{color: #ffffff; vertical-align:middle}\n\
    .green {color:  'rgb(0, 255, 0)' ;font-family: 'Georgia'; font-size: 15px; font-style:'italic'   }\
    .right{text-align: right}\
    .yellow {color: yellow; font-family: Futura; font-SIzE: 18px}\
    span.blue{color: blue}\
    .center{text-align: center}\
    .limit2{line-count:2; truncate-mode:tail}";
    
    [GSFancyText parseStyleAndSetGlobal:styleSheet];
}

- (void)tearDown {
    
}


- (void)testStyleParsing {
    NSMutableDictionary* css;
    
    css = [GSFancyText parsedStyle:@"p.small {font-size: 11; font-weigth: normal;}   p.medium {font-size:14px; font-style   :italic} p.large{   font-size:20.f}"];
    
    STAssertTrue( [[css objectForKey:@"p"] allKeys].count == 3, @"CSS classes are not all recognized");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"small"], @"class small not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"medium"], @"class medium not read");
    STAssertNotNil( [[css objectForKey:@"p"] objectForKey:@"large"], @"class large not read");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"medium"] objectForKey:@"font-size"] floatValue] == 14.f, @"Font size number parsing error");
    STAssertTrue( [[[[css objectForKey:@"p"] objectForKey:@"large"] objectForKey:@"font-size"] floatValue] == 20.f, @"Font size number parsing error");
    
    css = [GSFancyText parsedStyle:@".red {color: rEd; font-weigth: bold;}   .green {font-size:14px; color:#00ff00} p.blue{   color:RgB(0,  0,255)}"];
    
    STAssertEqualObjects( [[[css objectForKey:GSFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:GSFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"color"], [UIColor greenColor], @"Color parsing error");
    STAssertEqualObjects( [[[css objectForKey:@"p"] objectForKey:@"blue"] objectForKey:@"color"], [UIColor blueColor], @"Color parsing error");
    
    
    css = [GSFancyText parsedStyle:@".red {color: \"red\"; font-weigth: bold;}   .green {font-size:'14px'; color:#00ff00} .blue{   attrib:'{this is the fanciest value; period.}'"];
    
    STAssertEqualObjects( [[[css objectForKey:GSFancyTextDefaultClass] objectForKey:@"red"] objectForKey:@"color"], [UIColor redColor], @"quoted color parsing error");
    STAssertEquals( [[[[css objectForKey:GSFancyTextDefaultClass] objectForKey:@"green"] objectForKey:@"font-size"] floatValue], 14.f, @"quoted size parsing error");
    STAssertEqualObjects( [[[css objectForKey:GSFancyTextDefaultClass] objectForKey:@"blue"] objectForKey:@"attrib"], @"{this is the fanciest value; period.}", @"quoted string parsing error");
}

- (void)testGlobalStyle {
    NSMutableDictionary* globalStyle = [GSFancyText globalStyle];
    STAssertEquals([[[[globalStyle objectForKey:GSFancyTextDefaultClass] objectForKey:@"right"] objectForKey:@"text-align"] intValue], GSTextAlignRight, @"global style retrieving error");
}

- (void)testMarkupParsing {
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=green>c</b>e"];
    [fancyText parseStructure];
    int count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    GSMarkupNode* node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"green"] objectAtIndex:0] children] objectAtIndex:0];
    UIColor* color = [node.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor greenColor], @"class green's text color is %@", color);
    GSRelease(fancyText);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"yellow\">c</p><p class='green'>e</p>"];
    [fancyText parseStructure];
    count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 2, @"expecting 2 children but seeing %d", count);
    node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"green"] objectAtIndex:0] children] objectAtIndex:0];
    color = [node.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor greenColor], @"class green's text color is %@", color);
    node = [[[[fancyText.parsedResultTree childrenNodesWithClassName:@"yellow"] objectAtIndex:0] children] objectAtIndex:0];
    color = [node.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"class yellow's text color is %@", color);
    GSRelease(fancyText);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">c</p><span class='blue' id=2>e</span>"];
    [fancyText parseStructure];
    node = [[[fancyText.parsedResultTree childNodeWithID:@"1"] children] objectAtIndex:0];
    color = [node.data objectForKey:GSFancyTextColorKey];
    UIColor* white = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    STAssertEqualObjects(color, white, @"color is %@ but we expect white", color);
    node = [[[fancyText.parsedResultTree childNodeWithID:@"2"] children] objectAtIndex:0];
    color = [node.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor blueColor], @"class blue's text color is %@", color);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"yellow>c</p><p class='green'>e</p>"];
    [fancyText parseStructure];
    count = fancyText.parsedResultTree.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=green><ufo class=yellow id=1>c</ufo><span class='green'>e</span></p>"];
    [fancyText parseStructure];
    node = [fancyText.parsedResultTree childNodeWithID:@"1"];
    node = [node.children objectAtIndex:0];
    NSString* text = [node.data objectForKey:GSFancyTextTextKey];
    STAssertEqualObjects(text, @"c", @"text inside special tag parsing error: %@", text);
    color = [node.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"color inside special tag parsing error: %@", color);
}

- (void)testLineBreak {
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:@"<span class=green>Span 1</span><span>Span 2</span>"];
    fancyText.width = 1000.f;
    [fancyText generateLines];
    int count = fancyText.lines.count;
    STAssertEquals(count, 1, @"expecting 1 line but seeing %d", count);
    GSRelease(fancyText);

    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=green>1 <span>s</span></p>2<p>3</p>"];
    fancyText.width = 1000.f;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 3, @"expecting 3 lines but seeing %d", count);
    GSRelease(fancyText);
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=green>Here is a long long long line.<span>s</span></p>2<p>3</p>"];
    fancyText.width = [@"Here is a long long" sizeWithFont:[UIFont systemFontOfSize:14.f]].width;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 4, @"expecting 4 lines but seeing %d", count);
    GSRelease(fancyText);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=limit2>Here is a long long long long long long long long long long long long line.<span>s</span></p>2<p>3</p>"];
    fancyText.width = [@"Here is a" sizeWithFont:[UIFont systemFontOfSize:14.f]].width;
    [fancyText generateLines];
    count = fancyText.lines.count;
    STAssertEquals(count, 4, @"expecting 3 lines but seeing %d", count);
    GSRelease(fancyText);
}

- (void)testContentChange {
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span></p> <p> L2 </p>"];
    [fancyText parseStructure];    
    [fancyText changeNodeToText:@"Blah" forID:@"1"];
    GSMarkupNode* changedNode = [fancyText.parsedResultTree childNodeWithID:@"1"];
    int count = changedNode.children.count;
    STAssertEquals(count, 1, @"expecting 1 child but seeing %d", count);
    GSMarkupNode* child = [changedNode.children objectAtIndex:0];
    NSString* text = [child.data objectForKey:GSFancyTextTextKey];
    STAssertEqualObjects(text, @"Blah", @"text change failed. It's %@", text);
    GSRelease(fancyText);
    
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span> <lambda id=L></p> <p> L2 </p>"];
    [fancyText parseStructure];
    [fancyText changeNodeToStyledText:@"<strong>B</strong>lah" forID:@"1"];
    changedNode = [fancyText.parsedResultTree childNodeWithID:@"1"];
    count = changedNode.children.count;
    STAssertEquals(count, 1, @"expecting 2 children but seeing %d", count);
    GSMarkupNode* newRoot = [changedNode.children objectAtIndex:0];
    STAssertEquals(newRoot.isContainer, YES, @"styled text change failed.");
    STAssertTrue(newRoot.children.count == 2, @"inserted tree children count wrong: %d", newRoot.children.count);
    child = [newRoot.children objectAtIndex:0];
    STAssertEquals(child.isContainer, YES, @"styled text change failed.");
    child = [child.children objectAtIndex:0];
    text = [child.data objectForKey:GSFancyTextTextKey];
    STAssertEqualObjects(text, @"B", @"styled text change failed. It's %@", text);
    GSRelease(fancyText);
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"blue\" id=\"1\">1 and something else like <span class='blue' id=2>e</span> <lambda id=L></p> <p> L2 </p>"];
    [fancyText parseStructure];
    GSMarkupNode* id1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    count = id1.children.count;
    [fancyText appendStyledText:@"<strong>B</strong>lah" toID:@"1"];
    STAssertTrue(id1.children.count == count + 1, @"appending node didn't give the right count");
    newRoot = [changedNode.children lastObject]; // getting the new root
    child = [newRoot.children lastObject];
    text = [child.data objectForKey:GSFancyTextTextKey];
    STAssertEqualObjects(text, @"lah", @"styled text change failed. It's %@", text);
    GSRelease(fancyText);
    
    fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p id=1 class=right>Real right. Fake <span id=2 class=center>center</span></p>"];
    [fancyText parseStructure];
    id1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    GSMarkupNode* id2 = [fancyText.parsedResultTree childNodeWithID:@"2"];
    GSMarkupNode* node = [id1.children objectAtIndex:0];
    GSTextAlign align = [[node.data objectForKey:GSFancyTextTextAlignKey] intValue];
    STAssertTrue(align==GSTextAlignRight, @"p align incorrect:%d", align);
    node = [id2.children objectAtIndex:0];
    align = [[node.data objectForKey:GSFancyTextTextAlignKey] intValue];
    STAssertTrue(align==GSTextAlignRight, @"span align incorrect:%d", align);
}


- (void)testStyleChange {
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:@"<p class=\"green\" id=\"1\">1 and something else like <span class='blue' id=2>e</span></p> <p> L2 </p>"];
    [fancyText parseStructure];    
    [fancyText applyClass:@"yellow" on:GSFancyTextID withName:@"1"];
    GSMarkupNode* node1 = [fancyText.parsedResultTree childNodeWithID:@"1"];
    GSMarkupNode* node2 = [fancyText.parsedResultTree childNodeWithID:@"2"];
    UIColor* color = [node1.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor yellowColor], @"color apply failed. color is %@", color);
    color = [node2.data objectForKey:GSFancyTextColorKey];
    STAssertEqualObjects(color, [UIColor blueColor], @"color protection failed. color is %@", color);
    NSString* fontStyle = [node1.data objectForKey:GSFancyTextFontStyleKey];
    STAssertEqualObjects(fontStyle, @"italic", @"font style retain failed. style is %@", fontStyle);
    
    [fancyText changeStylesToClass:@"yellow" on:GSFancyTextID withName:@"1"];
    fontStyle = [node1.data objectForKey:GSFancyTextFontStyleKey];
    STAssertNil(fontStyle, @"italic", @"font style remove failed. style is %@", fontStyle);
    
    GSRelease(fancyText);
}

- (void)testPureText {
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:@"<span>Hello</span>! <a>How</a> <dog>are</dog> you doing? <lambda id=x alt='Read me if you can'>"];
    [fancyText parseStructure];
    NSString* pureText = [fancyText pureText];
    STAssertEqualObjects(pureText, @"Hello! How are you doing? Read me if you can", @"wrong pure text: %@", pureText);
}


- (void)compareLineBreak:(NSString*)markup leftMargin:(CGFloat)leftMargin rightMargin:(CGFloat)rightMargin fullWidth:(CGFloat)fullWidth {
    
    GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText:markup];
    NSString* marginClass = [NSString stringWithFormat:@".margin {margin-left: %f; margin-right:%f;}", leftMargin, rightMargin];
    
    [fancyText appendStyleSheet:marginClass];
    fancyText.width = fullWidth;
    [fancyText generateLines];
    int count = [fancyText lines].count;
    
    
    GSFancyText* refFancyText = [[GSFancyText alloc] initWithMarkupText:markup];
    marginClass = @".margin {color:red}";
    [fancyText appendStyleSheet:marginClass];
    refFancyText.width = fullWidth - leftMargin - rightMargin;
    [refFancyText generateLines];
    NSArray* refLines = [refFancyText lines];
    int refCount = refLines.count;
    
    STAssertTrue(count==refCount, @"should be %d but it is %d", refCount, count);
    for (int i=0; i< fancyText.lines.count; i++) {
        NSArray* line = [fancyText.lines objectAtIndex:i];
        NSArray* refLine = [refFancyText.lines objectAtIndex:i];
        STAssertTrue(line.count==refLine.count, @"line %d: should be %d but it is %d", i, refLine.count, line.count);
        for (int j=0; j< line.count; j++) {
            NSString* text = [[line objectAtIndex:j] objectForKey:GSFancyTextTextKey];
            NSString* refText = [[refLine objectAtIndex:j] objectForKey:GSFancyTextTextKey];
            STAssertEqualObjects(text, refText, @"line %d: should be %@ but it's %@", refText, text);
        }
    }
    
    GSRelease(fancyText);
    GSRelease(refFancyText);
}

- (void)testLineBreakWithMargin {
    NSString* markup_ = @"<p class=margin>This is a very quite exceptionally tremendously hugely intensely terribly truly really darned way dead long paragraph with some margins <span id=2>and some spans and spams</span></p>";

    [self compareLineBreak:markup_ leftMargin:10 rightMargin:10 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:0 rightMargin:0 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:100 rightMargin:100 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:0 rightMargin:250 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:250 rightMargin:0 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:500 rightMargin:400 fullWidth:1000];
    [self compareLineBreak:markup_ leftMargin:300 rightMargin:300 fullWidth:1000];
    
    markup_ = @"<p class=margin><span>short</span> <span>span</span> <span>s</span><span>h</span><span>o</span><span>r</span><span>t</span>. Next <span>line</span>. Many<span> spans </span>. <span>many</span> <span>many</span><span> many</span>\n Multile <span>line</span> after using slash N. Many lines.\nLine 2\nLine 3</p>";
    
    [self compareLineBreak:markup_ leftMargin:10 rightMargin:10 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:0 rightMargin:0 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:100 rightMargin:100 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:0 rightMargin:250 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:250 rightMargin:0 fullWidth:300];
    [self compareLineBreak:markup_ leftMargin:500 rightMargin:400 fullWidth:1000];
    [self compareLineBreak:markup_ leftMargin:300 rightMargin:300 fullWidth:1000];
}


@end
