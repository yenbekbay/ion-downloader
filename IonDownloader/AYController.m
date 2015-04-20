//
//  AYController.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYController.h"
#import "AYAppDelegate.h"
#import "AYStatusBarIcon.h"
#import "AYPopoverController.h"
#import "AYWishlistController.h"
#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"

@implementation AYController

- (id)init {
    self = [super init];
    // Create a custom status bar icon to detect mouse clicks and open the popover
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];
    self.statusBarIcon = [[AYStatusBarIcon alloc]
                          initWithFrame:(NSRect){.size={thickness, thickness}}];
    self.statusBarIcon.delegate = self;
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:thickness];
    [self.statusItem setView:self.statusBarIcon];
    [self.statusItem setHighlightMode:NO];
    self.popoverController = [[AYPopoverController alloc] init];
    self.popoverController.delegate = self;
    self.wishlistController = [[AYWishlistController alloc] init];
    return self;
}

#pragma mark - Status bar icon

- (void)startAnimatingIcon {
    [self.statusBarIcon startAnimating];
}

- (void)stopAnimatingIcon {
    [self.statusBarIcon stopAnimating];
}

- (void)statusBarClicked {
    self.active = !self.active;
    if (self.isActive) {
        [self openPopover];
    } else {
        [self closePopover];
    }
}

#pragma mark - Popover

- (void)closePopover {
    NSLog(@"Closing popover");
    [self.popoverController.popover performClose:self];
    self.active = NO;
}

- (void)openPopover {
    NSLog(@"Opening popover");
    [self.popoverController.popover showRelativeToRect:self.statusBarIcon.frame
                                             ofView:self.statusBarIcon
                                      preferredEdge:NSMinYEdge];
}

#pragma mark - Preferences

- (NSWindowController *)preferencesWindowController {
    if (_preferencesWindowController == nil) {
        self.generalViewController = [[GeneralPreferencesViewController alloc] init];
        NSArray *controllers = @[self.generalViewController, [NSNull null]];
        
        _preferencesWindowController = [[MASPreferencesWindowController alloc]
                                        initWithViewControllers:controllers
                                        title:NSLocalizedString(@"Preferences", @"Preferences")];
    }
    return _preferencesWindowController;
}

- (void)openPreferences {
    [self.preferencesWindowController showWindow:nil];
}

#pragma mark - Wishlist

- (void)openWishlist {
    [self.wishlistController showWindow:self];
}

- (void)addToWishlist:(NSString *)name {
    [self.wishlistController addToWishlist:name];
}

- (void)removeFromWishlist:(NSString *)name {
    [self.wishlistController removeFromWishlist:name];
}
    
@end