//
//  SQLConversationDB.h
//  Gobelieve
//
//  Created by ch999 on 2021/4/19.
//

#import "Conversation.h"

#import <Foundation/Foundation.h>
#import <fmdb/FMDB.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQLConversationDB : NSObject

@property(nonatomic, strong, readonly, class) SQLConversationDB *instance;
/// 数据库操作线程，所有相关操作都要在这个线程执行
@property(nonatomic, strong, readonly, class) dispatch_queue_t executeQueue;
/// 会话表id(唯一值，每个用户一个)
@property(nonatomic, assign) NSInteger conversationTableId;

/// 初始化数据库多线程队列方法
/// @param path 数据库路径
+ (void)setDataBaseQueuePath:(NSString *)path;

/// 获取会员会话列表
- (void)memberConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;
/// 获取内部聊天会话列表
- (void)internalConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;
/// 获取群聊会话列表
- (void)groupConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;
/// 获取所有置顶聊天会话列表
- (void)topConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;
/// 获取所有未置顶聊天会话列表
- (void)untopConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;

/// 获取所有聊天列表，排序顺序是根据是否置顶和时间戳排序，置顶数据在前面，按时间从新到旧排序
- (void)getSortTopChatConversationWithCompletion:(void (^ _Nonnull)(NSArray<Conversation *> * _Nonnull))completion;

/// 添加会话
/// @param conversation 添加的会话
/// @param completion 数据库操作执行完成回调，state为执行结果是否成功，此block会在主线程中回调
- (void)addConversation:(Conversation *)conversation completion:(void (^ _Nullable)(BOOL state))completion;

/// 检测是否存在表结构字段
- (void)manualCheckConversationDBColumn;

/// 删除所有会话
- (void)clearAllConversationCompletion:(void (^_Nullable)(BOOL state))completion;

/// 删除除了群聊外的其他会话
- (void)clearAllConversationExceptGroupTypeCompletion:(void (^_Nullable)(BOOL state))completion;

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
- (void)saveDraftToConversationWithUid:(int64_t)uid draft:(NSString *)draft
__deprecated_msg("方法废弃，使用saveDraftMessageWithUid替换");

/// Save draft message.
/// @param uid The uid of the conversation where the draft will be saved.
/// @param draft The string of the conversation where the draft will be saved.
/// @param newConversation The conversation for inspection.
- (void)saveDraftMessageWithUid:(int64_t)uid draft:(NSString *)draft conversation:(Conversation *)newConversation;

/// 修改会话置顶状态
/// @param isTop 是否置顶
/// @param uid 操作会话的uid
- (void)disposeConversationIsTop:(BOOL)isTop uid:(int64_t)uid;

/// 修改会话备注名称
/// @param remarkName 备注名
/// @param uid 操作会话的uid
- (void)updateConversationRemarkName:(NSString *)remarkName uid:(int64_t)uid;

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
                                    receiver:(int64_t)receiver;

/// 获取会话未读数量
/// @param receiver 消息接收方
- (NSInteger)getConversationNewMsgCountWithReceiver:(int64_t)receiver;

/// 获取所有会话未读数量
- (NSInteger)getAllConversationNewMsgCount;

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

/// 手动添加会话
/// @param conversation 所需添加内部咨询会话的conversation
- (BOOL)manualAddConversationWithConversation:(Conversation *)conversation;

#if DEBUG
/// 执行SQL语句，单元测试使用
/// @param statements SQL语句
- (void)executeStatements:(NSString *)statements;
/// 访问数据库，block在专门的数据库队列同步执行
/// @param block 数据库访问回调
- (void)inDatabase:(__attribute__((noescape)) void (^)(FMDatabase *db))block;
/// 关闭数据库，单元测试使用
- (void)close;
#endif

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
