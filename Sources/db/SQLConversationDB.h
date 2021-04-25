//
//  SQLConversationDB.h
//  gobelieveSDK
//
//  Created by ch999 on 2021/4/19.
//

#import <Foundation/Foundation.h>
#import "Conversation.h"
#import <fmdb/FMDB.h>
#import "GBConversdationIterator.h"

NS_ASSUME_NONNULL_BEGIN

@interface SQLConversationDB : NSObject
@property(nonatomic, strong) FMDatabaseQueue *dbQueue;
/// 会话表id(唯一值，每个用户一个)
@property(nonatomic, assign) NSInteger conversationTableId;
+ (SQLConversationDB *)instance;

/// 获取会员会话列表
- (id<GBConversdationIterator>)memberConversation;

/// 获取内部聊天会话列表
- (id<GBConversdationIterator>)internalConversation;

/// 获取所有置顶聊天会话列表
- (id<GBConversdationIterator>)topConversation;

/// 获取所有未置顶聊天会话列表
- (id<GBConversdationIterator>)untopConversation;

/// 添加会话
/// @param conversation 添加的会话
- (void)addConversation:(Conversation *)conversation;

/// 整体会话替换，将会话的所有展示内容做替换
/// @param conversation 添加的会话
- (void)replaceConversation:(Conversation *)conversation;

/// 修改会话头像

/// 修改会话显示最后一条消息相关
/// @param content 消息内容
/// @param msgUUID 消息uuid
/// @param timestamp 时间
/// @param receiver 消息接收方
- (void)updateConversationMessageWithContent:(NSString *)content
                                     msgUUID:(NSString *)msgUUID
                                   timestamp:(int64_t)timestamp
                                    receiver:(int64_t)receiver;

/// 根据targetUid获取会话
/// @param targetUid 目标会话uid
- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid;

///// 修改会话数据
///// @param conversation 添加的会话
//- (BOOL)amendConversation:(Conversation *)conversation;
//
///// 修改会话最后一条message的信息
///// @param message 消息
///// targetUid 目标会话uid
//- (BOOL)amendLatestMessage:(IMessage *)message
//                 targetUid:(int64_t)targetUid;
//
///// 获取会话列表
//- (NSArray<Conversation *> *)getAllConversation;
//
///// 根据targetUid获取会话
///// @param targetUid 目标会话uid
//- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid;
//
///// 根据targetUid删除会话
///// @param targetUid 目标会话uid
//- (BOOL)deleteConversationWithTargetUid:(int64_t)targetUid;
@end

NS_ASSUME_NONNULL_END
