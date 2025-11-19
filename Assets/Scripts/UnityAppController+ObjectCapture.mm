#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "ObjectCaptureBridge.h"
#import <objc/message.h>

// Simple coordinator class to manage the capture state
@interface ObjectCaptureCoordinator : NSObject
@property (nonatomic, assign) BOOL isPresented;
+ (instancetype)shared;
- (void)startCapture;
@end

@implementation ObjectCaptureCoordinator

+ (instancetype)shared {
    static ObjectCaptureCoordinator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isPresented = NO;
    }
    return self;
}

- (void)startCapture {
    NSLog(@"[ObjectCapture] Coordinator startCapture called");
    self.isPresented = YES;
    
    // Show a simple alert as placeholder for Object Capture UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Object Capture"
                                                                       message:@"Object Capture UI would appear here"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *successAction = [UIAlertAction actionWithTitle:@"Simulate Success"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"[ObjectCapture] Simulated success");
            self.isPresented = NO;
        }];
        
        UIAlertAction *failureAction = [UIAlertAction actionWithTitle:@"Simulate Failure"
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"[ObjectCapture] Simulated failure");
            self.isPresented = NO;
        }];
        
        [alert addAction:successAction];
        [alert addAction:failureAction];
        
        UIViewController *rootVC = UnityGetGLViewController();
        if (rootVC) {
            [rootVC presentViewController:alert animated:YES completion:^{
                NSLog(@"[ObjectCapture] Alert presented");
            }];
        } else {
            NSLog(@"[ObjectCapture] ERROR: No root view controller found");
        }
    });
}

@end

@interface OCHosting : NSObject
+ (void)setupIfNeeded;
+ (void)startCapture;
@end

@implementation OCHosting

static BOOL initialized = NO;

+ (void)setupIfNeeded
{
  NSLog(@"[ObjectCapture] setupIfNeeded called");
  if (initialized) {
    NSLog(@"[ObjectCapture] Already initialized, returning");
    return;
  }
  initialized = YES;
  NSLog(@"[ObjectCapture] Initialization complete (using UIAlertController instead of SwiftUI)");
}

+ (void)startCapture
{
  NSLog(@"[ObjectCapture] startCapture called");
  [self setupIfNeeded];
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"[ObjectCapture] In main queue dispatch block");
    Class coordClass = NSClassFromString(@"ObjectCaptureCoordinator");
    NSLog(@"[ObjectCapture] ObjectCaptureCoordinator class: %@", coordClass);
    if (!coordClass) {
      NSLog(@"[ObjectCapture] ERROR: ObjectCaptureCoordinator class not found");
      return;
    }
    if (![coordClass respondsToSelector:@selector(shared)]) {
      NSLog(@"[ObjectCapture] ERROR: ObjectCaptureCoordinator doesn't respond to 'shared'");
      return;
    }
    id shared = ((id (*)(id, SEL))objc_msgSend)(coordClass, @selector(shared));
    NSLog(@"[ObjectCapture] Got shared instance: %@", shared);
    if (shared && [shared respondsToSelector:@selector(startCapture)]) {
      NSLog(@"[ObjectCapture] Calling startCapture on coordinator");
      ((void (*)(id, SEL))objc_msgSend)(shared, @selector(startCapture));
      NSLog(@"[ObjectCapture] startCapture called on coordinator");
    } else {
      NSLog(@"[ObjectCapture] ERROR: Shared instance doesn't respond to startCapture or is nil");
    }
  });
}

@end

void StartObjectCaptureNative(void)
{
  NSLog(@"[ObjectCapture] StartObjectCaptureNative called");
  [OCHosting startCapture];
  NSLog(@"[ObjectCapture] StartObjectCaptureNative finished");
}

#endif

