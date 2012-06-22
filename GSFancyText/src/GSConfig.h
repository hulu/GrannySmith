//
//  GSConfig.h
//  -GrannySmith-
//
//  Created by Bao Lei on 6/22/12.
//  Copyright (c) 2012 Hulu, LLC. All rights reserved. See LICENSE.txt.
//

#ifndef GSConfig_h
#define GSConfig_h

#warning: Please set the GS_ARC_ENABLED flag according to your project setting. Then comment this line out to disable the warning.
/// For more information about ARC, please read: http://developer.apple.com/library/mac/#releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html
/// To check whether ARC is enabled for your project, hit cmd+1 in Xcode, select the project, then the target, then Build Settings, then search for Objective-C Automatic Reference Counting. If it exists and is set to Yes, ARC is enabled.


/// Uncomment the following line if ARC (Automatic Reference Counting) is enabled. Comment it if ARC is not enabled.
// #define GS_ARC_ENABLED 1

/// Comment the following line if ARC is enabled but your deployment target is iOS 4.x.
// #define GS_ARC_WEAK_REF_ENABLED 1


// #define GS_DEBUG_MARKUP 1           // Uncomment to log the markup text warnings
// #define GS_DEBUG_PERFORMANCE 1      // Uncomment to log the performance measurements



// Use these flags only when working on the code of GSFancyText
// #define GS_DEBUG_CODE 1             // Uncomment to log the debug information of the code
// #define GS_DEBUG_ALL 1              // Uncomment to enable all kinds of debug logs



#endif
