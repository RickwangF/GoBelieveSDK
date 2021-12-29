//
// Created by Nan Yang on 2021/12/23.
//

#import <Foundation/Foundation.h>

@class Conversation;

NS_ASSUME_NONNULL_BEGIN

// 使用接口定义 ConversationDatabase 的公共方法。保证更新时的外部 API 兼容性。
@protocol GoConversationDatabase <NSObject>
@required

@property(nonatomic, strong, readonly, class) id<GoConversationDatabase> instance
    API_DEPRECATED_WITH_REPLACEMENT("sharedInstance",
        macos(10.0, API_TO_BE_DEPRECATED), ios(2.0, API_TO_BE_DEPRECATED));

@property(nonatomic, strong, readonly, class) id<GoConversationDatabase> sharedInstance NS_SWIFT_NAME(shared);

+ (void)setDataBaseQueuePath:(NSString*)path;

/// 会话表id(唯一值，每个用户一个)
@property(nonatomic, assign) NSInteger conversationTableId;

/**
 * 同步地添加会话。
 * @param conversation 要添加的会话。
 * @return 是否执行成功。
 */
- (BOOL)addConversation:(Conversation *)conversation;

/// 异步地添加会话。
/// @param conversation 要添加的会话。
/// @param completion 数据库操作执行完成回调，state为执行结果是否成功，此block会在当前线程中回调。
- (void)addConversation:(Conversation*)conversation completion:(void (^ _Nullable)(BOOL state))completion;

/// 获取所有聊天列表，排序顺序是根据是否置顶和时间戳排序，置顶数据在前面，按时间从新到旧排序
- (void)getSortTopChatConversationWithCompletion:(void (^)(NSArray<Conversation*>*))completion;

/// 检测是否存在表结构字段
- (void)manualCheckConversationDBColumn;

/**
 * 删除所有会话。
 * @param completion 完成的回调，在当前线程执行。
 */
- (void)clearAllConversationCompletion:(void (^ _Nullable)(BOOL state))completion;

/**
 * 根据 UID 删除对应的会话。
 * @param uid 删除会话的 id。
 */
- (void)deleteConversationWithUid:(int64_t)uid;

/// 清空会话未读数量
/// @param uid 清空会话的id
- (void)clearConversationMsgCountWithUid:(int64_t)uid;

/// 保存草稿消息
/// @param uid 保存草稿会话的id
/// @param draft 保存草稿会话的文字
- (void)saveDraftToConversationWithUid:(int64_t)uid draft:(NSString*)draft
API_DEPRECATED_WITH_REPLACEMENT("-saveDraftMessageWithUid:draft:conversation:",
    macos(10.0, API_TO_BE_DEPRECATED), ios(2.0, API_TO_BE_DEPRECATED));

/// Save draft message.
/// @param uid The uid of the conversation where the draft will be saved.
/// @param draft The string of the conversation where the draft will be saved.
/// @param newConversation The conversation for inspection.
- (void)saveDraftMessageWithUid:(int64_t)uid draft:(NSString*)draft conversation:(Conversation*)newConversation;

/// 修改会话置顶状态
/// @param isTop 是否置顶
/// @param uid 操作会话的uid
- (void)disposeConversationIsTop:(BOOL)isTop uid:(int64_t)uid;

/// 修改会话备注名称
/// @param remarkName 备注名
/// @param uid 操作会话的uid
- (void)updateConversationRemarkName:(NSString*)remarkName uid:(int64_t)uid;

/// 根据uid修改会话targetId、昵称、头像
/// @param targetId 需要记录的targetId
/// @param nickname 需要记录的昵称
/// @param avatar 需要记录的头像
/// @param uid 目标会话uid
- (void)updateConversationTargetId:(NSString*)targetId
                          nickname:(NSString*)nickname
                            avatar:(NSString*)avatar
                               uid:(int64_t)uid;

/// 根据uid修改会话会员信息等
/// @param memberType 需要记录的会员类型
/// @param memberLevel 需要记录的会员等级
/// @param memberImg 需要记录的会员等级背景图
/// @param area 需要记录的地区信息
/// @param remarkName 备注名
/// @param uid 目标会话uid
- (void)updateConversationMemberInfoWithMemberType:(NSInteger)memberType
                                       memberLevel:(NSString*)memberLevel
                                         memberImg:(NSString*)memberImg
                                              area:(NSString*)area
                                        remarkName:(NSString*)remarkName
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
- (void)updateConversationMessageWithContent:(NSString*)content
                                     msgUUID:(NSString*)msgUUID
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
- (Conversation*)getConversationWithTargetUid:(int64_t)targetUid;

/// 修改会话失败状态
/// @param haveFailed 是否有失败消息
/// @param targetUid 目标会话uid
- (void)updateConversationSendFailedStatus:(BOOL)haveFailed targetUid:(int64_t)targetUid;

/// 修改会话撤回状态数据
/// @param uuids 消息uuid数组
- (void)updateConversationCallBackStatusWithMsgUUIDs:(NSArray<NSString*>*)uuids;

/// 手动添加会话
/// @param conversation 所需添加内部咨询会话的conversation
//- (BOOL)manualAddConversationWithConversation:(Conversation*)conversation;

@end

NS_ASSUME_NONNULL_END
