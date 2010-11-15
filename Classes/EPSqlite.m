//
//  EPSqlite.m
//  udptest
//
//  Created by Eden on 10/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EPSqlite.h"

@implementation EPSqlite

#pragma mark -
#pragma mark Opening Databases
/// @name Opening Databases
/// @{

- (sqlite3 *)database {
	return database;
}

/// Open a SQLite database in read-only mode from the app's bundle.
- (void)openDatabaseFromBundleWithFilename:(NSString *)theFilename {
	
	sqlite3_config(SQLITE_CONFIG_SERIALIZED);
	
	// open database
		
	NSString *databasePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:theFilename];
	
	if(sqlite3_open_v2([databasePath UTF8String], &database, SQLITE_OPEN_READONLY, NULL) != SQLITE_OK) {
		NSLog(@"Error opening SQLite DB");
	}
	
}

/// Open a SQLite database from the app's Documents directory. 
- (void)openDatabaseFromDocumentsWithFilename:(NSString *)theFilename {
	sqlite3_config(SQLITE_CONFIG_SERIALIZED);
	
	// open database
	
	NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	NSString *databasePath = [docDir stringByAppendingPathComponent:theFilename];	
	
	if(sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
		NSLog(@"Error opening SQLite DB");
	}
	
}
/// @}
#pragma mark -
#pragma mark One-Shot SQL Execution
/// @name One-Shot SQL Execution
/// @{

/// Execute a stringWithFormat.
- (void)queryExec:(NSString	*)theQuery, ... {
	int retVal= 0;
	
	va_list ap;
	va_start (ap, theQuery);
	NSString *sqlString= [[NSString alloc] initWithFormat: theQuery arguments: ap];
	va_end (ap);
	
	sqlite3_stmt *compiledStatement;
	
	if(sqlite3_prepare_v2(database, [sqlString UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
//			retVal= sqlite3_column_int(compiledStatement, 0);
		}
	}
	sqlite3_finalize(compiledStatement);
	
	[sqlString release];
	
	return retVal;
	
}

/// Execute a stringWithFormat and return the first result of the first row as an int.
- (int)querySingleInt:(NSString	*)theQuery, ... {
	int retVal= 0;
	
	va_list ap;
	va_start (ap, theQuery);
	NSString *sqlString= [[NSString alloc] initWithFormat: theQuery arguments: ap];
	va_end (ap);
		
	sqlite3_stmt *compiledStatement;
	
	if(sqlite3_prepare_v2(database, [sqlString UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			retVal= sqlite3_column_int(compiledStatement, 0);
		}
	}
	sqlite3_finalize(compiledStatement);

	[sqlString release];

	return retVal;
	
}
	
/// Execute a stringWithFormat and return the first result of the first row as a NSString.
- (NSString *)querySingleString:(NSString	*)theQuery, ... {
	const char *text= nil;
	
	va_list ap;
	va_start (ap, theQuery);
	NSString *sqlString= [[NSString alloc] initWithFormat: theQuery arguments: ap];
	va_end (ap);
	
	sqlite3_stmt *compiledStatement;
	
	if(sqlite3_prepare_v2(database, [sqlString UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			text= sqlite3_column_text(compiledStatement, 0);
		}
	}
	
	NSString *retVal= [NSString stringWithUTF8String:text];
	
	sqlite3_finalize(compiledStatement);
	
	[sqlString release];
	
	return retVal;
	
}

/// Execute a stringWithFormat and return the first result of the first row as a double.
- (double)querySingleDouble:(NSString	*)theQuery, ... {
	double retVal;
	
	va_list ap;
	va_start (ap, theQuery);
	NSString *sqlString= [[NSString alloc] initWithFormat: theQuery arguments: ap];
	va_end (ap);
	
	sqlite3_stmt *compiledStatement;
	
	if(sqlite3_prepare_v2(database, [sqlString UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		if(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			retVal= sqlite3_column_double(compiledStatement, 0);
		}
	}
	
	sqlite3_finalize(compiledStatement);
	
	[sqlString release];
	
	return retVal;
	
}

/// @}
#pragma mark -
#pragma mark Compiled Statements
/// @name Compiled Statements
/// @{

// inspired by: http://code.google.com/p/google-toolbox-for-mac/source/browse/trunk/Foundation/GTMSQLite.m?r=80&spec=svn412

/// Create a new active statement with a parameterized SQL string.
- (int)statementInitWithSql:(NSString *)theSql {
	return sqlite3_prepare(database, [theSql UTF8String], -1, &statement, NULL);
}

- (int)statementPositionOfParameter:(NSString *)theParameter {
	if (!statement) return -1;
	return sqlite3_bind_parameter_index(statement, [theParameter UTF8String]);
}

/// Bind a double to the active statement.
- (int)statementBindToParameter:(NSString *)theParameter doubleValue:(double)theDouble {
	return sqlite3_bind_double(statement, [self statementPositionOfParameter:theParameter], theDouble);
}

/// Bind an NSString to the active statement.
- (int)statementBindToParameter:(NSString *)theParameter stringValue:(NSString *)theString {
	return sqlite3_bind_text(statement, [self statementPositionOfParameter:theParameter], [theString UTF8String], -1, SQLITE_TRANSIENT);
}

/// Execute the active statement.
- (int)statementExec {
	return sqlite3_step(statement);
}

/// Bind a double to the active statement.
- (int)statementBindDouble:(double)theDouble forParameter:(NSString *)theParameter {
	return sqlite3_bind_double(statement, [self statementPositionOfParameter:theParameter], theDouble);
}

/// Bind an NSString to the active statement.
- (int)statementBindString:(NSString *)theString forParameter:(NSString *)theParameter {
	return sqlite3_bind_text(statement, [self statementPositionOfParameter:theParameter], [theString UTF8String], -1, SQLITE_TRANSIENT);
}

///@}

//- (void)queryExec:(NSString *)theQuery withBlock:


@end
