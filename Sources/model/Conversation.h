//
//  Conversation.h
//  im_demo
//
//  Created by houxh on 2016/12/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"

//会话类型
#define CONVERSATION_PEER 1
#define CONVERSATION_GROUP 2
#define CONVERSATION_SYSTEM 3
#define CONVERSATION_CUSTOMER_SERVICE 4

@interface Conversation : NSObject
//@property(nonatomic) int type;
//@property(nonatomic, assign) int64_t cid;
//@property(nonatomic) IMessage *message;
//@property(nonatomic, copy) NSString *detail;
/// 会话昵称
@property(nonatomic, copy) NSString *name;
/// 会话头像
@property(nonatomic, copy) NSString *avatarURL;
/// 会话最后一条显示描述内容
@property(nonatomic, copy) NSString *content;
/// 会话最后一条消息uuid
@property(nonatomic, copy) NSString *msguuid;
/// 会话对象targetUid
@property(nonatomic, assign) int64_t uid;
/// 会话对象targetId
@property (nonatomic, copy) NSString *targetId;
/// 会话是否置顶
@property(nonatomic, assign) BOOL isTop;
/// 会话最后一条消息是否撤回
@property(nonatomic, assign) BOOL isCallback;
/// 会话最后一条消息是否删除
@property(nonatomic, assign) BOOL isDelete;
/// 会话是否是群聊
@property(nonatomic, assign) BOOL isGroup;
/// 订制
/// 会话用户会员等级
@property(nonatomic, copy) NSString *memberLevel;
/// 用户类型
@property(nonatomic, assign) NSInteger memberType;
/// 会话会员背景图
@property(nonatomic, copy) NSString *memberImg;
/// 会话是否有草稿
@property(nonatomic, copy) NSString *draft;
/// 会话是否有发送失败的消息
@property(nonatomic, assign) BOOL unsendTag;
/// 会话新消息条数
@property(nonatomic) int newMsgCount;
/// 会话时间
@property(nonatomic) NSInteger timestamp;
/// 最后一条消息是否自己发送
@property(nonatomic, assign) BOOL is_self;
/// 会员地区
@property(nonatomic, copy) NSString *area;
/// 备注名
@property(nonatomic, copy) NSString *remarkName;
/// 会话类型
@property(nonatomic, assign) NSInteger conversationType;
@end

@interface IGroup : NSObject
@property(nonatomic, assign) int64_t gid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy) NSString *identifier;

@end
