//
//  SQLConversationDB.h
//  Gobelieve
//
//  Created by ch999 on 2021/4/19.
//

#import "Conversation.h"
#import "GBConversationIterator.h"

#import <Foundation/Foundation.h>
#import <fmdb/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQLConversationDB : NSObject

@property(nonatomic, strong, readonly, class) SQLConversationDB *instance;

@property(nonatomic, strong) FMDatabaseQueue *dbQueue;
/// 会话表id(唯一值，每个用户一个)
@property(nonatomic, assign) NSInteger conversationTableId;

/// 获取会员会话列表
- (id<GBConversationIterator>)memberConversation;

/// 获取内部聊天会话列表
- (id<GBConversationIterator>)internalConversation;

/// 获取所有置顶聊天会话列表
- (id<GBConversationIterator>)topConversation;

/// 获取所有未置顶聊天会话列表
- (id<GBConversationIterator>)untopConversation;

/// 添加会话
/// @param conversation 添加的会话
- (void)addConversation:(Conversation *)conversation;

/// 整体会话替换，将会话的所有展示内容做替换
/// @param conversation 添加的会话
- (void)replaceConversation:(Conversation *)conversation;

/// 删除会话
/// @param uid 删除会话的id
- (void)deleteConversationWithUid:(int64_t)uid;

/// 隐藏会话
/// @param isHide 是否隐藏
/// @param uid 删除会话的id
- (void)disposeConversationIsHide:(BOOL)isHide uid:(int64_t)uid;

/// 清空会话未读数量
/// @param uid 清空会话的id
- (void)clearConversationMsgCountWithUid:(int64_t)uid;

/// 保存草稿消息
/// @param uid 保存草稿会话的id
/// @param draft 保存草稿会话的文字
- (void)saveDraftToConversationWithUid:(int64_t)uid draft:(NSString *)draft;

/// 修改会话置顶状态
/// @param isTop 是否置顶
/// @param uid 操作会话的uid
- (void)disposeConversationIsTop:(BOOL)isTop uid:(int64_t)uid;

/// 根据uid修改会话targetId、昵称、头像
/// @param targetId 需要记录的targetId
/// @param nickname 需要记录的昵称
/// @param avatar 需要记录的头像
/// @param uid 目标会话uid
- (void)updateConversationTargetId:(NSString *)targetId
                          nickname:(NSString *)nickname
                            avatar:(NSString *)avatar
                               uid:(int64_t)uid;

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
                                               uid:(int64_t)uid;

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
                                    receiver:(int64_t)receiver;

/// 获取会话未读数量
/// @param receiver 消息接收方
- (NSInteger)getConversationNewMsgCountWithReceiver:(int64_t)receiver;

/// 根据targetUid获取会话
/// @param targetUid 目标会话uid
- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid;

/// 修改会话失败状态
/// @param haveFailed 是否有失败消息
/// @param targetUid 目标会话uid
- (void)updateConversationSendFailedStatus:(BOOL)haveFailed targetUid:(int64_t)targetUid;

/// 修改会话撤回状态数据
/// @param uuids 消息uuid数组
- (void)updateConversationCallBackStatusWithMsgUUIDs:(NSArray<NSString *> *)uuids;

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
