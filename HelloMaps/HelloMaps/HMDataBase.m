//
//  HMDataBase.m
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "HMDataBase.h"
#import "sqlite3_unicode.h"

#define AttachDBSQLString @"ATTACH '%s' AS %@;"
#define DetachDBSQLString @"DETACH DATABASE %@;"

#define HELLOMAPS_DB_VERSION 1
#define HELLOMAPS_DB_NAME @"hellomaps.db"

@interface SQLite3Database ()

- (void) loadCustomFunctional;

@end

@implementation HMDataBase

+ (instancetype)sharedInstance
{
    static HMDataBase * defaultDB = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isDbInitialized = [[NSFileManager defaultManager] fileExistsAtPath: [self dbFilePath]];
        defaultDB = [[HMDataBase alloc] initWithFileName: [self dbFilePath]];
        if (isDbInitialized)
        {
            if (![defaultDB checkVersion])
            {
                if (![defaultDB migrateToActual])
                {
                    defaultDB = nil;
                }
            }
        }
        else
        {
            if (![defaultDB migrateToActual])
            {
                defaultDB = nil;
            }
        }
        
    });
    return defaultDB;
}

- (id)initWithFileName:(NSString *)aFileName
{
    self = [super initWithFileName:aFileName];
    if (self) {
        [self executeQueryWithSQL:@"PRAGMA foreign_keys = ON;" args:nil];
    }
    return self;
}

+ (NSString *)cachesDirPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)documentDirPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)libraryDirPath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)databaseDirPath
{
    NSString *libraryDirPath = [self.class libraryDirPath];
    NSString *dbPath = [libraryDirPath stringByAppendingPathComponent:@"/database"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath])
    {
        NSError * error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:NO attributes:nil error:&error];
        if(error)
        {
            NSLog(@"Create database directory error: %@",error);
            dbPath = nil;
        }
    }
    return dbPath;
}

//! @override
+ (NSString *) dbFilePath
{
    return [[self databaseDirPath] stringByAppendingPathComponent: [self dbFileName]];
}

//! @override
+ (NSString *) dbFileName
{
    return HELLOMAPS_DB_NAME;
}

//! @override
- (NSInteger) actualUserVersion
{
    return HELLOMAPS_DB_VERSION;
}

#pragma mark - Private methods

/** Устанавливает текущую версию базы */
- (BOOL) setUserVersionTo: (NSInteger) version
{
    return [self executeQueryWithSQL: [NSString stringWithFormat:@"PRAGMA user_version = %ld;", (long)version]
                                args: nil];
}

- (void)loadCustomFunctional
{
    [super loadCustomFunctional];
    sqlite3_unicode_load();
}

- (void) dealloc
{
    sqlite3_unicode_free();
}

#pragma mark - Public methods

/** Проверяет текущую версию базы и сравнивает с актуальной в коде */
- (BOOL) checkVersion
{
    NSInteger userVersion = [self userVersion];
    return userVersion == [self actualUserVersion];
}

- (NSArray *)migrateSqlStatementsFromMigrateSqlString: (NSString*)migrateSqlString
{
    NSMutableArray * migrateSqlStatements = [NSMutableArray new];
    NSArray * parsedStatements = [migrateSqlString componentsSeparatedByString: @";\n"];
    for (NSString * statement in parsedStatements)
    {
        if (![statement isEqualToString:@""])
            [migrateSqlStatements addObject: statement];
    }
    return migrateSqlStatements;
}

- (BOOL) migrateToActual
{
    for (NSInteger version = [self userVersion] + 1; version <= [self actualUserVersion]; version++)
    {
        NSString *migrateVersionScriptPath = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"%@.%ld", [self.class dbSQLFileName], (long)version] ofType:@"sql"];
        NSError * migrateVersionScriptFileError = nil;
        NSString * migrateSqlString = [NSString stringWithContentsOfFile: migrateVersionScriptPath
                                                                encoding: NSUTF8StringEncoding
                                                                   error: &migrateVersionScriptFileError];
        if (!migrateVersionScriptFileError)
        {
            NSArray * migrateSqlStatements = [self migrateSqlStatementsFromMigrateSqlString:migrateSqlString];
            [self beginTransaction];
            for (NSString * migrateSqlStatement in migrateSqlStatements)
            {
                if (![self executeQueryWithSQL: migrateSqlStatement args: nil])
                {
                    [self rollbackTransaction];
                    return NO;
                }
            }
            [self setUserVersionTo: version];
            [self commitTransaction];
        }
        else
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL)attachDB:(HMDataBase *)database
{
    return [self attachDB:database as:[database.class dbFileName]];
}

- (BOOL)attachDB:(HMDataBase *)database as:(NSString *)dbName
{
    if (!database) {
        return NO;
    }
    NSString * sql = [NSString stringWithFormat:AttachDBSQLString, [[database.class dbFilePath] UTF8String], [dbName stringByDeletingPathExtension]];
    return [self executeQueryWithSQL:sql args:nil];
}

- (BOOL)detachDB:(HMDataBase *)database
{
    return [self detachDB:database withName:[database.class dbFileName]];
}

- (BOOL)detachDB:(HMDataBase *)database withName:(NSString *)dbName
{
    if (!database) {
        return NO;
    }
    NSString * sql = [NSString stringWithFormat:DetachDBSQLString, [dbName stringByDeletingPathExtension]];
    return [self executeQueryWithSQL:sql args:nil];
}

+ (NSString *) dbSQLFileName
{
    return [self dbFileName];
}

@end
