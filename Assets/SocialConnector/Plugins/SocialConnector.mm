//
//  SocialConnector.mm
//  Unity-iPhone
//
//  Created by Ando Keigo on 2012/12/08.
//
//
#if UNITY_VERSION <= 434
#import "iPhone_View.h"
#endif
#import <MessageUI/MessageUI.h>

extern "C" {
    
    @interface HXMailComposeViewDelegate : NSObject<MFMailComposeViewControllerDelegate>
@end
    @implementation HXMailComposeViewDelegate
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [UnityGetGLViewController() dismissViewControllerAnimated:YES completion:nil];
}
@end
    @interface SocialActivity : UIActivity
- (id)initWithTitle:(NSString *)title scheme:(NSString *)scheme imageName:(NSString *)imageName action:(id)myblock;
- (BOOL)isInstalled;
@end
    
    @implementation SocialActivity

NSString *_title;
NSString *_scheme;
NSString *_imageName;

void *(^_myblock)(void);

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (id)initWithTitle:(NSString *)title scheme:(NSString *)scheme imageName:(NSString *)imageName action:myblock {
    _title = title;
    _scheme = scheme;
    _imageName = imageName;
    _myblock = [myblock copy];
    return self;
}

- (BOOL)isInstalled {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:_scheme]];
}

- (NSString *)activityTitle {
    return _title;
}

- (UIImage *)_activityImage {
    if ([self isInstalled]) {
        return [UIImage imageNamed:_imageName];
    }
    else {
        return nil;
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
    
}

- (void)prepareWithActivityItems:(NSArray *)activityItems; {
    [super prepareWithActivityItems:activityItems];
}

- (UIViewController *)activityViewController {
    return nil;
}

- (void)performActivity {
    
    _myblock();
    
    [self activityDidFinish:YES];
}

- (void)activityDidFinish:(BOOL)completed {
    [super activityDidFinish:completed];
}
@end
    
    void SocialConnector_Mail (const char *to, const char *title, const char *message, const char *logfileUrl) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        auto path = [NSString stringWithCString:logfileUrl encoding:NSUTF8StringEncoding];
        auto basename = [[path componentsSeparatedByString:@"/"] lastObject];
        auto file = [NSData dataWithContentsOfFile:[NSString stringWithCString:logfileUrl encoding:NSUTF8StringEncoding]];
        [picker setToRecipients:@[[NSString stringWithCString:to encoding:NSUTF8StringEncoding]]];
        [picker addAttachmentData:file mimeType:@"text/plain" fileName:basename];
        [picker setSubject:[NSString stringWithCString:title encoding:NSUTF8StringEncoding]];
        [picker setMessageBody:[NSString stringWithCString:message encoding:NSUTF8StringEncoding] isHTML:false];
        auto del = [[HXMailComposeViewDelegate alloc] init];
        picker.mailComposeDelegate = del;
        [UnityGetGLViewController() presentViewController:picker animated:YES completion: nil];
    }
    
    void SocialConnector_Share(const char *text, const char *url, const char *textureURL) {
        
        NSString *_text = [NSString stringWithUTF8String:text ? text : ""];
        NSString *_url = [NSString stringWithUTF8String:url ? url : ""];
        NSString *_textureURL = [NSString stringWithUTF8String:textureURL ? textureURL : ""];
        
        UIImage *image = nil;
        
        if ([_textureURL length] != 0) {
            image = [UIImage imageWithContentsOfFile:_textureURL];
        }
        
        NSArray *actItems = [NSArray arrayWithObjects:_text, _url, image, nil];
        
        SocialActivity *social = [[[SocialActivity alloc] initWithTitle:@"LINE" scheme:@"line://" imageName:@"LINE" action:^() {
            
            NSString *contentType;
            NSString *contentKey;
            
            if ([_textureURL length] != 0) {
                UIImage *image = [UIImage imageWithContentsOfFile:_textureURL];
                if (image == nil) {
                    return;
                }
                
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.image = image;
                contentType = @"image";
                contentKey = pasteboard.name;
                
            } else if ([_text length] != 0) {
                contentType = @"text";
                contentKey = _text;
                
                if ([_url length] != 0) {
                    contentKey = [contentKey stringByAppendingFormat:@" - %@", _url];
                }
            }
            
            
            NSString *lineUrlString = [NSString stringWithFormat:@"line://msg/%@/%@", contentType, contentKey];
            
            lineUrlString = [lineUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:lineUrlString]];
            
        }] autorelease];
        
        NSArray *myItems = [NSArray arrayWithObjects:nil, nil];
        
        if (social.isInstalled) {
            myItems = [myItems arrayByAddingObject:social];
        }
        
        UIActivityViewController *activityView = [[[UIActivityViewController alloc] initWithActivityItems:actItems applicationActivities:myItems] autorelease];
        
        if(floorf(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
            activityView.popoverPresentationController.sourceView = UnityGetGLViewController().view;
        
        [UnityGetGLViewController() presentViewController:activityView animated:YES completion:nil];
    }
    
}
