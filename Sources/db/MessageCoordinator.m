//
//  MessageCoordinator.m
//  Gobelieve
//
//  Created by Tingsong Xu on 2021/7/27.
//

#import "MessageCoordinator.h"
#import "IMessage.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "IMessageIterator.h"

@implementation MessageRecords

@end

@implementation MessageCoordinator

#pragma mark - Forward Search
/// 根据UUID查找多条本地消息，未查到的返回到missingUUIDs中
/// @param uuids 需查询的uuid集合
+ (MessageRecords *)fetchMessagesByUUIDs:(NSArray<NSString *> *)uuids {
    if (!(uuids && uuids.count > 0)) {
        MessageRecords *records = [[MessageRecords alloc] init];
        records.messages = @[];
        records.uuids = @[];
        records.missingUUIDs = @[];
        return records;
    }
    
    NSMutableArray<NSString *> *items = [[NSMutableArray alloc] initWithCapacity:uuids.count];
    NSMutableArray<NSString *> *remainItems = [uuids mutableCopy];
    for (NSString *uuid in uuids) {
        [items addObject:[NSString stringWithFormat:@"'%@'", uuid]];
    }
    NSString *condition = [NSString stringWithFormat:@"(%@)", [items componentsJoinedByString:@","]];
    FMDatabase *peerDB = PeerMessageDB.instance.db;
//    FMDatabase *grouDB = GroupMessageDB.instance.db;
//    // 连接群聊数据库
//    NSString *statements = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS group_message", grouDB.databasePath];
//    BOOL success = [peerDB executeStatements:statements];
//    // 群聊数据读取不成功则只读取单聊的
//    NSString *sql;
//    if (!success) {
//        sql = [NSString stringWithFormat:@"SELECT %@ FROM peer_message WHERE readuuid IN %@", allColumns, condition];
//    }   else    {
//        sql = [NSString stringWithFormat:@"SELECT %@ FROM peer_message a INNER JOIN group_message g WHERE a.readuuid IN %@ OR b.readuuid IN %@", allColumns, condition, condition];
//    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT sender, receiver, '' group_id, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message a WHERE a.readuuid IN %@ UNION ALL SELECT sender, '' receiver, group_id, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM group_message b WHERE b.readuuid IN %@", condition, condition];
    
    FMResultSet *result = [peerDB executeQuery:sql];
    NSMutableArray<IMessage *> *messages = [[NSMutableArray alloc] initWithCapacity:uuids.count];
    while ([result next]) {
        NSString *groupID = [result stringForColumn:@"group_id"];
        if (groupID && groupID.length > 0) {
            IMessage *item = [SQLGroupMessageIterator messageFromResultSet:result];
            [messages addObject:item];
            [remainItems removeObject:item.readUUID];
            continue;
        }
        IMessage *item = [SQLPeerMessageIterator messageFromResultSet:result];
        [remainItems removeObject:item.readUUID];
        [messages addObject:item];
    }
    [result close];
    
    MessageRecords *records = [[MessageRecords alloc] init];
    records.messages = messages;
    records.uuids = uuids;
    records.missingUUIDs = remainItems;
    return records;
}
@end
