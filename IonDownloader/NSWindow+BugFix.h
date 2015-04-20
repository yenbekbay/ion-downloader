//
//  NSWindow+BugFix.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

/* This is to fix a bug on 10.7+ that prevent NSTextFields inside NSPopovers to get the focus */

#import <AppKit/AppKit.h>

@interface NSWindow (BugFix)

@end
