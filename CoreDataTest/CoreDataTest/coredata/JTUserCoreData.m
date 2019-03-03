//
//  JTUserCoreData.m
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/2.
//  Copyright © 2019年 黄金台. All rights reserved.
//

#import "JTUserCoreData.h"

@interface JTUserCoreData ()

@property (nonatomic, strong) NSManagedObjectContext        *backgroundMOC;

@property (nonatomic, strong) NSPersistentContainer         *userPC  NS_AVAILABLE_IOS(10.0);

@end

static JTUserCoreData *__user = nil;

@implementation JTUserCoreData

+ (instancetype)shareUser
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __user = [[JTUserCoreData alloc] init];
    });
    return __user;
}

#pragma mark =========================== lazy load ===========================

- (NSPersistentContainer *)userPC NS_AVAILABLE_IOS(10.0)
{
    if (!_userPC) {
        _userPC = [NSPersistentContainer persistentContainerWithName:@"coredata"];
        [_userPC loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
            if (error) {
                NSLog(@"创建数据失败: %@", error);
            } else {
                NSLog(@"创建数据库成功: %@", description);
            }
        }];
    }
    return _userPC;
}

- (NSManagedObjectModel *)userMOM
{
    if (!_userMOM) {
        if (@available(ios 10.0, *)) {
            _userMOM = self.userPC.managedObjectModel;
        } else {
            _userMOM = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
    }
    return _userMOM;
}

- (NSPersistentStoreCoordinator *)userPSC
{
    if (!_userPSC) {
        if (@available(ios 10.0, *)) {
            _userPSC = self.userPC.persistentStoreCoordinator;
        }
        else {
            _userPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.userMOM];
            NSString *dbpath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"coredata.sqlite"];
            NSURL *dbUrl = [NSURL URLWithString:[dbpath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                     [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
            NSError *dbError = nil;
            [_userPSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:dbUrl options:options error:&dbError];
            if (dbError) {
                NSLog(@"创建数据库失败: %@", dbError);
            } else {
                NSLog(@"创建数据库成功: %@", dbUrl);
            }
        }
    }
    return _userPSC;
}

- (NSManagedObjectContext *)userMOC
{
    if (!_userMOC) {
        if (@available(ios 10.0, *)) {
            _userMOC = self.userPC.viewContext;
        }
        else {
            // 主线程context
            _userMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _userMOC.persistentStoreCoordinator = self.userPSC;
        }
    }
    return _userMOC;
}

- (NSManagedObjectContext *)backgroundMOC
{
    if (!_backgroundMOC) {
        _backgroundMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        // 设置为主context的子context
        _backgroundMOC.parentContext = self.userMOC;
    }
    return _backgroundMOC;
}

#pragma mark =========================== operation ===========================

/**
 * @brief 批量插入
 * @param userInfo user数据
 * @param block 删除回调
 */
- (void)batchInsert:(NSArray <NSDictionary *> *)userInfo
        complection:(UserBatchInsertBlock)block
{
    if (JTIsEmptyArray(userInfo)) {
        NSLog(@"插入失败, userInfo为空");
        if (block) block (NO, nil);
        return;
    }
    
    [self.backgroundMOC performBlock:^{
        __block NSMutableArray <User *> *userList = @[].mutableCopy;
        [userInfo enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.backgroundMOC];
            user.userId = obj[@"userId"];
            user.avatar = obj[@"avatar"];
            user.name = obj[@"name"];
            user.age = [obj[@"age"] intValue];
            user.sex = obj[@"sex"];
            user.remark = obj[@"remark"];
            user.index = obj[@"index"];
            // 添加到数组
            [userList addObject:user];
        }];
        // 保存
        [self.backgroundMOC save:nil];
        
        // 到主线程执行保存（因为userMOC是主线程context）
        [self.userMOC performBlock:^{
            NSError *error = nil;
            if ([self.userMOC save:&error]) {
                NSLog(@"批量插入成功");
                if (block) block (YES, userList);
            } else {
                NSLog(@"批量插入失败: %@", error);
                if (block) block (NO, nil);
            }
        }];
    }];
}

/**
 * @brief 批量删除
 * @param predicate 筛选条件
 * @param block 删除回调
 */
- (void)batchDetele:(NSString * _Nullable)predicate complection:(UserBatchDeleteBlock)block
{
    if (JTIsEmptyString(predicate)) {
        NSLog(@"predicate为空, 将批量删除所有user");
    }
    
    [self.backgroundMOC performBlock:^{
        NSFetchRequest *request = [User fetchRequest];
        if (predicate) {
            @try {
                request.predicate = [NSPredicate predicateWithFormat:@"%@", predicate];
            } @catch (NSException *exception) {
                NSLog(@"exception: %@", exception);
            } @finally {
                request.predicate = nil;
            }
        }
        NSArray <User *> * list = [self.backgroundMOC executeFetchRequest:request error:nil];
        [list enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.backgroundMOC deleteObject:obj];
        }];
        // 保存
        @try {
            [self.backgroundMOC save:nil];
        }
        @catch (NSException *exception) {
            NSLog(@"exception: %@", exception);
        }
        @finally {
            // 到主线程执行保存（因为userMOC是主线程context）
            [self.userMOC performBlock:^{
                NSError *error = nil;
                if ([self.userMOC save:&error]) {
                    NSLog(@"批量删除成功");
                    if (block) block (YES);
                } else {
                    NSLog(@"批量删除失败: %@", error);
                    if (block) block (NO);
                }
            }];
        }
    }];
}

/**
 * @brief 批量更新
 * @param predicate 筛选条件
 * @param updateInfo 更新数据
 * @param block 删除回调
 */
- (void)batchUpdate:(NSString *)predicate
         updateInfo:(NSDictionary <NSString *, id> *)updateInfo
        complection:(UserBatchUpdateBlock)block
{
    if (JTIsEmptyDictionary(updateInfo)) {
        NSLog(@"updateInfo为空，没有更新目的");
        if (block) block (NO, nil);
        return;
    }
    
    if (JTIsEmptyString(predicate)) {
        NSLog(@"predicate为空，将更新所有用户");
    }
    
    if (@available(ios 10.0, *)) {
        
        [self.userPC performBackgroundTask:^(NSManagedObjectContext * _Nonnull context) {
            
            NSFetchRequest *request = [User fetchRequest];
            if (predicate) {
                @try {
                    request.predicate = [NSPredicate predicateWithFormat:@"%@", predicate];
                } @catch (NSException *exception) {
                    NSLog(@"exception: %@", exception);
                } @finally {
                    request.predicate = nil;
                }
            }
            NSBatchUpdateRequest *updateRequest = [[NSBatchUpdateRequest alloc] initWithEntityName:@"User"];
            updateRequest.resultType = NSUpdatedObjectIDsResultType;
            updateRequest.propertiesToUpdate = updateInfo;
            NSError *updateError = nil;
            NSBatchUpdateResult *result = [context executeRequest:updateRequest error:&updateError];
            
            [context refreshAllObjects];
            // 同步主线程数据
            [self.userMOC performBlock:^{
                [self.userMOC refreshAllObjects];
                
                if (!updateError) {
                    NSLog(@"更新成功");
                    NSArray <NSManagedObjectID *> * resultArray = result.result;
                    __block NSMutableArray <NSManagedObject *> *updateList = @[].mutableCopy;
                    [resultArray enumerateObjectsUsingBlock:^(NSManagedObjectID * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        User *user = [context objectWithID:obj];
                        [updateList addObject:user];
                    }];
                    if (block) block (YES, updateList);
                } else {
                    NSLog(@"更新失败: %@", updateError);
                    if (block) block (NO, nil);
                }
            }];
        }];
    }
    else {
        [self.backgroundMOC performBlock:^{
            NSFetchRequest *request = [User fetchRequest];
            if (predicate) {
                @try {
                    request.predicate = [NSPredicate predicateWithFormat:@"%@", predicate];
                } @catch (NSException *exception) {
                    NSLog(@"exception: %@", exception);
                } @finally {
                    request.predicate = nil;
                }
            }
            NSArray <User *> * list = [self.backgroundMOC executeFetchRequest:request error:nil];
            __block NSMutableArray *updateList = @[].mutableCopy;
            [list enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [updateInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    @try {
                        [obj setValue:obj forKey:key];
                        [updateList addObject:obj];
                    } @catch (NSException *exception) {
                        NSLog(@"更新异常: %@", exception);
                    }
                }];
            }];
            // 保存
            [self.backgroundMOC save:nil];
            
            // 到主线程执行保存（因为userMOC是主线程context）
            [self.userMOC performBlock:^{
                NSError *error = nil;
                if ([self.userMOC save:&error]) {
                    NSLog(@"批量更新成功");
                    if (block) block (YES, updateList);
                } else {
                    NSLog(@"批量更新失败: %@", error);
                    if (block) block (NO, nil);
                }
            }];
        }];
    }
}

// 查询所有用户个数
- (NSUInteger)allUserCount
{
    NSFetchRequest *request = [User fetchRequest];
    request.resultType = NSCountResultType;
    NSError *error = nil;
    NSArray *result = [self.userMOC executeFetchRequest:request error:&error];
    if (JTIsEmptyArray(result)) {
        return 0;
    }
    return [result[0] unsignedIntegerValue];
}

- (NSArray <User *> *)allUsers
{
    NSFetchRequest *request = [User fetchRequest];
    NSError *error = nil;
    NSArray *result = [self.userMOC executeFetchRequest:request error:&error];
    return result;
}



@end
