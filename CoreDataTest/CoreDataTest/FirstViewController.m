//
//  FirstViewController.m
//  CoreDataTest
//
//  Created by 黄金台 on 2019/3/2.
//  Copyright © 2019年 黄金台. All rights reserved.
//

#import "FirstViewController.h"
#import "JTUserCoreData.h"

@interface FirstViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UITableView                       * tableView;
@property (nonatomic, strong) NSFetchedResultsController        * frc;
@property (nonatomic, copy) NSString                            * remark;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"通讯录";
    
    [self.view addSubview:self.tableView];
    [self addBBI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSError *error = nil;
    if (![self.frc performFetch:&error]) {
        NSLog(@"查询失败: %@", error);
    } else {
        NSLog(@"查询成功");
        [self.tableView reloadData];
    }
}

- (void)addBBI
{
    UIBarButtonItem *addBBI = [[UIBarButtonItem alloc] initWithTitle:@"新增" style:UIBarButtonItemStylePlain target:self action:@selector(insertUsers)];
    UIBarButtonItem *deleteBBI = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(deleteUsers)];
    UIBarButtonItem *updateBBI = [[UIBarButtonItem alloc] initWithTitle:@"更新" style:UIBarButtonItemStylePlain target:self action:@selector(updateUsers)];
    UIBarButtonItem *spaceBBI = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.tabBarController.navigationItem.rightBarButtonItems = @[addBBI, spaceBBI, deleteBBI, spaceBBI, updateBBI];
}

- (void)viewDidLayoutSubviews
{
    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.sectionHeaderHeight = 30.0f;
        _tableView.sectionFooterHeight = 0.0f;
        _tableView.rowHeight = 60.0f;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

- (NSFetchedResultsController *)frc
{
    if (!_frc) {
        NSFetchRequest *request = [User fetchRequest];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        _frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[JTUserCoreData shareUser].userMOC sectionNameKeyPath:@"index" cacheName:nil];
        _frc.delegate = self;
    }
    return _frc;
}

#pragma mark =========================== operation ===========================

// 批量添加用户
- (void)insertUsers
{
    NSMutableArray *userArray = @[].mutableCopy;
    for (int i = 1; i <= 200; i++) {
        NSMutableDictionary *mutDict = @{}.mutableCopy;
        NSString *userId = [NSString stringWithFormat:@"%d", 200 + i];
        NSString *avatar = [NSString stringWithFormat:@"http://aliyun_oss.shenzhen.jt/1000000-%d.png", i];
        NSString *name = [NSString stringWithFormat:@"%c_name_%d", 'A' + (i-1)%26, i];
        NSString *index = [NSString stringWithFormat:@"%c", 'A' + (i-1)%26];
        NSNumber *age = [NSNumber numberWithInt:(arc4random()%120)];
        NSString *sex = (i % 2 == 0) ? @"male" : @"female";
        
        [mutDict setValue:index forKey:@"index"];
        [mutDict setValue:userId forKey:@"userId"];
        [mutDict setValue:avatar forKey:@"avatar"];
        [mutDict setValue:name forKey:@"name"];
        [mutDict setValue:age forKey:@"age"];
        [mutDict setValue:sex forKey:@"sex"];
        [userArray addObject:mutDict];
    }
    
    __block NSTimeInterval before = [[NSDate date] timeIntervalSinceNow];
    
    [[JTUserCoreData shareUser] batchInsert:userArray complection:^(BOOL finish, NSArray<NSManagedObject *> * _Nullable userList) {
        NSLog(@"finish: %d  userList: %lu", finish, userList.count);
        
        NSTimeInterval after = [[NSDate date] timeIntervalSinceNow];
        NSLog(@"time: %f", after - before);
    }];
}

- (void)deleteUsers
{
    [[JTUserCoreData shareUser] batchDetele:nil complection:^(BOOL finish) {
        NSLog(@"%s,  %d", __func__, finish);
    }];
}

- (void)updateUsers
{
    NSLog(@"%s", __func__);
}

#pragma mark =========================== UITableViewDataSource ===========================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.frc.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.frc.sections[section].numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    User *user = [self.frc objectAtIndexPath:indexPath];
    
    NSString *imageName = [NSString stringWithFormat:@"00%ld.jpg", (long)indexPath.row%7];
    UIImage * icon = [UIImage imageNamed:imageName];
    CGSize itemSize = CGSizeMake(50, 50);
    UIGraphicsBeginImageContextWithOptions(itemSize, NO, 0.0);//*1
    CGRect imageRect = CGRectMake(0, 5, itemSize.width, itemSize.height);
    [icon drawInRect:imageRect];
    cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();//*2
    UIGraphicsEndImageContext();//*3
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.textLabel.text = JTIsEmptyString(user.remark) ? user.name : user.remark;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    
    return self.frc.sectionIndexTitles[section];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.frc.sectionIndexTitles;
}

#pragma mark =========================== UITableViewDelegate ===========================

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *edit = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        User *user = [self.frc objectAtIndexPath:indexPath];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"备注" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            if (JTIsEmptyString(user.remark)) {
                textField.placeholder = @"请填写备注名";
            } else {
                textField.placeholder = user.remark;
            }
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sure = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // 更新备注名
            [[JTUserCoreData shareUser].userMOC performBlock:^{
                NSFetchRequest *request = [User fetchRequest];
                request.predicate = [NSPredicate predicateWithFormat:@"userId = %@", user.userId];
                NSArray <User *> *list = [[JTUserCoreData shareUser].userMOC executeFetchRequest:request error:nil];
                [list enumerateObjectsUsingBlock:^(User * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.remark = self.remark;
                }];
                [[JTUserCoreData shareUser].userMOC save:nil];
                self.remark = nil;
            }];
        }];
        [alertVC addAction:cancel];
        [alertVC addAction:sure];
        [self presentViewController:alertVC animated:YES completion:nil];
    }];
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        User *user = [self.frc objectAtIndexPath:indexPath];
        NSString *predicate = [NSString stringWithFormat:@"userId = %@", user.userId];
        [[JTUserCoreData shareUser] batchDetele:predicate complection:^(BOOL finish) {
            NSLog(@"删除 %@ 成功!", user.name);
        }];
    }];
    return @[delete, edit];
}

#pragma mark =========== NSFetchedResultsControllerDelegate ==============

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    return sectionName;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            User *contact = (User *)anObject;
            cell.textLabel.text = contact.name;
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
            break;
        default:
            break;
    }
}

#pragma mark =========================== noti ===========================

- (void)textFieldDidChange:(NSNotification *)noti
{
    UITextField *textField = (UITextField *)noti.object;
    self.remark = [textField.text copy];
}

@end
