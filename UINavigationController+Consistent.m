//
//  UINavigationController+Consistent.m
//  home
//
//  Created by MacUser on 4/30/14.
//
//

#import "UINavigationController+Consistent.h"
#import <objc/runtime.h>
/// This char is used to add storage for the isPushingViewController property.
static char const * const ObjectTagKey = "ObjectTag";

@interface UINavigationController ()
@property (readwrite,getter = isViewTransitionInProgress) BOOL viewTransitionInProgress;

@end

@implementation UINavigationController (Consistent)

- (void)setViewTransitionInProgress:(BOOL)property {
    NSNumber *number = [NSNumber numberWithBool:property];
    objc_setAssociatedObject(self, ObjectTagKey, number , OBJC_ASSOCIATION_RETAIN);
}


- (BOOL)isViewTransitionInProgress {
    NSNumber *number = objc_getAssociatedObject(self, ObjectTagKey);
    
    return [number boolValue];
}


#pragma mark - Intercept Pop, Push, PopToRootVC
/// @name Intercept Pop, Push, PopToRootVC

- (NSArray *)safePopToRootViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [self safePopToRootViewControllerAnimated:animated];

}


- (NSArray *)safePopToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [self safePopToViewController:viewController animated:animated];
}


- (UIViewController *)safePopViewControllerAnimated:(BOOL)animated {
    if (self.viewTransitionInProgress) return nil;
    if (animated) {
        self.viewTransitionInProgress = YES;
    }
    //-- This is not a recursion, due to method swizzling the call below calls the original  method.
    return [self safePopViewControllerAnimated:animated];
}



- (void)safePushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.delegate = self;
    //-- If we are already pushing a view controller, we dont push another one.
    if (self.isViewTransitionInProgress == NO) {
        //-- This is not a recursion, due to method swizzling the call below calls the original  method.
        [self safePushViewController:viewController animated:animated];
        if (animated) {
            self.viewTransitionInProgress = YES;
        }
    }
}


// This is confirmed to be App Store safe.
// If you feel uncomfortable to use Private API, you could also use the delegate method navigationController:didShowViewController:animated:.
- (void)safeDidShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //-- This is not a recursion. Due to method swizzling this is calling the original method.
    [self safeDidShowViewController:viewController animated:animated];
    self.viewTransitionInProgress = NO;
}


// If the user doesnt complete the swipe-to-go-back gesture, we need to intercept it and set the flag to NO again.
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> tc = navigationController.topViewController.transitionCoordinator;
    [tc notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.viewTransitionInProgress = NO;
        //--Reenable swipe back gesture.
        self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)viewController;
        [self.interactivePopGestureRecognizer setEnabled:YES];
    }];
    //-- Method swizzling wont work in the case of a delegate so:
    //-- forward this method to the original delegate if there is one different than ourselves.
    if (navigationController.delegate != self) {
        [navigationController.delegate navigationController:navigationController
                                     willShowViewController:viewController
                                                   animated:animated];
    }
}


+ (void)load {
    //-- Exchange the original implementation with our custom one.
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(pushViewController:animated:)), class_getInstanceMethod(self, @selector(safePushViewController:animated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(didShowViewController:animated:)), class_getInstanceMethod(self, @selector(safeDidShowViewController:animated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popViewControllerAnimated:)), class_getInstanceMethod(self, @selector(safePopViewControllerAnimated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:)), class_getInstanceMethod(self, @selector(safePopToRootViewControllerAnimated:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(popToViewController:animated:)), class_getInstanceMethod(self, @selector(safePopToViewController:animated:)));
}

@end