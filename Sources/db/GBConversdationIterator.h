//
//  GBConversdationIterator.h
//  gobelieveSDK
//
//  Created by ch999 on 2021/4/25.
//

#import <Foundation/Foundation.h>
#import "Conversation.h"

//由近到远遍历消息
@protocol GBConversdationIterator
- (Conversation *)next;
@end
