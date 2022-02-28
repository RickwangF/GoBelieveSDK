//
//  IMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "IMessage.h"
#import "IMessageIterator.h"

#import <Foundation/Foundation.h>

#define PAGE_COUNT 20
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
- (NSArray<IMessage *> *)fetchHistoryWithConversationID:(int64_t)conversationID baseOnUUID:(NSString *_Nonnull)uuid;

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

/// 批量更新多个消息为已读状态
/// @param uuids 消息唯一标识符
- (BOOL)markMesagesHaveRead:(NSArray<NSString *> * _Nonnull)uuids;

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

/// 批量更新消息已读状态，此方法不更新非自己发送的消息已读状态
/// @param uuids 未读消息uuid数组
/// @param sender 自己的uid
- (BOOL)updateHaveNotReadUUIDS:(NSArray *)uuids sender:(int64_t)sender;

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

/// 查询多条消息，根据uuid查
/// @param uuids 消息uuid集合
- (NSArray<IMessage *> * _Nonnull)queryMessagesWithUUIDs:(NSArray<NSString *> * _Nonnull)uuids;

/// 查询第一条未读消息（非本人发送）到指定消息的消息集合，按时间升序排列
/// @param uuid 最后的消息uuid，为nil则返回到最后一条消息
/// @param targetUID 聊天id，单聊是对方的UID，群聊是GID
/// @param senderUID 发送方id
- (NSArray<IMessage *> * _Nonnull)queryUnreadMessagesToUUID:(NSString * _Nullable)uuid byTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID;

/// 查询第一条未读消息（非本人发送）到指定消息的消息内所有未读消息集合，按时间升序排列
/// @param uuid 最后的消息uuid，为nil则查到最后一条消息
/// @param targetUID 聊天id，单聊是对方的UID，群聊是GID
/// @param senderUID 发送方id
- (NSArray<IMessage *> * _Nonnull)queryUnreadOnlyMessagesToUUID:(NSString * _Nullable)uuid byTargetUID:(int64_t)targetUID senderUID:(int64_t)senderUID;

/// 查询两条消息之间的所有消息，同一会话下
/// @param bottomUUID 底部最后一条消息，不存在时则查所有的
/// @param topUUID 顶部第一条消息
/// @param targetUID 会话uid
/// @param limited 查询条数，当前没有底部信息限制时此参数控制返回的条数
- (NSArray<IMessage *> * _Nonnull)queryMessagesToUUID:(NSString * _Nullable)bottomUUID from:(NSString * _Nonnull)topUUID byTargetUID:(int64_t)targetUID limited:(NSInteger)limited;

/// 所有聊天消息（非自己发送的、不失败的）调整为已读
- (BOOL)markAllMessagesRead:(int64_t)sender;

/// 已读指定会话下所有他人消息，自己的消息不处理
/// @param conversationID 会话id
/// @param senderUID 当前登录用户uid
- (BOOL)markAllMessagesReadByConversationID:(int64_t)conversationID senderUID:(int64_t)senderUID;

#pragma mark - gobelieveHandler method
- (int)gobelieveGetMessageId:(NSString *)uuid;
- (IMessage *)gobelieveGetMessage:(int)msgID;
- (BOOL)gobelieveUpdateFlags:(NSInteger)msgLocalID flags:(int)flags;
- (BOOL)gobelieveUpdateMessageContent:(NSInteger)msgLocalID content:(NSString *)content;
- (BOOL)gobelieveRemoveMessageIndex:(int)msgLocalID;
- (BOOL)gobelieveAcknowledgeMessage:(int)msgLocalID;
- (BOOL)gobelieveMarkMessageFailure:(NSInteger)msg;

//-(id<IMessageIterator>)newMessageIterator:(int64_t)conversationID;
////下拉刷新
//-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID last:(int)lastMsgID;
//-(id<IMessageIterator>)newMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp;
//-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID timeStamp:(NSInteger)timeStamp;
//-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int)messageID;
////上拉刷新
//-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int)messageID;
//-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid timeStamp:(NSInteger)timeStamp;
//-(IMessage*)getMessage:(int64_t)msgID;
//-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
//-(BOOL)saveMessage:(IMessage*)msg;
//-(BOOL)saveMessage:(IMessage*)msg andUid:(int64_t)uid;
//-(BOOL)removeMessage:(NSInteger)msg;
//-(BOOL)markMessageFailure:(NSInteger)msg;
//-(BOOL)markMesageListened:(NSInteger)msg;
//-(BOOL)eraseMessageFailure:(NSInteger)msg;
//-(BOOL)eraseMessageFailure:(NSInteger)msg haveRead:(BOOL)haveRead;
//-(BOOL)markMesageHaveRead:(NSString *)readUUID;
//- (BOOL)checkHaveFailedMessageUid:(int64_t)uid;

//- (BOOL)updateCallBack:(NSString *)uuid;
//- (BOOL)updateCallBackWithUUIDs:(NSArray *)uuidArr;
//- (BOOL)updateDelete:(NSString *)uuid;

//- (BOOL)updateHaveRead:(int)haveRead uuidArr:(NSArray *)readUUIDArr;
//- (BOOL)updateNewMessageWithUUidArr:(NSArray *)readUUIDArr uid:(int64_t)targetUid;
//- (NSArray *)getUnreadMsgs;
//- (NSArray *)getRecalledMsgs;

//- (BOOL)updateMessageWidth:(float)width height:(float)height lineHeight:(float)lineHeight msgId:(NSInteger)msg;

////获取存在关键字的消息
//- (NSArray<IMessage *> *)getTargetMessageAndLocationWithKeyWord:(NSString *)keyWord;
////获取目标会话下存在关键字的消息
//- (NSArray<IMessage *> *)getTargetMessageAndLocationWithKeyWord:(NSString *)keyWord target:(int64_t)targetUid;
//
//- (NSArray<IMessage *> *)getTargetMessageWith:(IMessage *)message uid:(int64_t)targetUid;
@end
