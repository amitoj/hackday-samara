//
//  SQLite3Database.h
//  SQLite3CursorTest
//
//  Created by Dmitry Tuhtamanov on 11/2/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class SQLite3Cursor;
@class SQLite3Query;

/** Обертка над sqlite3 */
@interface SQLite3Database : NSObject
{
@protected
    /** база данных */
    sqlite3 * db;
}

/** путь к базе данных */
@property (nonatomic, readonly) NSString * fileName;

@property (nonatomic, readonly) sqlite3 * db;
@property (unsafe_unretained, nonatomic, readonly) NSString * lastErrorMessage;

/**
 * @param fileName - путь к базе данных
 * @result SQLite3Database
 */
- (id)initWithFileName:(NSString *)fileName;

/** возвращает курсор для базы
 * @param sql - запрос к базе
 * @param args - массив или словарь значений для связывания
 * @param windowSize - максимальное количество единоверменно загруженных записей
 * @result кусрор
 */
- (SQLite3Cursor *)rawQueryWithSQL:(NSString *)sql args:(id)args windowSize:(NSUInteger)windowSize;

/** возвращает курсор для базы
 * @param cursorClass - класс курсора
 * @param sql - запрос к базе
 * @param args - массив или словарь значений для связывания
 * @param windowSize - максимальное количество единоверменно загруженных записей
 * @result кусрор
 */
- (SQLite3Cursor *)rawQueryWithCursorClass:(Class)cursorClass
                                       sql:(NSString *)sql
                                      args:(id)args
                                windowSize:(NSUInteger)windowSize;

/**
 * Возвращает запрос к бд
 * @param sql - sql запроса
 * @param args - аргументы запроса
 * @return запрос к бд
 */
- (SQLite3Query *)queryWithSQL:(NSString *)sql args:(id)args;

/**
 * Выполняет sql запрос с аргументами
 * @param sql - sql запроса
 * @param args - аргументы запроса
 * @return успешность выполнения запроса
 */
- (BOOL)executeQueryWithSQL:(NSString *)sql args:(id)args;

- (NSMutableArray *)arrayFromQueryWithSQL:(NSString *)sql args:(id)args;
- (NSMutableDictionary *)dictionaryFromQueryWithSQL:(NSString *)sql args:(id)args;
- (NSNumber *)numberFromQueryWithSQL:(NSString *)sql args:(id)args;
- (NSString *)stringFromQueryWithSQL:(NSString *)sql args:(id)args;

/** Начать транзакцию */
- (BOOL)beginTransaction;

/** Откатить транзакцию */
- (BOOL)rollbackTransaction;

/** Закончить транзакцию */
- (BOOL)commitTransaction;

/** Начать транзакцию именем savePointName */
- (BOOL)savePoint:(NSString *)savePointName;

/** Закончить транакцию с именем savePointName */
- (BOOL)releaseSavePoint:(NSString *)savePointName;

/** Откатить транзакцию до точки сохранения  savePointName */
- (BOOL)rollbackTransactionToSavePoint:(NSString *)savePointName;

/** 
 * Открывает базу данных 
 * @return успешность открытия базы
 */
- (BOOL) open;

/** 
 * Закрывает базу данных 
 * @return успешность закрытия базы
 */
- (BOOL)close;

/**
 * Возращает версию базы в PRAGMA user_version
 */
- (NSInteger) userVersion;

/** 
 * Номер последней записи вставленной в БД
 */
- (NSInteger) lastInsertRowId;

- (void) freeMemory;

@end
