//
//  GBConversationIterator.h
//  Gobelieve
//
//  Created by ch999 on 2021/4/25.
//

#import "Conversation.h"

#import <Foundation/Foundation.h>

//由近到远遍历消息
@protocol GBConversationIterator
- (nullable Conversation *)next;
@end
