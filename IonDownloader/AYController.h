//
//  AYController.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYStatusBarIcon.h"
#import "AYPopoverController.h"
#import "AYWishlistController.h"
#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"

@interface AYController : NSObject <AYPopoverDelegate, AYStatusBarIconDelegate> {
    NSWindowController *_preferencesWindowController;
}

@property AYStatusBarIcon *statusBarIcon;
@property AYPopoverController *popoverController;
@property AYWishlistController *wishlistController;
@property NSStatusItem *statusItem;
@property (getter = isActive) BOOL active;
@property GeneralPreferencesViewController *generalViewController;
@property (assign, nonatomic, readonly) NSWindowController *preferencesWindowController;

- (void)openPreferences;
- (void)openWishlist;
- (void)statusBarClicked;

@end

