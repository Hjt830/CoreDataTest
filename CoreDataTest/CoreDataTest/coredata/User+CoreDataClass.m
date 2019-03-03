//
//  User+CoreDataClass.m
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/3.
//  Copyright © 2019年 黄金台. All rights reserved.
//
//

#import "User+CoreDataClass.h"

@implementation User

- (nullable id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"%s ----- UndefinedKey: %@", __func__, key);
}

- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"%s ----- UndefinedKey: %@   value: %@", __func__, key, value);
}

- (void)setNilValueForKey:(NSString *)key
{
    NSLog(@"%s ----- Key: %@", __func__, key);
}

@end
