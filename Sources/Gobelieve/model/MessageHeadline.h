//
//  MessageHeadline.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageHeadline : MessageNotification
@property(nonatomic, readonly) NSString *headline;

-(id)initWithHeadline:(NSString*)headline;

@end
