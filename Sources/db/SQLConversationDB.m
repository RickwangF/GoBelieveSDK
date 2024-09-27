//
//  SQLConversationDB.m
//  Gobelieve
//
//  Created by ch999 on 2021/4/19.
//

#import "Conversation+Private.h"
#import "SQLConversationDB+Private.h"

NSString *stringOrEmpty(NSString *value) { return (value && value.length > 0) ? value : @""; }

@interface SQLConversationDB ()
/// FMDB数据库多线程队列
@property(nonatomic, strong) FMDatabaseQueue *dbQueue;
@end

@implementation SQLConversationDB

+ (dispatch_queue_t)executeQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.9ji.excute.database", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (SQLConversationDB *)instance {
    static SQLConversationDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[SQLConversationDB alloc] init];
    });
    return m;
}

+ (void)setDataBaseQueuePath:(NSString *)path {
    if (!(path && path.length > 0)) {
        NSLog(@">>> invalid path for database %@.", path);
        return;
    }
    
//    if (SQLConversationDB.instance.dbQueue) {
//        NSLog(@">>> database already created, no path set for %@.", path);
//        return;
//    }
    SQLConversationDB.instance.dbQueue = [[FMDatabaseQueue alloc] initWithPath:path];
}

#if DEBUG
- (void)executeStatements:(NSString *)statements {
    if (!(statements && statements.length > 0)) {
        NSLog(@">>> invalid statements %@", statements);
        return;
    }
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        [db executeStatements:statements];
    }];
}

- (void)inDatabase:(__attribute__((noescape)) void (^)(FMDatabase *db))block {
    [self.dbQueue inDatabase:block];
}

- (void)close {
    [self.dbQueue close];
}
#endif

- (void)setConversationTableId:(NSInteger)conversationTableId {
    _conversationTableId = conversationTableId;
}

/// 会话列表统一解析方法，解析完成后会关闭数据库链接，并执行回调block（切换回主线程）
/// @param rs 数据库数据集，内含数据库链接
/// @param completion 查询完成回调block
- (void)parseConversationList:(FMResultSet *)rs
                   completion:(void (^_Nullable)(NSArray<Conversation *> *_Nonnull))completion {
    if (!rs) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    NSMutableArray<Conversation *> *conversations = [[NSMutableArray alloc] initWithCapacity:20];
    BOOL result = true;
    while (result) {
        Conversation *conversation = [Conversation conversationFromResultSet:rs];
        result = [rs next];
        if (conversation.uid != 0) {
            [conversations addObject:conversation];
        }
        if (!result) {
            NSLog(@">>> last row for conversation reach, total %lu rows", (unsigned long)conversations.count);
        }
    }
    [rs close];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(conversations);
        }
    });
}

/// 获取会员会话列表
- (void)memberConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** memberConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 1 ");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        FMResultSet *rs = [db executeQuery:sql];
        [self parseConversationList:rs completion:completion];
    }];
}

/// 获取内部聊天会话列表
- (void)internalConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** internalConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 0 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        FMResultSet *rs = [db executeQuery:sql];
        [self parseConversationList:rs completion:completion];
    }];
}

/// 获取群聊会话列表
- (void)groupConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** internalConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 2 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        FMResultSet *rs = [db executeQuery:sql];
        [self parseConversationList:rs completion:completion];
    }];
}

/// 获取所有置顶聊天会话列表
- (void)topConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** topConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE is_top = 0 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        FMResultSet *rs = [db executeQuery:sql];
        [self parseConversationList:rs completion:completion];
    }];
}

/// 获取所有聊天列表，排序顺序是根据是否置顶和时间戳排序，置顶数据在前面，按时间从新到旧排序
- (void)getSortTopChatConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** getSortTopChatConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"select * from gb_conversation  where is_delete = 0  group by is_top, "
                                           @"timestamp, conversationid order by is_top desc, timestamp desc"];
        [self parseConversationList:rs completion:completion];
    }];
}

/// 获取所有未置顶聊天会话列表
- (void)untopConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion {
    NSAssert(completion != nil, @"*** untopConversationWithCompletion: must passs nonnull completion.");
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE is_top = 1 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        FMResultSet *rs = [db executeQuery:sql];
        [self parseConversationList:rs completion:completion];
    }];
}

- (BOOL)addConversationWithTimestampCheck:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *avatar = stringOrEmpty(conversation.avatarURL);
    NSString *nickname = stringOrEmpty(conversation.name);
    NSString *content = stringOrEmpty(conversation.content);
    NSString *readUUID = stringOrEmpty(conversation.msguuid);
    NSString *memberLevel = stringOrEmpty(conversation.memberLevel);
    NSString *memberImg = stringOrEmpty(conversation.memberImg);
    __block NSString *draft = stringOrEmpty(conversation.draft);
    NSString *targetId = stringOrEmpty(conversation.targetId);
    NSString *areaStr = stringOrEmpty(conversation.area);
    NSString *remarkNameStr = stringOrEmpty(conversation.remarkName);

    __block BOOL success = NO;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL haveRecord = NO;
        //BOOL timestampValid = NO;
        FMResultSet *result = [db
            executeQuery:@"SELECT conversationid, timestamp, draft FROM gb_conversation WHERE conversationid  = ?", @(conversation.uid)];
        if (result.next) {
            haveRecord = [result longLongIntForColumn:@"conversationid"] > 0;
            //timestampValid = conversation.timestamp > [result longLongIntForColumn:@"timestamp"];
            draft = stringOrEmpty([result stringForColumn:@"draft"]);
        }
        [result close];
        NSError *error = nil;
        if (haveRecord == NO) {
            NSString *sqlStr = @"INSERT INTO gb_conversation (" ALL_COL
                                ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?, ?)";
            success = [db executeUpdate:sqlStr
                                 values:@[@(conversation.uid), avatar, nickname, @(conversation.timestamp), content,
                                          readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                                          @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                                          memberLevel, memberImg, draft, @(conversation.unsendTag), targetId,
                                          @(conversation.is_self), areaStr, remarkNameStr, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg]
                                  error:&error];
        }else{
//            if (!timestampValid) {// 需要更新的时间小于本地数据时间
//                return;
//            }
            
            success = [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, msguuid = "
                                        @"?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount = ?, "
                                        @"member_type = ?, member_level= ?, member_img = ?, draft = ?, unsend_tag = ?, target_id= "
                                        @"?, is_self = ?, area = ?, remark_name = ?, conversation_type = ?, is_mute = ?, atmsg = ? WHERE conversationid  = ?"
                                 values:@[avatar, nickname, @(conversation.timestamp),
                                          content, readUUID, @(conversation.isCallback),
                                          @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                                          @(conversation.newMsgCount), @(conversation.memberType), memberLevel,
                                          memberImg, draft, @(conversation.unsendTag),
                                          targetId, @(conversation.is_self), areaStr,
                                          remarkNameStr, @(conversation.conversationType),@(conversation.isMute), conversation.atMsg, @(conversation.uid)]
                                  error:&error];
        }
        if (error) {
            NSLog(@">>> update/add conversation failed, %@", error);
        }
    }];
    return success;
}

- (BOOL)addConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *avatar = stringOrEmpty(conversation.avatarURL);
    NSString *nickname = stringOrEmpty(conversation.name);
    NSString *content = stringOrEmpty(conversation.content);
    NSString *readUUID = stringOrEmpty(conversation.msguuid);
    NSString *memberLevel = stringOrEmpty(conversation.memberLevel);
    NSString *memberImg = stringOrEmpty(conversation.memberImg);
    NSString *draft = stringOrEmpty(conversation.draft);
    NSString *targetId = stringOrEmpty(conversation.targetId);
    NSString *areaStr = stringOrEmpty(conversation.area);
    NSString *remarkNameStr = stringOrEmpty(conversation.remarkName);

    __block BOOL success = NO;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL haveRecord = NO;
        FMResultSet *result = [db
            executeQuery:@"SELECT conversationid FROM gb_conversation WHERE conversationid  = ?", @(conversation.uid)];
        if (result.next) {
            haveRecord = YES;
        }
        [result close];
        NSError *error = nil;
        if (haveRecord == NO) {
            NSString *sqlStr = @"INSERT INTO gb_conversation (" ALL_COL
                                ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?, ?)";
            success = [db executeUpdate:sqlStr
                                 values:@[@(conversation.uid), avatar, nickname, @(conversation.timestamp), content,
                                          readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                                          @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                                          memberLevel, memberImg, draft, @(conversation.unsendTag), targetId,
                                          @(conversation.is_self), areaStr, remarkNameStr, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg]
                                  error:&error];
        }else{
//            success =
//            [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, msguuid = "
//                              @"?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount = ?, "
//                              @"member_type = ?, member_level= ?, member_img = ?, draft = ?, unsend_tag = ?, target_id= "
//                              @"?, is_self = ?, area = ?, remark_name = ?, conversation_type = ? WHERE conversationid  = ?",
//                              avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback),
//                              @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
//                              @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft,
//                              @(conversation.unsendTag), targetId, @(conversation.is_self), areaStr, remarkNameStr, @(conversation.conversationType),
//                              @(conversation.uid)];
            success = [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, msguuid = "
                                        @"?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount = ?, "
                                        @"member_type = ?, member_level= ?, member_img = ?, draft = ?, unsend_tag = ?, target_id= "
                                        @"?, is_self = ?, area = ?, remark_name = ?, conversation_type = ?, is_mute = ?, atmsg = ? WHERE conversationid  = ?"
                                 values:@[avatar, nickname, @(conversation.timestamp),
                                          content, readUUID, @(conversation.isCallback),
                                          @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                                          @(conversation.newMsgCount), @(conversation.memberType), memberLevel,
                                          memberImg, draft, @(conversation.unsendTag),
                                          targetId, @(conversation.is_self), areaStr,
                                          remarkNameStr, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg, @(conversation.uid)]
                                  error:&error];
        }
        if (error) {
            NSLog(@">>> update/add conversation failed, %@", error);
        }
    }];
    return success;
}

/// 更新/添加会话，如果会话存在则更新内容，但是新消息数量会累加（newMsgCount会加到原表字段，而不是覆盖），新会话则是覆盖
/// @param conversation 是否插入成功
- (BOOL)updateConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *avatar = stringOrEmpty(conversation.avatarURL);
    NSString *nickname = stringOrEmpty(conversation.name);
    NSString *content = stringOrEmpty(conversation.content);
    NSString *readUUID = stringOrEmpty(conversation.msguuid);
    NSString *memberLevel = stringOrEmpty(conversation.memberLevel);
    NSString *memberImg = stringOrEmpty(conversation.memberImg);
    NSString *draft = stringOrEmpty(conversation.draft);
    NSString *targetId = stringOrEmpty(conversation.targetId);
    NSString *areaStr = stringOrEmpty(conversation.area);
    NSString *remarkNameStr = stringOrEmpty(conversation.remarkName);

    __block BOOL success = NO;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL haveRecord = NO;
        FMResultSet *result = [db
            executeQuery:@"SELECT conversationid FROM gb_conversation WHERE conversationid  = ?", @(conversation.uid)];
        Conversation *old = nil;
        if (result.next) {
            haveRecord = YES;
        }
        old = [Conversation conversationFromResultSet:result];
        NSInteger count = old ? old.newMsgCount:0;
#if DEBUG
        NSLog(@">>> [%lld] %@ conversation newMsgCount %ld update to %ld", conversation.uid, conversation.content, count, count + conversation.newMsgCount);
#endif
        [result close];
        NSError *error = nil;
        if (haveRecord == NO) {
            NSString *sqlStr = @"INSERT INTO gb_conversation (" ALL_COL
                                ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?, ?)";
            success = [db executeUpdate:sqlStr
                                 values:@[@(conversation.uid), avatar, nickname, @(conversation.timestamp), content,
                                          readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                                          @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                                          memberLevel, memberImg, draft, @(conversation.unsendTag), targetId,
                                          @(conversation.is_self), areaStr, remarkNameStr, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg]
                                  error:&error];
        }else{
            success = [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, msguuid = "
                                        @"?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount = unreadcount + ?, "
                                        @"member_type = ?, member_level= ?, member_img = ?, draft = ?, unsend_tag = ?, target_id= "
                                        @"?, is_self = ?, area = ?, remark_name = ?, conversation_type = ?, is_mute = ?, atmsg = ? WHERE conversationid  = ?"
                                 values:@[avatar, nickname, @(conversation.timestamp),
                                          content, readUUID, @(conversation.isCallback),
                                          @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                                          @(conversation.newMsgCount), @(conversation.memberType), memberLevel,
                                          memberImg, draft, @(conversation.unsendTag),
                                          targetId, @(conversation.is_self), areaStr,
                                          remarkNameStr, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg, @(conversation.uid)]
                                  error:&error];
        }
        if (error) {
            NSLog(@">>> update/add conversation failed, %@", error);
        }
    }];
    return success;
}

/// 检测是否存在表结构字段
- (void)manualCheckConversationDBColumn {
    FMDatabaseQueue *queue = self.dbQueue;
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *result = [db executeQuery:@"SELECT * FROM gb_conversation LIMIT 10;"];
        
        // 字段名
        NSArray<NSString *> *columnNames = @[@"conversation_type"];
        
        // 字段生成约束
        NSArray<NSString *> *constraints = @[@"INTEGER NOT NULL DEFAULT 0"];
        
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
                BOOL state = [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE gb_conversation ADD %@ %@", name, constraints[j]]];
                NSLog(@"群插入%@列%@", name, state ? @"成功" : @"失败");
            }
        }
        [result close];
    }];
}

- (void)checkConversationExtraColumns {
    FMDatabaseQueue *queue = self.dbQueue;
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *result = [db executeQuery:@"SELECT * FROM gb_conversation LIMIT 1;"];
        
        NSString *isMuteColumnName = @"is_mute";
        NSString *hasAtColumnName = @"atmsg";
        
        __block BOOL containsIsMuteColumnName = NO;
        __block BOOL containsHasAtColumnName = NO;
        NSDictionary<NSString *, NSNumber *> *allColumns = [result columnNameToIndexMap];
        
        [allColumns.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEqualToString:isMuteColumnName]) {
                containsIsMuteColumnName = YES;
            } else if ([obj isEqualToString:hasAtColumnName]) {
                containsHasAtColumnName = YES;
            }
        }];
        
        if (!containsIsMuteColumnName) {
            BOOL state = [db executeUpdate:@"ALTER TABLE gb_conversation ADD is_mute INTEGER NOT NULL DEFAULT 0;"];
            NSLog(@"alter gb_conversation add is_mute %@", state ? @"success" : @"failure");
        }
        
        if (!containsHasAtColumnName) {
            BOOL state = [db executeUpdate:@"ALTER TABLE gb_conversation ADD atmsg TEXT;"];
            NSLog(@"alter gb_conversation add atmsg %@", state ? @"success" : @"failure");
        }
        
        [result close];
    }];
}

/// 添加会话
/// @param conversation 添加的会话
/// @param completion 数据库操作执行完成回调，state为执行结果是否成功，此block会在主线程中回调
- (void)addConversation:(Conversation *)conversation completion:(void (^_Nullable)(BOOL state))completion {
    BOOL success = [self addConversation:conversation];
    if (completion) {
        completion(success);
    }
}

/// 智能添加更新会话
///
///
- (void)smartAddConversation:(Conversation *)conversation completion:(void (^_Nullable)(BOOL state))completion {
    BOOL success = [self addConversationWithTimestampCheck:conversation];
    if (completion) {
        completion(success);
    }
}

/// 删除所有会话
- (void)clearAllConversationCompletion:(void (^_Nullable)(BOOL state))completion {
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM gb_conversation"];
        if (completion) {
            completion(success);
        }
    }];
}

/// 删除除了群聊外的其他会话
- (void)clearAllConversationExceptGroupTypeCompletion:(void (^_Nullable)(BOOL state))completion {
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        BOOL success = [db executeUpdate:@"DELETE FROM gb_conversation where is_group = false"];
        if (completion) {
            completion(success);
        }
    }];
}

/// 整体会话替换，将会话的所有展示内容做替换，一般在将服务端会话请求下来时使用
/// @param conversation 添加的会话
- (void)replaceConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *avatar = stringOrEmpty(conversation.avatarURL);
    NSString *nickname = stringOrEmpty(conversation.name);
    NSString *content = stringOrEmpty(conversation.content);
    NSString *readUUID = stringOrEmpty(conversation.msguuid);
    NSString *memberLevel = stringOrEmpty(conversation.memberLevel);
    NSString *memberImg = stringOrEmpty(conversation.memberImg);
    NSString *draft = stringOrEmpty(conversation.draft);
    NSString *targetId = stringOrEmpty(conversation.targetId);
    NSString *areaStr = stringOrEmpty(conversation.area);
    NSString *remarkNameStr = stringOrEmpty(conversation.remarkName);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, msguuid = "
                          @"?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount = ?, "
                          @"member_type = ?, member_level= ?, member_img = ?, draft = ?, unsend_tag = ?, target_id= "
                          @"?, is_self = ?, area = ?, remark_name = ?, conversation_type = ?, is_mute = ?, atmsg = ? WHERE conversationid  = ?",
                          avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback),
                          @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                          @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft,
                          @(conversation.unsendTag), targetId, @(conversation.is_self), areaStr, remarkNameStr, @(conversation.conversationType),
                          @(conversation.isMute), conversation.atMsg,
                          @(conversation.uid)];
    }];
}

/// 删除会话
/// @param uid 删除会话的id
- (void)deleteConversationWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"DELETE FROM gb_conversation WHERE conversationid = ?", @(uid)];
    }];
}

/// 隐藏会话
/// @param isHide 是否隐藏
/// @param uid 删除会话的id
- (void)disposeConversationIsHide:(BOOL)isHide uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET is_delete= ? WHERE conversationid = ?", @(isHide), @(uid)];
    }];
}

/// 修改会话置顶状态
/// @param isTop 是否置顶
/// @param uid 操作会话的uid
- (void)disposeConversationIsTop:(BOOL)isTop uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET is_top = ? WHERE conversationid = ?", @(isTop), @(uid)];
    }];
}

/// 修改会话备注名称
/// @param remarkName 备注名
/// @param uid 操作会话的uid
- (void)updateConversationRemarkName:(NSString *)remarkName uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET remark_name = ? WHERE conversationid = ?", remarkName, @(uid)];
    }];
}

- (void)updateConversationName:(NSString *)name RemarkName:(NSString *)remarkName uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET remark_name = ?, nickname = ? WHERE conversationid = ?", remarkName, name, @(uid)];
    }];
}
 
/// 清空会话未读数量
/// @param uid 清空会话的id
- (void)clearConversationMsgCountWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET unreadcount = 0 WHERE conversationid = ?", @(uid)];
    }];
}

- (void)minusConversationMsgCountWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeUpdate:@"UPDATE gb_conversation SET unreadcount = CASE WHEN unreadcount > 0 THEN unreadcount - 1 ELSE 0 END WHERE conversationid = ?", @(uid)];
        if (success) {
            NSLog(@"minusConversationMsgCountWithUid success");
        } else {
            NSLog(@"minusConversationMsgCountWithUid fail");
        }
    }];
}

/// 保存草稿消息
/// @param uid 保存草稿会话的id
/// @param draft 保存草稿会话的文字
- (void)saveDraftToConversationWithUid:(int64_t)uid draft:(NSString *)draft {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *draftStr = stringOrEmpty(draft);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET draft = ? WHERE conversationid = ?", draftStr, @(uid)];
    }];
}

- (void)updateConversationUnreadCountWithUid:(int64_t)uid unreadCount:(int64_t)unreadCount completion:(void (^_Nullable)(BOOL state))completion {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL state = [db executeUpdate:@"UPDATE gb_conversation SET unreadcount = ? WHERE conversationid = ?", @(unreadCount), @(uid)];
#if DEBUG
        NSLog(@">>> sql update: %@", [NSString stringWithFormat:@"UPDATE gb_conversation SET unreadcount = %@ WHERE conversationid = %@", @(unreadCount), @(uid)]);
#endif
        if (completion) {
            completion(state);
        }
    }];
}

/// Save draft message.
/// @param uid The uid of the conversation where the draft will be saved.
/// @param draft The string of the conversation where the draft will be saved.
/// @param newConversation The conversation for inspection.
- (void)saveDraftMessageWithUid:(int64_t)uid draft:(NSString *)draft conversation:(Conversation *)newConversation {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *draftStr = stringOrEmpty(draft);
    NSString *avatar = stringOrEmpty(newConversation.avatarURL);
    NSString *nickname = stringOrEmpty(newConversation.name);
    NSString *content = stringOrEmpty(newConversation.content);
    NSString *readUUID = stringOrEmpty(newConversation.msguuid);
    NSString *memberLevel = stringOrEmpty(newConversation.memberLevel);
    NSString *memberImg = stringOrEmpty(newConversation.memberImg);
    NSString *targetId = stringOrEmpty(newConversation.targetId);
    NSString *areaStr = stringOrEmpty(newConversation.area);
    NSString *remarkNameStr = stringOrEmpty(newConversation.remarkName);
            
    __block BOOL success = NO;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL haveRecord = NO;
        FMResultSet *result = [db
                               executeQuery:@"SELECT conversationid FROM gb_conversation WHERE conversationid  = ?", @(newConversation.uid)];
        if (result.next) {
            haveRecord = YES;
        }
        [result close];
        if (haveRecord == NO) {
            if (draftStr.length > 0) {
                /// If there is a conversation but no draft, create a new conversation and update the draft
                NSString *sqlStr = @"INSERT INTO gb_conversation (" ALL_COL
                ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?, ?)";
                success =
                [db executeUpdate:sqlStr, @(newConversation.uid), avatar, nickname, @(newConversation.timestamp), content,
                 readUUID, @(newConversation.isCallback), @(newConversation.isGroup), @(newConversation.isDelete),
                 @(newConversation.isTop), @(newConversation.newMsgCount), @(newConversation.memberType),
                 memberLevel, memberImg, draftStr, @(newConversation.unsendTag), targetId,
                 @(newConversation.is_self), areaStr, remarkNameStr, @(newConversation.conversationType), @(newConversation.isMute), newConversation.atMsg];
                [db executeUpdate:@"UPDATE gb_conversation SET draft = ? WHERE conversationid = ?", draftStr, @(uid)];
            }else{
                /// If there are neither conversation nor draft, do nothing!
            }
        }else{
            /// If there is a conversation, update the draft!
            [db executeUpdate:@"UPDATE gb_conversation SET draft = ? WHERE conversationid = ?", draftStr, @(uid)];
        }
    }];
}

/// 根据uid修改会话targetId、昵称、头像
/// @param targetId 需要记录的targetId
/// @param nickname 需要记录的昵称
/// @param avatar 需要记录的头像
/// @param uid 目标会话uid
- (void)updateConversationTargetId:(NSString *)targetId
                          nickname:(NSString *)nickname
                            avatar:(NSString *)avatar
                               uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *avatarStr = stringOrEmpty(avatar);
    NSString *nicknameStr = stringOrEmpty(nickname);
    NSString *targetIdStr = stringOrEmpty(targetId);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:
                @"UPDATE gb_conversation SET avatar = ?, nickname = ?, target_id = ? WHERE conversationid = ?",
                avatarStr, nicknameStr, targetIdStr, @(uid)];
    }];
}

/// 根据uid修改会话会员信息等
/// @param memberType 需要记录的会员类型
/// @param memberLevel 需要记录的会员等级
/// @param memberImg 需要记录的会员等级背景图
/// @param area 需要记录的地区信息
/// @param remarkName 备注名
/// @param uid 目标会话uid
- (void)updateConversationMemberInfoWithMemberType:(NSInteger)memberType
                                       memberLevel:(NSString *)memberLevel
                                         memberImg:(NSString *)memberImg
                                              area:(NSString *)area
                                        remarkName:(NSString *)remarkName
                                               uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *memberLevelStr = stringOrEmpty(memberLevel);
    NSString *memberImgStr = stringOrEmpty(memberImg);
    NSString *areaStr = stringOrEmpty(area);
    NSString *remarkNameStr = stringOrEmpty(remarkName);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET member_type = ?, member_level = ?, member_img = ?, "
                          @"area = ?, remark_name = ? WHERE conversationid = ?",
                          @(memberType), memberLevelStr, memberImgStr, areaStr, remarkNameStr, @(uid)];
    }];
}

/// 修改会话显示最后一条消息相关
/// @param content 消息内容
/// @param msgUUID 消息uuid
/// @param timestamp 时间
/// @param isSelf 是否自己发送
/// @param isCallBack 是否撤回
/// @param count 需要添加的消息数量
/// @param clearCount 是否需要清空消息数量
/// @param receiver 消息接收方
- (void)updateConversationMessageWithContent:(NSString *)content
                                     msgUUID:(NSString *)msgUUID
                                   timestamp:(int64_t)timestamp
                                      isSelf:(BOOL)isSelf
                                  isCallBack:(BOOL)isCallBack
                                       count:(NSInteger)count
                                  clearCount:(BOOL)clearCount
                                    receiver:(int64_t)receiver {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *contentStr = stringOrEmpty(content);
    NSString *uuidStr = stringOrEmpty(msgUUID);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSInteger unreadCount = 0;
        if (clearCount == NO) {
            FMResultSet *result =
                [db executeQuery:@"SELECT unreadcount FROM gb_conversation WHERE conversationid = ?", @(receiver)];
            if ([result next]) {
                unreadCount = [result longLongIntForColumn:@"unreadcount"];
            }
            [result close];
        }
        
        [db executeUpdate:@"UPDATE gb_conversation SET content = ?, msguuid = ?, timestamp=  ?, unreadcount = ?, "
                          @"is_callback= ?, is_Self= ? WHERE conversationid = ?",
         contentStr, uuidStr, @(timestamp), clearCount == YES ? @(0) : @(unreadCount + count), isCallBack == YES ? @(1) : @(0), isSelf == YES ? @(1) : @(0), @(receiver)];
    }];
}

- (void)updateConversationMessageWithAtMsg:(NSString *)atMsg withConversationId:(int64_t)receiver {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *atMsgString = stringOrEmpty(atMsg);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET atmsg = ? WHERE conversationid = ?",
         atMsgString, @(receiver)];
    }];
}

/// 获取会话未读数量
/// @param receiver 消息接收方
- (NSInteger)getConversationNewMsgCountWithReceiver:(int64_t)receiver {
    __block NSInteger unreadCount = 0;
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *result =
            [db executeQuery:@"SELECT unreadcount FROM gb_conversation WHERE conversationid = ?", @(receiver)];
        if ([result next]) {
            unreadCount = [result longLongIntForColumn:@"unreadcount"];
        }
        [result close];
    }];
    return unreadCount;
}

/// 获取所有会话未读数量
- (NSInteger)getAllConversationNewMsgCount {
    __block NSInteger msgCount = 0;
    FMDatabaseQueue *queue = self.dbQueue;
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        /// 已隐藏的会话不统计在内
        FMResultSet *result = [db executeQuery:@"SELECT SUM(unreadcount) FROM gb_conversation where is_delete = 0"];
        if ([result next]) {
            msgCount = [result longLongIntForColumn:@"SUM(unreadcount)"];
        }
    }];
    return msgCount;
}

/// 根据targetUid获取会话
/// @param targetUid 目标会话uid
- (Conversation * _Nullable)getConversationWithTargetUid:(int64_t)targetUid {
    __block Conversation *reConver = nil;
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM gb_conversation WHERE conversationid = ?", @(targetUid)];
        if ([rs next]) {
            reConver = [Conversation conversationFromResultSet:rs];
        }   else    {
            // 无处理
        }
        [rs close];
    }];
    return reConver;
}

/// 修改会话失败状态
/// @param haveFailed 是否有失败消息
/// @param targetUid 目标会话uid
- (void)updateConversationSendFailedStatus:(BOOL)haveFailed targetUid:(int64_t)targetUid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET unsend_tag = ? WHERE conversationid = ?", @(haveFailed),
                          @(targetUid)];
    }];
}

/// 修改会话撤回状态数据
/// @param uuids 消息uuid数组
- (void)updateConversationCallBackStatusWithMsgUUIDs:(NSArray<NSString *> *)uuids {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *sqlStr = @"";
        if (uuids.count > 0) {
            NSMutableString *str = [[NSMutableString alloc] init];
            [str appendString:@"("];
            for (NSString *subStr in uuids) {
                [str appendString:[NSString stringWithFormat:@"'%@', ", subStr]];
            }
            [str replaceCharactersInRange:NSMakeRange(str.length - 2, 2) withString:@""];
            [str appendString:@")"];
            sqlStr = [NSString
                stringWithFormat:@"UPDATE gb_conversation SET is_callback= 1 WHERE msguuid IN %@", str];
        }

        [db executeUpdate:sqlStr];
    }];
}

/// 手动添加会话
/// @param conversation 所需添加内部咨询会话的conversation
- (BOOL)manualAddConversationWithConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;
    
    __block BOOL haveRecord = NO;
    __block BOOL success = NO;
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *checkRs = [db executeQuery:@"SELECT conversationid FROM gb_conversation WHERE conversationid  = ?", conversation.uid];
        if ([checkRs next]) {
            haveRecord = YES;
        }
        [checkRs close];
        
        if (haveRecord == NO) {
            NSString *sqlStr = @"INSERT INTO gb_conversation(" ALL_COL
            ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?, ?, ?)";
            
            success = [db executeUpdate:sqlStr, @(conversation.uid), conversation.avatarURL, conversation.name, @(conversation.timestamp), conversation.content, conversation.msguuid, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                       conversation.memberLevel, conversation.memberImg, conversation.draft, @(conversation.unsendTag), conversation.targetId,
                       @(conversation.is_self), conversation.area, conversation.remarkName, @(conversation.conversationType), @(conversation.isMute), conversation.atMsg];
        }
    }];
    return success;
}

/// 所有会话调整为已读，并清空新消息数量
- (void)markAllConversationRead:(void (^ _Nullable)(BOOL))completion {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL state = [db executeUpdate:@"UPDATE gb_conversation SET unreadcount = 0 WHERE unreadcount != 0"];
        if (completion) {
            completion(state);
        }
    }];
}

/// 获取最近一条会话记录
- (Conversation * _Nullable)getLastConversation {
    __block Conversation *reConver = nil;
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM gb_conversation WHERE is_delete = 0 order by timestamp desc LIMIT 1"];
        if ([rs next]) {
            reConver = [Conversation conversationFromResultSet:rs];
        }   else    {
            // 无处理
        }
        [rs close];
    }];
    return reConver;
}
///// 修改会话数据
///// @param conversation 添加的会话
//- (BOOL)amendConversation:(Conversation *)conversation {
//
//}
//
///// 修改会话最后一条message的信息
///// @param message 消息
///// targetUid 目标会话uid
//- (BOOL)amendLatestMessage:(IMessage *)message
//                 targetUid:(int64_t)targetUid {
//
//}
//
///// 获取会话列表
//- (NSArray<Conversation *> *)getAllConversation {
//
//}
//
///// 根据targetUid获取会话
///// @param targetUid 目标会话uid
//- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid {
//
//}
//
///// 根据targetUid删除会话
///// @param targetUid 目标会话uid
//- (BOOL)deleteConversationWithTargetUid:(int64_t)targetUid {
//
//}
@end
