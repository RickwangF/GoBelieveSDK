//
//  IMessageIterator.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "IMessage.h"

#import <Foundation/Foundation.h>

//由近到远遍历消息
@protocol IMessageIterator
- (IMessage *)next;
@end
