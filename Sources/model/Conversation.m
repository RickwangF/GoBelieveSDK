//
//  Conversation.m
//  im_demo
//
//  Created by houxh on 2016/12/28.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "Conversation.h"
#import "Conversation+Private.h"

@import FMDB;
@import MJExtension;

@implementation Conversation

+ (nonnull instancetype)conversationFromResultSet:(FMResultSet*)rs {
    Conversation *conversation = [[Conversation alloc] init];
    conversation.uid = [rs longLongIntForColumn:@"conversationid"];
    conversation.avatarURL = [rs stringForColumn:@"avatar"];
    conversation.name = [rs stringForColumn:@"nickname"];
    conversation.timestamp = [rs longLongIntForColumn:@"timestamp"];
    conversation.content = [rs stringForColumn:@"content"];
    conversation.msguuid = [rs stringForColumn:@"msguuid"];
    conversation.isCallback = [rs boolForColumn:@"is_callback"];
    conversation.isGroup = [rs boolForColumn:@"is_group"];
    conversation.isDelete = [rs boolForColumn:@"is_delete"];
    conversation.isTop = [rs boolForColumn:@"is_top"];
    conversation.newMsgCount = [rs intForColumn:@"unreadcount"];
    conversation.memberType = [rs intForColumn:@"member_type"];
    conversation.memberLevel = [rs stringForColumn:@"member_level"];
    conversation.memberImg = [rs stringForColumn:@"member_img"];
    conversation.draft = [rs stringForColumn:@"draft"];
    conversation.unsendTag = [rs boolForColumn:@"unsend_tag"];
    conversation.targetId = [rs stringForColumn:@"target_id"];
    conversation.is_self = [rs boolForColumn:@"is_self"];
    conversation.area = [rs stringForColumn:@"area"];
    conversation.remarkName = [rs stringForColumn:@"remark_name"];
    conversation.conversationType = [rs intForColumn:@"conversation_type"];
    conversation.isMute = [rs boolForColumn:@"is_mute"];
    conversation.atMsg = [rs stringForColumn:@"atmsg"];
    return conversation;
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{
        @"isMute": @"is_mute",
        @"atMsg": @"atMessagePrefix"
    };
}

@end

@implementation IGroup


@end
