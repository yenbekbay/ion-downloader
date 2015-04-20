//
//  VKAuthWindiowController.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/4/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

@protocol VKAuthWindowControllerDelegate <NSObject>
- (void)signOut;
- (void)setDefault:(NSString *)accessToken
            userId:(NSString *)userId
          userName:(NSString *)userName;
- (BOOL)isSignedIn;
@end

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface VKAuthWindowController : NSWindowController

@property id<VKAuthWindowControllerDelegate> delegate;
@property (nonatomic, assign) IBOutlet WebView *webView;
@property (nonatomic, copy) NSURLRequest *initialRequest;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, weak) IBOutlet NSButton *signOutButton;
@property (strong) NSWindow *preferencesWindow;
@property BOOL isActive;

- (IBAction)close:(id)sender;
- (void)open:(NSWindow *)parentWindowOrNil
     request:(NSURLRequest *)request;
- (void)destroyWindow;

@end