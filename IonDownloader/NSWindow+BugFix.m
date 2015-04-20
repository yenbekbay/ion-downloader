//
//  NSWindow+BugFix.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/objc-class.h>
#import "NSWindow+BugFix.h"
#import "AYAppDelegate.h"
#import "AYController.h"

@implementation NSWindow (BugFix)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(canBecomeKeyWindow)),
                                   class_getInstanceMethod(self, @selector(_canBecomeKeyWindow)));
}

- (BOOL)_canBecomeKeyWindow {
    if ([self class] == NSClassFromString(@"NSStatusBarWindow")) {
        AYController * controller = [((AYAppDelegate*)[NSApp delegate]) controller];
        if([controller isActive]) {
            return [controller isActive];
        }
    }
    return [self _canBecomeKeyWindow];
}

@end
