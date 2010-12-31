//
//  testAppDelegate.h
//  test
//
//  Created by John Wang on 12/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class testViewController;

@interface testAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    testViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet testViewController *viewController;

@end

