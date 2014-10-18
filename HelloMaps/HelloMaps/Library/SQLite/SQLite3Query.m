//
//  SQLite3Query.m
//  iAround
//
//  Created by d.tuhtamanov on 6/7/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import "SQLite3Query.h"
#import "SQLite3Database.h"

@interface SQLite3Query ()

- (void)bindArguments;
- (void)clearColumnNameInfo;
- (void)updateColumnNameInfo;

@end

@implementation SQLite3Query

#pragma mark - Class life cycle
- (id)initWithSQLite3Database:(SQLite3Database *)db sqlQuery:(NSString *)sqlQuery args:(id)args
{
    self = [super init];
    if (self) {
        int result = sqlite3_prepare_v2(db.db, [sqlQuery UTF8String], -1, &stmt, NULL);
        if (result == SQLITE_OK) {
            _sql = sqlQuery;
            self.bindArgs = args;
            [self bindArguments];
            rowNumber = 0;
            columnNameInfo = [[NSMutableDictionary alloc] init];
            isNeedToUpdateColumnNameInfo = YES; 
        } else {
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    sqlite3_finalize(stmt);
    columnNameInfo = nil;
    self.bindArgs = nil;
    _sql = nil;
}

#pragma mark - Private methods
- (void)bindArg:(id)arg atIndex:(int)index
{
    if (!arg) {
        return;
    }
    
    if ([arg isKindOfClass:[NSString class]]) {
        sqlite3_bind_text(stmt, index, [arg UTF8String], -1, NULL);
    } else if ([arg isKindOfClass:[NSNumber class]]) {
        if (strcmp([arg objCType], @encode(int)) == 0) {
            sqlite3_bind_int64(stmt, index, [arg longValue]);
        } else if (strcmp([arg objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(stmt, index, [arg longValue]);
        } else if (strcmp([arg objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(stmt, index, [arg longLongValue]);
        } else if (strcmp([arg objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(stmt, index, (long long)[arg unsignedLongLongValue]);
        } else if (strcmp([arg objCType], @encode(float)) == 0) {
            sqlite3_bind_double(stmt, index, [arg floatValue]);
        } else if (strcmp([arg objCType], @encode(double)) == 0) {
            sqlite3_bind_double(stmt, index, [arg doubleValue]);
        } else if (strcmp([arg objCType], @encode(BOOL)) == 0 ||
                   (arg == (void*)kCFBooleanFalse || arg == (void*)kCFBooleanTrue)) {
            sqlite3_bind_int(stmt, index, ([arg boolValue] ? 1 : 0));
        }
    } else if ([arg isKindOfClass:[NSDate class]]) {
        sqlite3_bind_double(stmt, index, [arg timeIntervalSince1970]);
    } else if ([arg isKindOfClass:[NSData class]]) {
        const void * bytes = [arg bytes];
        if (!bytes) {
            sqlite3_bind_null(stmt, index);
        } else {
            sqlite3_bind_blob(stmt, index, bytes, (int)[arg length], SQLITE_STATIC);
        }
    } else if ([arg isKindOfClass:[NSNull class]]) {
        sqlite3_bind_null(stmt, index);
    } else {
        sqlite3_bind_text(stmt, index, [arg UTF8String], -1, NULL);
    }
}

- (void)bindArguments
{
    if (!self.bindArgs) {
        return;
    }
    
    int bindArgsCount = sqlite3_bind_parameter_count(stmt);
    if ([self.bindArgs isKindOfClass:[NSDictionary class]]) {
        for (int i = 1; i <= bindArgsCount; i++) {
            NSString * paramKey = [[NSString stringWithUTF8String:sqlite3_bind_parameter_name(stmt, i)] stringByReplacingOccurrencesOfString:@":" withString:@""];
            id param = self.bindArgs[paramKey];
            if (param) {
                [self bindArg:param atIndex:i];
            } else {
                [self bindArg:[NSNull null] atIndex:i];
//#ifdef DEBUG
//                [NSException raise:NSInvalidArgumentException format:@"Ошибка! Не найден параметр биндинга для ключа : %@ sql : %@ args : %@", paramKey, _sql, self.bindArgs];
//#endif
            }
        }
    } else {
        
        if (bindArgsCount != [self.bindArgs count]) {
#ifdef DEBUG
            [NSException raise:NSInvalidArgumentException format:@"Ошибка! Кол-во параметров в запросе - %d не совпадает с кол-во параметров для биндинга - %lu", bindArgsCount, (unsigned long)[self.bindArgs count]];
#endif
        }
        
        int index = 1;
        for (id arg in self.bindArgs) {
            [self bindArg:arg atIndex:index];
            index++;
        }
    }
}

- (void)clearColumnNameInfo
{
    isNeedToUpdateColumnNameInfo = YES;
    [columnNameInfo removeAllObjects];
}

- (void)updateColumnNameInfo
{
    if (isNeedToUpdateColumnNameInfo) {
        
        [self clearColumnNameInfo];
        isNeedToUpdateColumnNameInfo = NO;
        
        int columnCount = sqlite3_column_count(stmt);
        for (int columnIndex = 0; columnIndex < columnCount; columnIndex++) {
            [columnNameInfo setObject:[NSNumber numberWithInt:columnIndex]
                               forKey:[[NSString stringWithUTF8String:sqlite3_column_name(stmt, columnIndex)] lowercaseString]];
        }
        
    }
}

#pragma mark - Properties
- (void)setBindArgs:(id)bindArgs
{
    if ([bindArgs isKindOfClass:[NSArray class]] ||
        [bindArgs isKindOfClass:[NSDictionary class]] ||
        bindArgs == nil) {
        _bindArgs = bindArgs;
    } else {
#ifdef DEBUG
        [NSException raise:NSInvalidArgumentException
                    format:@"Ошибка! Параметрами для биндинга может быть объект класса NSDictionaty или NSArray. Текущий параметр : %@", bindArgs];
#endif
    }
}
                 
#pragma mark - Public methods
- (void)requery
{
    [self reset];
    sqlite3_clear_bindings(stmt);
    [self bindArguments];
}

- (BOOL)step
{
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        rowNumber++;
        [self updateColumnNameInfo];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)execute
{
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE)
        NSLog(@"Error executing query: %@, args: %@, errorCode: %d", _sql, self.bindArgs, result);
    return result == SQLITE_DONE;
}

- (void)reset
{
    rowNumber = 0;
    [self clearColumnNameInfo];
    sqlite3_reset(stmt);
}

- (NSString *)stringForColumnIndex:(NSInteger)column
{
    if (sqlite3_column_type(stmt, (int)column) != SQLITE_NULL && column >= 0) {
        return [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, (int)column)];
    } else {
        return nil;
    }
}

- (NSString *) stringForColumnName: (NSString *) columnName
{
    NSString * columnIndex = columnNameInfo[[columnName lowercaseString]];
    if (columnIndex) {
        return [self stringForColumnIndex:[columnIndex intValue]];
    } else {
        return nil;
    }
}

- (NSNumber *)numberForColumnIndex:(NSInteger)column
{
    if (sqlite3_column_type(stmt, (int)column) != SQLITE_NULL && column >= 0) {
        return [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, (int)column)];
    } else {
        return nil;
    }
}

- (NSNumber *)numberForColumnName:(NSString *)columnName
{
    NSNumber * columnIndex = [columnNameInfo objectForKey:[columnName lowercaseString]];
    if (columnIndex) {
        return [self numberForColumnIndex:[columnIndex intValue]];
    } else {
        return nil;
    }
}

- (NSDate *)dateForColumnIndex:(NSInteger)column
{
    if (sqlite3_column_type(stmt, (int)column) != SQLITE_NULL && column >= 0) {
        return [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmt, (int)column)];
    } else {
        return nil;
    }
}

- (NSData *)dataForColumnIndex:(NSInteger)columnIndex
{
    if (sqlite3_column_type(stmt, (int)columnIndex) == SQLITE_NULL || (columnIndex < 0)) {
        return nil;
    }
    int dataSize = sqlite3_column_bytes(stmt, (int)columnIndex);
    NSMutableData * data = [NSMutableData dataWithLength:(NSUInteger)dataSize];
    memcpy([data mutableBytes], sqlite3_column_blob(stmt, (int)columnIndex), dataSize);
    return data;
}

- (id)objectForColumnIndex:(int)columnIndex
{
    int columnType = sqlite3_column_type(stmt, columnIndex);
    if (columnType == SQLITE_INTEGER) {
        return [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, columnIndex)];
    } else if (columnType == SQLITE_FLOAT) {
        return [NSNumber numberWithDouble:sqlite3_column_double(stmt, columnIndex)];
    } else if (columnType == SQLITE_BLOB) {
        return [self dataForColumnIndex:columnIndex];
    } else if (columnType == SQLITE_TEXT) {
        return [self stringForColumnIndex:columnIndex];
    } else {
        return nil;
    }
}

- (NSMutableDictionary *)resultDictionary
{
    NSUInteger numberOfColumns = (NSUInteger)sqlite3_data_count(stmt);
    if (numberOfColumns > 0) {
        NSMutableDictionary * result = [NSMutableDictionary dictionaryWithCapacity:numberOfColumns];
        for (int index = 0; index < numberOfColumns; index++) {
            NSString * columnName = [NSString stringWithUTF8String:sqlite3_column_name(stmt, index)];
            id objectValue = [self objectForColumnIndex:index];
            if (objectValue) {
                [result setObject:objectValue forKey:columnName];
            }
        }
        return result;
    }
    else {
        NSLog(@"Warning: There seem to be no columns in this set.");
    }
    
    return nil;
}

- (NSInteger)getRowNumber
{
    return rowNumber;
}

@end
