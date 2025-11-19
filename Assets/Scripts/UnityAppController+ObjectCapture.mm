#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "ObjectCaptureBridge.h"

void StartObjectCaptureNative(void)
{
    NSLog(@"[ObjectCapture] Starting Object Capture");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 17.0, *)) {
            // Get the Swift ObjectCaptureViewController class
            Class captureViewControllerClass = NSClassFromString(@"ObjectCaptureViewController");
            
            // Try with module prefix if not found
            if (!captureViewControllerClass) {
                captureViewControllerClass = NSClassFromString(@"UnityFramework.ObjectCaptureViewController");
            }
            
            if (captureViewControllerClass) {
                NSLog(@"[ObjectCapture] Found ObjectCaptureViewController class");
                // Create and present the Object Capture view controller
                UIViewController *captureVC = [[captureViewControllerClass alloc] init];
                UIViewController *rootVC = UnityGetGLViewController();
                
                if (rootVC && captureVC) {
                    captureVC.modalPresentationStyle = UIModalPresentationFullScreen;
                    [rootVC presentViewController:captureVC animated:YES completion:nil];
                } else {
                    NSLog(@"[ObjectCapture] ERROR: Failed to create or present view controller");
                }
            } else {
                NSLog(@"[ObjectCapture] ERROR: ObjectCaptureViewController class not found");
            }
        } else {
            // Show alert for unsupported iOS versions
            UIAlertController *alert = [UIAlertController 
                alertControllerWithTitle:@"Object Capture"
                message:@"Object Capture requires iOS 17.0 or later"
                preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction 
                actionWithTitle:@"OK"
                style:UIAlertActionStyleDefault
                handler:nil];
            
            [alert addAction:okAction];
            
            UIViewController *rootVC = UnityGetGLViewController();
            if (rootVC) {
                [rootVC presentViewController:alert animated:YES completion:nil];
            }
        }
    });
}

#endif

