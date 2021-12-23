//
//  IMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "IMessage.h"
#import "IMessageIterator.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IMessageDB <NSObject>

/// 根据最新时间进行消息降序查询
/// @param conversationID targetUid
/// @param timeStamp unix时间
- (id<IMessageIterator>)forwardMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp;

/// 根据最新时间进行消息升序查询
/// @param conversationID targetUid
/// @param timeStamp unix时间
- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp;

/// 获取指定消息的前两条开始往后面的17条数据和前面2条数据，总的20 条数据
/// @param conversationID 聊天会话id
/// @param uuid 消息唯一标识符
- (NSArray<IMessage *> *)fetchHistoryWithConversationID:(int64_t)conversationID baseOnUUID:(NSString *)uuid;

/// 获取单条消息
/// @param uuid 消息唯一标识
- (IMessage *)getMessage:(NSString *)uuid;

/// 存储消息
/// @param msg 消息体
- (BOOL)saveMessage:(IMessage *)msg;

/// 保存消息至数据库
/// @param msg 消息体
/// @param uid 消息保存uid
- (BOOL)insertMessage:(IMessage *)msg uid:(int64_t)uid;

/// 标记消息失败
/// @param uuid 消息唯一标识
- (BOOL)markMessageFailure:(NSString *)uuid;

/// 标记消息听取标识
/// @param uuid 消息唯一标识
- (BOOL)markMesageListened:(NSString *)uuid;

/// 修改消息失败状态
/// @param uuid 消息唯一标识
/// @param timestamp 时间
- (BOOL)eraseMessageFailure:(NSString *)uuid timestamp:(int64_t)timestamp;

/// 修改消息读取状态
/// @param uuid 消息唯一标识
- (BOOL)markMesageHaveRead:(NSString *)uuid;

/// 获取当前目标发送失败消息
/// @param uid targetUid
- (NSArray<IMessage *> *)getFailedMessages:(int64_t)uid;

/// 更新消息撤回状态
/// @param uuids 已经撤回的消息uuid数组
- (BOOL)updateCallbackUUIDS:(NSArray *)uuids;

/// 更新消息删除状态
/// @param uuids 已经删除的消息uuid数组
- (BOOL)updateDeleteUUIDS:(NSArray *)uuids;

/// 批量更新发送者的消息已读状态
/// @param uuids 未读消息uuid数组
- (BOOL)updateHaveNotReadUUIDS:(NSArray *)uuids;

/// 更新消息宽高以及行高
/// @param width 消息宽度
/// @param height 消息高度
/// @param lineHeight 消息行高
/// @param uuid 消息唯一标识
- (BOOL)updateMessageWidth:(float)width height:(float)height lineHeight:(float)lineHeight msgUUID:(NSString *)uuid;

/// 获取包含关键字的消息
/// @param keyword 关键字
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword;

/// 获取目标下包含关键字的消息
/// @param keyword 关键字
/// @param targetUid targetUid
- (NSArray<IMessage *> *)searchMessagesContainKeyword:(NSString *)keyword targetUid:(int64_t)targetUid;

/// 手动检查是否有自定义添加字段
- (void)checkHaveManualColumn;

/// 清楚消息数据
/// @param targetUid 目标uid
- (BOOL)clearMessagesWithTargetUid:(int64_t)targetUid;

/// 通过uid获取当前会话最新的没有做删除的消息
/// @param targetUid 目标uid
- (IMessage *)getLatestMessageWithTargetUid:(int64_t)targetUid;

#pragma mark - gobelieveHandler method

- (int)gobelieveGetMessageId:(NSString *)uuid;
- (IMessage *)gobelieveGetMessage:(int)msgID;
- (BOOL)gobelieveUpdateFlags:(NSInteger)msgLocalID flags:(int)flags;
- (BOOL)gobelieveUpdateMessageContent:(NSInteger)msgLocalID content:(NSString *)content;
- (BOOL)gobelieveRemoveMessageIndex:(int)msgLocalID;
- (BOOL)gobelieveAcknowledgeMessage:(int)msgLocalID;
- (BOOL)gobelieveMarkMessageFailure:(NSInteger)msg;

@end

NS_ASSUME_NONNULL_END
