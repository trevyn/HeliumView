//
//  HeliumViewAppDelegate.h
//  HeliumView
//
//  Created by Eden on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HeliumViewViewController;

@interface HeliumViewAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HeliumViewViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HeliumViewViewController *viewController;

@end

