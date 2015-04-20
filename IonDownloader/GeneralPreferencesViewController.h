#import <Foundation/Foundation.h>
#import "MASPreferencesViewController.h"
#import "VKAuth.h"

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController, VKAuthDelegate>

@property VKAuth* vkAuth;

@property (nonatomic, weak) IBOutlet NSTextField *authLabel;
@property (nonatomic, weak) IBOutlet NSButton *authButton;
@property (nonatomic, weak) IBOutlet NSTextField *minBitrateLabel;
@property (nonatomic, weak) IBOutlet NSTextField *minBitrateStatus;
@property (nonatomic, weak) IBOutlet NSTextField *savingDirectoryLabel;
@property (nonatomic, weak) IBOutlet NSMenu *savingDirectoryMenu;
@property (nonatomic, weak) IBOutlet NSTextField *matchingLabel;
@property (nonatomic, weak) IBOutlet NSButton *lookForMatchesCheckbox;
@property (nonatomic, weak) IBOutlet NSButton *applyTagsCheckbox;
@property (nonatomic, weak) IBOutlet NSTextField *wishlistLabel;
@property (nonatomic, weak) IBOutlet NSButton *useWishlistCheckbox;

@end