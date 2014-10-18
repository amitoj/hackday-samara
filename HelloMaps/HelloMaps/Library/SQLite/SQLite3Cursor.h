//
//  SQLite3Cursor.h
//  iAround
//
//  Created by d.tuhtamanov on 6/7/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SQLite3Database;
@class SQLite3Query;
@class SQLite3CursorWindow;

@interface SQLite3Cursor : NSObject
{
@protected
    /** количество записей в базе*/
    NSInteger count;
    
    /** база данных */
    SQLite3Database * db;
    
    /** запрос к базе данных */
    SQLite3Query * query;
        
    /** Окно курсора */
    SQLite3CursorWindow * window;
}
@property (nonatomic, readonly, getter = getCount) NSUInteger count;
@property (nonatomic) NSString * cursorDescription;

/**
 * Возвращает курсор для указанной БД и запроса, с указанным размером окна
 * @param db - БД, из которой берутся ланные
 * @param query - запрос к БД
 * @param windowSize - размер окна курсора
 * @return курсор
 */
- (id)initWithSQLite3Database:(SQLite3Database *)db sqlite3Query:(SQLite3Query *)query windowSize:(NSUInteger)windowSize;

/**
 * Возвращает общее кол-во записей в курсоре
 * @return общее кол-во записей
 */
- (NSUInteger)getCount;

/**
 * Возвращает элемент по его индексу, если элемент отсутствует в текущем окне, то окно перезаполняется
 * @param index - индекс элемента
 * @return - элемент для этого индекса
 */
- (NSMutableDictionary *)itemAtIndex:(NSUInteger)index;

/**
 * Возвращает элемент по его индексу, без перезаполнения окна
 * @param index - индекс элемента
 * @return - элемент для этого индекса
 */
- (NSMutableDictionary *)singleItemAtIndex:(NSUInteger)index;

/**
 * Заново перезаполняет окно с пересчетом общего кол-ва элементов
 */
- (void)requery;

/** Просто перезаполняет окно */
- (void)reloadWindow;

/** Возвращает массив всех элементов курсора */
- (NSArray *)allItems;

/** Чтобы был доступ к элементу курсора через литералы [] */
- (NSMutableDictionary *)objectAtIndexedSubscript:(NSUInteger)idx;

@end
