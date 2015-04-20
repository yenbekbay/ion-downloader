//
//  AYMenuButton.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/2/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYMenuButton.h"
#import "AYMenuButtonCell.h"
#import "AYAppDelegate.h"
#import "AYWishlistController.h"

@implementation AYMenuButton

- (void)mouseDown:(NSEvent *)theEvent {
    self.menu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    [self.menu insertItemWithTitle:NSLocalizedString(@"Send Feedback", @"Send Feedback") action:@selector(sendFeedback) keyEquivalent:@"" atIndex:0];
    [self.menu insertItemWithTitle:NSLocalizedString(@"Preferences", @"Preferences") action:@selector(openPreferences) keyEquivalent:@"," atIndex:1];
    [self.menu insertItemWithTitle:NSLocalizedString(@"Wishlist", @"Wishlist") action:@selector(openWishlist) keyEquivalent:@"W" atIndex:2];
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:3];
    [self.menu insertItemWithTitle:NSLocalizedString(@"Quit", @"Quit") action:@selector(terminate) keyEquivalent:@"q" atIndex:4];
    if ([theEvent type] == NSLeftMouseDown) {
        [[self cell] setMenu:[self menu]];
    } else {
        [[self cell] setMenu:nil];
    }
    [super mouseDown:theEvent];
}

- (void)sendFeedback {
    NSString *subject = @"ION Feedback";
    NSString *to = @"ayan.yenb@gmail.com";
    
    NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", [subject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *encodedTo = [to stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@", encodedTo, encodedSubject];
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

- (void)openPreferences {
    AYAppDelegate *appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate.controller openPreferences];
}

- (void)openWishlist {
    AYAppDelegate *appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate.controller openWishlist];
}

- (void)terminate {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

@end
