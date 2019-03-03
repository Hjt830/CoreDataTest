//
//  User+CoreDataProperties.m
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/3.
//  Copyright © 2019年 黄金台. All rights reserved.
//
//

#import "User+CoreDataProperties.h"

@implementation User (CoreDataProperties)

+ (NSFetchRequest<User *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"User"];
}

@dynamic age;
@dynamic avatar;
@dynamic index;
@dynamic name;
@dynamic remark;
@dynamic sex;
@dynamic userId;

@end
