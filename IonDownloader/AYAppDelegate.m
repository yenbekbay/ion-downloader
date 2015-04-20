//
//  AYAppDelegate.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYAppDelegate.h"
#import "AYController.h"
#import "AYConstants.h"
#import "NSTask+PTY.h"

@implementation AYAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Get the default user downloads folder
    self.downloadsFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory,
                               NSUserDomainMask, YES) objectAtIndex:0];
    // Set default user preferences
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"320", kMinimumBitrate,
                              self.downloadsFolder, kSavingDirectory,
                              @1, kLookForMatches,
                              @1, kApplyTags,
                              @1, kUseWishlist,
                              @"", kVKaccessToken,
                              @"", kVKuserId,
                              @"", kVKuserName,
                              @0, kImportsInstalled,
                              nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    self.controller = [[AYController alloc] init];
    // Check for VK access token
    [self checkSettings];
    // Start a python script to install required modules
    if ([self importsInstalled] == 0)
        [self performSelector:@selector(checkPythonImports) withObject:self afterDelay:1.0f];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

#pragma mark - Preferences

- (IBAction)openPreferences:(id)sender {
    [self.controller openPreferences];
}

- (IBAction)openWishlist:(id)sender {
    [self.controller openWishlist];
}

- (NSInteger)minimumBitrate {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kMinimumBitrate];    
}

- (void)setMinimumBitrate:(NSInteger)minimumBitrate {
    [[NSUserDefaults standardUserDefaults] setInteger:minimumBitrate forKey:kMinimumBitrate];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.controller.generalViewController.minBitrateStatus setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%ldkbps", @"{Bitrate Number}kbps"), (long)self.minimumBitrate]];
}

- (NSString *)savingDirectory {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kSavingDirectory];
}

- (void)setSavingDirectory:(NSString *)savingDirectory {
    [[NSUserDefaults standardUserDefaults] setObject:savingDirectory forKey:kSavingDirectory];
}

- (NSString *)accessToken {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kVKaccessToken];
}

- (void)setAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kVKaccessToken];
}

- (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kVKuserId];
}

- (void)setUserId:(NSString *)userId {
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kVKuserId];
}

- (NSString *)userName {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kVKuserName];
}

- (void)setUserName:(NSString *)userName {
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:kVKuserName];
}

- (NSInteger)lookForMatches {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kLookForMatches];
}

- (void)setLookForMatches:(NSInteger)lookForMatches {
    [[NSUserDefaults standardUserDefaults] setInteger:lookForMatches forKey:kLookForMatches];
}

- (NSInteger)applyTags {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kApplyTags];
}

- (void)setApplyTags:(NSInteger)applyTags {
    [[NSUserDefaults standardUserDefaults] setInteger:applyTags forKey:kApplyTags];
}

- (NSArray *)wishlist {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kWishlist];
}

- (void)setWishlist:(NSArray *)wishlist {
    [[NSUserDefaults standardUserDefaults] setObject:wishlist forKey:kWishlist];
}

- (NSInteger)useWishlist {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kUseWishlist];
}

- (void)setUseWishlist:(NSInteger)useWishlist {
    [[NSUserDefaults standardUserDefaults] setInteger:useWishlist forKey:kUseWishlist];
}

- (NSInteger)importsInstalled {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kImportsInstalled];
}

- (void)setImportsInstalled:(NSInteger)importsInstalled {
    [[NSUserDefaults standardUserDefaults] setInteger:importsInstalled forKey:kImportsInstalled];
}

#pragma mark - Checking access token

- (void)checkSettings {
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    // If no access token, open preferences with the login window
    if ([accessToken isEqualToString:@""]) {
        [self.controller.popoverController setSearchEnabled:NO];
        [self openPreferences:self];
        [self.controller.generalViewController.vkAuth signIn:NO];
    } else {
        [self.controller.popoverController setSearchEnabled:YES];
    }
}

#pragma mark - Imports

- (void)checkPythonImports {
    [self.controller statusBarClicked];
    [self.controller.popoverController animateIn];
    // Hide the spinner and show the status
    if (!self.controller.popoverController.spinner.isHidden) {
        [self.controller.popoverController.spinner stopAnimation:self];
        [self.controller.popoverController.spinner setHidden:YES];
    }
    [self.controller.popoverController.status setHidden:NO];
    [self.controller.popoverController.status setStringValue:
     NSLocalizedString(@"Preparing the system...", @"Preparing the system...")];
    // Run on a background thread
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        NSArray *args = [NSArray arrayWithObjects: [[NSBundle mainBundle] pathForResource:@"imports" ofType:@"py"], nil];
        NSString *output = nil;
        NSString *processErrorDescription = nil;
        BOOL success = [self runProcessAsAdministrator:@"/usr/local/bin/python"
                                         withArguments:args
                                                output:&output
                                      errorDescription:&processErrorDescription];
        if(!success) {
            NSLog(@"Problem running task: %@", processErrorDescription);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Terminating script");
            [self setImportsInstalled:1];
            [self performSelector:@selector(animateOut) withObject:self afterDelay:2.0f];
            });
        }
    });
}

- (void)animateOut {
    [self.controller.popoverController animateOut];
}

- (BOOL)runProcessAsAdministrator:(NSString *)scriptPath
                    withArguments:(NSArray *)arguments
                           output:(NSString **)output
                 errorDescription:(NSString **)errorDescription {
    NSString *allArgs = [arguments componentsJoinedByString:@" "];
    NSString *fullScript = [NSString stringWithFormat:@"%@ %@", scriptPath, allArgs];
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor *eventResult = [appleScript executeAndReturnError:&errorInfo];
    // Check errorInfo
    if(!eventResult) {
        // Describe common errors
        *errorDescription = nil;
        if([errorInfo valueForKey:NSAppleScriptErrorNumber]) {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this";
        }
        // Set error message from provided message
        if (*errorDescription == nil) {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
            *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        return NO;
    } else {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        return YES;
    }
}

@end
