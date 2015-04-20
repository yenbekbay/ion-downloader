//
//  AYAppDelegate.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYController.h"

@interface AYAppDelegate : NSObject <NSApplicationDelegate> {
    NSTimer * timer;
}

@property (nonatomic, strong) AYController *controller;
@property NSInteger minimumBitrate;
@property (weak) NSString *savingDirectory;
@property (weak) NSString *downloadsFolder;
@property (weak) NSString *accessToken;
@property (weak) NSString *userId;
@property (weak) NSString *userName;
@property NSInteger lookForMatches;
@property NSInteger applyTags;
@property NSInteger useWishlist;
@property NSInteger importsInstalled;
@property (weak) NSArray *wishlist;

@end