//
//  SQLConversationDB.m
//  gobelieveSDK
//
//  Created by ch999 on 2021/4/19.
//

#import "SQLConversationDB.h"
#import "NSString+JSMessagesView.h"

static const NSString *converAllColumns = @"conversationid, avatar, nickname, timestamp, content, msguuid, is_callback, is_group, is_delete, is_top, unreadcount, member_type, member_level, member_img, draft, failed_messages, target_id, is_self, area, remark_name";

@interface SQLGBConversdationIterator : NSObject<GBConversdationIterator>
@property(nonatomic, strong) __block FMResultSet *rs;

- (SQLGBConversdationIterator *)initMemberListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (SQLGBConversdationIterator *)initInternalListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (SQLGBConversdationIterator *)initTopListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (SQLGBConversdationIterator *)initUntopListWithDBQueue:(FMDatabaseQueue *)dbQueue;
@end

@implementation SQLGBConversdationIterator

- (SQLGBConversdationIterator *)initMemberListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE member_type = 1 AND is_delete= 0", converAllColumns];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        __weak typeof(self) weakSelf = self;
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            weakSelf.rs = [db executeQuery:sql];
        }];
    }
    return self;
}

- (SQLGBConversdationIterator *)initInternalListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE member_type = 0 AND is_delete= 0", converAllColumns];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        __weak typeof(self) weakSelf = self;
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            weakSelf.rs = [db executeQuery:sql];
        }];
    }
    return self;
}

- (SQLGBConversdationIterator *)initTopListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE is_top = 1 AND is_delete= 0", converAllColumns];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        __weak typeof(self) weakSelf = self;
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            weakSelf.rs = [db executeQuery:sql];
        }];
    }
    return self;
}

- (SQLGBConversdationIterator *)initUntopListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE is_top = 0 AND is_delete= 0", converAllColumns];
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        __weak typeof(self) weakSelf = self;
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            weakSelf.rs = [db executeQuery:sql];
        }];
    }
    return self;
}

- (Conversation *)next {
    BOOL result = [self.rs next];
    if (!result) {
        return nil;
    }
    
    Conversation *conver = [[Conversation alloc] init];
    [conver setUid:[self.rs longLongIntForColumn:@"conversationid"]];
    [conver setAvatarURL:[self.rs stringForColumn:@"avatar"]];
    [conver setName:[self.rs stringForColumn:@"nickname"]];
    [conver setTimestamp:[self.rs longLongIntForColumn:@"timestamp"]];
    [conver setContent:[self.rs stringForColumn:@"content"]];
    [conver setMsguuid:[self.rs stringForColumn:@"msguuid"]];
    [conver setIsCallback:[self.rs boolForColumn:@"is_callback"]];
    [conver setIsGroup:[self.rs boolForColumn:@"is_group"]];
    [conver setIsDelete:[self.rs boolForColumn:@"is_delete"]];
    [conver setIsTop:[self.rs boolForColumn:@"is_top"]];
    [conver setNewMsgCount:[self.rs intForColumn:@"unreadcount"]];
    [conver setMemberType:[self.rs intForColumn:@"member_type"]];
    [conver setMemberLevel:[self.rs stringForColumn:@"member_level"]];
    [conver setMemberImg:[self.rs stringForColumn:@"member_img"]];
    [conver setDraft:[self.rs stringForColumn:@"draft"]];
    [conver setFailedMessages:[self.rs stringForColumn:@"failed_messages"]];
    [conver setTargetId:[self.rs stringForColumn:@"target_id"]];
    [conver setIs_self:[self.rs boolForColumn:@"is_self"]];
    [conver setArea:[self.rs stringForColumn:@"area"]];
    [conver setRemarkName:[self.rs stringForColumn:@"remark_name"]];
    return conver;
}

@end

@implementation SQLConversationDB
+ (SQLConversationDB *)instance {
    static SQLConversationDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLConversationDB alloc] init];
        }
    });
    return m;
}

- (void)setConversationTableId:(NSInteger)conversationTableId {
    _conversationTableId = conversationTableId;
}

/// 获取会员会话列表
- (id<GBConversdationIterator>)memberConversation {
    return [[SQLGBConversdationIterator alloc] initMemberListWithDBQueue:self.dbQueue];
}

/// 获取内部聊天会话列表
- (id<GBConversdationIterator>)internalConversation {
    return [[SQLGBConversdationIterator alloc] initInternalListWithDBQueue:self.dbQueue];
}

/// 获取所有置顶聊天会话列表
- (id<GBConversdationIterator>)topConversation {
    return [[SQLGBConversdationIterator alloc] initTopListWithDBQueue:self.dbQueue];
}

/// 获取所有未置顶聊天会话列表
- (id<GBConversdationIterator>)untopConversation {
    return [[SQLGBConversdationIterator alloc] initUntopListWithDBQueue:self.dbQueue];
}

/// 添加会话
/// @param conversation 添加的会话
- (void)addConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *avatar = [conversation.avatarURL hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.avatarURL] : @"''";
    NSString *nickname = [conversation.name hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.name] : @"''";
    NSString *content = [conversation.content hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.content] : @"''";
    NSString *readUUID = [conversation.msguuid hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.msguuid] : @"''";
    NSString *memberLevel = [conversation.memberLevel hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.memberLevel] : @"''";
    NSString *memberImg = [conversation.memberImg hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.memberImg] : @"''";
    NSString *draft = [conversation.draft hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.draft] : @"''";
    NSString *failedMessages = [conversation.failedMessages hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.failedMessages] : @"''";
    NSString *targetId = [conversation.targetId hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.targetId] : @"''";
    NSString *areaStr = [conversation.area hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.area] : @"''";
    NSString *remarkNameStr = [conversation.remarkName hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.remarkName] : @"''";
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        BOOL haveRecord = NO;
        NSString *querySqlStr = [NSString stringWithFormat:@"SELECT conversationid FROM gb_conversation WHERE conversationid = %@", @(conversation.uid)];
        FMResultSet *result = [db executeQuery:querySqlStr];
        if (result.next) {
            haveRecord = YES;
        }
        if (haveRecord == YES) {
            NSString *replaceSqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET avatar= %@, nickname= %@, timestamp= %@, content= %@, msguuid= %@, is_callback= %@, is_group= %@, is_delete= %@, is_top= %@, unreadcount= %@, member_type= %@, member_level=%@, member_img= %@, draft= %@, failed_messages= %@, target_id= %@, is_self= %@, area= %@, remark_name= %@ WHERE conversationid = %@", avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft, failedMessages, targetId, @(conversation.is_self), areaStr, remarkNameStr, @(conversation.uid)];
            [db executeUpdate:replaceSqlStr];
            return;
        }
        NSString *sqlStr = [NSString stringWithFormat:@"INSERT INTO gb_conversation (%@) VALUES (%@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@)", converAllColumns, @(conversation.uid), avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft, failedMessages, targetId, @(conversation.is_self), areaStr, remarkNameStr];
        [db executeUpdate:sqlStr];
    }];
}

/// 整体会话替换，将会话的所有展示内容做替换，一般在将服务端会话请求下来时使用
/// @param conversation 添加的会话
- (void)replaceConversation:(Conversation *)conversation {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *avatar = [conversation.avatarURL hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.avatarURL] : @"''";
    NSString *nickname = [conversation.name hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.name] : @"''";
    NSString *content = [conversation.content hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.content] : @"''";
    NSString *readUUID = [conversation.msguuid hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.msguuid] : @"''";
    NSString *memberLevel = [conversation.memberLevel hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.memberLevel] : @"''";
    NSString *memberImg = [conversation.memberImg hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.memberImg] : @"''";
    NSString *draft = [conversation.draft hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.draft] : @"''";
    NSString *failedMessages = [conversation.failedMessages hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.failedMessages] : @"''";
    NSString *targetId = [conversation.targetId hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.targetId] : @"''";
    NSString *areaStr = [conversation.area hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.area] : @"''";
    NSString *remarkNameStr = [conversation.remarkName hasContent] ? [NSString stringWithFormat:@"'%@'", conversation.remarkName] : @"''";
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET avatar= %@, nickname= %@, timestamp= %@, content= %@, msguuid= %@, is_callback= %@, is_group= %@, is_delete= %@, is_top= %@, unreadcount= %@, member_type= %@, member_level=%@, member_img= %@, draft= %@, failed_messages= %@， target_id= %@, is_self= %@, area= %@, remark_name= %@ WHERE conversationid = %@", avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft, failedMessages, targetId, @(conversation.is_self), areaStr, remarkNameStr, @(conversation.uid)];
        [db executeUpdate:sqlStr];
    }];
}

/// 删除会话
/// @param uid 删除会话的id
- (void)deleteConversationWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *sqlStr = [NSString stringWithFormat:@"DELETE FROM gb_conversation WHERE conversationid= %@", @(uid)];
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [db executeUpdate:sqlStr];
    }];
}

/// 隐藏会话
/// @param isHide 是否隐藏
/// @param uid 删除会话的id
- (void)disposeConversationIsHide:(BOOL)isHide
                              uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET is_delete= %@ WHERE conversationid= %@", @(isHide), @(uid)];
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [db executeUpdate:sqlStr];
    }];
}

/// 修改会话置顶状态
/// @param isTop 是否置顶
/// @param uid 操作会话的uid
- (void)disposeConversationIsTop:(BOOL)isTop
                             uid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET is_top= %@ WHERE conversationid= %@", @(isTop), @(uid)];
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [db executeUpdate:sqlStr];
    }];
}

/// 清空会话未读数量
/// @param uid 清空会话的id
- (void)clearConversationMsgCountWithUid:(int64_t)uid {
    FMDatabaseQueue *queue = self.dbQueue;
    
    NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET unreadcount= 0 WHERE conversationid= %@", @(uid)];
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        [db executeUpdate:sqlStr];
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
    
    NSString *avatarStr = [avatar hasContent] ? [NSString stringWithFormat:@"'%@'", avatar] : @"''";
    NSString *nicknameStr = [nickname hasContent] ? [NSString stringWithFormat:@"'%@'", nickname] : @"''";
    NSString *targetIdStr = [targetId hasContent] ? [NSString stringWithFormat:@"'%@'", targetId] : @"''";
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET avatar= %@, nickname= %@, target_id= %@ WHERE conversationid= %@", avatarStr, nicknameStr, targetIdStr, @(uid)];
        [db executeUpdate:sqlStr];
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
    
    NSString *memberLevelStr = [memberLevel hasContent] ? [NSString stringWithFormat:@"'%@'", memberLevel] : @"''";
    NSString *memberImgStr = [memberImg hasContent] ? [NSString stringWithFormat:@"'%@'", memberImg] : @"''";
    NSString *areaStr = [area hasContent] ? [NSString stringWithFormat:@"'%@'", area] : @"''";
    NSString *remarkNameStr = [remarkName hasContent] ? [NSString stringWithFormat:@"'%@'", remarkName] : @"''";
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET member_type= %@, member_level= %@, member_img= %@, area= %@, remark_name= %@ WHERE conversationid= %@", @(memberType), memberLevelStr, memberImgStr, areaStr, remarkNameStr, @(uid)];
        [db executeUpdate:sqlStr];
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
    
    NSString *contentStr = [content hasContent] ? [NSString stringWithFormat:@"'%@'", content] : @"''";
    NSString *uuidStr = [msgUUID hasContent] ? [NSString stringWithFormat:@"'%@'", msgUUID] : @"''";
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE gb_conversation SET content= %@, msguuid= %@, timestamp= %@, unreadcount= %@ WHERE conversationid= %@", contentStr, uuidStr, @(timestamp), @(count), @(receiver)];
        [db executeUpdate:sqlStr];
    }];
}

/// 获取会话未读数量
/// @param receiver 消息接收方
- (NSInteger)getConversationNewMsgCountWithReceiver:(int64_t)receiver {
    __block NSInteger unreadCount = 0;
    FMDatabaseQueue *queue = self.dbQueue;
    dispatch_semaphore_t signal = dispatch_semaphore_create(0);
    NSString *sqlStr = [NSString stringWithFormat:@"SELECT unreadcount FROM gb_conversation WHERE conversationid= %@", @(receiver)];
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *result = [db executeQuery:sqlStr];
        if ([result next]) {
            unreadCount = [result longLongIntForColumn:@"unreadcount"];
        }
        [result close];
        dispatch_semaphore_signal(signal);
    }];
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    return unreadCount;
}

/// 根据targetUid获取会话
/// @param targetUid 目标会话uid
- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid {
    __block Conversation *reConver = nil;
    NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM gb_conversation WHERE conversationid= %@", @(targetUid)];
    
    dispatch_semaphore_t signal = dispatch_semaphore_create(0);
    FMDatabaseQueue *queue = self.dbQueue;
    
    [queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        FMResultSet *rs = [db executeQuery:sqlStr];
        if ([rs next]) {
            Conversation *conver = [[Conversation alloc] init];
            [conver setUid:[rs longLongIntForColumn:@"conversationid"]];
            [conver setAvatarURL:[rs stringForColumn:@"avatar"]];
            [conver setName:[rs stringForColumn:@"nickname"]];
            [conver setTimestamp:[rs longLongIntForColumn:@"timestamp"]];
            [conver setContent:[rs stringForColumn:@"content"]];
            [conver setMsguuid:[rs stringForColumn:@"msguuid"]];
            [conver setIsCallback:[rs boolForColumn:@"is_callback"]];
            [conver setIsGroup:[rs boolForColumn:@"is_group"]];
            [conver setIsDelete:[rs boolForColumn:@"is_delete"]];
            [conver setIsTop:[rs boolForColumn:@"is_top"]];
            [conver setNewMsgCount:[rs intForColumn:@"unreadcount"]];
            [conver setMemberType:[rs boolForColumn:@"member_type"]];
            [conver setMemberLevel:[rs stringForColumn:@"member_level"]];
            [conver setMemberImg:[rs stringForColumn:@"member_img"]];
            [conver setDraft:[rs stringForColumn:@"draft"]];
            [conver setFailedMessages:[rs stringForColumn:@"failed_messages"]];
            [conver setTargetId:[rs stringForColumn:@"target_id"]];
            [conver setIs_self:[rs boolForColumn:@"is_self"]];
            [conver setArea:[rs stringForColumn:@"area"]];
            [conver setRemarkName:[rs stringForColumn:@"remark_name"]];
            reConver = conver;
            dispatch_semaphore_signal(signal);
        }else{
            dispatch_semaphore_signal(signal);
        }
        [rs close];
    }];
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
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
