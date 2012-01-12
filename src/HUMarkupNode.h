//
//  HUMarkupNode.h
//  -HUSFT-
//
//  Created by Bao Lei on 1/4/12.
//  Copyright (c) 2012 Hulu. All rights reserved.
//

/// It's a tree node, and it's also a mutable dictionary

#import <Foundation/Foundation.h>

#import "HUFancyTextDefines.h"

@interface HUMarkupNode : NSObject {

    NSMutableDictionary* data_;
    NSMutableArray* children_;

    BOOL isContainer_;
    NSMutableDictionary* IDMap_;
    NSMutableDictionary* classesMap_;
    
    HUWeakPrefix HUMarkupNode* parent_;
}

/** the data of the node.
 * @discussion The data dictionary stores everything that is unrelated to the tree structure
 * Including the text, lambda ID, all styles. This makes it easy to copy and debug a node, and easy to pass bulk information among nodes
 */
@property (nonatomic, retain) NSMutableDictionary* data;

/** the children array. each object is an HUMarkupNode object
 * @note for a child-less leaf the children array is an empty array, instead of nil
 */
@property (nonatomic, retain) NSMutableArray* children;

/** Denoting if this node a container node. The root is always a container. A content node (lambda/text) isn't a container.
 */
@property (nonatomic, assign) BOOL isContainer;

/** A hash map for finding nodes with certain IDs
 */
@property (nonatomic, retain) NSMutableDictionary* IDMap;

/** A hash map for finding nodes with certain classes
 */
@property (nonatomic, retain) NSMutableDictionary* classesMap;

/** the parent node. Used for tracing back all the styles applied to this node.
 * @note If ARC is not enabled, it's __unsafe__unretained in order to avoid retain cycle, so use with caution.
 */
@property (nonatomic, HUWeak) HUMarkupNode* parent;

/** append a node into the children array
 * @note this also sets the parent of the child node
 * @warning it only establishes child/parent relationship, but doesn't pass styles and hashmaps. So it's mainly used during construction stage.
 */
- (void)appendChild:(HUMarkupNode*)node;


/** add subtree under a child node of this tree, and add the map info in subtree root into the root of this tree (assuming it's this node)
 * @note call this method only on the root node, and make sure that node is an offsprint under this node
 * @warning if the subtree has a conflicting ID with the original tree, the ID will refer to the one in the new subtree
 */
- (void)appendSubtree:(HUMarkupNode*)subtreeRoot underNode:(HUMarkupNode*)node;


/** display the information of the tree starting from this node, nonrecursively
 * @note for debug use
 */
- (NSString*)displayTree;

/** create an array with the content node data in this tree in depth first order (natural markup string order)
 * @return an array of dictionaries, each dictionary is the data of a content node
 * @example a tree based on "a <span>B<em>C</em> D </span>" will give an array of [a, B, C, D] (styles included)
 * @note only content nodes are exported. Container nodes are not. This makes output lighterweight.
 * @note only data (dictionary) is stored in the array because you don't need tree information (children, parent) when it's flattened
 * @note new means that you own it (it's not autoreleased, and you have to release it upon finishing, if it's not ARC)
 */
- (NSArray*)newDepthFirstOrderDataArray;


///-------------------------------
/// @name ID/Class access
///-------------------------------

/** Get the tree node under this node that has the given nodeID
 * @return the right node. If no node is found by the ID or the method is called on a non-root node, return Nil
 * @note this method must be called on a root node, where ID hashmap is stored
 * @note you can can use @"root" (HUFancyTextRootID) to refer to the root of the tree (this node)
 */
- (HUMarkupNode*)childNodeWithID:(NSString*)nodeID;

/** Get all the tree nodes under this node that has the given class name
 * @note this method must be called on a root node, where class hashmap is stored
 * @return an array with the right nodes. If no node is found by the ID or the method is called on a non-root node, return Nil
 */
- (NSArray*)childrenNodesWithClassName:(NSString*)className;


///-------------------------------
/// @name Modification
///-------------------------------

/** Cut this node from parent
 */
- (void)cutFromParent;

/** Dismiss all children of this node
 * @discussion from user's point of view, this method has similar effect with cutFromParent, but if we call this one, later we still have a chance to add children into this node. cutFromParent is more thorough.
 */
- (void)dismissAllChildren;

/** Reset the text under this node
 * @warning if there's any subtree under this node, it will be removed. After this call there will be only one text child note, plus the lambda nodes
 * @example in this tree "<span id=1>ABC<span class=xxx>XXX</span></span>, if we call resetChildToText:@"123" to id=1 node, it will become <span id=1>123</span>; and in "<span id=1>ABC<lambda id=xxx>DEF</span>", if we can the same method, it will give us "<span id=1>123<lambda id=xxx></span>"
 */
- (void)resetChildToText:(NSString*)text;

/** apply styles defined in the styles dictionary to self and all children
 * @param removeOldStyles is YES if it's a replace, NO if it's just adding new styles
 * @note removeOldStyles only refer to the old styles defined by the class at this node, and does NOT include the default styles and global styles
 */
- (void)applyAndSpreadStyles:(NSMutableDictionary*)styles removeOldStyles:(BOOL)removeOldStyles;

@end
