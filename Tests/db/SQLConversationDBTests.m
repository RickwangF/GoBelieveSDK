//
//  SQLConversationDBTests.m
//  gobelieveSDKTests
//
//  Created by Nan Yang on 2021/5/6.
//

#import <XCTest/XCTest.h>

@import Gobelieve;

@interface SQLConversationDBTests : XCTestCase {
    SQLConversationDB* _db;
}
@end

@implementation SQLConversationDBTests

- (void)setUp {
    _db = [SQLConversationDB instance];
}

- (void)testDatabaseCreation {
    XCTAssertNotNil(_db);
    XCTAssertNotNil(_db.dbQueue);
}

@end
