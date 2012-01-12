//
//  HUFancyText.h
//  -HUSFT-
//
//  Created by Bao Lei on 12/15/11.
//  Copyright (c) 2011 Hulu. All rights reserved.
//

/// A structure that stores tree based markup parsing result, and arrays of lines.
/// @discussion The initialization can be from an unparsed markup string, or a parsed result tree.
/// It also stores a dictionary of styles, which can be used in markup parsing, as well as style switching afterwards
/// @note This is a model class. It only processes strings and generate arrays. To create a view, see HUFancyTextView

#import <Foundation/Foundation.h>

#import "HUFancyTextDefines.h"
#import "HUMarkupNode.h"
#import "HUFancyTextDefines.h"


@interface HUFancyText : NSObject  {
    NSMutableArray* lines_; // each line is also an array of styled texts
    CGFloat width_;
    CGFloat maxHeight_;
    NSMutableDictionary* style_; // key is class name, value is "style" dictionary, with color and font keys
    NSString* text_;
    
    CGFloat contentHeight_; // will require parseStructure calculation
    
    NSMutableDictionary* lambdaBlocks_; // key is lambda id, value is a block for drawing code with 1 parameter: the starting point
    
    HUMarkupNode* parsedTree_; // root of the parsed result (in tree structure). ready after parseStructure
}

@property (nonatomic, retain) NSMutableDictionary* lambdaBlocks;
@property (nonatomic, retain) NSMutableDictionary* style;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat maxHeight;


/** initialize with a markup text (unparsed), a CSS dictionary (obtained with parsedCSS method), a width, and a maxHeight
 * @note this is the most low level initialization method.
 */
- (id)initWithMarkupText:(NSString*)text styleDict:(NSMutableDictionary*)styleDict width:(CGFloat)width maxHeight:(CGFloat)maxHeight;

/** initialize with a formatted text and the global style (if set). The width and max height are set to 0 and can be changed later.
 */
- (id)initWithMarkupText:(NSString*)text;

/** init with a parsed structure.
 * @discussion in this way you can re-use a parsing result
 * e.g. structure = [fancyText1 parse];
 * fancyText2 = [[HUFancyText alloc] initWithParsedStructure: structure];
 * [fancyText2 changeNodeToText:@"new text" forID:@"123"];
 * @note the width and max height are set to 0, but can be changed later
 */
- (id)initWithParsedStructure:(HUMarkupNode*)structure;

/** keep the original style sheet and append a new one on that.
 * If there is any conflicted class, follow the newStyleSheet.
 */
- (void)appendStyleSheet: (NSString*)newStyleSheet;

/** parse the markup text (e.g. "abc <p class=xyz>def</p>") 
 * @return the root of the result tree
 * @note after parsing, we can always call parsedResultTree to retrieve the result tree
 */
- (HUMarkupNode*)parseStructure;

/** result of parseStructure
 * @return the root of the result tree
 */
- (HUMarkupNode*)parsedResultTree;


/** generate lines based on a parsed text
 * @return an array containing several lines, each line is an array of dictionaries with text key and style keys
 */
- (NSMutableArray*)generateLines;

/** the result of generateLines
 * @return an array containing several lines, each line is an array of dictionaries with text key and style keys
 */
- (NSMutableArray*)lines;

/** returns the pure text (tags removed) for accessibility label.
 * @note extra stop signs may be exported based on forced line breaks. This is for the convenience of blind people
 */
- (NSString*)pureText;

/** returns the resulting total height after generating lines
 * @note call this only after doing generateLines
 */
- (CGFloat)contentHeight;



///--------------------
/// @name lambda blocks
///--------------------

/** set the drawing block for a lambda ID
 * So that in the fancy text markup string, the tag <lambda id=lambdaID width=xxx height=xxx valign=xxx> will be replaced by this drawing
 * @param drawingBlock is the block for drawing, it takes one CGRect parameter, which is the frame for drawing
 */
- (void)setBlock:(void(^)(CGRect))drawingBlock forLambdaID:(NSString*)lambdaID;


///---------------
/// @name styles
///---------------

/** Parse a style sheet string and set it as the global default style 
 */
+ (NSMutableDictionary*)parseStyleAndSetGlobal: (NSString*)styleSheet;

/** returns the global default style
 */
+ (NSMutableDictionary*)globalStyle;


/** A parser for CSS styled format string
 * @return a style dictionary
 * @discussion the style dictionary is something like {default:{class1:{color:red, font-size:10}, class2:{color:green} } p:{class1:{font-size: 12}} }. Basically it's a 3-level dictionary, the 1st level is element name, the 2nd level is class name, the 3rd level is the attribute name.
 */
+ (NSMutableDictionary*)parsedStyle: (NSString*)style;

/** Does the same thing as parsedStyle:, the only difference is that it returns a retained object, and you have to release it manually
 */
+ (NSMutableDictionary*)newParsedStyle: (NSString*)style;

/** A standalone parser for a markup styled string
 * @return a parsed result tree
 * @discussion this is similar to instance method parseStructure, but the difference is that we don't need to instantiate an HUFancyText object, and we don't need to worry about width, max height and all line breaking related stuff
 */
+ (HUMarkupNode*)parsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict;

/** Does the same thing as parsedMarkupString:withStyleDict:, the only difference is that it returns a retained object, and you have to release it manually
 */
+ (HUMarkupNode*)newParsedMarkupString: (NSString*)markup withStyleDict: (NSDictionary*)styleDict;


///-------------------
/// @name Font related
///-------------------


/** Create a UIFont based on name, size, weight, style
 * @param name is the normal font name
 * @param weight is the either bold or normal
 * @param style is either italic or normal
 */
+ (UIFont*)fontWithName:(NSString*)name size:(CGFloat)size weight:(NSString*)weight style:(NSString*)style;

/** returns a string that included all available font names, grouped by family names.
 * Used by developers to quickly look up what's available
 */
+ (NSString*)availableFonts;

/** make a font key based on font family, size, weight, style keys in the dictionary.
 * The font key's value is a UIFont object
 */
+ (void)createFontKeyForDict: (NSMutableDictionary*)dict;

///-------------------
/// @name Drawing
///-------------------

/** draw self in a rect
 */
- (void)drawInRect:(CGRect)rect;

///------------------------------
/// @name Content/style swapping
///------------------------------

/** change a node to text.
 * @example for "ABC <span id=x>123 <span>456</span> </span> DEF", changeNodeToText:@"000" forID:@"x" will give "ABC <span id=x>000</span> DEF"
 */
- (void)changeNodeToText:(NSString*)text forID:(NSString*)nodeID;

/** change a node to a styled text (to be parsed).
 * @discussion it's similar to changeNodeToText:forID: but the styledText can have markup tags, e.g. <strong>text</strong>
 * It can also refer to classes that is either stored in this HUFancyText instance or the global/default style sheet
 */
- (void)changeNodeToStyledText:(NSString*)styledText forID:(NSString*)nodeID;

/** append a styled text (to be parsed) to a node
 * @example for "ABC <span id=x>123 <span>456</span> </span> DEF", if we append "a <em>e</em>" to "x", "a <em>e</em>" will go after <span>456</span>
 */
- (void)appendStyledText:(NSString*)text toID:(NSString*)nodeID;

/** totally cut the node with the given ID
 * @example for "ABC <span id=x>123 <span>456</span> </span> DEF", removeID:@"x" will give "ABC  DEF"
 */
- (void)removeID: (NSString*)nodeID;


/** change the value of a single attribute to an ID or a class.
 * @param type can be either HUFancyTextID or HUFancyTextClass
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 */
- (void)changeAttribute:(NSString*)attribute to:(id)value on:(HUFancyTextReferenceType)type withName:(NSString*)name;

/** add styles defined in a dictionary to an ID or a class.
 * @param type can be either HUFancyTextID or HUFancyTextClass or HUFancyTextRoot 
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 */
- (void)addStyles:(NSMutableDictionary*)styles on:(HUFancyTextReferenceType)type withName:(NSString*)name;

/** apply styles defined in a class to an ID or a class. (also keeps the old styles)
 * @param type can be either HUFancyTextID or HUFancyTextClass
 * @param name is the ID or the class name  (in case it's root no name is required, it can be nil or anything)
 * @note this just changes styles, but doesn't change class mapping.
 * e.g. if we have <p class=a>123</p>, and we called applyClass:b on:HUFancyTextClass withName:a, the styles of 123 are based on b now.
 * But searching 123 would be still based on class=a
 */
- (void)applyClass:(NSString*)className on:(HUFancyTextReferenceType)type withName:(NSString*)name;

/** apply styles defined in a class to an ID or a class. (old styles get removed first)
 * @param type can be either HUFancyTextID or HUFancyTextClass
 * @param name is the ID or the class name (in case it's root no name is required, it can be nil or anything)
 * @note this just changes styles, but doesn't change class mapping.
 * e.g. if we have <p class=a>123</p>, and we called changeStylesToClass:b on:HUFancyTextClass withName:a, the styles of 123 are based on b now.
 * But searching 123 would be still based on class=a
 */
- (void)changeStylesToClass:(NSString*)className on:(HUFancyTextReferenceType)type withName:(NSString*)name;

///--------------
/// @name helper
///--------------

/** assuming the value for the key in this dict is an array, add the object to that array.
 * If the value for the key doesn't exist yet, then create a new array with this object and set it as the value for the key.
 */
+ (void)addObject:(NSObject*)object intoDict:(NSMutableDictionary*)dict underKey:(NSString*)key;

/** clean up the conflicting keys
 * @discussion we have this method because when we set styles, we copy attributes by a block
 * And only in a few cases we want to block attributes. So we use this method.
 * @example if dict does not have line-id key (which is from p) but it has text align, line-id, truncation-mode key, just kick them out
 * @note this method is called at the tag parsing level, e.g if we have <span class=centerAlign> we just remove the text-align
 */
+ (void)cleanStyleDict:(NSMutableDictionary*)dict;

@end

