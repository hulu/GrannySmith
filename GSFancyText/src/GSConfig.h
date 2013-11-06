//
//  GSConfig.h
//  -GrannySmith-
//
//  Created by Bao Lei on 6/22/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#ifndef GSConfig_h
#define GSConfig_h



/// Uncomment the following line if ARC (Automatic Reference Counting) is enabled. Comment it if ARC is not enabled.
//#if __has_feature(objc_arc)
#define GS_ARC_ENABLED 1
//#endif

/// Comment the following line if ARC is enabled but your deployment target is iOS 4.x.
//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0
#define GS_ARC_WEAK_REF_ENABLED 1
//#endif


// #define GS_DEBUG_MARKUP 1           // Uncomment to log the markup text warnings
// #define GS_DEBUG_PERFORMANCE 1      // Uncomment to log the performance measurements



// Use these flags only when working on the code of GSFancyText
// #define GS_DEBUG_CODE 1             // Uncomment to log the debug information of the code
// #define GS_DEBUG_ALL 1              // Uncomment to enable all kinds of debug logs



#endif
