/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */
#import "IMessageDB.h"
#import "SQLPeerMessageDB.h"

@interface PeerMessageDB : SQLPeerMessageDB <IMessageDB>
+ (PeerMessageDB * _Nonnull)instance;

/// 批量更新多个消息为已读状态
/// @param uuids 消息唯一标识符
- (BOOL)markMesagesHaveRead:(NSArray<NSString *> * _Nonnull)uuids;
@end
