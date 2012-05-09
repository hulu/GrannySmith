//
//  GSMarkupNode.m
//  -GrannySmith-
//
//  Created by Bao Lei on 1/4/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#import "GSMarkupNode.h"
#import "GSFancyText.h"

@implementation GSMarkupNode

@synthesize children = children_;
@synthesize data = data_;
@synthesize parent = parent_;

@synthesize isContainer = isContainer_;
@synthesize classesMap = classesMap_;
@synthesize IDMap = IDMap_;

- (id)init {
    if (( self = [super init])) {
        data_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
        children_ = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
        parent_ = nil;
        isContainer_ = NO;
        IDMap_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
        classesMap_ = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
    }
    return self;
}

#ifdef GS_ARC_ENABLED
#else
- (void)dealloc {
    GSRelease(children_);
    GSRelease(IDMap_);
    GSRelease(classesMap_);
    GSRelease(data_);
    [super dealloc];
}
#endif

- (void)appendChild:(GSMarkupNode*)node {
    [children_ addObject:node];
    node.parent = self;
}

- (void)appendSubtree:(GSMarkupNode*)subtreeRoot underNode:(GSMarkupNode*)node {
    [node appendChild:subtreeRoot];
    
    // upstream: the ID, class hashmap
    [self.IDMap setValuesForKeysWithDictionary:subtreeRoot.IDMap];

    for (NSString* className in [subtreeRoot.classesMap allKeys]) {
        NSArray* objects = [subtreeRoot.classesMap objectForKey:className];
        for (GSMarkupNode* object in objects) {
            [GSFancyText addObject:object intoDict:self.classesMap underKey:className];
        }
    }
    
    // downstream: the styles
    // first prepare the styles to be applied, bottom up
    NSMutableDictionary* stylesToPassDown = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];

    GSMarkupNode* styleGroup = node;
    while (styleGroup) {
        
        for (id key in [styleGroup.data allKeys]) {
            id value = [styleGroup.data objectForKey: key];
            if (value && ![stylesToPassDown objectForKey:key]) {
                // set only when it wasn't set before. because lower level has higher priority
                [stylesToPassDown setObject: value forKey:key];
            }
        }
        
        styleGroup = [styleGroup parent];
    }
    
    // do something to let the new subtree have the styles
    [subtreeRoot applyAndSpreadStyles:stylesToPassDown removeOldStyles:NO];
    
    GSRelease(stylesToPassDown);
}


- (NSString*)displayTree {
    
    NSMutableString* tree = [[NSMutableString alloc] init];
    
    NSMutableArray* stack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    NSMutableArray* indentStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    [stack addObject:self];
    [indentStack addObject:[NSNumber numberWithInt:0]];
    
    while ([stack count]) {
        GSMarkupNode* node = [stack lastObject];
        [stack removeLastObject];
        int indent = [[indentStack lastObject] intValue];
        [indentStack removeLastObject];
        
        for (int i=0; i<indent; i++) {
            [tree appendString:@"  "];
        }
        NSString* text = [node.data objectForKey:GSFancyTextTextKey];
        NSString* lid = [node.data objectForKey:GSFancyTextInternalLambdaIDKey];
        [tree appendString: text? text : (lid? [NSString stringWithFormat:@"lambda %@",lid] : @"*")];
        if (node.isContainer) {
            [tree appendFormat:@" (%p)", node];
        }
        [tree appendString:@"\n"];
        
        for (int i=node.children.count-1; i>=0; i--) {
            GSMarkupNode* child = [node.children objectAtIndex:i];
            [stack addObject: child];
            [indentStack addObject: [NSNumber numberWithInt:(indent+1)]];
        }
    }
    
    GSRelease(stack);
    GSRelease(indentStack);
    
    // also list the id, class map
    for (id key in [self.IDMap allKeys]) {
        [tree appendFormat:@"id %@ : %p\n", key, [self.IDMap objectForKey:key]];
    }
    
    for (NSString* key in [self.classesMap allKeys]) {
        [tree appendFormat:@"class %@ : ", key];
        NSArray* nodes = [self.classesMap objectForKey:key];
        for (GSMarkupNode* node in nodes) {
            [tree appendFormat:@"%p ", node];
        }
        [tree appendFormat:@"\n"];
    }
    
    return GSAutoreleased(tree);
}

- (NSArray*)newDepthFirstOrderDataArray {
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    NSMutableArray* stack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    [stack addObject:self];
    
    while ([stack count]) {
        GSMarkupNode* node = [stack lastObject];
        [stack removeLastObject];
        
        if (!node.isContainer) {
            [array addObject:node.data];
        }
        for (int i=node.children.count-1; i>=0; i--) {
            GSMarkupNode* child = [node.children objectAtIndex:i];
            [stack addObject: child];
        }
    }
    GSRelease(stack);
    return array;
}

- (GSMarkupNode*)childNodeWithID:(NSString*)nodeID {
    GSMarkupNode* node = [self.IDMap objectForKey:nodeID];
    if (!node && [nodeID caseInsensitiveCompare:GSFancyTextRootID]==NSOrderedSame) {
        node = self;
    }
    return node;
}

- (NSArray*)childrenNodesWithClassName:(NSString*)className {
    return [self.classesMap objectForKey:className];
}


- (GSMarkupNode*)firstChild {
    if (self.isContainer && self.children.count) {
        return [self.children objectAtIndex:0];
    }
    else {
        return nil;
    }
}

- (id)copy {
    
    GSMarkupNode* newGuy = [[GSMarkupNode alloc] init];

    // new hashmaps for the newGuy (since it's copying, the address will be different, so the map should point to something different)
    NSMutableDictionary* idMap = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];  // id must be unique, so the value is just an GSMarkupNode pointer
    NSMutableDictionary* classesMap = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize]; // classes won't be unique, so the value is an array
    
    
    NSMutableArray* oldTreeStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    NSMutableArray* newTreeStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    
    [oldTreeStack addObject:self];
    [newTreeStack addObject:newGuy];
    
    while ([oldTreeStack count]) {
        GSMarkupNode* nodeInOldTree = [oldTreeStack lastObject];
        [oldTreeStack removeLastObject];
        
        GSMarkupNode* nodeInNewTree = [newTreeStack lastObject];
        [newTreeStack removeLastObject];
        
        // copy dictionary data
        [nodeInNewTree.data setValuesForKeysWithDictionary:nodeInOldTree.data];
        nodeInNewTree.isContainer = nodeInOldTree.isContainer;
        
        // then we have to manually update the hashmaps, based on the new tree node address
        if (nodeInNewTree.isContainer) {
            NSString* tagID = [nodeInNewTree.data objectForKey: GSFancyTextIDKey];
            if (tagID) {
                [idMap setObject:nodeInNewTree forKey:tagID];
            }
            NSArray* tagClassNames = [nodeInNewTree.data objectForKey: GSFancyTextClassKey];
            if (tagClassNames) {
                for (NSString* className in tagClassNames) {
                    [GSFancyText addObject:nodeInNewTree intoDict:classesMap underKey:className];
                }
            }
        }
        NSString* lambdaID = [nodeInNewTree.data objectForKey: GSFancyTextInternalLambdaIDKey];
        if (lambdaID) {
            [idMap setObject:nodeInNewTree forKey:lambdaID];
        }
        
        // create enough children for the new node
        for (int i=0; i<nodeInOldTree.children.count; i++) {
            GSMarkupNode* childForNewTree = [[GSMarkupNode alloc] init];
            [nodeInNewTree appendChild: childForNewTree]; // declare child relation
            GSRelease(childForNewTree);
        }
        
        for (int i=nodeInOldTree.children.count-1; i>=0; i--) {
            GSMarkupNode* childInOldTree = [nodeInOldTree.children objectAtIndex:i];
            [oldTreeStack addObject: childInOldTree];
            
            GSMarkupNode* childInNewTree = [nodeInNewTree.children objectAtIndex:i];
            [newTreeStack addObject: childInNewTree];
        }
    }
    
    GSRelease(oldTreeStack);
    GSRelease(newTreeStack);
    
    newGuy.IDMap = idMap;
    newGuy.classesMap = classesMap;
    
    GSRelease(idMap);
    GSRelease(classesMap);
    
    return newGuy;
}

#pragma mark - Modification

- (void)cutFromParent {
    [self.parent.children removeObject: self];
    self.parent = nil;
}

- (void)dismissAllChildren {
    for (GSMarkupNode* child in self.children) {
        child.parent = nil;
    }
    [self.children removeAllObjects];
}

- (void)resetChildToText:(NSString*)text {
    // for performance considerations, we do this in this way:
    // 1. if there is a text node under this node, we just replace the text of that node, and remove all other nodes. E.g. <span>xyz<span>12</span><span>34</span></span>, just replace the xyz and cut 12, 34
    // 2. otherwise, remove all text children (lambda not included) and add the text node. E.g. <span><span>1</span><span>2</span></span>
    
    if (!text) {
        return;
    }
    BOOL found = NO;
    if (self.children.count > 0) {
        for (int i=self.children.count-1; i>=0; i--) {
            GSMarkupNode* child = [self.children objectAtIndex:i];
            if (!found && [child.data objectForKey:GSFancyTextTextKey] && !child.children.count) {
                [child.data setObject:text forKey:GSFancyTextTextKey];
                // just change the text and leave other styles
                found = YES;
            }
            else {
                if (![[child.data allKeys] containsObject:GSFancyTextInternalLambdaIDKey]) {
                    [child cutFromParent];
                }
            }
        }
    }
    if (!found) {
        GSMarkupNode* newChild = [[GSMarkupNode alloc] init];
        NSMutableArray* ancestorArray = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
        GSMarkupNode* ancestor = self;
        while (ancestor) {
            [ancestorArray addObject:ancestor];
            ancestor = ancestor.parent;
        }
        for (int i=ancestorArray.count-1; i>=0; i--) {
            ancestor = [ancestorArray objectAtIndex:i];
            [newChild.data setValuesForKeysWithDictionary:ancestor.data];
        }
        [newChild.data setObject:text forKey:GSFancyTextTextKey];
        [GSFancyText createFontKeyForDict:newChild.data];
        [self appendChild:newChild];
        GSRelease(newChild);
        GSRelease(ancestorArray);
    }
}

- (void)applyAndSpreadStyles:(NSMutableDictionary*)styles removeOldStyles:(BOOL)removeOldStyles; {
    NSMutableArray* stylesToRemove;
    
    // first apply the changes to the root node
    if (removeOldStyles) {
        stylesToRemove = [[NSMutableArray alloc] initWithCapacity:[self.data allKeys].count];
        for (NSString* key in [self.data allKeys]) {
            [self.data removeObjectForKey:key];
            [stylesToRemove addObject:key];
        }
    }
    [self.data setValuesForKeysWithDictionary:styles];
    
    // a DFS traversal to apply the styles to children and grandchildren etc
    // but a class node will block the penetration
    
    NSMutableArray* stack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    NSMutableArray* styleStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
    NSMutableArray* stylesToRemoveStack;
    
    [stack addObject:self];
    [styleStack addObject:styles];
    
    if (removeOldStyles) {
        stylesToRemoveStack = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
        [stylesToRemoveStack addObject: stylesToRemove];
        GSAutorelease(stylesToRemove); // can only autorelease because we need to use this object after popping it out of the stack
        
        if (!stylesToRemove.count) {
            removeOldStyles = NO; // if there's nothing necessary to remove, just don't bother checking every time
            GSRelease(stylesToRemoveStack);
        }
    }
    
    while ([stack count]) {
        GSMarkupNode* node = [stack lastObject];
        [stack removeLastObject];
        
        NSMutableDictionary* stylesForThisNode = [styleStack lastObject];
        [styleStack removeLastObject];
        
        NSMutableArray* stylesToRemoveForThisNode;
        if (removeOldStyles) {
            stylesToRemoveForThisNode = [stylesToRemoveStack lastObject];
            [stylesToRemoveStack removeLastObject];
        }
        
        if (!node.children.count) {
            // don't apply styles to class nodes
            // just apply to leaf nodes (text segments)
            
            if (removeOldStyles) {
                for (id key in stylesToRemoveForThisNode) {
                    [node.data removeObjectForKey:key];
                }
            }
            
            [node.data setValuesForKeysWithDictionary:stylesForThisNode];
            [GSFancyText createFontKeyForDict:node.data];
        }
        
        for (int i=node.children.count-1; i>=0; i--) {
            GSMarkupNode* child = [node.children objectAtIndex:i];

            NSMutableDictionary* stylesForTheChild = [[NSMutableDictionary alloc] initWithCapacity:GSFancyTextTypicalSize];
            NSMutableArray* stylesToRemoveForChild;
            
            if (removeOldStyles) {
                stylesToRemoveForChild = [[NSMutableArray alloc] initWithCapacity:GSFancyTextTypicalSize];
            }
            
            if (!child.children.count) {
                // if it's a leaf node,  pass all styles
                [stylesForTheChild setValuesForKeysWithDictionary:stylesForThisNode];
                
                if (removeOldStyles) {
                    [stylesToRemoveForChild addObjectsFromArray:stylesToRemoveForThisNode];
                }
            }
            else {
                // if it's a class node, just pass the styles not overriden by the class
                for (id key in [stylesForThisNode allKeys]) {
                    if (! [child.data objectForKey:key]) {
                        [stylesForTheChild setObject:[stylesForThisNode objectForKey:key] forKey:key];
                    }
                }
                if (removeOldStyles) {
                    for (id key in stylesToRemoveForThisNode) {
                        if (! [child.data objectForKey:key]) {
                            [stylesToRemoveForChild addObject:key];
                        }
                    }
                }
            }
            
            if ([stylesForTheChild allKeys].count || (removeOldStyles && stylesToRemoveForChild.count)) {
                [stack addObject: child];
                [styleStack addObject: stylesForTheChild];
                if (removeOldStyles) {
                    [stylesToRemoveStack addObject:stylesToRemoveForChild];
                }
            }
            
            // has to be auto released because later we need to pop the stylesForTheChild out of stack and use it. so can't release here
            GSAutorelease(stylesForTheChild);
            if (removeOldStyles) {
                GSAutorelease(stylesToRemoveForChild);
            }
        }
    }
    if (removeOldStyles) {
        GSRelease(stylesToRemoveStack);
    }
    GSRelease(stack);
    GSRelease(styleStack);
}

@end