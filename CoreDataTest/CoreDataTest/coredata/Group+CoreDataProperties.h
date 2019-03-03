//
//  Group+CoreDataProperties.h
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/2.
//  Copyright © 2019年 黄金台. All rights reserved.
//
//

#import "Group+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Group (CoreDataProperties)

+ (NSFetchRequest<Group *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *groupId;
@property (nullable, nonatomic, copy) NSString *owner;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *avatar;
@property (nullable, nonatomic, retain) NSObject *member;
@property (nullable, nonatomic, copy) NSString *notice;
@property (nullable, nonatomic, retain) User *group_user;

@end

NS_ASSUME_NONNULL_END
