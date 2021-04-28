/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "SQLGroupMessageDB.h"
#import "NSString+JSMessagesView.h"

static const NSString *allColumns = @"sender, group_id, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content";

@interface SQLGroupMessageIterator : NSObject<IMessageIterator>
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID;
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID;
- (SQLGroupMessageIterator *)initWithDB:(FMDatabase*)db
                                    gid:(int64_t)gid
                              timeStamp:(NSInteger)timeStamp;

- (SQLGroupMessageIterator *)initBackwardWithDB:(FMDatabase*)db
                                            gid:(int64_t)gid
                                      timeStamp:(NSInteger)timeStamp;

@property(nonatomic) FMResultSet *rs;
@end

@implementation SQLGroupMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

- (SQLGroupMessageIterator *)initWithDB:(FMDatabase*)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM group_message WHERE group_id = ? AND timestamp < ? AND deletetag = 0 ORDER BY timestamp DESC", allColumns];
        self.rs = [db executeQuery:sql, @(gid), @(timeStamp)];
    }
    return self;
}

- (SQLGroupMessageIterator *)initBackwardWithDB:(FMDatabase*)db gid:(int64_t)gid timeStamp:(NSInteger)timeStamp {
    self = [super init];
    if (self) {
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM group_message WHERE group_id = ? AND timestamp > ? AND deletetag = 0 ORDER BY timestamp ASC", allColumns];
        self.rs = [db executeQuery:sql, @(gid), @(timeStamp)];
    }
    return self;
}

//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(gid)];
//    }
//    return self;
//}
//
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id < ? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
//    }
//    return self;
//}
//
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id > ? AND id < ? ORDER BY id DESC";
//        self.rs = [db executeQuery:sql, @(gid), @(msgID-10), @(msgID+10)];
//    }
//    return self;
//}
//
////上拉刷新
//-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID {
//    self = [super init];
//    if (self) {
//        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id>? ORDER BY id";
//        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
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

    IMessage *msg = [[IMessage alloc] init];
    [msg setSender:[self.rs longLongIntForColumn:@"sender"]];
    [msg setReceiver:[self.rs longLongIntForColumn:@"group_id"]];
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



@implementation SQLGroupMessageDB

+(SQLGroupMessageDB*)instance {
    static SQLGroupMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLGroupMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

/// 获取单条消息
/// @param uuid 消息唯一标识
- (IMessage *)getMessage:(NSString *)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT ? FROM group_message WHERE readuuid= ?", allColumns, uuid];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"group_id"]];
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
/// @param uid 消息保存群uid
- (BOOL)insertMessage:(IMessage*)msg
                  uid:(int64_t)uid {
    FMDatabase *db = self.db;
    [db beginTransaction];
    
    BOOL haveMessage = NO;
    FMResultSet *selectResult = [db executeQuery:@"SELECT readuuid FROM group_message WHERE group_id = ? AND readuuid = ?", @(uid), msg.readUUID];
    if (selectResult.next) {
        haveMessage = YES;
    }
    
    if (haveMessage == NO) {
        //    @"sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content"
        NSString *readuuid = [msg.readUUID hasContent] ? msg.readUUID : @"";
        NSString *content = [msg.rawContent hasContent] ? msg.rawContent : @"";
        BOOL result = [db executeUpdate:@"INSERT INTO group_message (group_id, sender, receiver, timestamp, flags, haveread, readuuid, cacheheight, cachewidth, lineheight, callback, deletetag, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp), @(msg.flags), @(msg.haveRead), readuuid, @(msg.manualHeight), @(msg.manualWidth), @(msg.lineHeight), @(msg.callBack), @(msg.deleteTag), content];
        
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
- (BOOL)eraseMessageFailure:(NSString *)uuid {
    if ([uuid hasContent] == NO) {
        return NO;
    }
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE readuuid=?", uuid];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];

        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;

        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE readuuid= ?", @(flags), uuid];
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
    FMResultSet *rs = [db executeQuery:@"SELECT haveread FROM group_message WHERE readuuid=?", uuid];
    if (!rs) {
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

/// 获取当前目标发送失败消息
/// @param gid 群聊gid
- (NSArray<IMessage *> *)getFailedMessages:(int64_t)gid {
    FMDatabase *db = self.db;
    NSMutableArray *failedArr = [[NSMutableArray alloc] init];
    FMResultSet *rs = [db executeQuery:@"SELECT ? FROM group_message WHERE flags=? AND group_id=?", allColumns, @(MESSAGE_FLAG_FAILURE), @(gid)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"group_id"]];
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
            sqlStr = [NSString stringWithFormat:@"UPDATE group_message SET callback= %@ WHERE readuuid IN %@", @(1), str];
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
        sqlStr = [NSString stringWithFormat:@"UPDATE group_message SET deletetag= %@ WHERE readuuid IN %@", @(1), str];

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
        sqlStr = [NSString stringWithFormat:@"UPDATE group_message SET haveread= %d WHERE readuuid NOT IN %@ AND haveread= 0 AND sender= %lld", 1, str, sender];
        
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

    BOOL r = [db executeUpdate:@"UPDATE group_message SET cacheheight= ?, cachewidth= ?, lineheight= ? WHERE readuuid= ?", @(height), @(width), @(lineHeight), uuid];
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
    NSString *selectStr = [NSString stringWithFormat:@"SELECT %@ FROM group_message WHERE content LIKE '%%%@%%'", allColumns, keyword];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"group_id"]];
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
        BOOL addCH = [db executeUpdate:@"ALTER TABLE group_message ADD cacheheight"];
        NSLog(@"群插入cacheheight列%@", addCH == YES ? @"成功" : @"失败");
    }
    if (haveCacheWidth == NO) {
        BOOL addCW = [db executeUpdate:@"ALTER TABLE group_message ADD cachewidth"];
        NSLog(@"群插入cachewidth列%@", addCW == YES ? @"成功" : @"失败");
    }
    if (haveLineHeight == NO) {
        BOOL addLH = [db executeUpdate:@"ALTER TABLE group_message ADD lineheight"];
        NSLog(@"群插入lineheight列%@", addLH == YES ? @"成功" : @"失败");
    }
    if (haveCallBack == NO) {
        BOOL addCH = [db executeUpdate:@"ALTER TABLE group_message ADD callback"];
        NSLog(@"插入callback列%@", addCH == YES ? @"成功" : @"失败");
    }
    if (haveDeleteMessage == NO) {
        BOOL addDH = [db executeUpdate:@"ALTER TABLE group_message ADD deletetag"];
        NSLog(@"插入deletetag列%@", addDH == YES ? @"成功" : @"失败");
    }
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

#pragma mark - gobelieve handler method
- (int)gobelieveGetMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM group_message WHERE uuid= ?", uuid];
    if ([rs next]) {
        int msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

- (IMessage *)gobelieveGetMessage:(int)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"group_id"]];
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

/// 获取目标下包含关键字的消息
/// @param keyword 关键字
/// @param targetUid targetUid
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword targetUid:(int64_t)targetUid {
    FMDatabase *db = self.db;
    NSString *selectStr = [NSString stringWithFormat:@"SELECT %@ FROM group_message WHERE content LIKE '%%%@%%' AND group_id = %lld", allColumns, keyword, targetUid];
    FMResultSet *rs = [db executeQuery:selectStr];
    NSMutableArray<IMessage *> *messageArr = [[NSMutableArray alloc] init];
    while ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        [msg setSender:[rs longLongIntForColumn:@"sender"]];
        [msg setReceiver:[rs longLongIntForColumn:@"group_id"]];
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


-(BOOL)gobelieveAddFlag:(NSInteger)msgLocalID flag:(int)f {
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

- (BOOL)gobelieveInsertMessages:(NSArray*)msgs {
    FMDatabase *db = self.db;
    [db beginTransaction];

    for (IMessage *msg in msgs) {
        NSString *uuid = msg.uuid ? msg.uuid : @"";
        BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?)",
                  @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, msg.rawContent];
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
//        BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?)",
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
//    BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?)",
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
//    NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM group_message_fts WHERE group_message_fts MATCH '%@'", key];
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
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id= ? ORDER BY id DESC", @(gid)];
//    if ([rs next]) {
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
//    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE id= ?", @(msgID)];
//    if ([rs next]) {
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
//    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
//    IMessage *attachment = [[IMessage alloc] init];
//    attachment.sender = msg.sender;
//    attachment.receiver = msg.receiver;
//    attachment.rawContent = att.raw;
//    [self saveMessage:attachment];
//}
//
//-(BOOL)saveMessage:(IMessage*)msg {
//    return [self insertMessage:msg];
//}

@end

