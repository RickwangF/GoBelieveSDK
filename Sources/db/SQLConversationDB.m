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
        if (haveRecord) {
            success = [db
                executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, "
                              @"msguuid = ?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount= "
                              @"?, member_type = ?, member_level=?, member_img = ?, draft = ?, unsend_tag = ?, "
                              @"target_id = ?, is_self = ?, area = ?, remark_name = ? WHERE conversationid  = ?",
                              avatar, nickname, @(conversation.timestamp), content, readUUID,
                              @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                              @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                              memberLevel, memberImg, draft, @(conversation.unsendTag), targetId,
                              @(conversation.is_self), areaStr, remarkNameStr, @(conversation.uid)];
            return;
        }
        NSString *sqlStr = @"INSERT INTO gb_conversation (" ALL_COL
                            ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?)";
        success =
            [db executeUpdate:sqlStr, @(conversation.uid), avatar, nickname, @(conversation.timestamp), content,
                              readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                              @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType),
                              memberLevel, memberImg, draft, @(conversation.unsendTag), targetId,
                              @(conversation.is_self), areaStr, remarkNameStr];
    }];
    return success;
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
                          @"?, is_self = ?, area = ?, remark_name = ? WHERE conversationid  = ?",
                          avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback),
                          @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                          @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft,
                          @(conversation.unsendTag), targetId, @(conversation.is_self), areaStr, remarkNameStr,
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

/// 清空会话未读数量
/// @param uid 清空会话的id
- (void)clearConversationMsgCountWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET unreadcount = 0 WHERE conversationid = ?", @(uid)];
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
/// @param count 消息数量
/// @param receiver 消息接收方
- (void)updateConversationMessageWithContent:(NSString *)content
                                     msgUUID:(NSString *)msgUUID
                                   timestamp:(int64_t)timestamp
                                       count:(NSInteger)count
                                    receiver:(int64_t)receiver {
    FMDatabaseQueue *queue = self.dbQueue;

    NSString *contentStr = stringOrEmpty(content);
    NSString *uuidStr = stringOrEmpty(msgUUID);

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"UPDATE gb_conversation SET content = ?, msguuid = ?, timestamp=  ?, unreadcount = ?, "
                          @"is_callback= 0 WHERE conversationid = ?",
                          contentStr, uuidStr, @(timestamp), @(count), @(receiver)];
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
        FMResultSet *result = [db executeQuery:@"SELECT SUM(unreadcount) FROM gb_conversation"];
        if ([result next]) {
            msgCount = [result longLongIntForColumn:@"SUM(unreadcount)"];
        }
    }];
    return msgCount;
}

/// 根据targetUid获取会话
/// @param targetUid 目标会话uid
- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid {
    __block Conversation *reConver = nil;

    FMDatabaseQueue *queue = self.dbQueue;

    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM gb_conversation WHERE conversationid = ?", @(targetUid)];
        if ([rs next]) {
            reConver = [Conversation conversationFromResultSet:rs];
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
                stringWithFormat:@"UPDATE gb_conversation SET is_self= 0, is_callback= 1 WHERE msguuid IN %@", str];
        }

        [db executeUpdate:sqlStr];
    }];
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
