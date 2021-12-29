//
//  Conversation.h
//  im_demo
//
//  Created by houxh on 2016/12/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"

@interface Conversation : NSObject
/// 会话昵称
@property(nonatomic, copy, nullable) NSString* name;
/// 会话头像
@property(nonatomic, copy, nullable) NSString* avatarURL;
/// 会话最后一条显示描述内容
@property(nonatomic, copy, nullable) NSString* content;
/// 会话最后一条消息uuid
@property(nonatomic, copy, nullable) NSString* msguuid;
/// 会话对象targetUid
@property(nonatomic, assign) int64_t uid;
/// 会话对象targetId
@property(nonatomic, copy, nullable) NSString* targetId;
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
@property(nonatomic, copy, nullable) NSString* memberLevel;
/// 用户类型
@property(nonatomic, assign) NSInteger memberType;
/// 会话会员背景图
@property(nonatomic, copy, nullable) NSString* memberImg;
/// 会话是否有草稿
@property(nonatomic, copy, nullable) NSString* draft;
/// 会话是否有发送失败的消息
@property(nonatomic, assign) BOOL unsendTag;
/// 会话新消息条数
@property(nonatomic, assign) int newMsgCount;
/// 会话时间
@property(nonatomic, assign) NSInteger timestamp;
/// 最后一条消息是否自己发送
@property(nonatomic, assign) BOOL is_self;
/// 会员地区
@property(nonatomic, copy, nullable) NSString* area;
/// 备注名
@property(nonatomic, copy, nullable) NSString* remarkName;
/// 会话类型：0会员在线客服，1内部员工私聊，2专属客服聊天，3内部员工在线客服
@property(nonatomic, assign) NSInteger conversationType;
@end

@interface IGroup : NSObject
@property(nonatomic, assign) int64_t gid;
@property(nonatomic, copy, nullable) NSString* name;
@property(nonatomic, copy, nullable) NSString* avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy, nullable) NSString* identifier;

@end
