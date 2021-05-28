//
//  AppDelegate.m
//  Example
//
//  Created by ch999 on 2021/4/16.
//

#import "AppDelegate.h"
@import SQLite3;
@import Gobelieve;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // checkHaveManualColumn
    NSString *path = [self getDocumentPath];
    NSString *dbPath = [NSString stringWithFormat:@"%@/gobelieve_%d.db", path, 10000];
    //检查数据库文件是否已经存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dbPath]) {
        NSString *p = [[NSBundle bundleForClass:[SQLGroupMessageDB class]] pathForResource:@"gobelieve" ofType:@"db"];
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
    
    return YES;
}

- (NSString *)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
