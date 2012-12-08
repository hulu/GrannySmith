//
//  GSFancyTextUnitTest.m
//  i2
//
//  Created by Jeffrey Fan on 12/7/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#define GS_TEST_MAX_WIDTH 768
#define GS_TEST_MAX_HEIGHT 1024

@interface GSFancyTextUnitTest : SenTestCase {
    
}

@end

@implementation GSFancyTextUnitTest

- (void) testLoad {
    for (int i=0; i<1000000; i++) {
        GSFancyTextView *fancyTextView = [[GSFancyTextView alloc] init];
        GSFancyText *fancyText = [[GSFancyText alloc] initWithMarkupText:[NSString stringWithFormat:@"<p><strong>heading</strong></p><p>description</P>"]];
        
        int height = rand() % GS_TEST_MAX_HEIGHT;
        int width = rand() % GS_TEST_MAX_WIDTH;
        int x = rand() % GS_TEST_MAX_WIDTH;
        int y = rand() % GS_TEST_MAX_HEIGHT;
        CGRect frame = CGRectMake(x, y, width, height);
        
        fancyTextView.frame = frame;
        fancyTextView.fancyText = fancyText;
    }
}

@end