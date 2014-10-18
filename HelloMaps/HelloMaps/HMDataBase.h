//
//  HMDataBase.h
//  HelloMaps
//
//  Created by Alexandr Khrulev on 18.10.14.
//  Copyright (c) 2014 hackday. All rights reserved.
//

#import "SQLite3Database.h"
#import "SQLite3Cursor.h"

@interface HMDataBase : SQLite3Database

+(instancetype)sharedInstance;

/** Полный путь к файлу с базой данных */
+ (NSString *) dbFilePath;

/** Имя файла базы данных */
+ (NSString *) dbFileName;

/** Проверяет текущую версию базы и сравнивает с актуальной в коде */
- (BOOL) checkVersion;

/** Выполняет миграцию базы до актуальной версии. Пример формата имени файла: local.db.1.sql */
- (BOOL) migrateToActual;

/** Приаттачивает к себе указанную бд */
- (BOOL)attachDB:(HMDataBase *)database;

/** Отключает указанную бд */
- (BOOL)detachDB:(HMDataBase *)database;

- (BOOL)attachDB:(HMDataBase *)database as:(NSString *)dbName;

- (BOOL)detachDB:(HMDataBase *)database withName:(NSString *)dbName;

@end
