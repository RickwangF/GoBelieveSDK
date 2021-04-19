/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageContent.h"


@implementation MessageContent
- (id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
    }
    return self;
}

-(void)setRaw:(NSString *)raw {
    _raw = [raw copy];
    const char *utf8 = [raw UTF8String];
    if (utf8 == nil) return;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    self.dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
}

-(NSString*)uuid {
    return [self.dict objectForKey:@"uuid"];
}

//- (void)setVersion:(NSInteger)version {
//    _version = version;
//}
//
//- (void)setTarget_type:(NSString *)target_type {
//    _target_type = target_type;
//}
//
//- (void)setTarget_id:(NSString *)target_id {
//    _target_id = target_id;
//}
//
//- (void)setFrom_type:(NSString *)from_type {
//    _from_type = from_type;
//}
//
//- (void)setFrom_id:(NSString *)from_id {
//    _from_id = from_id;
//}
//
//- (void)setMsg_type:(NSString *)msg_type {
//    _msg_type = msg_type;
//}
//
//- (void)setMsg_body:(NSDictionary *)msg_body {
//    _msg_body = msg_body;
//}

-(int)type {
    return MESSAGE_UNKNOWN;
}

@end
