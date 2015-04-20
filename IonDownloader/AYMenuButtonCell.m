//
//  AYMenuButtonCell.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/2/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYMenuButtonCell.h"

@implementation AYMenuButtonCell

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp {
    // If menu defined show on left mouse
    if ([event type] == NSLeftMouseDown && [self menu]) {
        
        NSPoint result = [controlView convertPoint:NSMakePoint(NSMidX(cellFrame), NSMidY(cellFrame)) toView:nil];
        
        NSEvent *newEvent = [NSEvent mouseEventWithType: [event type]
                                               location: result
                                          modifierFlags: [event modifierFlags]
                                              timestamp: [event timestamp]
                                           windowNumber: [event windowNumber]
                                                context: [event context]
                                            eventNumber: [event eventNumber]
                                             clickCount: [event clickCount]
                                               pressure: [event pressure]];
        
        // Need to generate a new event otherwise selection of button
        // After menu display fails
        [NSMenu popUpContextMenu:[self menu] withEvent:newEvent forView:controlView];
        
        return YES;
    }
    
    return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

@end
