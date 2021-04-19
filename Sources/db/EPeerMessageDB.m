//
//  EPeerMessageDB.m
//  gobelieve
//
//  Created by houxh on 2018/1/17.
//

#import "EPeerMessageDB.h"


@implementation EPeerMessageDB
+(EPeerMessageDB*)instance {
    static EPeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[EPeerMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        self.secret = YES;
    }
    return self;
}


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    [self gobelieveUpdateMessageContent:msg.msgLocalID content:msg.rawContent];
}

-(BOOL)saveMessage:(IMessage*)msg {
    NSAssert(msg.isOutgoing, @"");
    return [self insertMessage:msg uid:msg.receiver];
}

- (BOOL)saveMessage:(IMessage *)msg andUid:(int64_t)uid {
    return [self insertMessage:msg uid:uid];
}



@end
