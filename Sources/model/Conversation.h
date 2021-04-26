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
@property(nonatomic) int type;
@property(nonatomic, assign) int64_t cid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;
@property(nonatomic) IMessage *message;
@property(nonatomic, copy) NSString *content;
@property(nonatomic, copy) NSString *msguuid;
@property(nonatomic, assign) int64_t uid;
@property (nonatomic, copy) NSString *userName;
@property(nonatomic, assign) BOOL isTop;
@property(nonatomic, assign) BOOL isCallback;
@property(nonatomic, assign) BOOL isDelete;
@property(nonatomic, assign) BOOL isGroup;
@property(nonatomic, copy) NSString *memberLevel;
@property(nonatomic, assign) BOOL isMember;

@property(nonatomic) int newMsgCount;
@property(nonatomic, copy) NSString *detail;
@property(nonatomic) NSInteger timestamp;
@end

@interface IGroup : NSObject
@property(nonatomic, assign) int64_t gid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy) NSString *identifier;

@end
