//
//  VKAuthWindiowController.m
//  MusicDownloader
//
//  Created by Ayan Yenbekbay on 2/4/15.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "VKAuthWindowController.h"

@implementation VKAuthWindowController

- (id)init {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *nibPath = [bundle pathForResource:@"VKAuthWindow" ofType:@"nib"];
    return [super initWithWindowNibPath:nibPath owner:self];
}

- (void)awakeFromNib {
    [self.webView setResourceLoadDelegate:self];
    [self.webView setPolicyDelegate:self];
    [self.webView setFrameLoadDelegate:self];
    
    [self.spinner startAnimation:self];
    if ([self.delegate isSignedIn]) {
        [self.signOutButton setHidden:NO];
        [self.signOutButton sizeToFit];
    }

    const NSTimeInterval kJanuary2015 = 1420070400;
    BOOL isDateValid = ([[NSDate date] timeIntervalSince1970] > kJanuary2015);
    if (isDateValid) {
        // start the asynchronous load of the sign-in web page
        [[self.webView mainFrame] performSelector:@selector(loadRequest:)
                                   withObject:self.initialRequest
                                   afterDelay:0.01
                                      inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    } else {
        NSString *htmlTemplate = @"<html><body><div align=center><font size='7'>"
          "&#x231A; ?<br><i>System Clock Incorrect</i><br>%@"
          "</font></div></body></html>";
        NSString *errHTML = [NSString stringWithFormat:htmlTemplate, [NSDate date]];
        [[self.webView mainFrame] loadHTMLString:errHTML baseURL:nil];
    }
}

#pragma mark -

- (void)open:(NSWindow *)parentWindowOrNil
     request:(NSURLRequest *)request {
    self.preferencesWindow = parentWindowOrNil;
    if (request != nil) {
        // display the request
        self.initialRequest = request;
        if (self.preferencesWindow) {
            [self.preferencesWindow beginSheet:[self window]
                    completionHandler:^(NSModalResponse returnCode){
                        [[self window] orderOut:self];
                        self.preferencesWindow = nil;
                    }];
        } else {
            // modeless
            [self showWindow:self];
        }
    }
}

- (IBAction)close:(id)sender {
    [self destroyWindow];
}

- (IBAction)signOut:(id)sender {
    [self.delegate signOut];
}

- (void)destroyWindow {
    // no request; close the window (but not immediately, in case
    // we're called in response to some window event)
    [[self webView] stopLoading:nil];

    if (self.preferencesWindow) {
        [self.preferencesWindow endSheet:[self window]];
    } else {
        [[self window] performSelector:@selector(close)
                            withObject:nil
                            afterDelay:0.1
                               inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
  }
}

#pragma mark -

- (void)webView:(WebView *)webView
decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id<WebPolicyDecisionListener>)listener {
    // default behavior is to open the URL in NSWorkspace's default browser
    NSURL *url = [request URL];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [listener ignore];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (!self.isActive) {
        [self.spinner stopAnimation:self];
        self.isActive = YES;
        NSURL *URL = [[[frame dataSource] request] URL];
        [self checkRedirect:URL];
    }
}

- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
    [self checkRedirect:URL];
}

- (void)checkRedirect:(NSURL *)URL {
    NSString *urlString = [URL absoluteString];
    if ([urlString rangeOfString:@"oauth.vk.com/blank.html#"].location != NSNotFound) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"];
        [self.spinner startAnimation:self];
        [self performSelector:@selector(makeRequests) withObject:self afterDelay:2.0];
    }
}

- (void)makeRequests {
    NSString *urlString = [self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    [self destroyWindow];
    NSMutableDictionary *queryStringDictionary = [self breakUrl:urlString];
    NSString *accessToken = [queryStringDictionary objectForKey:@"access_token"];
    NSString *userId =[queryStringDictionary objectForKey:@"user_id"];
    NSString *userName = [self getNameWithUserId:userId accessToken:accessToken];
    NSString *error =[queryStringDictionary objectForKey:@"error"];
    NSString *errorDesc =[queryStringDictionary objectForKey:@"error_description"];
    if (accessToken != nil) {
        [self.delegate setDefault:accessToken
                           userId:userId
                         userName:userName];
    } else if (error != nil) {
        NSLog(@"Error: %@", [errorDesc stringByReplacingOccurrencesOfString:@"+" withString:@" "]);
    }
}

- (NSString *)getNameWithUserId:(NSString *)userId accessToken:(NSString *)accessToken {
    NSString *requestString = [NSString stringWithFormat: @"https://api.vk.com/method/users.get?uids=%@&fields=first_name,last_name&lang=%@", userId, [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:requestString]];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&responseCode
                                                     error:nil];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                             options: kNilOptions
                                             error: nil];
    NSMutableDictionary *response = [[[json valueForKey:@"response"] objectAtIndex:0] mutableCopy];
    NSString *name = [NSString stringWithFormat:@"%@ %@", [response objectForKey:@"first_name"], [response objectForKey:@"last_name"]];
    return name;
}

- (NSMutableDictionary *)breakUrl:(NSString *)urlString {
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    urlString = [urlString stringByReplacingOccurrencesOfString:@"#" withString:@"&"];
    NSArray *urlComponents = [urlString componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        [queryStringDictionary setObject:value forKey:key];
    }
    return queryStringDictionary;
}

@end