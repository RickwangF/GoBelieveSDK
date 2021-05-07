//
//  MessageRevoke.h
//  Pods
//
//  Created by houxh on 2018/6/26.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageRevoke : MessageNotification
- (id)initWithMsgId:(NSString*)msgid;

@property(nonatomic, readonly) NSString* msgid;
@end
