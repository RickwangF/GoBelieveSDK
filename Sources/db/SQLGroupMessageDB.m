/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "SQLGroupMessageDB.h"

#import "NSString+JSMessagesView.h"

@import SQLite3;

static const NSString *allColumns = @"sender, group_id, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, "
                                    @"lineheight, callback, deletetag, content, purecontent, messagetype, source, readcount";

@interface SQLGroupMessageIterator () <IMessageIterator>
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID;
- (SQLGroupMessageIterator *)initWithDB:(FMDatabase *)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp;

- (SQLGroupMessageIterator *)initBackwardWithDB:(FMDatabase *)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp;

@property(nonatomic) FMResultSet *rs;
@end

@implementation SQLGroupMessageIterator

// thread safe problem
- (void)dealloc {
    [self.rs close];
}

- (SQLGroupMessageIterator *)initWithDB:(FMDatabase *)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND timestamp < %@ AND "
                                                   @"(deletetag = 0 OR deletetag IS NULL) ORDER BY timestamp DESC LIMIT 0,20",
                                                   @(gid), @(timeStamp)];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        self.rs = [db executeQuery:sql, @(gid), @(timeStamp)];
    }
    return self;
}

- (SQLGroupMessageIterator *)initBackwardWithDB:(FMDatabase *)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND timestamp > %@ AND "
                                                   @"(deletetag = 0 OR deletetag IS NULL) ORDER BY timestamp ASC LIMIT 0,21",
                                                   @(gid), @(timeStamp)];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        self.rs = [db executeQuery:sql, @(gid), @(timeStamp)];
    }
    return self;
}

//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=?
//        ORDER BY id DESC"; self.rs = [db executeQuery:sql, @(gid)];
//    }
//    return self;
//}
//
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=?
//        AND id < ? ORDER BY id DESC"; self.rs = [db executeQuery:sql, @(gid), @(msgID)];
//    }
//    return self;
//}
//
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=?
//        AND id > ? AND id < ? ORDER BY id DESC"; self.rs = [db executeQuery:sql, @(gid), @(msgID-10), @(msgID+10)];
//    }
//    return self;
//}
//
////上拉刷新
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=?
//        AND id>? ORDER BY id"; self.rs = [db executeQuery:sql, @(gid), @(msgID)];
//    }
//    return self;
//}
//
//-(IMessage*)next {
//    BOOL r = [self.rs next];
//    if (!r) {
//        return nil;
//    }
//
//    IMessage *msg = [[IMessage alloc] init];
//    msg.sender = [self.rs longLongIntForColumn:@"sender"];
//    msg.receiver = [self.rs longLongIntForColumn:@"group_id"];
//    msg.timestamp = [self.rs intForColumn:@"timestamp"];
//    msg.flags = [self.rs intForColumn:@"flags"];
//    msg.rawContent = [self.rs stringForColumn:@"content"];
//    msg.msgLocalID = [self.rs intForColumn:@"id"];
//    return msg;
//}

- (IMessage *)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }

    
    return [SQLGroupMessageIterator messageFromResultSet:self.rs];
}

/// 将FMDB结果集转化成IMessage对象
/// @param set 数据库结果集
+ (IMessage *)messageFromResultSet:(FMResultSet *)set {
    IMessage *message = [[IMessage alloc] init];
    [message setMsgId:[set longLongIntForColumn:@"id"]];
    [message setSender:[set longLongIntForColumn:@"sender"]];
    [message setReceiver:[set longLongIntForColumn:@"group_id"]];
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
    [message setPureContent:[set stringForColumn:@"purecontent"]];
    [message setMessageType:[set stringForColumn:@"messagetype"]];
    [message setSource:[set stringForColumn:@"source"]];
    [message setReadCount:[set intForColumn:@"readcount"]];
    return message;
}

@end

@implementation SQLGroupMessageDB

+ (SQLGroupMessageDB *)instance {
    static SQLGroupMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      if (!m) {
          m = [[SQLGroupMessageDB alloc] init];
      }
    });
    return m;
}

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

/// 获取单条消息
/// @param uuid 消息唯一标识
- (IMessage *)getMessage:(NSString *)uuid {
    NSString *text = [NSString stringWithFormat:@"SELECT %@ FROM group_message WHERE readuuid= '%@'", allColumns, uuid];
    FMResultSet *rs = [self.db executeQuery:text];
    if ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        return msg;
    }
    return nil;
}

/// 存储消息
/// @param msg 消息体
- (BOOL)saveMessage:(IMessage *)msg {
    return [self insertMessage:msg uid:msg.receiver];
}

/// 保存消息至数据库
/// @param msg 消息体
/// @param uid 消息保存群uid
- (BOOL)insertMessage:(IMessage *)msg uid:(int64_t)uid {
    FMDatabase *db = self.db;
    [db beginTransaction];
    NSData *jsonData = [msg.rawContent dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    if (dic[@"msg_uuid"] && [dic[@"msg_uuid"] isNotEmpty]) {
        [msg setReadUUID:[NSString stringWithFormat:@"%@", dic[@"msg_uuid"]]];
    }
    
    NSDictionary *bodyDictionary = dic[@"msg_body"];
    NSDictionary *extraDictionary;
    NSString *pureContent = @"";
    NSString *source = @"";
    NSString *messageType = @"";
    
    if (bodyDictionary) {
        extraDictionary = bodyDictionary[@"extras"];
        if (extraDictionary) {
            if (extraDictionary[@"content"]) {
                pureContent = [NSString stringWithFormat:@"%@", extraDictionary[@"content"]];
            } else if (bodyDictionary[@"text"]) {
                pureContent = [NSString stringWithFormat:@"%@", bodyDictionary[@"text"]];
            }
            
            if (extraDictionary[@"type"]) {
                messageType = [NSString stringWithFormat:@"%@", extraDictionary[@"type"]];
            }
            
            if (extraDictionary[@"src"]) {
                source = [NSString stringWithFormat:@"%@", extraDictionary[@"src"]];
            }
        }
    }
    
    BOOL haveMessage = NO;
    FMResultSet *selectResult = [db
        executeQuery:@"SELECT readuuid FROM group_message WHERE group_id = ? AND readuuid = ?", @(uid), msg.readUUID];
    if (selectResult.next) {
        haveMessage = YES;
    }
    [selectResult close];

    if (haveMessage == NO) {
        //    @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback,
        //    deletetag, content"
        NSString *readuuid = [msg.readUUID isNotEmpty] ? msg.readUUID : @"";
        NSString *content = [msg.rawContent isNotEmpty] ? msg.rawContent : @"";
        BOOL result = [db executeUpdate:@"INSERT INTO group_message (group_id, sender, timestamp, flags, "
                                        @"haveread, readuuid, cacheheight, cachewidth, lineheight, callback, "
                                        @"deletetag, content, purecontent, messagetype, source, readcount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                        @(uid), @(msg.sender), @(msg.timestamp), @(msg.flags),
                                        @(msg.haveRead), readuuid, @(msg.manualHeight), @(msg.manualWidth),
                                        @(msg.lineHeight), @(msg.callBack), @(msg.deleteTag), content, pureContent, messageType, source, @(0)];

        if (!result) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }

        int64_t rowID = [self.db lastInsertRowId];
        msg.msgId = rowID;

        if (msg.textContent) {
            NSString *text = [msg.textContent.text tokenizer];
            [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
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
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE readuuid=?", uuid];
    if (!rs) {
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];

        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;

        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ?, timestamp= ? WHERE readuuid= ?", @(flags),
                                   @(timestamp), uuid];
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
    if ([uuid isNotEmpty] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM group_message WHERE readuuid=?", uuid];
    if (!rs) {
        [rs close];
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"haveread"];
        flags |= 1;

        BOOL r = [db executeUpdate:@"UPDATE group_message SET haveread= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 批量更新多个消息为已读状态
/// @param uuids 消息唯一标识符
- (BOOL)markMesagesHaveRead:(NSArray<NSString *> * _Nonnull)uuids {
    if (!(uuids && uuids.count > 0)) {
        return NO;
    }
    
    FMDatabase *db = self.db;
    
    BOOL success = true;
    [db beginTransaction];
    
    // @"SELECT haveread FROM group_message WHERE readuuid=? AND json_extract(content, '$.target_type') != 'i_multi_group'"
    for (NSString *uuid in uuids) {
        FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM group_message WHERE readuuid=?", uuid];
        if (!rs) {
            continue;
        }
        
        if ([rs next]) {
            int flags = [rs intForColumn:@"haveread"];
            flags |= 1;

            BOOL r = [db executeUpdate:@"UPDATE group_message SET haveread= ? WHERE readuuid= ?", @(flags), uuid];
            success = r;
            if (!r) {
                [rs close];
                NSLog(@"error = %@", [db lastErrorMessage]);
                continue;
            }
        }
        [rs close];
    }
    
    if (!success) {
        [db rollback];
        return NO;
    }
    
    [db commit];
    return YES;
}

- (BOOL)updateMessageWithUUID:(NSString *)uuid readCount:(NSInteger)readCount {
    BOOL result = NO;
    
    FMDatabase *db = self.db;
    result = [db executeUpdate:@"UPDATE group_message SET readcount = ? WHERE readuuid = ?", @(readCount), uuid];
    
    return result;
}

/// 获取当前目标发送失败消息
/// @param gid 群聊gid
- (NSArray<IMessage *> *)getFailedMessages:(int64_t)gid {
    FMDatabase *db = self.db;
    NSMutableArray *failedArr = [[NSMutableArray alloc] init];
    FMResultSet *rs =
        [db executeQuery:@"SELECT * FROM group_message WHERE flags=? AND group_id=? AND callback == 0 AND (deletetag = 0 OR deletetag IS NULL)", @(MESSAGE_FLAG_FAILURE), @(gid)];
    if ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
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
                [NSString stringWithFormat:@"UPDATE group_message SET callback= %@ WHERE readuuid IN %@", @(1), str];
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
        sqlStr = [NSString stringWithFormat:@"UPDATE group_message SET deletetag= %@ WHERE readuuid IN %@", @(1), str];

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
                @"UPDATE group_message SET haveread= %@ WHERE readuuid NOT IN %@ AND (haveread = 0 OR haveread IS NULL) AND flags != %@", @(1),
                str, @(MESSAGE_FLAG_FAILURE)];
    }else{
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE group_message SET haveread= %@ WHERE (haveread = 0 OR haveread IS NULL) AND flags != %@", @1, @(MESSAGE_FLAG_FAILURE)];
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
                @"UPDATE group_message SET haveread= %@ WHERE readuuid NOT IN %@ AND (haveread = 0 OR haveread IS NULL) AND flags != %@ AND sender = %@", @(1),
                str, @(MESSAGE_FLAG_FAILURE), @(sender)];
    }else{
        sqlStr = [NSString
            stringWithFormat:
                @"UPDATE group_message SET haveread= %@ WHERE (haveread = 0 OR haveread IS NULL) AND flags != %@ AND sender = %@", @(1), @(MESSAGE_FLAG_FAILURE), @(sender)];
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
        [db executeUpdate:@"UPDATE group_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE readuuid= ?",
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
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE REGEXP(content, '%@') AND messagetype != 'notice'", keyword];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (NSArray<IMessage *> *)searchMessagesWithKeyword:(NSString *)keyword withGroupId:(int64_t)groupId{
    FMDatabase *db = self.db;
    NSString *escapedKeyword = [keyword stringByReplacingOccurrencesOfString:@"'" withString:@"''"]; // 防止SQL注入，处理单引号
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE pureContent like '%%%@%%' AND group_id = %@ AND callback = 0 AND deletetag = 0 AND messagetype != 'notice' ORDER BY timestamp DESC;", escapedKeyword, @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (NSArray<IMessage *> *)searchMessagesWithGroupId:(int64_t)groupId sender:(int64_t)sender {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND sender = %@ AND callback = 0 AND deletetag = 0 ORDER BY timestamp DESC;",@(groupId), @(sender)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (NSArray<IMessage *> *)searchVideoImageMessageWithGroupId:(int64_t)groupId {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND messageType IN ('video', 'image') AND callback = 0 AND deletetag = 0 ORDER BY timestamp DESC", @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (NSArray<IMessage *> *)searchFileMessageWithGroupId:(int64_t)groupId {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND messageType = 'file' AND callback = 0 AND deletetag = 0 ORDER BY timestamp DESC", @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (NSArray<IMessage *> *)searchLinkMessageWithGroupId:(int64_t)groupId {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (purecontent LIKE '%%http://%%' OR purecontent LIKE '%%https://%%') AND callback = 0 AND deletetag = 0 ORDER BY timestamp DESC", @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (int64_t)searchEarliestMessageTimestampWithGroupId:(int64_t)groupId {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT timestamp FROM group_message WHERE group_id = %@ AND callback = 0 AND deletetag = 0 ORDER BY timestamp ASC LIMIT 1", @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    
    int64_t timestamp = 0;
    if ([rs next]) {
        timestamp = [rs longLongIntForColumn:@"timestamp"];
    }
    [rs close];
    return timestamp;
}

- (NSArray<MessageDate *> *)searchMessageExistDateWithGroupId:(int64_t)groupId {
    NSMutableArray<MessageDate *> *result = [NSMutableArray array];
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT CAST(strftime('%%Y', timestamp / 1000, 'unixepoch') AS INTEGER) AS year, CAST(strftime('%%m', timestamp / 1000, 'unixepoch') AS INTEGER) AS month, CAST(strftime('%%d', timestamp / 1000, 'unixepoch') AS INTEGER) as day, COUNT(*) AS message_count, gm1.readuuid FROM group_message gm1 WHERE gm1.group_id = %@ GROUP BY year, month, day HAVING COUNT(*) > 0 ORDER BY year, month, day;", @(groupId)];
    FMResultSet *rs = [db executeQuery:selectStr];
    
    while ([rs next]) {
        MessageDate *messageDate = [[MessageDate alloc] init];
        messageDate.year = [rs intForColumn:@"year"];
        messageDate.month = [rs intForColumn:@"month"];
        messageDate.day = [rs intForColumn:@"day"];
        messageDate.count = [rs intForColumn:@"message_count"];
        messageDate.firstuuid = [rs stringForColumn:@"readuuid"];
        
        [result addObject:messageDate];
    }

    [rs close];
    return result;
}

/// 获取目标下包含关键字的消息
/// @param keyword 关键字
/// @param targetUid targetUid
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword targetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    NSString *selectStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE REGEXP(content, '%@') AND group_id = %@",
                                   keyword, @(targetUid)];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

/// 给数据库动态添加正则匹配方法
/// 使用方法示例，下面这个SQL语句会查询content字段中包含你好字样的记录：
/// SELECT * FROM group_message WHERE REGEXP(content, '你好')
- (void)regularExpressionFunctionAdd {
    [self.db makeFunctionNamed:@"REGEXP" arguments:2 block:^(void * _Nonnull context, int argc, void * _Nonnull * _Nonnull argv) {
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
                    NSLog(@">>> group not found %@ at %@", expr.pattern, content);
#endif
                    sqlite3_result_null(context);
                    return;
                }
                sqlite3_result_int(context, 1);
            }
        } else {
#if DEBUG
            NSLog(@"Unknown formart for REGEXP (%d, %d) %s:%d", sqlite3_value_type(argv[0]), sqlite3_value_type(argv[1]), __FUNCTION__, __LINE__);
#endif
            sqlite3_result_null(context);
        }
    }];
}

- (BOOL)addFlag:(NSString *)uuid flag:(int)f {
    if ([uuid isNotEmpty] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE readuuid=?", uuid];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;

        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE readuuid= ?", @(flags), uuid];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

/// 根据最新时间进行消息降序查询
/// @param gid 群聊gid
/// @param timeStamp unix时间
- (id<IMessageIterator>)forwardMessageIterator:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid timeStamp:timeStamp];
}

/// 根据最新时间进行消息升序查询
/// @param gid 群聊gid
/// @param timeStamp unix时间
- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    return [[SQLGroupMessageIterator alloc] initBackwardWithDB:self.db gid:gid timeStamp:timeStamp];
}

/// 手动检查是否有自定义添加字段
- (void)checkHaveManualColumn {
    FMDatabase *db = self.db;
    FMResultSet *result = [db executeQuery:@"SELECT * FROM group_message"];
    // 字段名
    NSArray<NSString *> *columnNames = @[@"cacheheight",
                                         @"cachewidth",
                                         @"lineheight",
                                         @"callback",
                                         @"deletetag",
                                         @"haveread",
                                         @"readuuid",
                                         @"haveevaluate"];
    // 字段生成约束
    NSArray<NSString *> *constraints = @[@"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"INTEGER NOT NULL DEFAULT 0",
                                         @"TEXT",
                                         @"INTEGER NOT NULL DEFAULT 0"];
    
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
            BOOL state = [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE group_message ADD %@ %@", name, constraints[j]]];
            NSLog(@"群插入%@列%@", name, state ? @"成功" : @"失败");
        }
    }
    [result close];
}

- (void)checkHaveExtraColumn {
    FMDatabase *db = self.db;
    FMResultSet *result = [db executeQuery:@"SELECT * from group_message ORDER BY timestamp DESC LIMIT 1"];
    
    NSDictionary<NSString *, NSNumber *> *allColumns = [result columnNameToIndexMap];
    NSString *pureContentColumnName = @"purecontent";
    NSString *messageTypeColumnName = @"messagetype";
    NSString *sourceColumnName = @"source";
    NSString *readCountColumnName = @"readcount";
    __block BOOL containsPureContent = NO;
    __block BOOL containsMessageType = NO;
    __block BOOL containsSource = NO;
    __block BOOL containsReadCount = NO;
    
    [allColumns.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:pureContentColumnName]) {
            containsPureContent = YES;
        } else if ([obj isEqualToString:messageTypeColumnName]) {
            containsMessageType = YES;
        } else if ([obj isEqualToString:sourceColumnName]) {
            containsSource = YES;
        } else if ([obj isEqualToString:readCountColumnName]) {
            containsReadCount = YES;
        }
    }];
    
    if (!containsPureContent) {
        BOOL state = [db executeUpdate:@"ALTER TABLE group_message ADD purecontent TEXT;"];
        NSLog(@"alter group_message add pureContent %@", state ? @"success" : @"failure");
    }
    
    if (!containsMessageType) {
        BOOL state = [db executeUpdate:@"ALTER TABLE group_message ADD messagetype TEXT;"];
        NSLog(@"alter group_message add messageType %@", state ? @"success" : @"failure");
    }
    
    if (!containsSource) {
        BOOL state = [db executeUpdate:@"ALTER TABLE group_message ADD source TEXT;"];
        NSLog(@"alter group_message add source %@", state ? @"success" : @"failure");
    }
    
    if (!containsReadCount) {
        BOOL state = [db executeUpdate:@"ALTER TABLE group_message ADD readcount INTEGER NOT NULL DEFAULT 0;"];
        NSLog(@"alter group_message add readcount %@", state ? @"success" : @"failure");
    }
    
    if (!containsPureContent || !containsMessageType || !containsSource) {
        
        NSString *updatePureContent = @"UPDATE group_message SET purecontent = CASE WHEN json_extract(content, '$.msg_body.extras.content') IS NOT NULL THEN json_extract(content, '$.msg_body.extras.content') ELSE json_extract(content, '$.msg_body.text') END;";
        
        BOOL updatePureContentResult = [db executeUpdate:updatePureContent];
        NSLog(@"executeUpdate updatePureContent %@", updatePureContentResult ? @"success" : @"failure");
        
        NSString *updateMessageType = @"UPDATE group_message set messagetype = json_extract(content, '$.msg_body.extras.type');";
        BOOL updateMessageTypeResult = [db executeUpdate:updateMessageType];
        NSLog(@"executeUpdate messageType %@", updateMessageTypeResult ? @"success" : @"failure");
        
        NSString *updateSource = @"UPDATE group_message set source = json_extract(content, '$.msg_body.extras.src');";
        BOOL updateSourceResult = [db executeUpdate:updateSource];
        NSLog(@"executeUpdate source %@", updateSourceResult ? @"success" : @"failure");
    }
    
    [result close];
}

- (void)updateExtraColumns {
    FMDatabase *db = self.db;
    NSString *updatePureContent = @"UPDATE group_message SET purecontent = CASE WHEN json_extract(content, '$.msg_body.extras.content') IS NOT NULL THEN json_extract(content, '$.msg_body.extras.content') ELSE json_extract(content, '$.msg_body.text') END;";
    
    BOOL updatePureContentResult = [db executeUpdate:updatePureContent];
    NSLog(@"executeUpdate updatePureContent %@", updatePureContentResult ? @"success" : @"failure");
    
    NSString *updateMessageType = @"UPDATE group_message set messagetype = json_extract(content, '$.msg_body.extras.type');";
    BOOL updateMessageTypeResult = [db executeUpdate:updateMessageType];
    NSLog(@"executeUpdate messageType %@", updateMessageTypeResult ? @"success" : @"failure");
    
    NSString *updateSource = @"UPDATE group_message set source = json_extract(content, '$.msg_body.extras.src');";
    BOOL updateSourceResult = [db executeUpdate:updateSource];
    NSLog(@"executeUpdate source %@", updateSourceResult ? @"success" : @"failure");
}

- (BOOL)fixUUIDMissing {
    FMDatabase *db = self.db;
    [db beginTransaction];
    
    // 先获取readuuid为空的记录
    NSString *querySQL = @"SELECT * FROM group_message WHERE readuuid IS NULL";
    FMResultSet *rs = [db executeQuery:querySQL];
    NSMutableArray<IMessage *> *messages = [[NSMutableArray alloc] initWithCapacity:100];
    
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messages addObject:msg];
    }
    [rs close];

    for (IMessage *msg in messages) {
        NSError *error = nil;
        NSDictionary *contentJSON = [NSJSONSerialization JSONObjectWithData:[msg.rawContent dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            NSLog(@">>> json convert error %@", error);
            continue;
        }
        
        // 从content字段中取到uuid
        NSString *uuid = contentJSON[@"msg_uuid"] ?: @"";
        if (!(uuid && [uuid isKindOfClass:[NSString class]])) {
            NSLog(@">>> empty uuid for message %@", @(msg.msgLocalID));
            continue;
        }
        
        // 更新数据readuuid字段
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE group_message SET readuuid= '%@' WHERE id= %@", uuid, @(msg.msgLocalID)];
#if DEBUG
        NSLog(@">>> update sql %@", updateSQL);
#endif
        BOOL r = [db executeUpdate:updateSQL];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }
    }

    [db commit];
    return YES;
}

/// 清除消息数据
/// @param targetUid 目标uid
- (BOOL)clearMessagesWithTargetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE group_id=?", @(targetUid)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

- (BOOL)clearAllMessageWithGroupId:(int64_t)groupId {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"UPDATE group_message SET deletetag = 1 WHERE group_id=?", @(groupId)];
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
    //    SELECT * FROM group_message WHERE timestamp= (SELECT MAX(timestamp) FROM group_message) AND peer =
    //    1586920918308426275 AND (deletetag = 0 OR deletetag IS NULL)
    NSString *sqlStr =
        [NSString stringWithFormat:@"SELECT * FROM group_message WHERE timestamp= (SELECT MAX(timestamp) FROM "
                                   @"group_message WHERE (deletetag = 0 OR deletetag IS NULL) AND group_id = %@)",
                                   @(targetUid)];
    FMResultSet *rs = [db executeQuery:sqlStr];

    if ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [rs close];
        return msg;
    }
    [rs close];
    return nil;
}

#pragma mark - gobelieve handler method
- (int)gobelieveGetMessageId:(NSString *)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM group_message WHERE uuid= ?", uuid];
    if ([rs next]) {
        int msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

- (IMessage *)gobelieveGetMessage:(int)msgID {
    FMResultSet *rs =
        [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE id= ?",
                              @(msgID)];
    if ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        return msg;
    }
    return nil;
}

- (BOOL)gobelieveUpdateFlags:(NSInteger)msgLocalID flags:(int)flags {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

- (BOOL)gobelieveUpdateMessageContent:(NSInteger)msgLocalID content:(NSString *)content {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE group_message SET content=? WHERE id=?", content, @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return [db changes] == 1;
}

- (BOOL)gobelieveRemoveMessageIndex:(int)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message_fts WHERE rowid=?", @(msgLocalID)];
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
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;

        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }

    [rs close];
    return YES;
}

- (BOOL)gobelieveInsertMessages:(NSArray *)msgs {
    FMDatabase *db = self.db;
    [db beginTransaction];

    for (IMessage *msg in msgs) {
        NSError *error = nil;
        NSDictionary *contentJSON = [NSJSONSerialization JSONObjectWithData:[msg.rawContent dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        
        NSDictionary *bodyDictionary = contentJSON[@"msg_body"];
        NSDictionary *extraDictionary;
        NSString *pureContent = @"";
        NSString *source = @"";
        NSString *messageType = @"";
        
        if (bodyDictionary) {
            extraDictionary = bodyDictionary[@"extras"];
            if (extraDictionary) {
                if (extraDictionary[@"content"]) {
                    pureContent = [NSString stringWithFormat:@"%@", extraDictionary[@"content"]];
                } else if (bodyDictionary[@"text"]) {
                    pureContent = [NSString stringWithFormat:@"%@", bodyDictionary[@"text"]];
                }
                
                if (extraDictionary[@"type"]) {
                    messageType = [NSString stringWithFormat:@"%@", extraDictionary[@"type"]];
                }
                
                if (extraDictionary[@"src"]) {
                    source = [NSString stringWithFormat:@"%@", extraDictionary[@"src"]];
                }
            }
        }
        
        if (error) {
            NSLog(@">>> json convert error %@", error);
            continue;
        }
        NSString *uuid = contentJSON[@"msg_uuid"] ?: @"";
        BOOL r =
            [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, readuuid, content, purecontent, messagetype, source, readcount) VALUES "
                              @"(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                              @(msg.sender), @(msg.receiver), @(msg.timestamp), @(msg.flags), uuid, uuid, msg.rawContent, pureContent, messageType, source, @(0)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }

        int64_t rowID = [db lastInsertRowId];
        msg.msgId = rowID;

        if (msg.textContent) {
            NSString *text = [msg.textContent.text tokenizer];
            [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
        }
    }

    [db commit];
    return YES;
}

/// 获取指定消息的前两条开始往后面的17条数据和前面2条数据，总的20 条数据
/// @param conversationID 聊天会话id
/// @param uuid 消息唯一标识符
- (NSArray<IMessage *> *)fetchHistoryWithConversationID:(int64_t)conversationID baseOnUUID:(NSString *_Nonnull)uuid {
    FMDatabase *db = self.db;
    // 前两条数据和后18条数据合并，最后按时间升序排序
    NSString *selectStr = [NSString
          stringWithFormat:@"SELECT * FROM (SELECT * FROM group_message "
                           @"WHERE group_id = %@ "
                           @"AND timestamp < (SELECT timestamp FROM group_message b  WHERE group_id = %@ AND readuuid = '%@') "
                           @"AND (deletetag = 0 OR deletetag IS NULL) "
                           @"ORDER BY timestamp "
                           @"DESC "
                           @"LIMIT 0,2) "
                           @"union "
                           @"SELECT * FROM (SELECT * FROM group_message "
                           @"WHERE group_id = %@ "
                           @"AND timestamp >= (SELECT timestamp FROM group_message b  WHERE group_id = %@ AND "
                           @"readuuid = '%@') "
                           @"AND (deletetag = 0 OR deletetag IS NULL) "
                           @"ORDER BY "
                           @"timestamp "
                           @"ASC "
                           @"LIMIT 0,20) "
                           @"ORDER BY timestamp "
                           @"ASC ",
                           @(conversationID),
                           @(conversationID),
                           uuid,
                           @(conversationID),
                           @(conversationID),
                           uuid];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [messageArr addObject:msg];
    }
    [rs close];
    return messageArr;
}

- (UnreadIMMessageModel *)queryGroupUnreadMessagesWithGroupId:(int64_t)groupId atUserId:(NSString *)atUserId sender:(int64_t)sender {
    FMDatabase *db = self.db;
    NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM group_message WHERE group_id = %@ AND haveread = 0 AND sender != %@ AND (deletetag = 0 OR deletetag IS NULL) ORDER BY timestamp DESC", @(groupId), @(sender)];
    FMResultSet *rs = [db executeQuery:querySQL];
    UnreadIMMessageModel *unreadModel = [[UnreadIMMessageModel alloc] init];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        if ([msg.pureContent containsString:@"@所有人"]) {
            unreadModel.isAtAll = YES;
            unreadModel.hasAt = YES;
            [messageArr addObject:msg];
            break;
        }
        NSData *jsonData = [msg.rawContent dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
        NSDictionary *bodyDic = dic[@"msg_body"] ?: @{};
        NSDictionary *extrasDic = bodyDic[@"extras"] ?: @{};
        NSArray *atUserIds = [NSMutableArray array];
        if (extrasDic[@"atUserId"] && [extrasDic[@"atUserId"] isKindOfClass:NSArray.class]) {
            atUserIds = extrasDic[@"atUserId"];
        }
        if (atUserIds.count > 0 && [atUserIds containsObject:atUserId]) {
            unreadModel.isAtAll = NO;
            unreadModel.hasAt = YES;
            [messageArr addObject:msg];
            break;
        }
        
        [messageArr addObject:msg];
    }
    unreadModel.unreadMessages = messageArr;
    [rs close];
    
    return unreadModel;
}

- (UnreadIMMessageModel *)queryGroupUnreadMessagesWithGroupId:(int64_t)groupId atUserId:(NSString *)atUserId sender:(int64_t)sender latestTimestamp:(int64_t)latestTimestamp {
    FMDatabase *db = self.db;
    NSString *querySQL = [NSString stringWithFormat: @"SELECT * FROM group_message WHERE group_id = %@ AND sender != %@ AND (deletetag = 0 OR deletetag IS NULL) AND timestamp > %@ ORDER BY timestamp DESC", @(groupId), @(sender), @(latestTimestamp)];
    FMResultSet *rs = [db executeQuery:querySQL];
    UnreadIMMessageModel *unreadModel = [[UnreadIMMessageModel alloc] init];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        if ([msg.pureContent containsString:@"@所有人"]) {
            unreadModel.isAtAll = YES;
            unreadModel.hasAt = YES;
            [messageArr addObject:msg];
            break;
        }
        NSData *jsonData = [msg.rawContent dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
        NSDictionary *bodyDic = dic[@"msg_body"] ?: @{};
        NSDictionary *extrasDic = bodyDic[@"extras"] ?: @{};
        NSArray *atUserIds = [NSMutableArray array];
        if (extrasDic[@"atUserId"] && [extrasDic[@"atUserId"] isKindOfClass:NSArray.class]) {
            atUserIds = extrasDic[@"atUserId"];
        }
        if (atUserIds.count > 0 && [atUserIds containsObject:atUserId]) {
            unreadModel.isAtAll = NO;
            unreadModel.hasAt = YES;
            [messageArr addObject:msg];
            break;
        }
        
        [messageArr addObject:msg];
    }
    unreadModel.unreadMessages = messageArr;
    [rs close];
    
    return unreadModel;
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
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE readuuid IN (%@)", ids];
#if DEBUG
    NSLog(@">>> sql queryMessagesWithUUIDs: %@", sql);
#endif
    FMResultSet *rs = [db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
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
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND timestamp >= (SELECT timestamp FROM group_message WHERE group_id = %@  AND (haveread = 0 OR haveread IS NULL) AND (deletetag = 0 OR deletetag IS NULL) AND sender != %@ ORDER BY timestamp ASC LIMIT 1) AND timestamp <= (SELECT timestamp FROM group_message WHERE group_id = %@ AND readuuid = '%@') ORDER BY timestamp ASC",
               @(targetUID),
               @(senderUID),
               @(targetUID),
               @(targetUID),
               uuid];
    }   else    {
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND timestamp >= (SELECT timestamp FROM group_message WHERE group_id = %@  AND (haveread = 0 OR haveread IS NULL) AND (deletetag = 0 OR deletetag IS NULL) AND sender != %@ ORDER BY timestamp ASC LIMIT 1) ORDER BY timestamp ASC",
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
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
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
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND timestamp <= (SELECT timestamp FROM group_message WHERE readuuid = '%@') AND timestamp >= (SELECT timestamp FROM group_message WHERE readuuid = '%@') ORDER BY timestamp ASC;", @(targetUID), bottomUUID, topUUID];
    }   else    {
        NSString *limitedString = limited > 0 ? [NSString stringWithFormat:@" LIMIT %ld", limited]:@"";
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND timestamp >= (SELECT timestamp FROM group_message WHERE readuuid = '%@') ORDER BY timestamp ASC%@;", @(targetUID), topUUID, limitedString];
    }
    
#if DEBUG
    NSLog(@">>> sql queryMessagesToUUID:from:byTargetUID: %@", sql);
#endif
    
    FMResultSet *rs = [self.db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}

- (NSArray<IMessage *> * _Nonnull)queryUnreadOnlyMessagesToUUID:(NSString * _Nullable)uuid byTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID {
    NSString *sql;
    if ([uuid isKindOfClass:NSString.class] && uuid.length > 0) {
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND (haveread = 0 OR haveread IS NULL) AND sender != %@ AND timestamp >= (SELECT timestamp FROM group_message WHERE group_id = %@  AND (haveread = 0 OR haveread IS NULL) AND (deletetag = 0 OR deletetag IS NULL) AND sender != %@ ORDER BY timestamp ASC LIMIT 1) AND timestamp <= (SELECT timestamp FROM group_message WHERE group_id = %@ AND readuuid = '%@') ORDER BY timestamp ASC",
               @(targetUID),
               @(senderUID),
               @(senderUID),
               @(targetUID),
               @(targetUID),
               uuid];
    }   else    {
        sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND (haveread = 0 OR haveread IS NULL) AND sender != %@ AND timestamp >= (SELECT timestamp FROM group_message WHERE group_id = %@  AND (haveread = 0 OR haveread IS NULL) AND (deletetag = 0 OR deletetag IS NULL) AND sender != %@ ORDER BY timestamp ASC LIMIT 1) ORDER BY timestamp ASC",
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
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}

/// 所有聊天消息（非自己发送的、不失败的）调整为已读
- (BOOL)markAllMessagesRead:(int64_t)sender {
    FMDatabase *db = self.db;

    BOOL r = [db executeUpdate:@"UPDATE group_message SET haveread= ? WHERE (haveread = 0 OR haveread IS NULL) AND flags != ? AND sender != ?", @(1), @(MESSAGE_FLAG_FAILURE), @(sender)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

/// 已读指定会话下所有他人消息，自己的消息不处理
/// @param conversationID 会话id
/// @param senderUID 当前登录用户uid
- (BOOL)markAllMessagesReadByConversationID:(int64_t)conversationID senderUID:(int64_t)senderUID {
    FMDatabase *db = self.db;
    
    NSString *sql = [NSString stringWithFormat:@"UPDATE group_message SET haveread = %@ WHERE (haveread = 0 OR haveread IS NULL) AND flags != %@ AND sender != %@ AND group_id = %@", @(1), @(MESSAGE_FLAG_FAILURE), @(senderUID), @(conversationID)];
    
#if DEBUG
    NSLog(@">>> sql markAllMessagesReadByConversationID: %@", sql);
#endif

    BOOL r = [db executeUpdate:sql];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }

    return YES;
}

/// 查询未读消息数量，不包含自己的消息
- (NSArray<IMessage *> *)queryUnreadMessagesByTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM group_message WHERE group_id = %@ AND (deletetag = 0 OR deletetag IS NULL) AND (haveread = 0 OR haveread IS NULL) AND sender != %@ ORDER BY timestamp ASC",
           @(targetUID),
           @(senderUID)];
    
#if DEBUG
    NSLog(@">>> sql queryUnreadMessagesByTargetUID: %@", sql);
#endif
    FMResultSet *rs = [self.db executeQuery:sql];
    NSMutableArray<IMessage *> *items = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [SQLGroupMessageIterator messageFromResultSet:rs];
        [items addObject:msg];
    }
    [rs close];
    return items;
}


//-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)gid messageID:(int)messageID {
//    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid middle:messageID];
//}
//
//-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid messageID:(int)messageID {
//    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid last:messageID];
//}
//
//
//-(BOOL)clearConversation:(int64_t)gid {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE group_id=?", @(gid)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//
//-(BOOL)clear {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM group_message"];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE group_message SET content=? WHERE id=?", content, @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return [db changes] == 1;
//}
//
//-(BOOL)insertMessages:(NSArray*)msgs {
//    FMDatabase *db = self.db;
//    [db beginTransaction];
//
//    for (IMessage *msg in msgs) {
//        NSString *uuid = msg.uuid ? msg.uuid : @"";
//        BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content)
//        VALUES (?, ?, ?, ?, ?, ?)",
//                  @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, msg.rawContent];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            [db rollback];
//            return NO;
//        }
//
//        int64_t rowID = [db lastInsertRowId];
//        msg.msgId = rowID;
//
//        if (msg.textContent) {
//            NSString *text = [msg.textContent.text tokenizer];
//            [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
//        }
//    }
//
//    [db commit];
//    return YES;
//}
//
//-(BOOL)insertMessage:(IMessage*)msg {
//    FMDatabase *db = self.db;
//    [db beginTransaction];
//    NSString *uuid = msg.uuid ? msg.uuid : @"";
//    BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES
//    (?, ?, ?, ?, ?, ?)",
//              @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, msg.rawContent];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        [db rollback];
//        return NO;
//    }
//
//    int64_t rowID = [db lastInsertRowId];
//    msg.msgId = rowID;
//
//    if (msg.textContent) {
//        NSString *text = [msg.textContent.text tokenizer];
//        [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
//    }
//
//
//    [db commit];
//    return YES;
//
//}
//
//-(BOOL)removeMessage:(int)msgLocalID {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE id=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    r = [db executeUpdate:@"DELETE FROM group_message_fts WHERE rowid=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//-(BOOL)removeMessageIndex:(int)msgLocalID {
//    FMDatabase *db = self.db;
//    BOOL r = [db executeUpdate:@"DELETE FROM group_message_fts WHERE rowid=?", @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//    return YES;
//}
//
//-(NSArray*)search:(NSString*)key {
//    FMDatabase *db = self.db;
//
//    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@"\'"];
//    key = [key tokenizer];
//    NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM group_message_fts WHERE group_message_fts MATCH
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
//-(IMessage*)getLastMessage:(int64_t)gid {
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM
//    group_message WHERE group_id= ? ORDER BY id DESC", @(gid)]; if ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"group_id"];
//        msg.timestamp = [rs intForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs intForColumn:@"id"];
//
//        [rs close];
//        return msg;
//    }
//    [rs close];
//    return nil;
//}
//
//-(int)getMessageId:(NSString*)uuid {
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM group_message WHERE uuid= ?", uuid];
//    if ([rs next]) {
//        int msgId = (int)[rs longLongIntForColumn:@"id"];
//        [rs close];
//        return msgId;
//    }
//    return 0;
//}
//
//-(IMessage*)getMessage:(int64_t)msgID {
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM
//    group_message WHERE id= ?", @(msgID)]; if ([rs next]) {
//        IMessage *msg = [[IMessage alloc] init];
//        msg.sender = [rs longLongIntForColumn:@"sender"];
//        msg.receiver = [rs longLongIntForColumn:@"group_id"];
//        msg.timestamp = [rs intForColumn:@"timestamp"];
//        msg.flags = [rs intForColumn:@"flags"];
//        msg.rawContent = [rs stringForColumn:@"content"];
//        msg.msgLocalID = [rs intForColumn:@"id"];
//        return msg;
//    }
//    return nil;
//}
//
//-(BOOL)acknowledgeMessage:(int)msgLocalID {
//    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
//}
//
//-(BOOL)markMessageFailure:(int)msgLocalID {
//    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
//}
//
//-(BOOL)markMesageListened:(int)msgLocalID {
//    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_LISTENED];
//}
//
//
//-(BOOL)addFlag:(int)msgLocalID flag:(int)f {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"flags"];
//        flags |= f;
//
//
//        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
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
//
//-(BOOL)eraseMessageFailure:(int)msgLocalID {
//    FMDatabase *db = self.db;
//    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
//    if (!rs) {
//        return NO;
//    }
//    if ([rs next]) {
//        int flags = [rs intForColumn:@"flags"];
//
//        int f = MESSAGE_FLAG_FAILURE;
//        flags &= ~f;
//
//        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
//        if (!r) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            return NO;
//        }
//    }
//
//    [rs close];
//    return YES;
//
//}
//
//-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags {
//    FMDatabase *db = self.db;
//
//    BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
//    if (!r) {
//        NSLog(@"error = %@", [db lastErrorMessage]);
//        return NO;
//    }
//
//    return YES;
//}
//
//
//-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
//    //以附件的形式存储，以免第二次查询
//    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID
//    address:address]; IMessage *attachment = [[IMessage alloc] init]; attachment.sender = msg.sender;
//    attachment.receiver = msg.receiver;
//    attachment.rawContent = att.raw;
//    [self saveMessage:attachment];
//}
//
//-(BOOL)saveMessage:(IMessage*)msg {
//    return [self insertMessage:msg];
//}

@end
