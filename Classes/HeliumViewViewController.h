//
//  HeliumViewViewController.h
//  HeliumView
//
//  Created by Eden on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPSqlite.h"

@interface HeliumViewViewController : UIViewController {
	UIView *outerView;
	IBOutlet UIScrollView *scrollView;
	
	
	double scaleFactor;
	double tileLayerScaleFactor;
	
	NSString *databaseName;
	NSString *databasePath;
	sqlite3 *database;
	
	double minLongitude;
	double maxLongitude;
	double minLatitude;
	double maxLatitude;
	
	double tileLayerMinLongitude;
	double tileLayerMaxLongitude;
	double tileLayerMinLatitude;
	double tileLayerMaxLatitude;
	
	EPSqlite *sqlite;
	CALayer *lastClosestLayer;
}

- (double)xFromLongitude: (double)longitude;
- (double)yFromLatitude: (double)latitude;

@end

