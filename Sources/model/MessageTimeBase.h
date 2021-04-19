//
//  MessageTimeBase.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageTimeBase : MessageNotificationContent
@property(nonatomic, readonly) NSInteger timestamp;

-(id)initWithTimestamp:(NSInteger)ts;

@end

typedef MessageTimeBase MessageTimeBaseContent;
