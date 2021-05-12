//
//  SQLConversationDB.m
//  Gobelieve
//
//  Created by ch999 on 2021/4/19.
//

#import "SQLConversationDB.h"

#import "Conversation+Private.h"

NSString *stringOrEmpty(NSString *value) { return (value && value.length > 0) ? value : @""; }

//static const NSString *converAllColumns =
//    @"conversationid, avatar, nickname, timestamp, content, msguuid, is_callback, is_group, is_delete, is_top, "
//    @"unreadcount, member_type, member_level, member_img, draft, unsend_tag, target_id, is_self, area, remark_name";

@interface SQLGBConversdationIterator : NSObject <GBConversationIterator>
@property(nonatomic, strong) FMResultSet *rs;

- (instancetype)initMemberListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (instancetype)initInternalListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (instancetype)initTopListWithDBQueue:(FMDatabaseQueue *)dbQueue;
- (instancetype)initUntopListWithDBQueue:(FMDatabaseQueue *)dbQueue;
@end

@implementation SQLGBConversdationIterator

- (SQLGBConversdationIterator *)initMemberListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        //        NSString *sql =
        //            [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE member_type = 1 AND is_delete=
        //            0",
        //                                       converAllColumns];
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 1 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            self.rs = [db executeQuery:sql];
        }];
//        [dbQueue inDatabase:^(FMDatabase *db) {
//          self.rs = [db executeQuery:sql];
//        }];
    }
    return self;
}

- (void)dealloc {
    [self.rs close];
}

- (SQLGBConversdationIterator *)initInternalListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        //        NSString *sql =
        //            [NSString stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE member_type = 0 AND is_delete=
        //            0",
        //                                       converAllColumns];
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 0 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            self.rs = [db executeQuery:sql];
        }];
//        [dbQueue inDatabase:^(FMDatabase *db) {
//          self.rs = [db executeQuery:sql];
//        }];
    }
    return self;
}

- (SQLGBConversdationIterator *)initTopListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        //        NSString *sql = [NSString
        //            stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE is_top = 1 AND is_delete= 0",
        //            converAllColumns];
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE is_top = 1 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            self.rs = [db executeQuery:sql];
        }];
//        [dbQueue inDatabase:^(FMDatabase *db) {
//          self.rs = [db executeQuery:sql];
//        }];
    }
    return self;
}

- (SQLGBConversdationIterator *)initUntopListWithDBQueue:(FMDatabaseQueue *)dbQueue {
    self = [super init];
    if (self) {
        // 取到数据的第一条应该是这批数据中最老的的消息，所以做timestamp升序排序
        //        NSString *sql = [NSString
        //            stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE is_top = 0 AND is_delete= 0",
        //            converAllColumns];
        NSString *sql = @("SELECT " ALL_COL " FROM gb_conversation WHERE is_top = 0 AND is_delete = 0");
#if DEBUG
        NSLog(@">>> query sql %@", sql);
#endif
        [dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            self.rs = [db executeQuery:sql];
        }];
//        [dbQueue inDatabase:^(FMDatabase *db) {
//          self.rs = [db executeQuery:sql];
//        }];
    }
    return self;
}

- (Conversation *)next {
    BOOL result = [self.rs next];
    if (!result) {
        return nil;
    }
    return [Conversation conversationFromResultSet:self.rs];
}

@end

@implementation SQLConversationDB

+ (SQLConversationDB *)instance {
    static SQLConversationDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      m = [[SQLConversationDB alloc] init];
    });
    return m;
}

- (void)setConversationTableId:(NSInteger)conversationTableId {
    _conversationTableId = conversationTableId;
}

/// 获取会员会话列表
- (id<GBConversationIterator>)memberConversation {
    return [[SQLGBConversdationIterator alloc] initMemberListWithDBQueue:self.dbQueue];
}

/// 获取内部聊天会话列表
- (id<GBConversationIterator>)internalConversation {
    return [[SQLGBConversdationIterator alloc] initInternalListWithDBQueue:self.dbQueue];
}

/// 获取所有置顶聊天会话列表
- (id<GBConversationIterator>)topConversation {
    return [[SQLGBConversdationIterator alloc] initTopListWithDBQueue:self.dbQueue];
}

/// 获取所有未置顶聊天会话列表
- (id<GBConversationIterator>)untopConversation {
    return [[SQLGBConversdationIterator alloc] initUntopListWithDBQueue:self.dbQueue];
}

/// 添加会话
/// @param conversation 添加的会话
- (void)addConversation:(Conversation *)conversation {
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
      BOOL haveRecord = NO;
      FMResultSet *result = [db
          executeQuery:@"SELECT conversationid FROM gb_conversation WHERE conversationid  = ?", @(conversation.uid)];
      if (result.next) {
          haveRecord = YES;
      }
      [result close];
      if (haveRecord) {
          [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, timestamp = ?, content = ?, "
                            @"msguuid = ?, is_callback = ?, is_group = ?, is_delete = ?, is_top = ?, unreadcount= "
                            @"?, member_type = ?, member_level=?, member_img = ?, draft = ?, unsend_tag = ?, "
                            @"target_id = ?, is_self = ?, area = ?, remark_name = ? WHERE conversationid  = ?",
                            avatar, nickname, @(conversation.timestamp), content, readUUID, @(conversation.isCallback),
                            @(conversation.isGroup), @(conversation.isDelete), @(conversation.isTop),
                            @(conversation.newMsgCount), @(conversation.memberType), memberLevel, memberImg, draft,
                            @(conversation.unsendTag), targetId, @(conversation.is_self), areaStr, remarkNameStr,
                            @(conversation.uid)];
          return;
      }
      //      NSString *sqlStr = [NSString
      //          stringWithFormat:@"INSERT INTO gb_conversation (%@) VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?,
      //          ?, "
      //                           @" ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?)",
      //                           converAllColumns];
      NSString *sqlStr =
          @"INSERT INTO gb_conversation (" ALL_COL ") VALUES ( ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, "
           " ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?)";
      [db executeUpdate:sqlStr, @(conversation.uid), avatar, nickname, @(conversation.timestamp), content, readUUID,
                        @(conversation.isCallback), @(conversation.isGroup), @(conversation.isDelete),
                        @(conversation.isTop), @(conversation.newMsgCount), @(conversation.memberType), memberLevel,
                        memberImg, draft, @(conversation.unsendTag), targetId, @(conversation.is_self), areaStr,
                        remarkNameStr];
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
      [db executeUpdate:@"UPDATE gb_conversation SET avatar = ?, nickname = ?, target_id = ? WHERE conversationid = ?",
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
      [db executeUpdate:@"UPDATE gb_conversation SET content = ?, msguuid = ?, timestamp= \
                        ?, unreadcount = ?, is_callback= 0 WHERE conversationid = ?",
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
