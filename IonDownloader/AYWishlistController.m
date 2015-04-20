//
//  AYWishlistController.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/5/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import "AYWishlistController.h"
#import "AYAppDelegate.h"

static AYAppDelegate *appDelegate;

@implementation AYWishlistController

- (id)init {
    // Create a small panel in the middle of the screen
    NSPanel* panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(600, 600, 0, 0)
                                                     styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [panel setTitle:NSLocalizedString(@"Wishlist", @"Wishlist")];
    appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    return [super initWithWindow:panel];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self populateWindow];
}

- (void)populateWindow {
    NSLog(@"Updating wishlist window");
    int height = 6;
    int width = 0;
    self.listView = [[NSView alloc] initWithFrame:self.window.frame];
    NSArray* wishlist = [appDelegate wishlist];
    if ([wishlist count] == 0) {
        NSTextField *placeholder = [[NSTextField alloc]
                                  initWithFrame:NSMakeRect(6, height, 0, 0)];
        [placeholder setStringValue:NSLocalizedString(@"You have no items in your wishlist",
                                                      @"You have no items in your wishlist")];
        [placeholder setBordered:NO];
        [placeholder setDrawsBackground:NO];
        [placeholder setEditable:NO];
        [placeholder sizeToFit];
        height += placeholder.frame.size.height + 6;
        width = placeholder.frame.size.width + 12;
        [self.listView addSubview:placeholder];
        [self resizeToSize:NSMakeSize(width, height)];
    } else {
        NSButton *clearButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, height, 0, 0)];
        [clearButton setTag:-1];
        [clearButton setAction:@selector(clearAll)];
        [clearButton setTitle:NSLocalizedString(@"Clear All", @"Clear All")];
        [clearButton setBezelStyle:1];
        [clearButton sizeToFit];
        [self.listView addSubview:clearButton];
        height += clearButton.frame.size.height + 12;
        for (int i = 0; i < (int)[wishlist count]; i++) {
            NSTextField *trackName = [[NSTextField alloc]
                                      initWithFrame:NSMakeRect(6, height, 0, 0)];
            [trackName setStringValue:wishlist[i]];
            [trackName setBordered:NO];
            [trackName setDrawsBackground:NO];
            [trackName setEditable:NO];
            [trackName setSelectable:YES];
            [trackName sizeToFit];
            NSButton *removeButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, height, trackName.frame.size.height, trackName.frame.size.height)];
            [removeButton setAction:@selector(removeItem:)];
            [removeButton setTag:i];
            [removeButton setImage:[NSImage imageNamed:@"RemoveIcon"]];
            [removeButton setBordered:NO];
            NSBox *separator = [[NSBox alloc] initWithFrame:NSMakeRect(0, height - 7, 0, 1)];
            [separator setBorderColor:[NSColor colorWithRed:0.47 green:0.47 blue:0.47 alpha:1]];
            [self.listView addSubview:trackName];
            [self.listView addSubview:separator];
            [self.listView addSubview:removeButton];
            height += trackName.frame.size.height + 12;
            if (trackName.frame.size.width > width) width = trackName.frame.size.width + 12;
        }
        [self resizeToSize:NSMakeSize(width + 24, height - 6)];
    }
}

- (void)resizeToSize:(NSSize)newSize {
    NSRect aFrame = [NSWindow contentRectForFrameRect:[self.window frame]
                                                styleMask:[self.window styleMask]];
    aFrame.origin.y += aFrame.size.height;
    aFrame.size.height = newSize.height - 22;
    aFrame.size.width = newSize.width;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame
                                         styleMask:[self.window styleMask]];
    for (NSView *subview in [self.listView subviews]) {
        if ([subview isKindOfClass:[NSBox class]]) {
            [subview setFrameSize:NSMakeSize(newSize.width, 1)];
        } else if ([subview isKindOfClass:[NSButton class]]) {
            if ([subview tag] == -1) {
                [subview setFrameOrigin:NSMakePoint((newSize.width - subview.frame.size.width) / 2, subview.frame.origin.y)];
            } else {
                [subview setFrameOrigin:NSMakePoint(newSize.width - 22, subview.frame.origin.y)];
            }
        }
    }
    [self.listView setFrame:aFrame];
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:aFrame];
    BOOL wantScroller = aFrame.size.height > 500;
    [scrollView setHasVerticalScroller:wantScroller];
    [scrollView setDocumentView:self.listView];
    [self.window setContentView:scrollView];
    NSPoint newScrollOrigin = NSMakePoint(0.0, NSMaxY([[self.window.contentView documentView] frame])
                                          -NSHeight([[self.window.contentView contentView] bounds]));
    [[self.window.contentView documentView] scrollPoint:newScrollOrigin];
    
    aFrame.size.height += 22;
    if (aFrame.size.height > 500) {
        aFrame.size.width += 12;
        aFrame.size.height = 500;
        aFrame.origin.y -= 478;
    } else {
        aFrame.origin.y -= newSize.height;
    }
    [self.window setFrame:aFrame display:YES animate:YES];
}

- (void)clearAll {
    [appDelegate setWishlist:nil];
    [self populateWindow];
}

- (void)addToWishlist:(NSString *)name {
    NSMutableArray *updatedWishlist = [NSMutableArray arrayWithArray:[appDelegate wishlist]];
    if ([updatedWishlist indexOfObject:name] == NSNotFound) {
        NSLog(@"Adding %@ to wishlist", name);
        [updatedWishlist addObject:name];
        [appDelegate setWishlist:updatedWishlist];
        [self populateWindow];
    }
}

- (IBAction)removeItem:(id)sender {
    [self removeFromWishlist:[[appDelegate wishlist] objectAtIndex:[sender tag]]];
}

- (void)removeFromWishlist:(NSString *)name {
    NSMutableArray *updatedWishlist = [NSMutableArray arrayWithArray:[appDelegate wishlist]];
    if ([updatedWishlist indexOfObject:name] != NSNotFound) {
        NSLog(@"Removing %@ from wishlist", name);
        [updatedWishlist removeObject:name];
        [appDelegate setWishlist:updatedWishlist];
        [self populateWindow];
    }
}

@end
