//
//  NSTask+PTY.h
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/9/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTask (PTY)

- (NSFileHandle *)masterSideOfPTYOrError:(NSError **)error;

@end
