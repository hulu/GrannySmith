//
//  GSMarkupNodeTest.m
//  GSFancyTextTest
//
//  Created by Bao Lei on 1/10/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
#import "GSFancyTextDefines.h"
#import "GSFancyText.h"

@interface GSMarkupNodeTest : SenTestCase {
    GSMarkupNode* testMarkupNode_;
}

@end

@implementation GSMarkupNodeTest

- (void)setUp {
    NSString* markupText = @"0 <p id=1 class=1>1 <p id=2 class=2>2</p> <p id=3 class=2>3</p> <p id=4><span id=5 class=5>5</span></p></p> 6";
    testMarkupNode_ = [GSFancyText newParsedMarkupString:markupText withStyleDict:nil];
}

- (void)tearDown {
    GSRelease(testMarkupNode_);
}

- (void)testMarkupNodeChildren {
    NSArray* rootChildren = [testMarkupNode_ children];
    STAssertTrue(rootChildren.count == 3, @"Root should have 3 kids, but we found %d", rootChildren.count);
    
    for (GSMarkupNode* child in rootChildren) {
        STAssertTrue(child.parent == testMarkupNode_, @"parent of a root's child isn't pointing back to the root");
    }
}

- (void)testIsContainer {
    NSArray* rootChildren = [testMarkupNode_ children];
    GSMarkupNode* child;
    
    child = [rootChildren objectAtIndex:0];
    STAssertTrue(child.isContainer == NO, @"The 1st child of root is supposed to be content but it's not");
    
    child = [rootChildren objectAtIndex:1];
    STAssertTrue(child.isContainer == YES, @"The 2nd child of root is supposed to be container but it's not");
    STAssertTrue([[child.children objectAtIndex:0] isContainer] == NO, @"The 1st grandchild of root is supposed to be content but it's not");
    
    child = [rootChildren objectAtIndex:2];
    STAssertTrue(child.isContainer == NO, @"The 3rd child of root is supposed to be content but it's not");
}

- (void)testMarkupNodeClassMap {
    NSArray* class2 = [testMarkupNode_ childrenNodesWithClassName:@"2"];
    STAssertTrue(class2.count == 2, @"Class 2 should have 2 nodes, but we found %d", class2.count);
    
    NSArray* class5 = [testMarkupNode_ childrenNodesWithClassName:@"5"];
    STAssertTrue(class5.count == 1, @"Class 5 should have 1 nodes, but we found %d", class2.count);
}


- (void)testMarkupNodeIDMap {
    GSMarkupNode* idRoot = [testMarkupNode_ childNodeWithID:GSFancyTextRootID];
    STAssertTrue(idRoot == testMarkupNode_, @"We are supposed to get root by ID root but we didn't");
    
    GSMarkupNode* id3 = [testMarkupNode_ childNodeWithID:@"3"];
    NSString* id3class = [[id3.data objectForKey:@"class"] objectAtIndex:0];
    STAssertTrue([id3class isEqualToString:@"2"], @"id3's class should be 2, but it's %@", [id3.data objectForKey:@"class"]);
    
    GSMarkupNode* id5 = [testMarkupNode_ childNodeWithID:@"5"];
    GSMarkupNode* traceUp = id5;
    for(int i=0; i<3; i++) {
        traceUp = traceUp.parent;
    }
    STAssertTrue(traceUp == testMarkupNode_, @"id5 should be 3 levels below root, but it's not");
}

- (void)testAppendNode {
    GSMarkupNode* hostingNode = [testMarkupNode_ childNodeWithID:@"4"];
    int originalCount = hostingNode.children.count;
    GSMarkupNode* newNode = [GSFancyText parsedMarkupString:@"I'm new <span id=7>1234567</span>" withStyleDict:nil];
    [testMarkupNode_ appendSubtree:newNode underNode:hostingNode];
    STAssertTrue(hostingNode.children.count == originalCount + 1, @"before adding:%d, after adding 1: %d", originalCount, hostingNode.children.count);
    STAssertTrue(newNode.parent == hostingNode, @"after adding, parent of the child is not correctly set");
    
    // search new child from root
    GSMarkupNode* firstChildOfNewNode = [[[testMarkupNode_ childNodeWithID:@"7"] children] objectAtIndex:0];
    STAssertTrue([[firstChildOfNewNode.data objectForKey:GSFancyTextTextKey] isEqualToString:@"1234567"]==YES, @"Searching new children has some issue. We found %@", [firstChildOfNewNode.data objectForKey:GSFancyTextTextKey]);
}

- (void)testCut {
    int originalCount = testMarkupNode_.children.count;
    
    [[testMarkupNode_.children lastObject] cutFromParent];
    STAssertTrue(testMarkupNode_.children.count == originalCount - 1, @"before cutting:%d, after cutting 1: %d", originalCount, testMarkupNode_.children.count);
}

- (void)testChildrenRemoval {
    [testMarkupNode_ dismissAllChildren];
    STAssertTrue(testMarkupNode_.children.count == 0, @"after dismissing all, there are still: %d", testMarkupNode_.children.count);
}

- (void)testReplaceText {
    GSMarkupNode* testNode = [testMarkupNode_ childNodeWithID:@"4"];
    [testNode resetChildToText:@"Hello"];
    STAssertTrue(testNode.children.count == 1, @"we are expecting one text child but we see %d", testNode.children.count);
    
    GSMarkupNode* textNode = [testNode.children lastObject];
    NSString* newText = [textNode.data objectForKey:GSFancyTextTextKey];
    STAssertTrue([newText isEqualToString:@"Hello"], @"we set Hello but get %@", newText);
    
    GSMarkupNode* lambdaNode = [GSFancyText parsedMarkupString:@"<span id=9>xyz<lambda id=10></span>" withStyleDict:nil];
    [testMarkupNode_ appendSubtree:lambdaNode underNode:testNode];
    testNode = [testMarkupNode_ childNodeWithID:@"9"];
    [testNode resetChildToText:@"123"];
    STAssertTrue(testNode.children.count == 2, @"we are expecting 2 children but we see %d", testNode.children.count);
    textNode = [testNode.children objectAtIndex:0];
    STAssertTrue([[textNode.data objectForKey:GSFancyTextTextKey] isEqualToString:@"123"], @"we set Hello but get %@", newText);
}

- (void)testApplyStyle {
    GSMarkupNode* id1 = [testMarkupNode_ childNodeWithID:@"1"];
    GSMarkupNode* id2 = [testMarkupNode_ childNodeWithID:@"2"];
    GSMarkupNode* id1Kid = [id1.children objectAtIndex:0];
    GSMarkupNode* id2Kid = [id2.children objectAtIndex:0];
    GSMarkupNode* rootKid = [testMarkupNode_.children objectAtIndex:0];
    
    NSMutableDictionary* style = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"white", @"color", nil];
    [testMarkupNode_ applyAndSpreadStyles:style removeOldStyles:NO];
    STAssertTrue([[id1Kid.data objectForKey:@"color"] isEqualToString:@"white"], @"id1 color: %@ (white expected)", [id1Kid.data objectForKey:@"color"]);
    STAssertTrue([[id2Kid.data objectForKey:@"color"] isEqualToString:@"white"], @"id2 color: %@ (white expected)", [id2Kid.data objectForKey:@"color"]);
    STAssertTrue([[rootKid.data objectForKey:@"color"] isEqualToString:@"white"], @"root color: %@ (white expected)", [rootKid.data objectForKey:@"color"]);
    
    style = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"red", @"color", @"light", @"weight", nil];
    [id1 applyAndSpreadStyles:style removeOldStyles:NO];
    [id2 applyAndSpreadStyles:style removeOldStyles:NO]; // id2 will be blocking color and weight
    // since id1 doesn't have a color key to block the red invasion
    STAssertTrue([[id1Kid.data objectForKey:@"color"] isEqualToString:@"red"], @"id1 color: %@ (red expected)", [id1Kid.data objectForKey:@"color"]);
    STAssertTrue([[id2Kid.data objectForKey:@"color"] isEqualToString:@"red"], @"id2 color: %@ (red expected)", [id2Kid.data objectForKey:@"color"]);
    STAssertTrue([[rootKid.data objectForKey:@"color"] isEqualToString:@"white"], @"root color: %@ (white expected)", [rootKid.data objectForKey:@"color"]);
    STAssertTrue([[id1Kid.data objectForKey:@"weight"] isEqualToString:@"light"], @"id1 weight: %@ (light expected)", [id1Kid.data objectForKey:@"weight"]);
    STAssertTrue([[id2Kid.data objectForKey:@"weight"] isEqualToString:@"light"], @"id2 weight: %@ (light expected)", [id2Kid.data objectForKey:@"weight"]);
    
    style = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"blue", @"color", nil];
    [id1 applyAndSpreadStyles:style removeOldStyles:NO];
    STAssertTrue([[id1Kid.data objectForKey:@"color"] isEqualToString:@"blue"], @"id1 color: %@ (red expected)", [id1Kid.data objectForKey:@"color"]);
    STAssertTrue([[id2Kid.data objectForKey:@"color"] isEqualToString:@"red"], @"id2 color: %@ (red expected)", [id2Kid.data objectForKey:@"color"]);
    STAssertTrue([[id1Kid.data objectForKey:@"weight"] isEqualToString:@"light"], @"id1 weight: %@ (light expected)", [id1Kid.data objectForKey:@"weight"]);
    STAssertTrue([[id2Kid.data objectForKey:@"weight"] isEqualToString:@"light"], @"id2 weight: %@ (light expected)", [id2Kid.data objectForKey:@"weight"]);
    
    style = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"yellow", @"color", nil];
    [id1 applyAndSpreadStyles:style removeOldStyles:YES];
    STAssertTrue([[id1Kid.data objectForKey:@"color"] isEqualToString:@"yellow"], @"id1 color: %@ (red expected)", [id1Kid.data objectForKey:@"color"]);
    STAssertTrue([[id2Kid.data objectForKey:@"color"] isEqualToString:@"red"], @"id2 color: %@ (red expected)", [id2Kid.data objectForKey:@"color"]);
    STAssertNil([id1Kid.data objectForKey:@"weight"], @"id1 weight: %@ (nil expected)", [id1Kid.data objectForKey:@"weight"]);
    STAssertTrue([[id2Kid.data objectForKey:@"weight"] isEqualToString:@"light"], @"id2 weight: %@ (light expected)", [id2Kid.data objectForKey:@"weight"]);
}

- (void)testDeepCopy {
    GSMarkupNode* copied = [testMarkupNode_ copy];
    int originalCount = copied.children.count;
    [testMarkupNode_ dismissAllChildren];
    STAssertTrue(copied.children.count == originalCount, @"shallow copy");
    
    GSMarkupNode* newID5 = [copied childNodeWithID:@"5"];
    GSMarkupNode* traceUp = newID5;
    while(traceUp.parent != nil) {
        traceUp = traceUp.parent;
    }
    STAssertTrue(traceUp == copied, @"new parent/ID hash relation was not correct");
    GSRelease(copied);
}

@end