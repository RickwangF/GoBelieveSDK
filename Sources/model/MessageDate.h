//
//  MessageDate.h
//  Gobelieve
//
//  Created by Rick Wang on 2024/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MessageDate : NSObject

@property (nonatomic, assign) NSInteger year;

@property (nonatomic, assign) NSInteger month;

@property (nonatomic, assign) NSInteger day;

@property (nonatomic, assign) NSInteger count;

@property (nonatomic, copy, nullable) NSString *firstuuid;

@end

NS_ASSUME_NONNULL_END
