//
// Created by Nan Yang on 2021/5/7.
//

#import "Conversation.h"
#import "magic.h"

#import <Foundation/Foundation.h>

#define COL_UID conversationid
#define COL_AVATARURL avatar
#define COL_NAME nickname
#define COL_TIMESTAMP timestamp
#define COL_CONTENT content
#define COL_MSGUUID msguuid
#define COL_ISCALLBACK is_callback
#define COL_ISGROUP is_group
#define COL_ISDELETE is_delete
#define COL_ISTOP is_top
#define COL_NEWMSGCOUNT unreadcount
#define COL_MEMBERTYPE member_type
#define COL_MEMBERLEVEL member_level
#define COL_MEMBERIMG member_img
#define COL_DRAFT draft
#define COL_UNSENDTAG unsend_tag
#define COL_TARGETID target_id
#define COL_IS_SELF is_self
#define COL_AREA area
#define COL_REMARKNAME remark_name
#define COL_CONVERSATION_TYPE conversation_type

#define ALL_COL                                                                                                        \
    comma(COL_UID, COL_AVATARURL, COL_NAME, COL_TIMESTAMP, COL_CONTENT, COL_MSGUUID, COL_ISCALLBACK, COL_ISGROUP,      \
          COL_ISDELETE, COL_ISTOP, COL_NEWMSGCOUNT, COL_MEMBERTYPE, COL_MEMBERLEVEL, COL_MEMBERIMG, COL_DRAFT,         \
          COL_UNSENDTAG, COL_TARGETID, COL_IS_SELF, COL_AREA, COL_REMARKNAME, COL_CONVERSATION_TYPE)

@class FMResultSet;

@interface Conversation (Private)

+ (nonnull instancetype)conversationFromResultSet:(nonnull FMResultSet *)resultSet;

@end
