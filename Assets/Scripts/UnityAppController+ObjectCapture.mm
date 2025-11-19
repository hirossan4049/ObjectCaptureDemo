#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#import "UnityAppController.h"
#import "ObjectCaptureBridge.h"
#import <objc/message.h>
#import <RealityKit/RealityKit.h>

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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 17.0, *)) {
            NSLog(@"[ObjectCapture] iOS 17+ detected, attempting to use Swift ObjectCaptureViewController");
            
            // Debug: List all registered classes containing "Capture"
            int numClasses = objc_getClassList(NULL, 0);
            Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
            objc_getClassList(classes, numClasses);
            
            NSLog(@"[ObjectCapture] Searching for Capture-related classes...");
            for (int i = 0; i < numClasses; i++) {
                const char *className = class_getName(classes[i]);
                if (strstr(className, "Capture") != NULL) {
                    NSLog(@"[ObjectCapture] Found class: %s", className);
                }
            }
            free(classes);
            
            // Try different naming patterns
            Class captureViewControllerClass = NSClassFromString(@"ObjectCaptureViewController");
            if (!captureViewControllerClass) {
                // Try with module prefix (Unity project name)
                captureViewControllerClass = NSClassFromString(@"ObjectCaptureDemo.ObjectCaptureViewController");
                NSLog(@"[ObjectCapture] Try with module prefix: %@", captureViewControllerClass);
            }
            if (!captureViewControllerClass) {
                // Try with underscore prefix
                captureViewControllerClass = NSClassFromString(@"_TtC17ObjectCaptureDemo26ObjectCaptureViewController");
                NSLog(@"[ObjectCapture] Try with mangled name: %@", captureViewControllerClass);
            }
            
            NSLog(@"[ObjectCapture] ObjectCaptureViewController class: %@", captureViewControllerClass);
            
            if (captureViewControllerClass) {
                // Create instance of ObjectCaptureViewController
                UIViewController *captureVC = [[captureViewControllerClass alloc] init];
                NSLog(@"[ObjectCapture] Created ObjectCaptureViewController: %@", captureVC);
                
                if (captureVC) {
                    UIViewController *rootVC = UnityGetGLViewController();
                    if (rootVC) {
                        [rootVC presentViewController:captureVC animated:YES completion:^{
                            NSLog(@"[ObjectCapture] Swift ObjectCaptureViewController presented");
                        }];
                    } else {
                        NSLog(@"[ObjectCapture] ERROR: No root view controller found");
                        [self fallbackToAlert];
                    }
                } else {
                    NSLog(@"[ObjectCapture] ERROR: Failed to create ObjectCaptureViewController instance");
                    [self fallbackToAlert];
                }
            } else {
                NSLog(@"[ObjectCapture] ERROR: ObjectCaptureViewController class not found");
                NSLog(@"[ObjectCapture] Make sure Swift file is included in Xcode project");
                [self fallbackToAlert];
            }
        } else {
            NSLog(@"[ObjectCapture] iOS version < 17.0, using fallback");
            [self fallbackToAlert];
        }
    });
}

- (void)fallbackToAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Object Capture"
                                                                   message:@"ObjectCaptureView requires iOS 17.0+"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"[ObjectCapture] Fallback alert dismissed");
        self.isPresented = NO;
    }];
    
    [alert addAction:okAction];
    
    UIViewController *rootVC = UnityGetGLViewController();
    if (rootVC) {
        [rootVC presentViewController:alert animated:YES completion:^{
            NSLog(@"[ObjectCapture] Fallback alert presented");
        }];
    }
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

