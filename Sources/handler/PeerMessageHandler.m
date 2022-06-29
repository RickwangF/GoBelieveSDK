/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageHandler.h"
#import "Message.h"
#import "PeerMessageDB.h"
#import "EPeerMessageDB.h"

@implementation PeerMessageHandler
+(PeerMessageHandler*)instance {
    static PeerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageHandler alloc] init];
        }
    });
    return m;
}

//将发送失败的消息置为成功
-(void)repairFailureMessage:(NSString*)uuid {
    PeerMessageDB *db = [PeerMessageDB instance];
    if (uuid.length > 0) {
        int msgId = [db gobelieveGetMessageId:uuid];
        IMessage *mm = [db gobelieveGetMessage:msgId];
        if (mm != nil) {
            if ((mm.flags & MESSAGE_FLAG_FAILURE) != 0 || (mm.flags & MESSAGE_FLAG_ACK) == 0) {
                mm.flags = mm.flags & (~MESSAGE_FLAG_FAILURE);
                mm.flags = mm.flags | MESSAGE_FLAG_ACK;
                [db gobelieveUpdateFlags:mm.msgLocalID flags:mm.flags];
            }
        }
    }
}

-(BOOL)handleMessage:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    IMMessage *im = msg;
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.rawContent = im.content;
    m.timestamp = msg.timestamp;
    
    if (self.uid == msg.sender) {
        m.flags = m.flags|MESSAGE_FLAG_ACK;
    }


    if (im.isSelf) {
        NSAssert(im.sender == self.uid, @"");
        [self repairFailureMessage:m.uuid];
        return true;
    } else if (m.type == MESSAGE_REVOKE) {
        BOOL r = YES;
        MessageRevoke *revoke = m.revokeContent;
        int msgId = [[PeerMessageDB instance] gobelieveGetMessageId:revoke.msgid];
        if (msgId > 0) {
            r = [[PeerMessageDB instance] gobelieveUpdateMessageContent:msgId content:msg.content];
            [[PeerMessageDB instance] gobelieveRemoveMessageIndex:msgId];
        }
        return r;
    } else {
        BOOL r = [[PeerMessageDB instance] insertMessage:m uid:pid];
        if (r) {
            msg.msgLocalID = m.msgLocalID;
        }
        return r;
    }
}

-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error {
    if (error == MSG_ACK_SUCCESS) {
        if (msg.msgLocalID > 0) {
            return [[PeerMessageDB instance] gobelieveAcknowledgeMessage:(int)msg.msgLocalID];
        } else {
            MessageContent *content = [IMessage fromRaw:msg.plainContent];
            if (content.type == MESSAGE_REVOKE) {
                MessageRevoke *revoke = (MessageRevoke*)content;
                int revokedMsgId = [[PeerMessageDB instance] gobelieveGetMessageId:revoke.msgid];
                if (revokedMsgId > 0) {
                    [[PeerMessageDB instance]  gobelieveUpdateMessageContent:revokedMsgId content:content.raw];
                    [[PeerMessageDB instance] gobelieveRemoveMessageIndex:revokedMsgId];
                }
            }
            return YES;
        }
    } else {
        PeerMessageDB *db = [PeerMessageDB instance];
        
        MessageACK *ack = [[MessageACK alloc] initWithError:error];
        IMessage *ackMsg = [[IMessage alloc] init];
        ackMsg.sender = 0;
        ackMsg.receiver = msg.sender;
        ackMsg.timestamp = [self getNowTimeTimestamp];
        ackMsg.content = ack;
        [db insertMessage:ackMsg uid:msg.receiver];
        
        if (msg.msgLocalID > 0) {
            return [db gobelieveMarkMessageFailure:msg.msgLocalID];
        }
        return true;
    }
}

- (NSInteger)getNowTimeTimestamp{

    NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式

    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970]*1000)];

    return [timeSp integerValue];
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
    PeerMessageDB *db = [PeerMessageDB instance];
    return [db gobelieveMarkMessageFailure:msg.msgLocalID];
}

@end
