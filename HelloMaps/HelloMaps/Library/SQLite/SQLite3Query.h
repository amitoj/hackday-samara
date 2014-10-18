//
//  SQLite3Query.h
//  iAround
//
//  Created by d.tuhtamanov on 6/7/12.
//  Copyright (c) 2012 Parcsis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class SQLite3Database;

/** запрос к базе */
@interface SQLite3Query : NSObject
{
@protected
    /** оператор */
    sqlite3_stmt * stmt;
    
    /** Текущее положение в наборе данных */
    NSInteger rowNumber;
    
    /** Информация о названиях колонок и их индексы */
    NSMutableDictionary * columnNameInfo;
    
    /** Нужно ли обновлять информацию о колонках */
    BOOL isNeedToUpdateColumnNameInfo;
}

/** значения для связывания */
@property (nonatomic, strong) id bindArgs;

/** sql запроса */
@property (nonatomic, readonly) NSString * sql;

/**
 * @param db - SQLite3Database
 * @param sqlQuery - sql запрос
 * @param args - массив(NSArray) или словарь(NSDictionary) значений для связывания
 * @result SQLite3Query
 */
- (id)initWithSQLite3Database:(SQLite3Database *)db sqlQuery:(NSString *)sqlQuery args:(id)args;

/** берет следующую запись в таблице (только для Select)
 * @result есть ли еще записи
 */
- (BOOL)step;

/** берет следующую запись в таблице  (для всего кроме select)
 * @result завершено ли выполнение
 */
- (BOOL)execute;

/** сброс оператора в начальную позицию */
- (void)reset;

/** сброс оператора в начальную позицию, сброс и связывание значений */
- (void)requery;

/** возвращает строку из колонки
 * @param column - номер колонки
 * @result строка из указанной колонки
 */
- (NSString *)stringForColumnIndex:(NSInteger)column;

/** возвращает строку по имени колонки
 * @param column - имя колонки
 * @result строка из указанной колонки
 */
- (NSString *) stringForColumnName: (NSString *) columnName;

/** возвращает NSNumber из колонки
 * @param column - номер колонки
 * @result NSNumber из указанной колонки
 */
- (NSNumber *)numberForColumnIndex:(NSInteger)column;

/** возвращает NSNumber по имени колонки
 * @param columnName - имя колонки
 * @result NSNumber из указанной колонки
 */
- (NSNumber *)numberForColumnName:(NSString *)columnName;

/** возвращает NSDate из колонки
 * @param column - номер колонки
 * @result NSDate из указанной колонки
 */
- (NSDate *)dateForColumnIndex:(NSInteger)column;

/** возвращает NSData из колонки
 * @param column - номер колонки
 * @result NSData из указанной колонки
 */
- (NSData *)dataForColumnIndex:(NSInteger)columnIndex;

/** @result словарь: ключи - название колонок; значения - значения в колонках */
- (NSMutableDictionary *)resultDictionary;

/** Возвращает текущее положение в выборке */
- (NSInteger)getRowNumber;

@end
