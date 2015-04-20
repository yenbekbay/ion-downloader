//
//  AYPopoverController.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

@protocol AYPopoverDelegate <NSObject>

- (BOOL)isActive;
- (void)startAnimatingIcon;
- (void)stopAnimatingIcon;
- (void)closePopover;
- (void)addToWishlist:(NSString *)name;
- (void)removeFromWishlist:(NSString *)name;

@end

#import <Foundation/Foundation.h>
#import "AYMenuButton.h"
#import "AYWishlistController.h"

@interface AYPopoverController : NSViewController <NSUserNotificationCenterDelegate>

@property NSPopover *popover;
@property BOOL processing;
@property BOOL success;
@property (nonatomic, weak) NSString *query;
@property (setter = setSearchEnabled:) BOOL isSearchEnabled;
@property (nonatomic, weak) id<AYPopoverDelegate> delegate;
@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, weak) IBOutlet NSButton *searchButton;
@property (nonatomic, weak) IBOutlet AYMenuButton *menuButton;
@property (nonatomic, weak) IBOutlet NSTextField *status;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *spinner;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic, weak) IBOutlet NSImageView *successIcon;
@property (nonatomic, weak) IBOutlet NSImageView *failureIcon;

- (void)animateIn;
- (void)animateOut;

@end
