//
//  IMessage+CreatorMode.h
//  GobelieveTests
//
//  Created by Tingsong Xu on 2021/6/1.
//

#import <Foundation/Foundation.h>
#import <Gobelieve/Gobelieve.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMessage (CreatorMode)
/// 生成多条随机文本聊天消息
/// @param count 指定条数聊天信息
+ (NSArray<IMessage *> *)randomTextMessagesWithCount:(NSInteger)count;
@end

NS_ASSUME_NONNULL_END
