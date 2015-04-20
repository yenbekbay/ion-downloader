#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "GeneralPreferencesViewController.h"
#import "AYAppDelegate.h"
#import "VKAuth.h"

static AYAppDelegate *appDelegate = nil;

@implementation GeneralPreferencesViewController

- (id)init {
    if (appDelegate == nil)
        appDelegate = (AYAppDelegate *)[[NSApplication sharedApplication] delegate];
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

- (void)awakeFromNib {
    [self adjustLabels];
    // Update the vk account
    self.vkAuth = [[VKAuth alloc] init];
    self.vkAuth.delegate = self;
    [self.vkAuth update];
    // Update the bitrate number
    [self.minBitrateStatus setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%ldkbps", @"{Bitrate Number}kbps"), (long)[[NSUserDefaults standardUserDefaults] integerForKey:@"minimumBitrate"]]];
    // Update the saving directory
    [self.savingDirectoryMenu setAutoenablesItems:NO];
    NSMenuItem *downloadsFolder = [self.savingDirectoryMenu itemAtIndex:0];
    NSMenuItem *customFolder = [self.savingDirectoryMenu itemAtIndex:1];
    if (![appDelegate.savingDirectory isEqualToString:appDelegate.downloadsFolder]) {
        [downloadsFolder setState:0];
        [self.savingDirectoryMenu removeItemAtIndex:0];
        [self.savingDirectoryMenu insertItem:downloadsFolder atIndex:0];
        [customFolder setTitle:[appDelegate.savingDirectory lastPathComponent]];
        [customFolder setState:1];
    }
    // Update checkboxes
    if ([appDelegate lookForMatches] == 0) {
        [self.lookForMatchesCheckbox setState:0];
        [self.applyTagsCheckbox setState:0];
        [self.applyTagsCheckbox setEnabled:NO];
    } else if ([appDelegate applyTags] == 0) {
        [self.applyTagsCheckbox setState:0];
    }
    if ([appDelegate useWishlist] == 0) {
        [self.useWishlistCheckbox setState:0];
    }
}

- (void)adjustLabels {
    NSArray *textFieldsArray = @[self.authLabel, self.minBitrateLabel, self.savingDirectoryLabel, self.matchingLabel, self.wishlistLabel];
    for (NSTextField *textField in textFieldsArray) {
        NSSize oldSize = textField.frame.size;
        [textField sizeToFit];
        NSPoint newPoint = NSMakePoint(textField.frame.origin.x - textField.frame.size.width + oldSize.width, textField.frame.origin.y);
        [textField setFrame:NSMakeRect(newPoint.x, newPoint.y,
                                       textField.frame.size.width, textField.frame.size.height)];
    }
}

- (IBAction)selectDirectory:(id)sender {
    NSWindow *window = appDelegate.controller.preferencesWindowController.window;
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    openPanel.title = NSLocalizedString(@"Choose a folder", @"Choose a folder");
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    
    [openPanel beginSheetModalForWindow:window
        completionHandler:^(NSInteger result) {
            if (result == 1) {
                NSURL *selection = openPanel.URLs[0];
                NSString* path = [selection.path stringByResolvingSymlinksInPath];
                NSString* theFolderName = [path lastPathComponent];
                [sender setTitle:theFolderName];
                [appDelegate setSavingDirectory:path];
            } else {
                [sender setState:0];
                [self.savingDirectoryMenu removeItemAtIndex:1];
                [self.savingDirectoryMenu insertItem:sender atIndex:1];
            }
        }];
}

- (IBAction)setDefaultDirectory:(id)sender {
    [appDelegate setSavingDirectory:appDelegate.downloadsFolder];
    [[self.savingDirectoryMenu itemAtIndex:1] setTitle:NSLocalizedString(@"Other", @"Other")];
}

#pragma mark - Connecting VK

- (IBAction)vkButtonClicked:(id)sender {
    if (!self.vkAuth.isSignedIn) {
        NSLog(@"Signing in with VK");
        [self.vkAuth signIn:NO];
    } else {
        [self.vkAuth signIn:YES];
    }    
}

- (void)setAuthLabelValue:(NSString *)str {
    [self.authLabel setStringValue:str];
}

- (void)setAuthButtonValue:(NSString *)str {
    [self.authButton setTitle:str];
    [self.authButton sizeToFit];
}

#pragma mark - Matches

- (IBAction)setLookForMatchesValue:(id)sender {
    if ([appDelegate lookForMatches] == 1) {
        [appDelegate setLookForMatches:0];
        [appDelegate setApplyTags:0];
        [self.applyTagsCheckbox setState:0];
        [self.applyTagsCheckbox setEnabled:NO];
    } else {
        [appDelegate setLookForMatches:1];
        [self.applyTagsCheckbox setEnabled:YES];
    }
}

- (IBAction)setApplyTagsValue:(id)sender {
    [appDelegate setApplyTags:self.applyTagsCheckbox.state];
}

- (IBAction)setUseWishlist:(id)sender {
    [appDelegate setUseWishlist:self.useWishlistCheckbox.state];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"General", @"General");
}

@end