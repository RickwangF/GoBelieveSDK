//
//  MessageCoordinator.h
//  Gobelieve
//
//  Created by Tingsong Xu on 2021/7/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IMessage;

@interface MessageRecords : NSObject
/// 请求的uuid集合
@property (nonatomic, strong) NSArray<NSString *> *uuids;
/// 没有找到的UUID集合
@property (nonatomic, strong) NSArray<NSString *> *missingUUIDs;
/// 本地数据库查到的消息数据
@property (nonatomic, strong) NSArray<IMessage *> *messages;
@end

@interface MessageCoordinator : NSObject
/// 根据UUID查找多条本地消息，未查到的返回到missingUUIDs中
/// @param uuids 需查询的uuid集合
+ (MessageRecords *)fetchMessagesByUUIDs:(NSArray<NSString *> *)uuids;
@end

NS_ASSUME_NONNULL_END
