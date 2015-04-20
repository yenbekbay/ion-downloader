//
//  VKAuth.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/3/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKAuth.h"
#import "AYAppDelegate.h"
#import "VKAuthWindowController.h"
#import "AYConstants.h"

static AYAppDelegate *appDelegate = nil;
    
@implementation VKAuth

- (id)init {
    if (appDelegate == nil)
        appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    return self;
}

- (void)signIn:(BOOL)new {
    // Display the autentication sheet
    self.windowController = [[VKAuthWindowController alloc] init];
    self.windowController.delegate = self;
    NSString *authString = [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&scope=offline,audio&redirect_uri=https://oauth.vk.com/blank.html&display=touch&response_type=token", kVKclientID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:authString]];
    if (new) [request setHTTPShouldHandleCookies:NO];

    NSWindow *window = appDelegate.controller.preferencesWindowController.window;
    [self.windowController open:window request:request];
}

- (void)signOut {
    [appDelegate setAccessToken:@""];
    [appDelegate setUserId:@""];
    [appDelegate setUserName:@""];
    [self update];
    [self setSearchEnabled:NO];
    [self.windowController destroyWindow];
}

- (void)setDefault:(NSString *)accessToken userId:(NSString *)userId userName:(NSString *)userName {
    [appDelegate setAccessToken:accessToken];
    [appDelegate setUserId:userId];
    [appDelegate setUserName:userName];
    NSLog(@"New access token: %@", accessToken);
    NSLog(@"New user ID: %@", userId);
    NSLog(@"New user name: %@", userName);
    [self update];
    [self setSearchEnabled:YES];
}

- (void)setSearchEnabled:(BOOL)state {
    [appDelegate.controller.popoverController.searchField setEnabled:state];
    if (state == YES)
        [appDelegate.controller.popoverController.searchField
         setPlaceholderString:NSLocalizedString(@"Enter your query", @"Enter your query")];
    else
        [appDelegate.controller.popoverController.searchField
         setPlaceholderString:NSLocalizedString(@"Connect your VK account", @"Connect your VK account")];
}

- (void)update {
    if ([[appDelegate userName] isNotEqualTo:@""]) {
        // Signed in
        [self.delegate setAuthLabelValue:NSLocalizedString(@"Logged in as:", @"Logged in as:")];
        [self.delegate setAuthButtonValue:[appDelegate userName]];
        self.isSignedIn = YES;
    } else {
        [self.delegate setAuthLabelValue:NSLocalizedString(@"Connect your VK account:", @"Connect your VK account:")];
        [self.delegate setAuthButtonValue:NSLocalizedString(@"Sign in", @"Sign in")];
        self.isSignedIn = NO;
        [self.delegate adjustLabels];
    }
}

@end
