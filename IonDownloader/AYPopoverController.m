//
//  AYPopoverController.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYPopoverController.h"
#import "AYAppDelegate.h"
#import "NSTask+PTY.h"

static AYAppDelegate *appDelegate;

@implementation AYPopoverController

id mouseEventMonitor;

- (id)init {
    self = [super initWithNibName:@"AYPopover" bundle:nil];
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = self;
    
    mouseEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask) handler:^(NSEvent *event) {
        if ([self.delegate isActive] && !(event.modifierFlags & NSCommandKeyMask)) {
            NSLog(@"Clicked outside");
            [self.delegate closePopover];
        }
       
    }];
    appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    
    return self;
}

- (void)awakeFromNib {
    if (!self.isSearchEnabled) {
        [self.searchField setEnabled:NO];
        [self.searchField setPlaceholderString:NSLocalizedString(@"Connect your VK account",
                                                                 @"Connect your VK account")];
    }
}

#pragma mark - Search field

- (void)controlTextDidChange:(NSNotification *)obj {
    self.query = [self.searchField stringValue];
    if ([self.query length] != 0) {
        [self.searchButton setEnabled:YES];
        [self.searchField setPlaceholderString:NSLocalizedString(@"Enter your query",
                                                                 @"Enter your query")];
    } else {
        [self.searchButton setEnabled:NO];
    }
}

#pragma mark - Parsing query

- (IBAction)parseQuery:(id)sender {
    self.query = [self.searchField stringValue];
    if ([self.query length] != 0) {
        [self animateIn];
        [self runScript];
    } else {
        [self.searchField setPlaceholderString:NSLocalizedString(@"Enter something!",
                                                                 @"Enter something!")];
    }
}

- (void)animateIn {
    [self.delegate startAnimatingIcon];
    NSRect searchFieldFrame = [self.searchField frame];
    searchFieldFrame.origin.y += 20;
    NSRect searchButtonFrame = [self.searchButton frame];
    searchButtonFrame.origin.y += 20;
    NSRect menuButtonFrame = [self.menuButton frame];
    menuButtonFrame.origin.y += 20;
    [self.spinner setHidden:NO];
    [self.spinner setAlphaValue:0];
    [self.spinner startAnimation:self];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1.50];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self.searchField setHidden:YES];
        [self.searchButton setHidden:YES];
        [self.menuButton setHidden:YES];
        [self.searchField setStringValue:@""];
        [self.searchButton setEnabled:NO];
    }];
    self.searchField.animator.alphaValue = 0;
    self.searchButton.animator.alphaValue = 0;
    self.menuButton.animator.alphaValue = 0;
    self.spinner.animator.alphaValue = 1;
    self.searchButton.animator.frame = searchButtonFrame;
    self.searchField.animator.frame = searchFieldFrame;
    self.menuButton.animator.frame = menuButtonFrame;
    [NSAnimationContext endGrouping];
}

- (void)runScript {
    // Run on a background thread
    dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(taskQueue, ^{
        @try {
            // Create a task for python script
            NSTask *task = [[NSTask alloc] init];
            task.launchPath = @"/usr/local/bin/python";
            task.arguments = [NSArray arrayWithObjects: [[NSBundle mainBundle] pathForResource:@"downloader" ofType:@"py"],
                              self.query, [NSString stringWithFormat:@"%ld", (long)appDelegate.minimumBitrate], appDelegate.savingDirectory, appDelegate.accessToken, appDelegate.userId, [@(appDelegate.lookForMatches) stringValue], [@(appDelegate.applyTags) stringValue], nil];
            NSError *error;
            NSFileHandle *masterHandle = [task masterSideOfPTYOrError:&error];
            if (!masterHandle) {
                NSLog(@"error: could not set up PTY for task: %@", error);
                return;
            }
            // Get a reference to the location where the pipe dumps its output
            [masterHandle waitForDataInBackgroundAndNotify];
            // Notify whenever data is available
            __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:masterHandle queue:nil usingBlock:^(NSNotification *notification) {
                // Get the data and convert it to a string
                NSData *output = [masterHandle availableData];
                NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
                // Set status to the string
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self setCurrentStatus:outStr observer:observer];
                });
                // Repeat the call to wait for data in the background
                [masterHandle waitForDataInBackgroundAndNotify];
            }];
            [task launch];
            [task waitUntilExit];
        } @catch (NSException *exception) {
            NSLog(@"Problem running task: %@", [exception description]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Terminating script");
            [self performSelector:@selector(animateOut) withObject:self afterDelay:3.0f];
        });
    });
}

- (void)setCurrentStatus:(NSString *)outStr observer:(id)observer {
    if (!self.spinner.isHidden) {
        [self.spinner stopAnimation:self];
        [self.spinner setHidden:YES];
    }
    if (self.progressBar.doubleValue == 100 || (!([outStr containsString:@"Analyzing"] || [outStr containsString:@"Downloading"]) && self.progressBar.doubleValue > 95)) {
        self.progressBar.doubleValue = 0;
        self.processing = NO;
    }
    if ([outStr containsString:@"Analyzing"] || [outStr containsString:@"Downloading"]) self.processing = YES;
    if (!self.processing) {
        [self.status setHidden:NO];
        [self.progressBar setHidden:YES];
        if ([self.view frame].size.height == 85.0) {
            NSRect viewFrame = [self.view frame];
            viewFrame.size.height = 62.0;
            [self.popover setContentSize:viewFrame.size];
        }
        [self.status setStringValue:[self localizeOutput:outStr]];
        if ([outStr containsString:@"Success"] || [outStr containsString:@"Failure"]) {
            [self checkOutcome:outStr];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            observer = nil;
        }
    } else {
        if ([self.view frame].size.height == 62.0) {
            NSRect viewFrame = [self.view frame];
            viewFrame.size.height = 85.0;
            [self.popover setContentSize:viewFrame.size];
        }
        NSString *progressString;
        NSScanner *scanner = [NSScanner scannerWithString:outStr];
        NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
        [scanner scanCharactersFromSet:numbers intoString:&progressString];
        double progress = [progressString doubleValue];
        if ([outStr containsString:@"Analyzing"]) {
            [self.status setStringValue:NSLocalizedString(@"Analyzing", @"Analyzing")];
        } else if ([outStr containsString:@"Downloading"]) {
            [self.status setStringValue:NSLocalizedString(@"Downloading", @"Downloading")];
        }
        [self.progressBar setHidden:NO];
        if (progress > self.progressBar.doubleValue)
            [self.progressBar setDoubleValue:progress];
    }
}

- (void)checkOutcome:(NSString *)outStr {
    if ([outStr containsString:@"Success"]) {
        [self.successIcon setHidden:NO];
        if ([appDelegate useWishlist] == 1) [self.delegate removeFromWishlist:self.query];
        self.success = 1;
    } else if([outStr containsString:@"Failure"]) {
        [self.failureIcon setHidden:NO];
        if ([appDelegate useWishlist] == 1 && ![outStr containsString:@"exists"]) [self.delegate addToWishlist:self.query];
        self.success = 0;
    }
    if (![self.delegate isActive]) [self showNotificationWithTitle:@"ION" message:[self localizeOutput:outStr]];
    self.query = @"";
}

-(void)animateOut {
    [self.progressBar setHidden:YES];
    NSRect viewFrame = [self.view frame];
    viewFrame.size.height = 62.0;
    [self.popover setContentSize:viewFrame.size];
    
    [self.delegate stopAnimatingIcon];
    NSRect searchFieldFrame = [self.searchField frame];
    searchFieldFrame.origin.y -= 20;
    NSRect searchButtonFrame = [self.searchButton frame];
    searchButtonFrame.origin.y -= 20;
    NSRect menuButtonFrame = [self.menuButton frame];
    menuButtonFrame.origin.y -= 20;
    NSRect statusFrame = [self.status frame];
    statusFrame.origin.y += 20;
    NSRect iconFrame = [self.successIcon frame];
    iconFrame.origin.y += 20;
    [self.searchField setHidden:NO];
    [self.searchField setAlphaValue:0];
    [self.searchButton setHidden:NO];
    [self.searchButton setAlphaValue:0];
    [self.menuButton setHidden:NO];
    [self.menuButton setAlphaValue:0];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1.50];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        NSRect statusFrame = [self.status frame];
        statusFrame.origin.y -= 20;
        if (!self.successIcon.isHidden) {
            NSRect iconFrame = [self.successIcon frame];
            iconFrame.origin.y -= 20;
            [self.successIcon setHidden:YES];
            [self.successIcon setAlphaValue:1];
            [self.successIcon setFrame:iconFrame];
        }
        if (!self.failureIcon.isHidden) {
            NSRect iconFrame = [self.failureIcon frame];
            iconFrame.origin.y -= 20;
            [self.failureIcon setHidden:YES];
            [self.failureIcon setAlphaValue:1];
            [self.failureIcon setFrame:iconFrame];
        }
        [self.status setHidden:YES];
        [self.status setAlphaValue:1];
        [self.status setFrame:statusFrame];
    }];
    self.searchField.animator.alphaValue = 1;
    self.searchButton.animator.alphaValue = 1;
    self.menuButton.animator.alphaValue = 1;
    self.status.animator.alphaValue = 0;
    self.searchButton.animator.frame = searchButtonFrame;
    self.searchField.animator.frame = searchFieldFrame;
    self.menuButton.animator.frame = menuButtonFrame;
    self.status.animator.frame = statusFrame;
    if (!self.successIcon.isHidden) {
        self.successIcon.animator.alphaValue = 0;
        self.successIcon.animator.frame = iconFrame;
    }
    if (!self.failureIcon.isHidden) {
        self.failureIcon.animator.alphaValue = 0;
        self.failureIcon.animator.frame = iconFrame;
    }
    [NSAnimationContext endGrouping];
}

- (NSString *)localizeOutput:(NSString *)outStr {
    if ([outStr containsString:@"Connecting..."])
        outStr = NSLocalizedString(@"Connecting...", @"Connecting...");
    if ([outStr containsString:@"Fetching results="])
        outStr = NSLocalizedString(@"Fetching results",
                                   @"Fetching results");
    if ([outStr containsString:@"Looking for a match"])
        outStr = NSLocalizedString(@"Looking for a match", @"Looking for a match");
    if ([outStr containsString:@"Found a match"])
        outStr = NSLocalizedString(@"Found a match", @"Found a match");
    if ([outStr containsString:@"No match found"])
        outStr = NSLocalizedString(@"No match found", @"No match found");
    if ([outStr containsString:@"Success: Track downloaded"])
        outStr = NSLocalizedString(@"Track downloaded", @"Track downloaded");
    if ([outStr containsString:@"Failure: Nothing found"])
        outStr = NSLocalizedString(@"Nothing found", @"Nothing found");
    if ([outStr containsString:@"Failure: No internet connection"])
        outStr = NSLocalizedString(@"No internet connection",
                                   @"No internet connection");
    if ([outStr containsString:@"Failure: File already exists"])
        outStr = NSLocalizedString(@"File already exists",
                                   @"File already exists");
    if ([outStr containsString:@"Failure: Something went wrong"])
        outStr = NSLocalizedString(@"Something went wrong",
                                   @"Something went wrong");
    return outStr;
}

#pragma mark - Notifications

- (void)showNotificationWithTitle:(NSString *)title message:(NSString *)message {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = message;
    notification.soundName = NSUserNotificationDefaultSoundName;
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    [center deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
    if (self.success == 1) {
        [[NSWorkspace sharedWorkspace] openFile:appDelegate.savingDirectory withApplication:@"Finder"];
    }
}

@end