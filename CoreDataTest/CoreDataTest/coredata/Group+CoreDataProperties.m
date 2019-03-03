//
//  Group+CoreDataProperties.m
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/2.
//  Copyright © 2019年 黄金台. All rights reserved.
//
//

#import "Group+CoreDataProperties.h"

@implementation Group (CoreDataProperties)

+ (NSFetchRequest<Group *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Group"];
}

@dynamic groupId;
@dynamic owner;
@dynamic name;
@dynamic avatar;
@dynamic member;
@dynamic notice;
@dynamic group_user;

@end
