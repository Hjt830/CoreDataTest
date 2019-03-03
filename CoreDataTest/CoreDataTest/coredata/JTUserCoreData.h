//
//  JTUserCoreData.h
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/2.
//  Copyright © 2019年 黄金台. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

// 批量插入回调
typedef void(^UserBatchInsertBlock)(BOOL, NSArray <NSManagedObject *> * _Nullable);
// 批量删除回调
typedef void(^UserBatchDeleteBlock)(BOOL);
// 批量更新回调
typedef void(^UserBatchUpdateBlock)(BOOL, NSArray <NSManagedObject *> * _Nullable);


@interface JTUserCoreData : NSObject

+ (instancetype)shareUser;

// 托管对象模型
@property (nonatomic, strong) NSManagedObjectModel            * userMOM;
// 托管对象上下文
@property (nonatomic, strong) NSManagedObjectContext          * userMOC;
// 持久化存储协调器
@property (nonatomic, strong) NSPersistentStoreCoordinator    * userPSC;


/**
 * @brief 批量插入
 * @param userInfo user数据
 * @param block 删除回调
 */
- (void)batchInsert:(NSArray <NSDictionary *> *)userInfo
        complection:(UserBatchInsertBlock)block;

/**
 * @brief 批量删除
 * @param predicate 筛选条件
 * @param block 删除回调
 */
- (void)batchDetele:(NSString * _Nullable)predicate complection:(UserBatchDeleteBlock)block;

/**
 * @brief 批量更新
 * @param predicate 筛选条件
 * @param updateInfo 更新数据
 * @param block 删除回调
 */
- (void)batchUpdate:(NSString *)predicate
         updateInfo:(NSDictionary <NSString *, id> *)updateInfo
        complection:(UserBatchUpdateBlock)block;

// 查询所有用户个数
- (NSUInteger)allUserCount;
- (NSArray <User *> *)allUsers;


@end

NS_ASSUME_NONNULL_END
