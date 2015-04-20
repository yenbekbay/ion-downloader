//
//  AYStatusBarIcon.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@protocol AYStatusBarIconDelegate <NSObject>

- (BOOL)isActive;
- (void)statusBarClicked;

@end

@interface AYStatusBarIcon : NSView

@property (nonatomic, weak) id<AYStatusBarIconDelegate> delegate;
@property BOOL animating;
@property NSInteger animationFrame;

- (void)startAnimating;
- (void)stopAnimating;

@end