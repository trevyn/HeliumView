//
//  EPSqlite.h
//  udptest
//
//  Created by Eden on 10/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

/// Simple wrapper class for sqlite3.

@interface EPSqlite : NSObject {
	sqlite3 *database;			///< The sqlite database object.
	sqlite3_stmt *statement;	///< The current compiled statement.
}

- (double)querySingleDouble:(NSString	*)theQuery, ...;

@end
