////
////  SQLConversationDB.h
////  gobelieveSDK
////
////  Created by ch999 on 2021/4/19.
////
//
//#import <Foundation/Foundation.h>
//#import "Conversation.h"
//#import <fmdb/FMDB.h>
//
//NS_ASSUME_NONNULL_BEGIN
//
//@interface SQLConversationDB : NSObject
//@property(nonatomic, strong) FMDatabase *db;
///// 会话表id(唯一值，每个用户一个)
//@property(nonatomic, assign) NSInteger conversationTableId;
//+ (SQLConversationDB *)instance;
//
///// 创建会话表
//- (BOOL)createConversationTable;
//
///// 添加会话
///// @param conversation 添加的会话
//- (BOOL)addConversation:(Conversation *)conversation;
//
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
//@end
//
//NS_ASSUME_NONNULL_END
