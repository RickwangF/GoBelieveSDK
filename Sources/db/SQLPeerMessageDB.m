#import "SQLPeerMessageDB.h"

#import "NSString+JSMessagesView.h"

@import SQLite3;

static const NSString *allColumns = @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, "
                                    @"lineheight, callback, deletetag, content";

@interface SQLPeerMessageIterator () <IMessageIterator>

//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer secret:(BOOL)secret;
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID secret:(BOOL)secret;

- (SQLPeerMessageIterator *)initWithDB:(FMDatabase *)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp;

- (SQLPeerMessageIterator *)initBackwardWithDB:(FMDatabase *)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp;

@property(nonatomic, strong) FMResultSet *rs;
@end

@implementation SQLPeerMessageIterator

// thread safe problem
- (void)dealloc {
    [self.rs close];
}

- (SQLPeerMessageIterator *)initWithDB:(FMDatabase *)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND timestamp < %@ AND "
                                                   @"deletetag = 0 ORDER BY timestamp DESC LIMIT 0,20",
                                                   @(peer), @(timeStamp)];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        self.rs = [db executeQuery:sql];
    }
    return self;
}

- (SQLPeerMessageIterator *)initBackwardWithDB:(FMDatabase *)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND timestamp > %@ AND "
                                                   @"deletetag = 0 ORDER BY timestamp ASC LIMIT 0,20",
                                                   @(peer), @(timeStamp)];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        self.rs = [db executeQuery:sql];
    }
    return self;
}

//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? ORDER BY
//        id DESC"; self.rs = [db executeQuery:sql, @(peer), @(s)];
//    }
//    return self;
//}
//
//
//-(SQLPeerMessageIterator*)initForwardWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND timestamp < ? ORDER
//        BY timestamp DESC"; self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id <
//        ? ORDER BY id DESC"; self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer middle:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id >
//        ? AND id < ? ORDER BY id DESC"; self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID-10), @(msgID+10)];
//    }
//    return self;
//}
//
//-(SQLPeerMessageIterator*)initBackwardWithDB:(FMDatabase*)db peer:(int64_t)peer timeStamp:(NSInteger)timeStamp {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND timestamp > ? ORDER
//        BY timestamp ASC"; self.rs = [db executeQuery:sql, @(peer), @(timeStamp)];
//    }
//    return self;
//}
//
////上拉刷新
//-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer last:(int)msgID secret:(BOOL)secret {
//    self = [super init];
//    if (self) {
//        int s = secret ? 1 : 0;
//        NSString *sql = @"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight,
//        cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND secret = ? AND id>?
//        ORDER BY id"; self.rs = [db executeQuery:sql, @(peer), @(s), @(msgID)];
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

    return [SQLPeerMessageIterator messageFromResultSet:self.rs];
}

/// 将FMDB结果集转化成IMessage对象
/// @param set 数据库结果集
+ (IMessage *)messageFromResultSet:(FMResultSet *)set {
    IMessage *message = [[IMessage alloc] init];
    [message setSender:[set longLongIntForColumn:@"sender"]];
    [message setReceiver:[set longLongIntForColumn:@"receiver"]];
    [message setTimestamp:[set longLongIntForColumn:@"timestamp"]];
    [message setFlags:[set intForColumn:@"flags"]];
    [message setRawContent:[set stringForColumn:@"content"]];
    [message setHaveRead:[set intForColumn:@"haveread"] == 1];
    [message setReadUUID:[set stringForColumn:@"readuuid"]];
    [message setManualWidth:(float)[set doubleForColumn:@"cachewidth"]];
    [message setManualHeight:(float)[set intForColumn:@"cacheheight"]];
    [message setLineHeight:(float)[set intForColumn:@"lineheight"]];
    [message setCallBack:[set intForColumn:@"callback"] == 1];
    [message setDeleteTag:[set intForColumn:@"deletetag"] == 1];
    return message;
}

@end

@implementation SQLPeerMessageDB
/// 获取单条消息
/// @param uuid 消息唯一标识
- (IMessage *)getMessage:(NSString *)uuid {
    NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE readuuid= %@", uuid];
    FMResultSet *rs = [self.db executeQuery:sqlStr];
    if ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [rs close];
        return msg;
    }
    [rs close];
    return nil;
}

/// 存储消息
/// @param msg 消息体
- (BOOL)saveMessage:(IMessage *)msg {
    return [self insertMessage:msg uid:msg.receiver];
}

/// 保存消息至数据库
/// @param msg 消息体
/// @param uid 消息保存uid
- (BOOL)insertMessage:(IMessage *)msg uid:(int64_t)uid {
    FMDatabase *db = self.db;
    [db beginTransaction];
    NSData *jsonData = [msg.rawContent dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    if (dic[@"msg_uuid"] && [dic[@"msg_uuid"] isNotEmpty]) {
        [msg setReadUUID:[NSString stringWithFormat:@"%@", dic[@"msg_uuid"]]];
    }
    BOOL haveMessage = NO;
    FMResultSet *selectResult =
        [db executeQuery:@"SELECT readuuid FROM peer_message WHERE peer = ? AND readuuid = ?", @(uid), msg.readUUID];
    if (selectResult.next) {
        haveMessage = YES;
    }
    [selectResult close];

    if (haveMessage == NO) {
        //    @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback,
        //    deletetag, content"
        NSString *readuuid = [msg.readUUID isNotEmpty] ? msg.readUUID : @"";
        NSString *content = [msg.rawContent isNotEmpty] ? msg.rawContent : @"";
        BOOL result = [db
            executeUpdate:
                @"INSERT INTO peer_message (peer, sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, "
                @"cachewidth, lineheight, callback, deletetag, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp), @(msg.flags), @(msg.haveRead), readuuid,
                @(msg.manualHeight), @(msg.manualWidth), @(msg.lineHeight), @(msg.callBack), @(msg.deleteTag), content];

        if (!result) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }

        int64_t rowID = [self.db lastInsertRowId];
        msg.msgId = rowID;

        if (msg.textContent) {
            NSString *text = [msg.textContent.text isKindOfClass:NSString.class] ? [msg.textContent.text tokenizer]:@"";
            [db executeUpdate:@"INSERT INTO peer_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
        }

        result = [db commit];
        return result;
    }
    [db commit];
    return NO;
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
/// @param timestamp 时间
- (BOOL)eraseMessageFailure:(NSString *)uuid timestamp:(int64_t)timestamp {
    if ([uuid isNotEmpty] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];

        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ?, timestamp= ? WHERE readuuid= ?", @(flags),
                                   @(timestamp), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [rs close];
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 修改消息读取状态
/// @param uuid 消息唯一标识
- (BOOL)markMesageHaveRead:(NSString *)uuid {
    if ([uuid isNotEmpty] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"haveread"];
        flags |= 1;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [rs close];
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
    FMResultSet *rs =
        [db executeQuery:@"SELECT * FROM peer_message WHERE flags=? AND peer=? AND callback == 0 AND deletetag = 0", @(MESSAGE_FLAG_FAILURE), @(uid)];
    if ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [failedArr addObject:msg];
    }
    [rs close];
    return failedArr;
}

/// 更新消息撤回状态
/// @param uuids 已经撤回的消息uuid数组
- (BOOL)updateCallbackUUIDS:(NSArray *)uuids {
    if (uuids.count > 0) {
        FMDatabase *db = self.db;
        NSString *sqlStr;
        if (uuids.count > 0) {
            NSMutableString *str = [[NSMutableString alloc] init];
            [str appendString:@"("];
            for (NSString *subStr in uuids) {
                [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
            }
            [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
            [str appendString:@")"];
            sqlStr =
                [NSString stringWithFormat:@"UPDATE peer_message SET callback= %@ WHERE readuuid IN %@", @(1), str];
        }

        BOOL r = [db executeUpdate:sqlStr];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    } else {
        return NO;
    }
    return YES;
}

/// 更新消息删除状态
/// @param uuids 已经删除的消息uuid数组
- (BOOL)updateDeleteUUIDS:(NSArray *)uuids {
    if (uuids.count > 0) {
        FMDatabase *db = self.db;
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
    } else {
        return NO;
    }
    return YES;
}

/// 批量更新发送者的消息已读状态
/// @param uuids 未读消息uuid数组
- (BOOL)updateHaveNotReadUUIDS:(NSArray *)uuids {
    FMDatabase *db = self.db;
    NSString *sqlStr;
    
    if (uuids.count > 0) {
        NSMutableString *str = [[NSMutableString alloc] init];
        [str appendString:@"("];
        for (NSString *subStr in uuids) {
            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
        }
        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
        [str appendString:@")"];
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE peer_message SET haveread= %@ WHERE readuuid NOT IN %@ AND haveread= 0 AND flags != %@", @(1),
                str, @(MESSAGE_FLAG_FAILURE)];
    }else{
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE peer_message SET haveread= %@ WHERE haveread= 0 AND flags != %@", @(1), @(MESSAGE_FLAG_FAILURE)];
    }

    BOOL r = [db executeUpdate:sqlStr];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

/// 批量更新消息已读状态，此方法不更新非自己发送的消息已读状态
/// @param uuids 未读消息uuid数组
/// @param sender 自己的uid
- (BOOL)updateHaveNotReadUUIDS:(NSArray *)uuids sender:(int64_t)sender {
    FMDatabase *db = self.db;
    NSString *sqlStr;
    
    if (uuids.count > 0) {
        NSMutableString *str = [[NSMutableString alloc] init];
        [str appendString:@"("];
        for (NSString *subStr in uuids) {
            [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
        }
        [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
        [str appendString:@")"];
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE peer_message SET haveread= %@ WHERE readuuid NOT IN %@ AND haveread= 0 AND flags != %@ AND sender = %@", @(1),
                str, @(MESSAGE_FLAG_FAILURE), @(sender)];
    }else{
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE peer_message SET haveread= %@ WHERE haveread= 0 AND flags != %@ AND sender = %@", @(1), @(MESSAGE_FLAG_FAILURE), @(sender)];
    }

    BOOL r = [db executeUpdate:sqlStr];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

/// 更新消息宽高以及行高
/// @param width 消息宽度
/// @param height 消息高度
/// @param lineHeight 消息行高
/// @param uuid 消息唯一标识
- (BOOL)updateMessageWidth:(float)width height:(float)height lineHeight:(float)lineHeight msgUUID:(NSString *)uuid {
    FMDatabase *db = self.db;

    BOOL r =
        [db executeUpdate:@"UPDATE peer_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE readuuid= ?",
                          @(height), @(width), @(lineHeight), uuid];
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
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE REGEXA(content, '%@')", keyword];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

/// 给数据库动态添加正则匹配方法
/// 使用方法示例，下面这个SQL语句会查询content字段中包含你好字样的记录：
/// SELECT * FROM peer_message WHERE REGEXA(content, '你好')
- (void)regularExpressionFunctionAdd {
    [self.db makeFunctionNamed:@"REGEXA" arguments:2 block:^(void * _Nonnull context, int argc, void * _Nonnull * _Nonnull argv) {
        if ((sqlite3_value_type(argv[0]) == SQLITE_TEXT) && (sqlite3_value_type(argv[1]) == SQLITE_TEXT)) {
            @autoreleasepool {
                const char *cString = (const char *)sqlite3_value_text(argv[0]);
                const char *cString2 = (const char *)sqlite3_value_text(argv[1]);
                NSString *content = [NSString stringWithUTF8String:cString];
                NSString *keyword = [NSString stringWithUTF8String:cString2];
                NSError *error = nil;
                NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\"content\":\"[^\"]{0,}%@", keyword] options:NSRegularExpressionCaseInsensitive error:&error];
                if (error) {
#if DEBUG
                    NSLog(@">>> expression error: %@", error.localizedDescription);
#endif
                    sqlite3_result_null(context);
                    return;
                }
                NSTextCheckingResult *result = [expr firstMatchInString:content options:NSMatchingReportCompletion range:NSMakeRange(0, content.length)];
                if (!result || result.range.location == NSNotFound) {
#if DEBUG
                    NSLog(@">>> not found %@ at %@", expr.pattern, content);
#endif
                    sqlite3_result_null(context);
                    return;
                }
                sqlite3_result_int(context, 1);
            }
        } else {
#if DEBUG
            NSLog(@"Unknown formart for REGEXA (%d, %d) %s:%d", sqlite3_value_type(argv[0]), sqlite3_value_type(argv[1]), __FUNCTION__, __LINE__);
#endif
            sqlite3_result_null(context);
        }
    }];
}

/// 获取目标下包含关键字的消息
/// @param keyword 关键字
/// @param targetUid targetUid
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword targetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE REGEXA(content, '%@') AND peer = %@", keyword,
                                   @(targetUid)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (BOOL)addFlag:(NSString *)uuid flag:(int)f {
    if ([uuid isNotEmpty] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE readuuid=?", uuid];
    if (!rs) {
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [rs close];
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
    FMResultSet *result = [db executeQuery:@"SELECT * FROM peer_message LIMIT 10;"];
    // 字段名
    NSArray<NSString *> *columnNames = @[@"cacheheight",
                                         @"cachewidth",
                                         @"lineheight",
                                         @"callback",
                                         @"deletetag",
                                         @"haveread",
                                         @"readuuid"];
    // 字段生成约束
    NSArray<NSString *> *constraints = @[@"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"TEXT"];
    // 表中所有字段名
    NSDictionary<NSString *, NSNumber *> *all = [result columnNameToIndexMap];

    for (int j = 0; j < columnNames.count; j++) {
        NSString *name = columnNames[j];
        __block BOOL found = NO;
        [all enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:name]) {
                found = YES;
                *stop = true;
            }
        }];
        if (!found) {
            BOOL state = [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE peer_message ADD %@ %@", name, constraints[j]]];
            NSLog(@"群插入%@列%@", name, state ? @"成功" : @"失败");
        }
    }
    [result close];
//    BOOL haveCacheHeight = NO;
//    BOOL haveCacheWidth = NO;
//    BOOL haveLineHeight = NO;
//    BOOL haveCallBack = NO;
//    BOOL haveDeleteMessage = NO;
//    FMResultSet *result = [db executeQuery:@"SELECT * FROM peer_message"];
//    for (int i = 0; i < [result columnCount]; i++) {
//        NSString *columnName = [result columnNameForIndex:i];
//        if ([columnName containsString:@"cacheheight"]) {
//            haveCacheHeight = YES;
//        } else if ([columnName containsString:@"cachewidth"]) {
//            haveCacheWidth = YES;
//        } else if ([columnName containsString:@"lineheight"]) {
//            haveLineHeight = YES;
//        } else if ([columnName containsString:@"callback"]) {
//            haveCallBack = YES;
//        } else if ([columnName containsString:@"deletetag"]) {
//            haveDeleteMessage = YES;
//        }
//    }
//    if (haveCacheWidth == YES && haveLineHeight == YES && haveCacheHeight == YES && haveCallBack == YES &&
//        haveDeleteMessage == YES) {
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
//    [result close];
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

/// 通过uid获取当前会话最新的没有做删除的消息
/// @param targetUid 目标uid
- (IMessage *)getLatestMessageWithTargetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    //    SELECT * FROM peer_message WHERE timestamp= (SELECT MAX(timestamp) FROM peer_message) AND peer =
    //    1586920918308426275 AND deletetag = 0
    NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE timestamp= (SELECT MAX(timestamp) "
                                                  @"FROM peer_message WHERE deletetag = 0 AND peer = %@)",
                                                  @(targetUid)];
    FMResultSet *rs = [db executeQuery:sqlStr];

    if ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [db commit];
        [rs close];
        return msg;
    }
    [db commit];
    [rs close];
    return nil;
}

#pragma mark - gobelieve handler method
- (int)gobelieveGetMessageId:(NSString *)uuid {
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
    FMResultSet *rs = [self.db
        executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread, readuuid, cacheheight, "
                     @"cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE id= ?",
                     @(msgID)];
    if ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [rs close];
        return msg;
    }
    [rs close];
    return nil;
}

- (BOOL)gobelieveUpdateFlags:(NSInteger)msgLocalID flags:(int)flags {
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
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;

        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [rs close];
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 获取指定消息的前两条开始往后面的20条数据
/// @param conversationID 聊天会话id
/// @param uuid 消息唯一标识符
- (NSArray<IMessage *> *)fetchHistoryWithConversationID:(int64_t)conversationID baseOnUUID:(NSString *_Nonnull)uuid {
    FMDatabase *db = self.db;
    // 前两条数据和后18条数据合并，最后按时间升序排序
    NSString *selectStr = [NSString
          stringWithFormat:@"SELECT * FROM (SELECT * FROM peer_message "
                           @"WHERE peer = %@ "
                           @"AND timestamp < (SELECT timestamp FROM peer_message b  WHERE peer = %@ AND readuuid = '%@') "
                           @"AND deletetag = 0 "
                           @"ORDER BY timestamp "
                           @"DESC "
                           @"LIMIT 0,2) "
                           @"union "
                           @"SELECT * FROM (SELECT * FROM peer_message "
                           @"WHERE peer = %@ "
                           @"AND timestamp >= (SELECT timestamp FROM peer_message b  WHERE peer = %@ AND "
                           @"readuuid = '%@') "
                           @"AND deletetag = 0 "
                           @"ORDER BY "
                           @"timestamp "
                           @"ASC "
                           @"LIMIT 0,18) "
                           @"ORDER BY timestamp "
                           @"ASC ",
                           @(conversationID),
                           @(conversationID),
                           uuid,
                           @(conversationID),
                           @(conversationID),
                           uuid];
#if DEBUG
    NSLog(@">>> sql fetchHistoryWithConversationID %@", selectStr);
#endif
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

/// 查询多条消息，根据uuid查
/// @param uuids 消息uuid集合
- (NSArray<IMessage *> * _Nonnull)queryMessagesWithUUIDs:(NSArray<NSString *> * _Nonnull)uuids {
    if (!([uuids isKindOfClass:NSArray.class] && uuids.count > 0)) {
#if DEBUG
    NSLog(@">>> queryMessagesWithUUIDs uuids is invalid, %@", uuids);
#endif
        return @[];
    }
    FMDatabase *db = self.db;
    NSString *ids = [uuids componentsJoinedByString:@","];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE readuuid IN (%@)", ids];
#if DEBUG
    NSLog(@">>> sql queryMessagesWithUUIDs: %@", sql);
#endif
    FMResultSet *rs = [db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}


/// 查询第一条未读消息（非本人发送）到指定消息的消息集合，按时间升序排列
/// @param uuid 最后的消息uuid，为nil则返回到最后一条消息
/// @param targetUID 聊天id，单聊是对方的UID，群聊是GID
/// @param senderUID 发送方id
- (NSArray<IMessage *> * _Nonnull)queryUnreadMessagesToUUID:(NSString * _Nullable)uuid byTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID {
    NSString *sql;
    if ([uuid isKindOfClass:NSString.class] && uuid.length > 0) {
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND timestamp >= (SELECT timestamp FROM peer_message WHERE peer = %@  AND haveread = 0 AND deletetag = 0 AND sender != %@ ORDER BY timestamp ASC LIMIT 1) AND timestamp <= (SELECT timestamp FROM peer_message WHERE peer = %@ AND readuuid = '%@') ORDER BY timestamp ASC",
               @(targetUID),
               @(senderUID),
               @(targetUID),
               @(targetUID),
               uuid];
    }   else    {
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND timestamp >= (SELECT timestamp FROM peer_message WHERE peer = %@  AND haveread = 0 AND deletetag = 0 AND sender != %@ ORDER BY timestamp ASC LIMIT 1) ORDER BY timestamp ASC",
               @(targetUID),
               @(targetUID),
               @(senderUID)];
    }
    
#if DEBUG
    NSLog(@">>> sql queryUnreadMessagesToUUID: %@", sql);
#endif
    FMResultSet *rs = [self.db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}

/// 查询两条消息之间的所有消息，同一会话下
/// @param bottomUUID 底部最后一条消息，不存在时则查所有的
/// @param topUUID 顶部第一条消息
/// @param targetUID 会话uid
/// @param limited 查询条数，当前没有底部信息限制时此参数控制返回的条数
- (NSArray<IMessage *> * _Nonnull)queryMessagesToUUID:(NSString * _Nullable)bottomUUID from:(NSString * _Nonnull)topUUID byTargetUID:(int64_t)targetUID limited:(NSInteger)limited {
    if (!([topUUID isKindOfClass:NSString.class] && topUUID.length > 0)) {
        return @[];
    }
    NSString *sql;
    if ([bottomUUID isKindOfClass:NSString.class] && bottomUUID.length > 0) {
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND timestamp <= (SELECT timestamp FROM peer_message WHERE readuuid = '%@') AND timestamp >= (SELECT timestamp FROM peer_message WHERE readuuid = '%@') ORDER BY timestamp ASC;", @(targetUID), bottomUUID, topUUID];
    }   else    {
        NSString *limitedString = limited > 0 ? [NSString stringWithFormat:@" LIMIT %ld", limited]:@"";
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND timestamp >= (SELECT timestamp FROM peer_message WHERE readuuid = '%@') ORDER BY timestamp ASC%@;", @(targetUID), topUUID, limitedString];
    }
    
#if DEBUG
    NSLog(@">>> sql queryMessagesToUUID:from:byTargetUID: %@", sql);
#endif
    
    FMResultSet *rs = [self.db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}

- (NSArray<IMessage *> * _Nonnull)queryUnreadOnlyMessagesToUUID:(NSString * _Nullable)uuid byTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID {
    NSString *sql;
    if ([uuid isKindOfClass:NSString.class] && uuid.length > 0) {
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND haveread = 0 AND sender != %@ AND timestamp >= (SELECT timestamp FROM peer_message WHERE peer = %@  AND haveread = 0 AND deletetag = 0 AND sender != %@ ORDER BY timestamp ASC LIMIT 1) AND timestamp <= (SELECT timestamp FROM peer_message WHERE peer = %@ AND readuuid = '%@') ORDER BY timestamp ASC",
               @(targetUID),
               @(senderUID),
               @(senderUID),
               @(targetUID),
               @(targetUID),
               uuid];
    }   else    {
        sql = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %@ AND deletetag = 0 AND haveread = 0 AND sender != %@ AND timestamp >= (SELECT timestamp FROM peer_message WHERE peer = %@  AND haveread = 0 AND deletetag = 0 AND sender != %@ ORDER BY timestamp ASC LIMIT 1) ORDER BY timestamp ASC",
               @(targetUID),
               @(senderUID),
               @(targetUID),
               @(senderUID)];
    }
    
#if DEBUG
    NSLog(@">>> sql queryUnreadOnlyMessagesToUUID: %@", sql);
#endif
    FMResultSet *rs = [self.db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLPeerMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}

/// 所有聊天消息（非自己发送的、不失败的）调整为已读
- (BOOL)markAllMessagesRead:(int64_t)sender {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE peer_message SET haveread= ? WHERE haveread= 0 AND flags != ? AND sender != ?", @(1), @(MESSAGE_FLAG_FAILURE), @(sender)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

//- (BOOL)checkHaveFailedMessageUid:(int64_t)uid {
//    FMDatabase *db = self.db;
//    BOOL haveFailed = NO;
//    FMResultSet *result = [db executeQuery:@"SELECT * FROM peer_message WHERE flags=? AND peer=?",
//    @(MESSAGE_FLAG_FAILURE), @(uid)]; while ([result next]) {
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
//    if (haveCacheWidth == YES && haveLineHeight == YES && haveCacheHeight == YES && haveCallBack == YES &&
//    haveDeleteMessage == YES) {
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
////    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread,
/// readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND
/// readuuid = ?", @(uid), msg.readUUID]; /    if (rs.next) { /        haveMessage = YES; /    }
////
////    if (haveMessage == NO) {
////        FMDatabase *db = self.db;
////
////        [db beginTransaction];
////        int secret = self.secret ? 1 : 0;
////        NSString *uuid = msg.uuid ? msg.uuid : @"";
////        CHGBMessageModel *model = [[CHGBMessageTool sharedTool] getMessageModelWith:msg];
////        BOOL r = [db executeUpdate:@"INSERT INTO peer_message (peer, sender, receiver, timestamp, secret, flags,
/// haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, uuid, content) VALUES (?, ?, ?, ?, ?,
///?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", /                  @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp),
///@(secret), @(msg.flags), @(msg.haveRead), model.msg_uuid, @(msg.manualHeight), @(msg.manualWidth), @(msg.lineHeight),
///@(msg.callBack), @(msg.deleteTag), uuid, msg.rawContent];
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
//    NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM peer_message_fts WHERE peer_message_fts MATCH
//    '%@'", key];
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
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread,
//    readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE peer = ? AND
//    secret = ? ORDER BY id DESC", @(uid), @(s)]; if ([rs next]) {
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
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, secret, flags, haveread,
//    readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content FROM peer_message WHERE id= ?",
//    @(msgID)]; if ([rs next]) {
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
////    FMResultSet *rs = [self.db executeQuery:[NSString stringWithFormat:@"SELECT readuuid FROM peer_message WHERE
/// haveread= 0 AND sender=%@", selfUid]];
//    NSMutableArray *unreadArr = [[NSMutableArray alloc] init];
////    while ([rs next]) {
////        if ([[rs stringForColumn:@"readuuid"] isNotEmpty]) {
////            [unreadArr addObject:[rs stringForColumn:@"readuuid"]];
////        }
////    }
//    return unreadArr;
//}
//
//- (NSArray *)getRecalledMsgs {
//    FMResultSet *rs = [self.db executeQuery:[NSString stringWithFormat:@"SELECT readuuid FROM peer_message WHERE
//    callback= 1"]]; NSMutableArray *unreadArr = [[NSMutableArray alloc] init];
////    while ([rs next]) {
////        if ([[rs stringForColumn:@"readuuid"] isNotEmpty]) {
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
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE content LIKE '%%%@%%'",
//    keyWord]; FMResultSet *rs = [db executeQuery:selectStr]; NSMutableArray<IMessage *> *messageArr = [[NSMutableArray
//    alloc] init]; while ([rs next]) {
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
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE content LIKE '%%%@%%' AND peer
//    = %lld ORDER BY timestamp ASC", keyWord, targetUid]; FMResultSet *rs = [db executeQuery:selectStr];
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
//    NSString *selectStr = [NSString stringWithFormat:@"SELECT * FROM peer_message WHERE peer = %lld ORDER BY timestamp
//    ASC", targetUid]; FMResultSet *rs = [db executeQuery:selectStr]; NSMutableArray<IMessage *> *messageArr =
//    [[NSMutableArray alloc] init];
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
////        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= %@ WHERE readuuid NOT IN %@ AND
/// haveread= 0 AND sender= %@", @(haveRead), str, selfUid]; /    }else{ /        sqlStr = [NSString
/// stringWithFormat:@"UPDATE peer_message SET haveread= 1 WHERE haveread= 0 AND sender= %@", selfUid]; /    }
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
//    BOOL r = [db executeUpdate:@"UPDATE peer_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE id= ?",
//    @(height), @(width), @(lineHeight), @(msg)]; if (!r) {
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
//        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET haveread= 0 WHERE readuuid IN %@ AND sender=
//        %@", str, [NSString stringWithFormat:@"%lld", targetUid]];
//    }else{
//        sqlStr = [NSString stringWithFormat:@"UPDATE peer_message SET flags= %@, haveread= 1 WHERE sender= %@",
//        @(MESSAGE_FLAG_LISTENED), [NSString stringWithFormat:@"%lld", targetUid]];
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

#pragma mark - Testing

- (void)checkDuplicateMessageForPeer:(int64_t)peer {
    NSString *sql =
        [NSString stringWithFormat:@"SELECT sender, timestamp, readuuid FROM peer_message WHERE peer = %@", @(peer)];
#if DEBUG
    NSLog(@">>> query sql %@", sql);
#endif
    //    self. = [db executeQuery:sql];
}

@end
