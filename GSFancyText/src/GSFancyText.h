//
//  GSFancyText.h
//  -GrannySmith-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

/// GSFancyText does markup text parsing, stores parsing result, generated lines, and draw the rich text.

/// The initialization can be from an unparsed markup string, or a parsed result tree.
///
/// It also stores a dictionary of styles, which can be used in markup parsing, as well as style switching afterwards
///
/// This is a model class. It's mainly for processing strings and generate arrays. To create a view, see GSFancyTextView

#import <Foundation/Foundation.h>

#import "GSFancyTextDefines.h"
#import "GSMarkupNode.h"

@interface GSFancyText : NSObject  {
    NSMutableArray* lines_; // each line is also an array of styled texts
    CGFloat width_;
    CGFloat maxHeight_;
    NSMutableDictionary* style_; // key is class name, value is "style" dictionary, with color and font keys
    NSString* text_;
    
    CGFloat contentHeight_; // will require lineGeneration calculation
    CGFloat contentWidth_; // will require lineGeneration calculation
    
    NSMutableDictionary* lambdaBlocks_; // key is lambda id, value is a block for drawing code with 1 parameter: the starting point
    
    GSMarkupNode* parsedTree_; // root of the parsed result (in tree structure). ready after parseStructure
}


///--------------------
/// @name Properties
///--------------------

/// A dictionary of lambda block. Key:lambda ID. Value: a block
@property (nonatomic, retain) NSMutableDictionary* lambdaBlocks;

/// The style dictionary. It's a dictionary of dictionaries of dictionaries. Key: tag name. Value: a dictionary with [Key:class name. Value: (a dictionary with key: attribute name, value: value of the attribute)]
///
/// Use key "default" (GSFancyTextDefaultClass) to get classes that are not associated with any tag.
@property (nonatomic, retain) NSMutableDictionary* style;

/// The original markup text.
/// @warning If the fancy text instance is instatiated based on a parsed structure, the text will be empty. Don't always rely on this property because texts in some tags maybe changed after calling changeNodeToText:forID:
@property (nonatomic, retain) NSString* text;

/// The confined width of the fancy text object
@property (nonatomic, assign) CGFloat width;

/// The confined height of the fancy text object. If it's set to 0, it means that there's no limit on height.
@property (nonatomic, assign) CGFloat maxHeight;

///--------------------
/// @name Initialization
///--------------------

/** Initialize with a markup text (unparsed), a CSS dictionary (obtained with parsedCSS method), a width, and a maxHeight
 *
 * The global style sheet (if set) is also applied, but the styleDict will be on top of it (higher priority).
 *
 * Note: global style will be applied with this init method, and the passed styleDict param will override on top.
 *
 * @param maxHeight is limit of the height. Use 0 if there is no height limit. Use contentHeight method to get the actual height (must be after generateLines)
 */
- (id)initWithMarkupText:(NSString*)text styleDict:(NSMutableDictionary*)styleDict width:(CGFloat)width maxHeight:(CGFloat)maxHeight;

/** Initialize with a formatted text and the global style (if set). The width and max height are set to 0 and can be changed later.
 */
- (id)initWithMarkupText:(NSString*)text;

/** Init with a parsed structure.
 *
 * In this way you can re-use a parsing result
 *
 * e.g. structure = [fancyText1 parse];
 *
 * fancyText2 = [[GSFancyText alloc] initWithParsedStructure: structure];
 *
 * [fancyText2 changeNodeToText:@"new text" forID:@"123"];
 *
 * The width and max height are set to 0, but can be changed later
 */
- (id)initWithParsedStructure:(GSMarkupNode*)structure;

///-----------------------
/// @name Add style sheet
///-----------------------

/** Keep the original style sheet and append a new one on that.
 *
 * If there is any conflicted class, follow the newStyleSheet.
 */
- (void)appendStyleSheet: (NSString*)newStyleSheet;


///--------------------
/// @name Markup parsing
///--------------------

/** Parse the markup text (e.g. "xyz <p class=xyz>def</p>") 
 *
 * After parsing, we can always call parsedResultTree to retrieve the result tree
 *
 * @return the root of the result tree
 */
- (GSMarkupNode*)parseStructure;

/** The result of parseStructure
 * @return the root of the result tree
 */
- (GSMarkupNode*)parsedResultTree;

///----------------------
/// @name Line generation
///----------------------

/** Generate lines based on a parsed text
 * @return an array containing several lines, each line is an array of dictionaries with text key and style keys
 */
- (NSMutableArray*)generateLines;

/** The result of generateLines
 * @return an array containing several lines, each line is an array of dictionaries with text key and style keys
 */
- (NSMutableArray*)lines;

///--------------------
/// @name Information
///--------------------

/** Returns the pure text (tags removed) for accessibility label.
 *
 * Extra stop signs may be exported based on forced line breaks. This is for the convenience of blind people
 */
- (NSString*)pureText;

/** Returns the resulting total height after generating lines
 *
 * Call this only after doing generateLines
 */
- (CGFloat)contentHeight;

/** Returns the content width after generating lines
 *
 * Call this only after doing generateLines
 *
 * Note: this is used when the original assigned width is too big, and actually none of the lines reached the width. This method gives the actually reached width.
 */
- (CGFloat)contentWidth;

///--------------------
/// @name Lambda block
///--------------------

/** Set the drawing block for a lambda ID, so that in the fancy text markup string, the tag <lambda id=lambdaID width=xxx height=xxx> will be replaced by this drawing
 * @param drawingBlock is the block for drawing, it takes one CGRect parameter, which is the frame for drawing
 */
- (void)defineLambdaID:(NSString*)lambdaID withBlock:(void(^)(CGRect))drawingBlock;


///----------------------
/// @name Node searching
///----------------------

/** Find the node with a certain ID
 */
- (GSMarkupNode*)nodeWithID:(NSString*)nodeID;

/** Find a list of nodes with a certain class name
 */
- (NSArray*)nodesWithClass:(NSString*)className;


///--------------------
/// @name Global style
///--------------------

/** Parse a style sheet string and set it as the global default style 
 */
+ (NSMutableDictionary*)parseStyleAndSetGlobal: (NSString*)styleSheet;

/** Returns the global default style
 */
+ (NSMutableDictionary*)globalStyle;

///-------------------------
/// @name Standalone parsers
///-------------------------

/** A parser for CSS styled format string
 *
 * The style dictionary is something like {default:{class1:{color:red, font-size:10}, class2:{color:green} } p:{class1:{font-size: 12}} }. Basically it's a 3-level dictionary, the 1st level is element name, the 2nd level is class name, the 3rd level is the attribute name.
 * @return a style dictionary
 */
+ (NSMutableDictionary*)parsedStyle: (NSString*)style;

/** Does the same thing as parsedStyle:, the only difference is that it returns a retained object, and you have to release it manually
 */
+ (NSMutableDictionary*)newParsedStyle: (NSString*)style;

/** A standalone parser for a markup styled string
 *
 * This is similar to instance method parseStructure, but the difference is that we don't need to instantiate an GSFancyText object, and we don't need to worry about width, max height and all line breaking related stuff
 * @return a parsed result tree
 */
+ (GSMarkupNode*)parsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict;

/** Does the same thing as parsedMarkupString:withStyleDict:, the only difference is that it returns a retained object, and you have to release it manually
 */
+ (GSMarkupNode*)newParsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict;


///--------------------
/// @name Font handling
///--------------------


/** Create a UIFont based on name, size, weight, style
 * @param name is the normal font name
 * @param weight is the either bold or normal
 * @param style is either italic or normal
 */
+ (UIFont*)fontWithName:(NSString*)name size:(CGFloat)size weight:(NSString*)weight style:(NSString*)style;

/** Returns a string that included all available font names, grouped by family names.
 *
 * Used by developers to quickly look up what's available
 */
+ (NSString*)availableFonts;

/** Make a font key based on font family, size, weight, style keys in the dictionary.
 *
 * The font key's value is a UIFont object
 */
+ (void)createFontKeyForDict: (NSMutableDictionary*)dict;

///-------------------
/// @name Drawing
///-------------------

/** Draw self in a rect
 */
- (void)drawInRect:(CGRect)rect;

///----------------------------------
/// @name Content/Style modification
///----------------------------------

/** Change a node to text.
 *
 * Example: for "xyz <span id=x>123 <span>456</span> </span> DEF", changeNodeToText:@"000" forID:@"x" will give "xyz <span id=x>000</span> DEF"
 */
- (void)changeNodeToText:(NSString*)text forID:(NSString*)nodeID;

/** Change a node to a styled text (to be parsed).
 *
 * It's similar to changeNodeToText:forID: but the styledText can have markup tags, e.g. <strong>text</strong>
 *
 * It can also refer to classes that is either stored in this GSFancyText instance or the global/default style sheet
 */
- (void)changeNodeToStyledText:(NSString*)styledText forID:(NSString*)nodeID;

/** Append a styled text (to be parsed) to a node
 *
 * Example: for "xyz <span id=x>123 <span>456</span> </span> DEF", if we append "a <em>e</em>" to "x", "a <em>e</em>" will go after <span>456</span>
 */
- (void)appendStyledText:(NSString*)text toID:(NSString*)nodeID;

/** Totally cut the node with the given ID
 *
 * Example: for "xyz <span id=x>123 <span>456</span> </span> DEF", removeID:@"x" will give "xyz  DEF"
 */
- (void)removeID: (NSString*)nodeID;


/** Change the value of a single attribute to an ID or a class.
 * @param type can be either GSFancyTextID or GSFancyTextClass
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 */
- (void)changeAttribute:(NSString*)attribute to:(id)value on:(GSFancyTextReferenceType)type withName:(NSString*)name;

/** Add styles defined in a dictionary to an ID or a class.
 * @param type can be either GSFancyTextID or GSFancyTextClass or GSFancyTextRoot 
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 */
- (void)addStyles:(NSMutableDictionary*)styles on:(GSFancyTextReferenceType)type withName:(NSString*)name;

/** Apply styles defined in a class to an ID or a class. (also keeps the old styles)
 *
 * This just changes styles, but doesn't change class mapping.
 *
 * Example: if we have <p class=a>123</p>, and we called applyClass:b on:GSFancyTextClass withName:a, the styles of 123 are based on b now.
 *
 * But searching 123 would be still based on class=a
 * @param type can be either GSFancyTextID or GSFancyTextClass
 * @param name is the ID or the class name  (in case it's root no name is required, it can be nil or anything)
 */
- (void)applyClass:(NSString*)className on:(GSFancyTextReferenceType)type withName:(NSString*)name;

/** Apply styles defined in a class to an ID or a class. (old styles get removed first)
 *
 * This just changes styles, but doesn't change class mapping.
 *
 * Example: if we have <p class=a>123</p>, and we called changeStylesToClass:b on:GSFancyTextClass withName:a, the styles of 123 are based on b now.
 *
 * But searching 123 would be still based on class=a
 * @param type can be either GSFancyTextID or GSFancyTextClass
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 */
- (void)changeStylesToClass:(NSString*)className on:(GSFancyTextReferenceType)type withName:(NSString*)name;

///----------------------
/// @name Helper methods
///----------------------

/** Assuming the value for the key in this dict is an array, add the object to that array.
 *
 * If the value for the key doesn't exist yet, then create a new array with this object and set it as the value for the key.
 */
+ (void)addObject:(NSObject*)object intoDict:(NSMutableDictionary*)dict underKey:(NSString*)key;

/** Clean up the conflicting keys
 *
 * We have this method because when we set styles, we copy attributes by a block
 *
 * And only in a few cases we want to block attributes. So we use this method.
 *
 * Example: if dict does not have line-id key (which is from p) but it has text align, line-id, truncation-mode key, just kick them out
 *
 * Note: this method is called at the tag parsing level, e.g if we have <span class=centerAlign> we just remove the text-align
 */
+ (void)cleanStyleDict:(NSMutableDictionary*)dict;

@end


/// @example GSFancyText GSFancyText* fancyText = [[GSFancyText alloc] initWithMarkupText: @"\<strong\>GSFancyText\</strong\>\<p class=some_class\>Another line\</p\>"]


