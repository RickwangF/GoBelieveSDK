//
//  MagicTests.m
//  Gobelieve
//
//  Created by Nan Yang on 2021/5/7.
//
//

#import "Conversation+Private.h"
#import "magic.h"

#import <XCTest/XCTest.h>

@interface MagicTests : XCTestCase

@end

@implementation MagicTests

- (void)testStringConcatenation {
    NSString *allColumns =
        @"conversationid, avatar, nickname, timestamp, content, msguuid, is_callback, is_group, is_delete, is_top, "
        @"unreadcount, member_type, member_level, member_img, draft, unsend_tag, target_id, is_self, area, remark_name";
    XCTAssertEqualObjects(@ALL_COL, allColumns);

    NSString *sql1 = [NSString
        stringWithFormat:@"SELECT %@ FROM gb_conversation WHERE member_type = 1 AND is_delete = 0", allColumns];
    NSString *sql2 = @("SELECT " ALL_COL " FROM gb_conversation WHERE member_type = 1 AND is_delete = 0");
    XCTAssertEqualObjects(sql1, sql2);
}

@end
