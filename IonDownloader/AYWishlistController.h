//
//  AYWishlistController.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/5/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface AYWishlistController : NSWindowController

@property (nonatomic) NSView *listView;

- (void)populateWindow;
- (void)addToWishlist:(NSString *)name;
- (void)removeFromWishlist:(NSString *)name;

@end
