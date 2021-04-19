////
////  SQLConversationDB.m
////  gobelieveSDK
////
////  Created by ch999 on 2021/4/19.
////
//
//#import "SQLConversationDB.h"
//#import "NSString+JSMessagesView.h"
//
//static const NSString *converALlColumns = @"avatar, nickname, timestamp, latestmsgcontent, latestmsguuid, latestmsgrecalltag, grouptag, deletetag, toptag, unreadcount";
//
//@implementation SQLConversationDB
//+ (SQLConversationDB *)instance {
//    static SQLConversationDB *m;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        if (!m) {
//            m = [[SQLConversationDB alloc] init];
//        }
//    });
//    return m;
//}
//
///// 创建会话表
//- (BOOL)createConversationTable {
//    if (self.conversationTableId > 0) {
//        FMDatabase *db = self.db;
//        [db beginTransaction];
//        
//        NSString *converTableName = [NSString stringWithFormat:@"GBConversationTable%ld", self.conversationTableId];
//        
//        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, %@)", converTableName, converALlColumns];
//        
//        if (!result) {
//            NSLog(@"error = %@", [db lastErrorMessage]);
//            [db rollback];
//            return NO;
//        }
//        
//        NSLog(@">>> 建立%@表成功", converTableName);
//        return YES;
//    }else{
//        return NO;
//    }
//}
//
///// 添加会话
///// @param conversation 添加的会话
//- (BOOL)addConversation:(Conversation *)conversation {
//    FMDatabase *db = self.db;
//    [db beginTransaction];
//    
//    NSString *converTableName = [NSString stringWithFormat:@"GBConversationTable%ld", self.conversationTableId];
//    //@"avatar, nickname, timestamp, latestmsgcontent, latestmsguuid, latestmsgrecalltag, grouptag, deletetag, toptag, unreadcount"
//    
//    NSString *avatar = [conversation.avatarURL hasContent] ? conversation.avatarURL : @"";
//    NSString *nickname = [conversation.name hasContent] ? conversation.name : @"";
//    NSString *latestmsgcontent = [conversation.message.rawContent hasContent] ? conversation.message.rawContent : @"";
//    
//    BOOL result = [db executeUpdate:@"INSERT INTO %@ (%@) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", converTableName, converALlColumns, avatar, nickname, @(conversation.timestamp), ]
//}
//
///// 修改会话数据
///// @param conversation 添加的会话
//- (BOOL)amendConversation:(Conversation *)conversation {
//    
//}
//
///// 修改会话最后一条message的信息
///// @param message 消息
///// targetUid 目标会话uid
//- (BOOL)amendLatestMessage:(IMessage *)message
//                 targetUid:(int64_t)targetUid {
//    
//}
//
///// 获取会话列表
//- (NSArray<Conversation *> *)getAllConversation {
//    
//}
//
///// 根据targetUid获取会话
///// @param targetUid 目标会话uid
//- (Conversation *)getConversationWithTargetUid:(int64_t)targetUid {
//    
//}
//
///// 根据targetUid删除会话
///// @param targetUid 目标会话uid
//- (BOOL)deleteConversationWithTargetUid:(int64_t)targetUid {
//    
//}
//@end
