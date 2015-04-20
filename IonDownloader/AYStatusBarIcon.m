//
//  AYStatusBarIcon.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 1/30/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYStatusBarIcon.h"

NSTimer *animTimer;

@implementation AYStatusBarIcon

- (void)drawRect:(NSRect)rect {
    NSImage *iconImage;
    [[NSColor clearColor] set];
    if (!self.animating)
        iconImage = [NSImage imageNamed:@"StatusBarIcon"];
    else
        iconImage = [NSImage imageNamed:[NSString stringWithFormat:@"StatusBarIcon%ld",
                                                  (long)self.animationFrame]];
    [iconImage drawInRect:NSInsetRect(rect, 2, 2) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)event {
    [self.delegate statusBarClicked];
}

- (void)startAnimating {
    self.animating = YES;
    self.animationFrame = 0;
    // Create a timer and update the icon every 1/20 of a second
    animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
}

- (void)stopAnimating {
    [animTimer invalidate];
    self.animating = NO;
    // Redraw
    [self setNeedsDisplay:YES];
}

- (void)updateImage:(NSTimer*)timer {
    // We only have 16 frames, so iterate
    if (self.animationFrame == 16)
        self.animationFrame = 1;
    else
        self.animationFrame++;
    // Redraw
    [self setNeedsDisplay:YES];
}

@end