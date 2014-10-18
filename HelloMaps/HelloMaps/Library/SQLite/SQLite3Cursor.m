//
//  SQLite3Cursor.m
//  iAround
//
//  Created by d.tuhtamanov on 6/7/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import "SQLite3Cursor.h"
#import "SQLite3Database.h"
#import "SQLite3Query.h"
#import "SQLite3CursorWindow.h"

#define NO_COUNT -1

@interface SQLite3Cursor ()

@end

@implementation SQLite3Cursor

@synthesize description = _description;

#pragma mark - Class life cycle
- (id)initWithSQLite3Database:(SQLite3Database *)dataBase sqlite3Query:(SQLite3Query *)aQuery windowSize:(NSUInteger)size
{
    self = [super init];
    if (self) {
        db = dataBase;
        query = aQuery;
        count = NO_COUNT;
        window = [[SQLite3CursorWindow alloc] initWithWindowSize:size];
        _cursorDescription = @"";
    }
    return self;
}

- (void)dealloc
{
    db = nil;
    query = nil;
    window = nil;
}

#pragma mark - Private methods
- (BOOL)moveCursorToPosition:(NSInteger)position
{
    BOOL result = NO;
    NSInteger rowNumber = [query getRowNumber];
    for (NSInteger i = rowNumber; i <= position; i++) {
        result = [query step];
    }
    return result;
}

- (void)updateCount
{
    count = [query getRowNumber];
    while ([query step]) {
        count++;
    }
    [query reset];
}

- (void)updateCountIfNeeded
{
    if (count == NO_COUNT) {
        [self updateCount];
    }
}

- (void)fillWindow:(SQLite3CursorWindow *)aWindow withStartPosition:(NSInteger)startPosition
{
#if DEBUG || DISTRIBUTION
    NSDate * date = [NSDate date];
#endif
    [aWindow clear];
    
    if (startPosition < 0) {
        startPosition = 0;
    }
    
    aWindow.startPosition = startPosition;
    if ([self moveCursorToPosition:aWindow.startPosition]) {
        [aWindow addItem:[query resultDictionary]];
        while (aWindow.count < aWindow.size && [query step]) {
            [window addItem:[query resultDictionary]];
        }
    }
    [self updateCountIfNeeded];
    [query reset];
#if DEBUG || DISTRIBUTION
    double time = - [date timeIntervalSinceNow];
#endif
}

#pragma mark - Public methods
- (NSUInteger)getCount
{
    if (count == NO_COUNT) {
        [self fillWindow:window withStartPosition:0];
    }
    return count;
}

- (NSMutableDictionary *)itemAtIndex:(NSUInteger)index
{
    if ([window containsItemWithIndex:index]) {
        return [window itemAtIndex:index];
    } else {
        if (index < window.startPosition) {
            [self fillWindow:window withStartPosition:index - (int)(window.size * 0.5)];
        } else {
            [self fillWindow:window withStartPosition:index];
        }
        return [window itemAtIndex:index];
    }
}

- (NSMutableDictionary *)singleItemAtIndex:(NSUInteger)index
{
    if ([window containsItemWithIndex:index]) {
        return [window itemAtIndex:index];
    } else {
        if ([self moveCursorToPosition:index]) {
            return [query resultDictionary];
        }
        return nil;
    }
}

- (void)requery
{
    [query requery];
    count = NO_COUNT;
    [self fillWindow:window withStartPosition:0];
}

- (void)reloadWindow
{
    [self fillWindow:window withStartPosition:window.startPosition];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"window.count = %lu, window = %@", (unsigned long)window.count, window];
}

- (NSArray *)allItems
{
    NSMutableArray * allItems = [NSMutableArray new];
    for (int i = 0; i < [self getCount]; i++) {
        [allItems addObject:[self itemAtIndex:i]];
    }
    return allItems;
}

- (NSMutableDictionary *)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [self itemAtIndex:idx];
}

@end
