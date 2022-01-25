#import "PeerMessageDB.h"

@implementation PeerMessageDB
+ (PeerMessageDB *)instance {
    static PeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (!m) {
          m = [[PeerMessageDB alloc] init];
      }
    });
    return m;
}
- (id)init {
    self = [super init];
    if (self) {
        self.secret = NO;
    }
    return self;
}

- (void)saveMessageAttachment:(IMessage *)msg address:(NSString *)address {
    //以附件的形式存储，以免第二次查询
    [self gobelieveUpdateMessageContent:msg.msgLocalID content:msg.rawContent];
    //    [self updateMessageContent:msg.msgLocalID content:msg.rawContent];
}

- (BOOL)saveMessage:(IMessage *)msg {
    //    NSAssert(msg.isOutgoing, @"");
    return [self insertMessage:msg uid:msg.receiver];
}

- (BOOL)saveMessage:(IMessage *)msg andUid:(int64_t)uid {
    return [self insertMessage:msg uid:uid];
}

/// 批量更新多个消息为已读状态
/// @param uuids 消息唯一标识符
- (BOOL)markMesagesHaveRead:(NSArray<NSString *> * _Nonnull)uuids {
    if (!(uuids && uuids.count > 0)) {
        return NO;
    }
    
    NSMutableArray<NSString *> *items = [[NSMutableArray alloc] initWithCapacity:uuids.count];
    [uuids enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [items addObject:[NSString stringWithFormat:@"'%@'", obj]];
    }];
    NSString *params = [items componentsJoinedByString:@","];
    NSString *sql = [NSString stringWithFormat:@"UPDATE peer_message set haveread = 1 WHERE readuuid IN (%@) AND haveread != 1", params];
#if DEBUG
    NSLog(@">>> markMesagesHaveRead sql: %@", sql);
#endif
    FMDatabase *db = self.db;
    BOOL state = [db executeUpdate:sql];
    return state;
    
//    BOOL success = true;
//    [db beginTransaction];
//
//    for (NSString *uuid in uuids) {
//        FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM peer_message WHERE readuuid=?", uuid];
//        if (!rs) {
//            continue;
//        }
//
//        if ([rs next]) {
//            int flags = [rs intForColumn:@"haveread"];
//            flags |= 1;
//
//            BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE readuuid= ?", @(flags), uuid];
//            success = r;
//            if (!r) {
//                [rs close];
//                NSLog(@"error = %@", [db lastErrorMessage]);
//                continue;
//            }
//        }
//        [rs close];
//    }
//
//    if (!success) {
//        [db rollback];
//        return NO;
//    }
//
//    [db commit];
//    return YES;
}

@end
