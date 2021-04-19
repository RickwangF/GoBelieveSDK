#import "SQLPeerMessageDB.h"
#import "NSString+JSMessagesView.h"

static const NSString *allColumns = @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content";

@interface SQLPeerMessageIterator : NSObject<IMessageIterator>

//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer secret:(BOOL)secret;
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID secret:(BOOL)secret;

- (SQLPeerMessageIterator *)initWithDB:(FMDatabase*)db
                                  peer:(int64_t)peer
                             timeStamp:(NSInteger)timeStamp;

- (SQLPeerMessageIterator *)initBackwardWithDB:(FMDatabase*)db
                                          peer:(int64_t)peer
                                     timeStamp:(NSInteger)timeStamp;

@property(nonatomic, strong) FMResultSet *rs;
@end

@implementation SQLPeerMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

- (SQLPeerMessageIterator *)initWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM peer_message WHERE peer = ? AND timestamp < ? ORDER BY timestamp DESC", allColumns];
        self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
    }
    return self;
}

- (SQLPeerMessageIterator *)initBackwardWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM peer_message WHERE peer = ? AND timestamp > ? ORDER BY timestamp ASC", allColumns];
        self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
    }
    return self;
}

//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(peer), @(s)];
//    }
//    return self;
//}
//
//
//-(SQLPeerMessageIterator*)initForwardWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND timestamp < ? ORDER BY timestamp DESC";
//        self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id < ? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer middle:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id > ? AND id < ? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID-10), @(msgID+10)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initBackwardWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND timestamp > ? ORDER BY timestamp ASC";
//        self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
//    }
//    return self;
//}
//
////上拉刷新
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer last:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id>? ORDER BY id";
//        self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
//    }
//    return self;
//}
//
//
//-(IMessage*)next {
//    BOOL r = [self.rs next];
//    if (!r) {
//        return nil;
//    }
//
//    IMessage *msg = [[IMessage alloc] init];
//    msg.sender = [self.rs longLongIntForColumn:@"sender"];
//    msg.receiver = [self.rs longLongIntForColumn:@"receiver"];
//    msg.timestamp = [self.rs longLongIntForColumn:@"timestamp"];
//    msg.flags = [self.rs intForColumn:@"flags"];
//    msg.secret = [self.rs intForColumn:@"secret"] == 1;
//    msg.rawContent = [self.rs stringForColumn:@"content"];
//    msg.msgLocalID = [self.rs longLongIntForColumn:@"id"];
//    msg.haveRead = [self.rs intForColumn:@"haveread"] == 1;
//    msg.readUUID = [self.rs stringForColumn:@"readuuid"];
//    msg.manualHeight = (float)[self.rs intForColumn:@"cacheheight"];
//    msg.manualWidth = (float)[self.rs intForColumn:@"cachewidth"];
//    msg.lineHeight = (float)[self.rs intForColumn:@"lineheight"];
//    msg.callBack = [self.rs intForColumn:@"callback"] == 1;
//    msg.deleteTag = [self.rs intForColumn:@"deletetag"] == 1;
//    return msg;
//}

- (IMessage *)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }

    IMessage *msg = [[IMessage alloc] init];
    [msg setSender:[self.rs longLongIntForColumn:@"sender"]];
    [msg setReceiver:[self.rs longLongIntForColumn:@"receiver"]];
    [msg setTimestamp:[self.rs longLongIntForColumn:@"timestamp"]];
    [msg setFlags:[self.rs intForColumn:@"flags"]];
    [msg setRawContent:[self.rs stringForColumn:@"content"]];
    [msg setHaveRead:[self.rs intForColumn:@"haveread"] == 1];
    [msg setReadUUID:[self.rs stringForColumn:@"readuuid"]];
    [msg setManualWidth:(float)[self.rs doubleForColumn:@"cachewidth"]];
    [msg setManualHeight:(float)[self.rs intForColumn:@"cacheheight"]];
    [msg setLineHeight:(float)[self.rs intForColumn:@"lineheight"]];
    [msg setCallBack:[self.rs intForColumn:@"callback"] == 1];
    [msg setDeleteTag:[self.rs intForColumn:@"deletetag"] == 1];
    return msg;
}

@end



@implementation SQLPeerMessageDB
/// 获取单条消息
/// @param uuid 消息唯一标识
- (IMessage *)getMessage:(NSString *)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT ? FROM peer_message WHERE readuuid= ?", allColumns, uuid];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"receiver"]];
        [msg setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
        [msg setFlags:[rs intForColumn:@"flags"]];
        [msg setRawContent:[rs stringForColumn:@"content"]];
        [msg setHaveRead:[rs intForColumn:@"haveread"] == 1];
        [msg setReadUUID:[rs stringForColumn:@"readuuid"]];
        [msg setManualWidth:(float)[rs doubleForColumn:@"cachewidth"]];
        [msg setManualHeight:(float)[rs intForColumn:@"cacheheight"]];
        [msg setLineHeight:(float)[rs intForColumn:@"lineheight"]];
        [msg setCallBack:[rs intForColumn:@"callback"] == 1];
        [msg setDeleteTag:[rs intForColumn:@"deletetag"] == 1];
        return msg;
    }
    return nil;
}

/// 存储消息
/// @param msg 消息体
- (BOOL)saveMessage:(IMessage*)msg {
    return [self insertMessage:msg uid:msg.receiver];
}

/// 保存消息至数据库
/// @param msg 消息体
/// @param uid 消息保存uid
- (BOOL)insertMessage:(IMessage *)msg
                  uid:(int64_t)uid {
    FMDatabase *db = self.db;
    [db beginTransaction];
    
//    @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content"
    NSString *readuuid = [msg.readUUID hasContent] ? msg.readUUID : @"";
    NSString *content = [msg.rawContent hasContent] ? msg.rawContent : @"";
    BOOL result = [db executeUpdate:@"INSERT INTO peer_message (peer, sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp), @(msg.flags), @(msg.haveRead), readuuid, @(msg.manualHeight), @(msg.manualWidth), @(msg.lineHeight), @(msg.callBack), @(msg.deleteTag), content];
    
    if (!result) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        [db rollback];
        return NO;
    }
    
    int64_t rowID = [self.db lastInsertRowId];
    msg.msgId = rowID;
    
    if (msg.textContent) {
        NSString *text = [msg.textContent.text tokenizer];
        [db executeUpdate:@"INSERT INTO peer_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
    }
    
    result = [db commit];
    return result;
}

/// 标记消息失败
/// @param uuid 消息唯一标识
- (BOOL)markMessageFailure:(NSString *)uuid {
    return [self addFlag:uuid flag:MESSAGE_FLAG_FAILURE];
}

/// 标记消息听取标识
/// @param uuid 消息唯一标识
- (BOOL)markMesageListened:(NSString *)uuid {
    return [self addFlag:uuid flag:MESSAGE_FLAG_LISTENED];
}

/// 修改消息失败状态
/// @param uuid 消息唯一标识
- (BOOL)eraseMessageFailure:(NSString *)uuid {
    if ([uuid hasContent] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];

        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 修改消息读取状态
/// @param uuid 消息唯一标识
- (BOOL)markMesageHaveRead:(NSString *)uuid {
    if ([uuid hasContent] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"haveread"];
        flags |= 1;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 获取当前目标发送失败消息
/// @param uid targetUid
- (NSArray<IMessage *> *)getFailedMessages:(int64_t)uid {
    FMDatabase *db = self.db;
    NSMutableArray *failedArr = [[NSMutableArray alloc] init];
    FMResultSet *rs = [db executeQuery:@"SELECT ? FROM peer_message WHERE flags=? AND peer=?", allColumns, @(MESSAGE_FLAG_FAILURE), @(uid)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"receiver"]];
        [msg setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
        [msg setFlags:[rs intForColumn:@"flags"]];
        [msg setRawContent:[rs stringForColumn:@"content"]];
        [msg setHaveRead:[rs intForColumn:@"haveread"] == 1];
        [msg setReadUUID:[rs stringForColumn:@"readuuid"]];
        [msg setManualWidth:(float)[rs doubleForColumn:@"cachewidth"]];
        [msg setManualHeight:(float)[rs intForColumn:@"cacheheight"]];
        [msg setLineHeight:(float)[rs intForColumn:@"lineheight"]];
        [msg setCallBack:[rs intForColumn:@"callback"] == 1];
        [msg setDeleteTag:[rs intForColumn:@"deletetag"] == 1];
        [failedArr addObject:msg];
    }
    return failedArr;
}

/// 更新消息撤回状态
/// @param uuids 已经撤回的消息uuid数组
- (BOOL)updateCallbackUUIDS:(NSArray *)uuids {
    if (uuids.count > 0) {
        FMDatabase *db = self.db;
        [db beginTransaction];
        NSString *sqlStr;
        if (uuids.count > 0) {
            NSMutableString *str = [[NSMutableString alloc] init];
            [str appendString:@"("];
            for (NSString *subStr in uuids) {
                [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
            }
            [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
            [str appendString:@")"];
            sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET callback= %@ WHERE readuuid IN %@", @(1), str];
        }

        BOOL r = [db executeUpdate:sqlStr];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }else{
        return NO;
    }
    return YES;
}

/// 更新消息删除状态
/// @param uuids 已经删除的消息uuid数组
- (BOOL)updateDeleteUUIDS:(NSArray *)uuids {
    if (uuids.count > 0) {
        FMDatabase *db = self.db;
        [db beginTransaction];
        NSString *sqlStr;
        NSMutableString *str = [[NSMutableString alloc] init];
        [str appendString:@"("];
        for (NSString *subStr in uuids) {
            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
        }
        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
        [str appendString:@")"];
        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET deletetag= %@ WHERE readuuid IN %@", @(1), str];

        BOOL r = [db executeUpdate:sqlStr];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }else{
        return NO;
    }
    return YES;
}

/// 批量更新发送者的消息已读状态
/// @param uuids 未读消息uuid数组
/// @param sender 发送者
- (BOOL)updateHaveNotReadUUIDS:(NSArray *)uuids
                        sender:(int64_t)sender {
    if (uuids.count > 0) {
        FMDatabase *db = self.db;
        [db beginTransaction];
        NSString *sqlStr;
        
        NSMutableString *str = [[NSMutableString alloc] init];
        [str appendString:@"("];
        for (NSString *subStr in uuids) {
            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
        }
        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
        [str appendString:@")"];
        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= %d WHERE readuuid NOT IN %@ AND haveread= 0 AND sender= %lld", 1, str, sender];
        
        BOOL r = [db executeUpdate:sqlStr];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
        return YES;
    }else{
        return NO;
    }
}

/// 更新消息宽高以及行高
/// @param width 消息宽度
/// @param height 消息高度
/// @param lineHeight 消息行高
/// @param uuid 消息唯一标识
- (BOOL)updateMessageWidth:(float)width
                    height:(float)height
                lineHeight:(float)lineHeight
                   msgUUID:(NSString *)uuid {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE peer_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE readuuid= ?", @(height), @(width), @(lineHeight), uuid];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

/// 获取包含关键字的消息
/// @param keyword 关键字
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword {
    FMDatabase *db = self.db;
    NSString *selectStr = [NSString stringWithFormat:@"SELECT %@ FROM peer_message WHERE content LIKE '%%%@%%'", allColumns, keyword];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"receiver"]];
        [msg setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
        [msg setFlags:[rs intForColumn:@"flags"]];
        [msg setRawContent:[rs stringForColumn:@"content"]];
        [msg setHaveRead:[rs intForColumn:@"haveread"] == 1];
        [msg setReadUUID:[rs stringForColumn:@"readuuid"]];
        [msg setManualWidth:(float)[rs doubleForColumn:@"cachewidth"]];
        [msg setManualHeight:(float)[rs intForColumn:@"cacheheight"]];
        [msg setLineHeight:(float)[rs intForColumn:@"lineheight"]];
        [msg setCallBack:[rs intForColumn:@"callback"] == 1];
        [msg setDeleteTag:[rs intForColumn:@"deletetag"] == 1];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

/// 获取目标下包含关键字的消息
/// @param keyword 关键字
/// @param targetUid targetUid
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword
                                            targetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    NSString *selectStr = [NSString stringWithFormat:@"SELECT %@ FROM peer_message WHERE content LIKE '%%%@%%' AND peer = %lld", allColumns, keyword, targetUid];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"receiver"]];
        [msg setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
        [msg setFlags:[rs intForColumn:@"flags"]];
        [msg setRawContent:[rs stringForColumn:@"content"]];
        [msg setHaveRead:[rs intForColumn:@"haveread"] == 1];
        [msg setReadUUID:[rs stringForColumn:@"readuuid"]];
        [msg setManualWidth:(float)[rs doubleForColumn:@"cachewidth"]];
        [msg setManualHeight:(float)[rs intForColumn:@"cacheheight"]];
        [msg setLineHeight:(float)[rs intForColumn:@"lineheight"]];
        [msg setCallBack:[rs intForColumn:@"callback"] == 1];
        [msg setDeleteTag:[rs intForColumn:@"deletetag"] == 1];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (BOOL)addFlag:(NSString *)uuid flag:(int)f {
    if ([uuid hasContent] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;


        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}


/// 根据最新时间进行消息降序查询
/// @param conversationID targetUid
/// @param timeStamp unix时间
- (id<IMessageIterator>)forwardMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:conversationID timeStamp:timeStamp];
}

/// 根据最新时间进行消息升序查询
/// @param conversationID targetUid
/// @param timeStamp unix时间
- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp {
    return [[SQLPeerMessageIterator alloc] initBackwardWithDB:self.db peer:conversationID timeStamp:timeStamp];
}

/// 手动检查是否有自定义添加字段
- (void)checkHaveManualColumn {
    FMDatabase *db = self.db;
    BOOL haveCacheHeight = NO;
    BOOL haveCacheWidth = NO;
    BOOL haveLineHeight = NO;
    BOOL haveCallBack = NO;
    BOOL haveDeleteMessage = NO;
    FMResultSet *result = [db executeQuery:@"SELECT * FROM group_message"];
    for (int i = 0; i<[result columnCount]; i++) {
        NSString * columnName = [result columnNameForIndex:i];
        if ([columnName containsString:@"cacheheight"]) {
            haveCacheHeight = YES;
        }else if ([columnName containsString:@"cachewidth"]) {
            haveCacheWidth = YES;
        }else if ([columnName containsString:@"lineheight"]) {
            haveLineHeight = YES;
        }else if ([columnName containsString:@"callback"]) {
            haveCallBack = YES;
        }else if ([columnName containsString:@"deletetag"]) {
            haveDeleteMessage = YES;
        }
    }
    if (haveCacheWidth == YES && haveLineHeight == YES && haveCacheHeight == YES && haveCallBack == YES && haveDeleteMessage == YES) {
        return;
    }
    if (haveCacheHeight == NO) {
        BOOL addCH = [db executeUpdate:@"ALTER TABLE peer_message ADD cacheheight"];
        NSLog(@"插入cacheheight列%@", addCH == YES ? @"成功" : @"失败");
    }
    if (haveCacheWidth == NO) {
        BOOL addCW = [db executeUpdate:@"ALTER TABLE peer_message ADD cachewidth"];
        NSLog(@"插入cachewidth列%@", addCW == YES ? @"成功" : @"失败");
    }
    if (haveLineHeight == NO) {
        BOOL addLH = [db executeUpdate:@"ALTER TABLE peer_message ADD lineheight"];
        NSLog(@"插入lineheight列%@", addLH == YES ? @"成功" : @"失败");
    }
    if (haveCallBack == NO) {
        BOOL addCH = [db executeUpdate:@"ALTER TABLE peer_message ADD callback"];
        NSLog(@"插入callback列%@", addCH == YES ? @"成功" : @"失败");
    }
    if (haveDeleteMessage == NO) {
        BOOL addDH = [db executeUpdate:@"ALTER TABLE peer_message ADD deletetag"];
        NSLog(@"插入deletetag列%@", addDH == YES ? @"成功" : @"失败");
    }
}

/// 清除消息数据
/// @param targetUid 目标uid
- (BOOL)clearMessagesWithTargetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM peer_message WHERE peer=?", @(targetUid)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

#pragma mark - gobelieve handler method
- (int)gobelieveGetMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM peer_message WHERE uuid=?", uuid];
    if ([rs next]) {
        int msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    [rs close];
    return 0;
}

- (IMessage *)gobelieveGetMessage:(int)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"receiver"]];
        [msg setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
        [msg setFlags:[rs intForColumn:@"flags"]];
        [msg setRawContent:[rs stringForColumn:@"content"]];
        [msg setHaveRead:[rs intForColumn:@"haveread"] == 1];
        [msg setReadUUID:[rs stringForColumn:@"readuuid"]];
        [msg setManualWidth:(float)[rs doubleForColumn:@"cachewidth"]];
        [msg setManualHeight:(float)[rs intForColumn:@"cacheheight"]];
        [msg setLineHeight:(float)[rs intForColumn:@"lineheight"]];
        [msg setCallBack:[rs intForColumn:@"callback"] == 1];
        [msg setDeleteTag:[rs intForColumn:@"deletetag"] == 1];
        return msg;
    }
    return nil;
}

-(BOOL)gobelieveUpdateFlags:(NSInteger)msgLocalID flags:(int)flags {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

- (BOOL)gobelieveUpdateMessageContent:(NSInteger)msgLocalID content:(NSString *)content {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE peer_message SET content=? WHERE id=?", content, @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return [db changes] == 1;
}

- (BOOL)gobelieveRemoveMessageIndex:(int)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM peer_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

- (BOOL)gobelieveAcknowledgeMessage:(int)msgLocalID {
    return [self gobelieveAddFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

- (BOOL)gobelieveMarkMessageFailure:(NSInteger)msg {
    return [self gobelieveAddFlag:msg flag:MESSAGE_FLAG_FAILURE];
}

- (BOOL)gobelieveAddFlag:(NSInteger)msgLocalID flag:(int)f {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;


        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

//- (BOOL)checkHaveFailedMessageUid:(int64_t)uid {
//    FMDatabase *db = self.db;
//    BOOL haveFailed = NO;
//    FMResultSet *result = [db executeQuery:@"SELECT * FROM peer_message WHERE flags=? AND peer=?", @(MESSAGE_FLAG_FAILURE), @(uid)];
//    while ([result next]) {
//        haveFailed = YES;
//        break;
//    }
//    return haveFailed;
//}
//
//- (void)checkHaveManualColumn {
//    FMDatabase *db = self.db;
//    BOOL haveCacheHeight = NO;
//    BOOL haveCacheWidth = NO;
//    BOOL haveLineHeight = NO;
//    BOOL haveCallBack = NO;
//    BOOL haveDeleteMessage = NO;
//    FMResultSet *result = [db executeQuery:@"SELECT * FROM peer_message"];
//    for (int i = 0; i < [result columnCount]; i++) {
//        NSString * columnName = [result columnNameForIndex:i];
//        if ([columnName containsString:@"cacheheight"]) {
//            haveCacheHeight = YES;
//        }else if ([columnName containsString:@"cachewidth"]) {
//            haveCacheWidth = YES;
//        }else if ([columnName containsString:@"lineheight"]) {
//            haveLineHeight = YES;
//        }else if ([columnName containsString:@"callback"]) {
//            haveCallBack = YES;
//        }else if ([columnName containsString:@"deletetag"]) {
//            haveDeleteMessage = YES;
//        }
//    }
//    if (haveCacheWidth == YES && haveLineHeight == YES && haveCacheHeight == YES && haveCallBack == YES && haveDeleteMessage == YES) {
//        return;
//    }
//    if (haveCacheHeight == NO) {
//        BOOL addCH = [db executeUpdate:@"ALTER TABLE peer_message ADD cacheheight"];
//        NSLog(@"插入cacheheight列%@", addCH == YES ? @"成功" : @"失败");
//    }
//    if (haveCacheWidth == NO) {
//        BOOL addCW = [db executeUpdate:@"ALTER TABLE peer_message ADD cachewidth"];
//        NSLog(@"插入cachewidth列%@", addCW == YES ? @"成功" : @"失败");
//    }
//    if (haveLineHeight == NO) {
//        BOOL addLH = [db executeUpdate:@"ALTER TABLE peer_message ADD lineheight"];
//        NSLog(@"插入lineheight列%@", addLH == YES ? @"成功" : @"失败");
//    }
//    if (haveCallBack == NO) {
//        BOOL addCH = [db executeUpdate:@"ALTER TABLE peer_message ADD callback"];
//        NSLog(@"插入callback列%@", addCH == YES ? @"成功" : @"失败");
//    }
//    if (haveDeleteMessage == NO) {
//        BOOL addDH = [db executeUpdate:@"ALTER TABLE peer_message ADD deletetag"];
//        NSLog(@"插入deletetag列%@", addDH == YES ? @"成功" : @"失败");
//    }
//}
//
//-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
////    BOOL haveMessage = NO;
////    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND readuuid = ?", @(uid), msg.readUUID];
////    if (rs.next) {
////        haveMessage = YES;
////    }
////
////    if (haveMessage == NO) {
////        FMDatabase *db = self.db;
////
////        [db beginTransaction];
////        int secret = self.secret ? 1 : 0;
////        NSString *uuid = msg.uuid ? msg.uuid : @"";
////        CHGBMessageModel *model = [[CHGBMessageTool sharedTool] getMessageModelWith:msg];
////        BOOL r = [db executeUpdate:@"INSERT INTO peer_message (peer, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, uuid, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
////                  @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp), @(secret), @(msg.flags), @(msg.haveRead), model.msg_uuid, @(msg.manualHeight), @(msg.manualWidth), @(msg.lineHeight), @(msg.callBack), @(msg.deleteTag), uuid, msg.rawContent];
////
////        if (!r) {
////            NSLog(@"error = %@", [db lastErrorMessage]);
////            [db rollback];
////            return NO;
////        }
////
////        int64_t rowID = [self.db lastInsertRowId];
////        msg.msgId = rowID;
////
////        if (msg.textContent) {
////            NSString *text = [msg.textContent.text tokenizer];
////            [db executeUpdate:@"INSERT INTO peer_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
////        }
////
////        r = [db commit];
////        return r;
////    }else{
//        return NO;
////    }
//}
//
//-(BOOL)removeMessage:(NSInteger)msgLocalID {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM peer_message WHERE id=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    r = [db executeUpdate:@"DELETE FROM peer_message_fts WHERE rowid=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(BOOL)removeMessageIndex:(NSInteger)msgLocalID {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM peer_message_fts WHERE rowid=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(BOOL)clearConversation:(int64_t)uid {
//    FMDatabase *db = self.db;
//    int secret = self.secret ? 1 : 0;
//    BOOL r = [db executeUpdate:@"DELETE FROM peer_message WHERE peer=? AND secret=?", @(uid), @(secret)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(BOOL)clear {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM peer_message"];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(BOOL)updateMessageContent:(NSInteger)msgLocalID content:(NSString*)content {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET content=? WHERE id=?", content, @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return [db changes] == 1;
//}
//
//-(NSArray*)search:(NSString*)key {
//    FMDatabase *db = self.db;
//
//    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@"\'"];
//    key = [key tokenizer];
//    NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM peer_message_fts WHERE peer_message_fts MATCH '%@'", key];
//
//    FMResultSet *rs = [db executeQuery:sql];
//    NSMutableArray *array = [NSMutableArray array];
//    while ([rs next]) {
//        int64_t msgID = [rs longLongIntForColumn:@"rowid"];
//        IMessage *msg = [self getMessage:msgID];
//        if (msg) {
//            [array addObject:msg];
//        }
//    }
//
//    [rs close];
//    return array;
//}
//
//-(IMessage*)getLastMessage:(int64_t)uid {
//    int s = self.secret ? 1 : 0;
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? ORDER BY id DESC", @(uid), @(s)];
//    if ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"receiver"];
//        msg.timestamp = [rs longLongIntForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.secret = [rs intForColumn:@"secret"] == 1;
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs longLongIntForColumn:@"id"];
//        msg.haveRead = [rs intForColumn:@"haveread"] == 1;
//        msg.readUUID = [rs stringForColumn:@"readuuid"];
//        msg.manualHeight = (float)[rs intForColumn:@"cacheheight"];
//        msg.manualWidth = (float)[rs intForColumn:@"cachewidth"];
//        msg.lineHeight = (float)[rs intForColumn:@"lineheight"];
//        msg.callBack = [rs intForColumn:@"callback"] == 1;
//        msg.deleteTag = [rs intForColumn:@"deletetag"] == 1;
//        [rs close];
//        return msg;
//    }
//    [rs close];
//    return nil;
//}
//
//-(int)getMessageId:(NSString*)uuid {
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM peer_message WHERE uuid=?", uuid];
//    if ([rs next]) {
//        int msgId = (int)[rs longLongIntForColumn:@"id"];
//        [rs close];
//        return msgId;
//    }
//    [rs close];
//    return 0;
//}
//
//-(IMessage*)getMessage:(int64_t)msgID {
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE id= ?", @(msgID)];
//    if ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"receiver"];
//        msg.timestamp = [rs longLongIntForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.secret = [rs intForColumn:@"secret"] == 1;
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs longLongIntForColumn:@"id"];
//        msg.haveRead = [rs intForColumn:@"haveread"] == 1;
//        msg.readUUID = [rs stringForColumn:@"readuuid"];
//        msg.manualHeight = (float)[rs intForColumn:@"cacheheight"];
//        msg.manualWidth = (float)[rs intForColumn:@"cachewidth"];
//        msg.lineHeight = (float)[rs intForColumn:@"lineheight"];
//        msg.callBack = [rs intForColumn:@"callback"] == 1;
//        msg.deleteTag = [rs intForColumn:@"deletetag"] == 1;
//        return msg;
//    }
//    return nil;
//
//}
//
//- (NSArray *)getUnreadMsgs {
////    NSString *selfUid = [CHGBSignatureModel localSignatureModel].uid;
////    FMResultSet *rs = [self.db executeQuery:[NSString stringWithFormat:@"SELECT readuuid FROM peer_message WHERE haveread= 0 AND sender=%@", selfUid]];
//    NSMutableArray *unreadArr = [[NSMutableArray alloc] init];
////    while ([rs next]) {
////        if ([[rs stringForColumn:@"readuuid"] hasContent]) {
////            [unreadArr addObject:[rs stringForColumn:@"readuuid"]];
////        }
////    }
//    return unreadArr;
//}
//
//- (NSArray *)getRecalledMsgs {
//    FMResultSet *rs = [self.db executeQuery:[NSString stringWithFormat:@"SELECT readuuid FROM peer_message WHERE callback= 1"]];
//    NSMutableArray *unreadArr = [[NSMutableArray alloc] init];
////    while ([rs next]) {
////        if ([[rs stringForColumn:@"readuuid"] hasContent]) {
////            [unreadArr addObject:[rs stringForColumn:@"readuuid"]];
////        }
////    }
//    return unreadArr;
//}
//
//-(BOOL)acknowledgeMessage:(NSInteger)msgLocalID{
//    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
//}
//
//-(BOOL)markMessageFailure:(NSInteger)msgLocalID {
//    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
//}
//
//-(BOOL)markMesageListened:(NSInteger)msgLocalID {
//    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_LISTENED];
//}
//
//- (BOOL)markMesageHaveRead:(NSString *)readUUID {
//    return [self addHaveRead:readUUID haveRead:1];
//}
//
//-(BOOL)addFlag:(NSInteger)msgLocalID flag:(int)f {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"flags"];
//        flags |= f;
//
//
//        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//    }
//
//    [rs close];
//    return YES;
//}
//
//-(BOOL)addHaveRead:(NSString *)readUUID haveRead:(int)f {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM peer_message WHERE readuuid=?", readUUID];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"haveread"];
//        flags |= f;
//
//
//        BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE readuuid= ?", @(flags), readUUID];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//    }
//
//    [rs close];
//    return YES;
//}
//
////获取存在关键字的消息
//- (NSArray<IMessage *> *)getTargetMessageAndLocationWithKeyWord:(NSString *)keyWord {
//    FMDatabase *db = self.db;
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE content LIKE '%%%@%%'", keyWord];
//    FMResultSet *rs = [db executeQuery:selectStr];
//    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
//    while ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"receiver"];
//        msg.timestamp = [rs longLongIntForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.secret = [rs intForColumn:@"secret"] == 1;
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs longLongIntForColumn:@"id"];
//        msg.haveRead = [rs intForColumn:@"haveread"] == 1;
//        msg.readUUID = [rs stringForColumn:@"readuuid"];
//        msg.manualHeight = (float)[rs intForColumn:@"cacheheight"];
//        msg.manualWidth = (float)[rs intForColumn:@"cachewidth"];
//        msg.lineHeight = (float)[rs intForColumn:@"lineheight"];
//        msg.callBack = (float)[rs intForColumn:@"callback"] == 1;
//        msg.deleteTag = (float)[rs intForColumn:@"deletetag"] == 1;
//        [messageArr addObject:msg];
//    }
//    NSMutableArray *arr = [[NSMutableArray alloc] init];
////    for (IMessage *message in messageArr) {
////        CHGBMessageModel *model = [[CHGBMessageTool sharedTool] getMessageModelWith:message];
////        if ([model.msg_body.extras.content containsString:keyWord]) {
////            [arr addObject:message];
////        }
////    }
//
//    [rs close];
//    return arr;
//}
//
////获取目标会话下存在关键字的消息
//- (NSArray<IMessage *> *)getTargetMessageAndLocationWithKeyWord:(NSString *)keyWord target:(int64_t)targetUid {
//    FMDatabase *db = self.db;
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE content LIKE '%%%@%%' AND peer = %lld ORDER BY timestamp ASC", keyWord, targetUid];
//    FMResultSet *rs = [db executeQuery:selectStr];
//    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
//    while ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"receiver"];
//        msg.timestamp = [rs longLongIntForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.secret = [rs intForColumn:@"secret"] == 1;
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs longLongIntForColumn:@"id"];
//        msg.haveRead = [rs intForColumn:@"haveread"] == 1;
//        msg.readUUID = [rs stringForColumn:@"readuuid"];
//        msg.manualHeight = (float)[rs intForColumn:@"cacheheight"];
//        msg.manualWidth = (float)[rs intForColumn:@"cachewidth"];
//        msg.lineHeight = (float)[rs intForColumn:@"lineheight"];
//        msg.callBack = (float)[rs intForColumn:@"callback"] == 1;
//        msg.deleteTag = (float)[rs intForColumn:@"deletetag"] == 1;
//        [messageArr addObject:msg];
//    }
//
//    NSMutableArray *arr = [[NSMutableArray alloc] init];
////    for (IMessage *message in messageArr) {
////        CHGBMessageModel *model = [[CHGBMessageTool sharedTool] getMessageModelWith:message];
////        if ([model.msg_body.extras.content containsString:keyWord]) {
////            [arr addObject:message];
////        }
////    }
//
//    [rs close];
//    return arr;
//}
//
////获取传入message的早于该消息的前面两条
//- (NSArray<IMessage *> *)getTargetMessageWith:(IMessage *)message uid:(int64_t)targetUid {
//    FMDatabase *db = self.db;
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %lld ORDER BY timestamp ASC", targetUid];
//    FMResultSet *rs = [db executeQuery:selectStr];
//    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
//
//    while ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"receiver"];
//        msg.timestamp = [rs longLongIntForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.secret = [rs intForColumn:@"secret"] == 1;
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs longLongIntForColumn:@"id"];
//        msg.haveRead = [rs intForColumn:@"haveread"] == 1;
//        msg.readUUID = [rs stringForColumn:@"readuuid"];
//        msg.manualHeight = (float)[rs intForColumn:@"cacheheight"];
//        msg.manualWidth = (float)[rs intForColumn:@"cachewidth"];
//        msg.lineHeight = (float)[rs intForColumn:@"lineheight"];
//        msg.callBack = (float)[rs intForColumn:@"callback"] == 1;
//        msg.deleteTag = (float)[rs intForColumn:@"deletetag"] == 1;
//        [messageArr addObject:msg];
//    }
//
//    NSMutableArray *backMessages = [[NSMutableArray alloc] init];
//
//    int index = 0;
//    for (int i = 0; i < messageArr.count; i++) {
//        if ([messageArr[i].readUUID isEqualToString:message.readUUID]) {
//            index = i;
//            break;
//        }
//    }
//
//    if (index > 2) {
//        [messageArr removeObjectsInRange:NSMakeRange(0, index - 2)];
//        if (messageArr.count > 20) {
//            for (int i = 0; i < 20; i++) {
//                [backMessages addObject:messageArr[i]];
//            }
//        }else{
//            backMessages = [[NSMutableArray alloc] initWithArray:messageArr];
//        }
//    }else{
//        if (messageArr.count > 20) {
//            for (int i = 0; i < 20; i++) {
//                [backMessages addObject:messageArr[i]];
//            }
//        }else{
//            backMessages = [[NSMutableArray alloc] initWithArray:messageArr];
//        }
//    }
//
//
//    return backMessages;
//}
//
//-(BOOL)eraseMessageFailure:(NSInteger)msgLocalID {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"flags"];
//
//        int f = MESSAGE_FLAG_FAILURE;
//        flags &= ~f;
//
//        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//    }
//
//    [rs close];
//    return YES;
//}
//
//-(BOOL)eraseMessageFailure:(NSInteger)msg haveRead:(BOOL)haveRead {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msg)];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"flags"];
//
//        int f = MESSAGE_FLAG_FAILURE;
//        flags &= ~f;
//
//        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msg)];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//        int havereadnum = haveRead == YES ? 1 : 0;
//        BOOL r2 = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE id= ?", @(havereadnum), @(msg)];
//        if (!r2) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//    }
//
//    [rs close];
//    return YES;
//}
//
//-(BOOL)updateFlags:(NSInteger)msgLocalID flags:(int)flags {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateHaveRead:(NSInteger)msgLocalID haveRead:(int)haveRead uuidStr:(NSString *)readUUID {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE readuuid= ?", @(haveRead), readUUID];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateCallBack:(NSString *)uuid {
//    IMessage *msg = [self getMessage:(int64_t)[uuid integerValue]];
//    NSLog(@"msg.RawContent = %@", msg.rawContent);
//
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET callback= ? WHERE readuuid= ?", @(1), uuid];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateDelete:(NSString *)uuid {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET deletetag= ? WHERE readuuid= ?", @(1), uuid];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateCallBackWithUUIDs:(NSArray *)uuidArr {
//    FMDatabase *db = self.db;
//    NSString *sqlStr;
//
//    if (uuidArr.count > 0) {
//        NSMutableString *str = [[NSMutableString alloc] init];
//        [str appendString:@"("];
//        for (NSString *subStr in uuidArr) {
//            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
//        }
//        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
//        [str appendString:@")"];
//        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET callback= %@ WHERE readuuid IN %@", @(1), str];
//    }
//
//    BOOL r = [db executeUpdate:sqlStr];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateHaveRead:(int)haveRead uuidArr:(NSArray *)readUUIDArr {
//    FMDatabase *db = self.db;
//    NSString *sqlStr;
//
////    NSString *selfUid = [CHGBSignatureModel localSignatureModel].uid;
//
////    if (readUUIDArr.count > 0) {
////        NSMutableString *str = [[NSMutableString alloc] init];
////        [str appendString:@"("];
////        for (NSString *subStr in readUUIDArr) {
////            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
////        }
////        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
////        [str appendString:@")"];
////        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= %@ WHERE readuuid NOT IN %@ AND haveread= 0 AND sender= %@", @(haveRead), str, selfUid];
////    }else{
////        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= 1 WHERE haveread= 0 AND sender= %@", selfUid];
////    }
////
////    BOOL r = [db executeUpdate:sqlStr];
////    if (!r) {
////        NSLog(@"error = %@", [db lastErrorMessage]);
////        return NO;
////    }
//    return YES;
//}
//
//- (BOOL)updateMessageWidth:(float)width height:(float)height lineHeight:(float)lineHeight msgId:(NSInteger)msg {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE id= ?", @(height), @(width), @(lineHeight), @(msg)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)updateNewMessageWithUUidArr:(NSArray *)readUUIDArr uid:(int64_t)targetUid {
//    FMDatabase *db = self.db;
//    NSString *sqlStr;
//
//    if (readUUIDArr.count > 0) {
//        NSMutableString *str = [[NSMutableString alloc] init];
//        [str appendString:@"("];
//        for (NSString *subStr in readUUIDArr) {
//            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
//        }
//        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
//        [str appendString:@")"];
//        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= 0 WHERE readuuid IN %@ AND sender= %@", str, [NSString stringWithFormat:@"%lld", targetUid]];
//    }else{
//        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET flags= %@, haveread= 1 WHERE sender= %@", @(MESSAGE_FLAG_LISTENED), [NSString stringWithFormat:@"%lld", targetUid]];
//    }
//
//    BOOL r = [db executeUpdate:sqlStr];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(id<IMessageIterator>)newMessageIterator:(int64_t)uid {
//    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid secret:self.secret];
//}
//
//-(id<IMessageIterator>)newMessageIterator:(int64_t)uid timeStamp:(NSInteger)timeStamp {
//    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid timeStamp:timeStamp];
//}
//
//-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid timeStamp:(NSInteger)timeStamp {
//    return [[SQLPeerMessageIterator alloc] initForwardWithDB:self.db peer:uid timeStamp:timeStamp];
//}
//
//-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid timeStamp:(NSInteger)timeStamp {
//    return [[SQLPeerMessageIterator alloc] initBackwardWithDB:self.db peer:uid timeStamp:timeStamp];
//}
//
//-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid last:(int)lastMsgID {
//    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid position:lastMsgID secret:self.secret];
//}
//-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)uid messageID:(int)messageID {
//    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid middle:messageID secret:self.secret];
//}
//
//-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid messageID:(int)messageID {
//    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid last:messageID secret:self.secret];
//}


@end


