//
//  VKAuth.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/3/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

@protocol VKAuthDelegate <NSObject>
- (void)setAuthLabelValue:(NSString *)str;
- (void)setAuthButtonValue:(NSString *)str;
- (void)adjustLabels;
@end

#import <Foundation/Foundation.h>
#import "VKAuthWindowController.h"

@interface VKAuth : NSObject <VKAuthWindowControllerDelegate>

@property id<VKAuthDelegate> delegate;
@property VKAuthWindowController *windowController;
@property BOOL isSignedIn;

- (void)signIn:(BOOL)new;
- (void)update;

@end
