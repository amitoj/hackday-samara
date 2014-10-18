//
//  SQLite3Database.m
//  SQLite3CursorTest
//
//  Created by Dmitry Tuhtamanov on 11/2/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import "SQLite3Database.h"
#import "SQLite3Cursor.h"
#import "SQLite3Query.h"

@implementation SQLite3Database

@synthesize db, lastErrorMessage;

#pragma mark - Class life cycle
- (id)initWithFileName:(NSString *)aFileName
{
    self = [super init];
    if (self) {
        _fileName = aFileName;
        if (![self open])
            self = nil;
    }
    return self;
}

- (void)dealloc
{
    [self close];
    _fileName = nil;
}

#pragma mark - Private methods
- (void)loadCustomFunctional
{
    //
}

- (int) dbFlags
{
    return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX;
}

#pragma mark - Public methods

- (void) freeMemory
{
    sqlite3_db_release_memory(db);
}

- (NSInteger) userVersion
{
    SQLite3Query * query = [self queryWithSQL: [NSString stringWithFormat:@"PRAGMA user_version;"] args:nil];
    [query step];
    NSNumber * userVersionNumber = [query numberForColumnName: @"user_version"];
    [query reset];
    return [userVersionNumber intValue];
}

- (NSString *)lastErrorMessage
{
    return [NSString stringWithUTF8String:sqlite3_errmsg(db)];
}

- (NSInteger) lastInsertRowId
{
    return (NSInteger)sqlite3_last_insert_rowid(db);
}

- (SQLite3Cursor *)rawQueryWithSQL:(NSString *)sql args:(id)args windowSize:(NSUInteger)windowSize
{
    return [self rawQueryWithCursorClass:nil sql:sql args:args windowSize:windowSize];
}

- (SQLite3Cursor *)rawQueryWithCursorClass:(Class)cursorClass
                                       sql:(NSString *)sql
                                      args:(id)args
                                windowSize:(NSUInteger)windowSize
{
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    if (!cursorClass) {
        cursorClass = [SQLite3Cursor class];
    }
    SQLite3Cursor * cursor = [[cursorClass alloc] initWithSQLite3Database:self
                                                             sqlite3Query:query
                                                               windowSize:windowSize];
    [cursor getCount];
    return cursor;
}

- (SQLite3Query *)queryWithSQL:(NSString *)sql args:(id)args
{
    return [[SQLite3Query alloc] initWithSQLite3Database:self
                                                sqlQuery:sql
                                                    args:args];
}

- (BOOL)executeQueryWithSQL:(NSString *)sql args:(id)args
{
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    BOOL result = [query execute];
    [query reset];
    query = nil;
    sqlite3_db_release_memory(db);
    return result;
}

- (NSMutableArray *)arrayFromQueryWithSQL:(NSString *)sql args:(id)args
{
    NSMutableArray * result = [NSMutableArray new];
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    while ([query step]) {
        [result addObject:[query resultDictionary]];
    }
    [query reset];
    return result;
}

- (NSMutableDictionary *)dictionaryFromQueryWithSQL:(NSString *)sql args:(id)args
{
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    [query step];
    NSMutableDictionary * result = [query resultDictionary];
    [query reset];
    return result;
}

- (NSNumber *)numberFromQueryWithSQL:(NSString *)sql args:(id)args
{
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    [query step];
    NSNumber * result = [query numberForColumnIndex:0];
    [query reset];
    return result;
}

- (NSString *)stringFromQueryWithSQL:(NSString *)sql args:(id)args
{
    SQLite3Query * query = [self queryWithSQL:sql args:args];
    [query step];
    NSString * result = [query stringForColumnIndex:0];
    [query reset];
    return result;
}

- (BOOL)beginTransaction
{
    return sqlite3_exec(db, "BEGIN TRANSACTION;", 0, 0, 0) == SQLITE_OK;
}

- (BOOL)rollbackTransaction
{
    return sqlite3_exec(db, "ROLLBACK TRANSACTION;", 0, 0, 0) == SQLITE_OK;
}

- (BOOL)commitTransaction
{
    return sqlite3_exec(db, "COMMIT TRANSACTION;", 0, 0, 0) == SQLITE_OK;
}

- (BOOL)savePoint:(NSString *)savePointName
{
    NSString * sql = [NSString stringWithFormat:@"SAVEPOINT %@;", savePointName];
    return sqlite3_exec(db, [sql UTF8String], 0, 0, 0) == SQLITE_OK;
}

- (BOOL)releaseSavePoint:(NSString *)savePointName
{
    NSString * sql = [NSString stringWithFormat:@"RELEASE SAVEPOINT %@;", savePointName];
    return sqlite3_exec(db, [sql UTF8String], 0, 0, 0) == SQLITE_OK;
}

- (BOOL)rollbackTransactionToSavePoint:(NSString *)savePointName
{
    NSString * sql = [NSString stringWithFormat:@"ROLLBACK TRANSACTION TO SAVEPOINT %@;", savePointName];
    return sqlite3_exec(db, [sql UTF8String], 0, 0, 0) == SQLITE_OK;
}

- (BOOL) open
{
    [self loadCustomFunctional];
    BOOL openResult = (sqlite3_open_v2([_fileName UTF8String], &db, [self dbFlags], 0) == SQLITE_OK);
    if (!openResult)
    {
        NSLog(@"Failed to open db %@ : %@", _fileName.lastPathComponent, self.lastErrorMessage);
    }
    return openResult;
}

- (BOOL) close
{
    return sqlite3_close(db) == SQLITE_OK;
}

@end
