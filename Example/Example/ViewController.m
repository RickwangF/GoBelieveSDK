//
//  ViewController.m
//  Example
//
//  Created by ch999 on 2021/4/16.
//

#import "ViewController.h"
@import SQLite3;
@import Gobelieve;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // checkHaveManualColumn
    NSString *path = [self getDocumentPath];
    NSString *dbPath = [NSString stringWithFormat:@"%@/gobelieve_%d.db", path, 10000];
    //检查数据库文件是否已经存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dbPath]) {
        NSString *p = [[NSBundle mainBundle] pathForResource:@"gobelieve" ofType:@"db"];
        if (p && p.length > 0) {
            NSError *error = nil;
            [fileManager copyItemAtPath:p toPath:dbPath error:&error];
            if (error) {
                NSLog(@">>> copy %@ to %@ failed, %@", p, dbPath, error);
            }
        }   else    {
            NSLog(@">>> invalid path for gobelieve.db, %@", p);
        }
    }
    FMDatabase *db = [[FMDatabase alloc] initWithPath:dbPath];
    BOOL r = [db openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_WAL];
    if (!r) {
        NSLog(@"open database error:%@", [db lastError]);
        db = nil;
        NSAssert(NO, [db lastError].localizedDescription);
    }
    [SQLGroupMessageDB instance].db = db;
    [[SQLGroupMessageDB instance] checkHaveManualColumn];
}

- (NSString *)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


@end
